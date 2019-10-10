
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
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
  Call_PostDescribeDBLogFiles_603880 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBLogFiles_603882(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_603881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603883 = query.getOrDefault("Action")
  valid_603883 = validateParameter(valid_603883, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603883 != nil:
    section.add "Action", valid_603883
  var valid_603884 = query.getOrDefault("Version")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603884 != nil:
    section.add "Version", valid_603884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Content-Sha256", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Algorithm")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Algorithm", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Signature")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Signature", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-SignedHeaders", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_603892 = formData.getOrDefault("FilenameContains")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "FilenameContains", valid_603892
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603893 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = nil)
  if valid_603893 != nil:
    section.add "DBInstanceIdentifier", valid_603893
  var valid_603894 = formData.getOrDefault("FileSize")
  valid_603894 = validateParameter(valid_603894, JInt, required = false, default = nil)
  if valid_603894 != nil:
    section.add "FileSize", valid_603894
  var valid_603895 = formData.getOrDefault("Marker")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "Marker", valid_603895
  var valid_603896 = formData.getOrDefault("MaxRecords")
  valid_603896 = validateParameter(valid_603896, JInt, required = false, default = nil)
  if valid_603896 != nil:
    section.add "MaxRecords", valid_603896
  var valid_603897 = formData.getOrDefault("FileLastWritten")
  valid_603897 = validateParameter(valid_603897, JInt, required = false, default = nil)
  if valid_603897 != nil:
    section.add "FileLastWritten", valid_603897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603898: Call_PostDescribeDBLogFiles_603880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603898.validator(path, query, header, formData, body)
  let scheme = call_603898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603898.url(scheme.get, call_603898.host, call_603898.base,
                         call_603898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603898, url, valid)

proc call*(call_603899: Call_PostDescribeDBLogFiles_603880;
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
  var query_603900 = newJObject()
  var formData_603901 = newJObject()
  add(formData_603901, "FilenameContains", newJString(FilenameContains))
  add(formData_603901, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603901, "FileSize", newJInt(FileSize))
  add(formData_603901, "Marker", newJString(Marker))
  add(query_603900, "Action", newJString(Action))
  add(formData_603901, "MaxRecords", newJInt(MaxRecords))
  add(formData_603901, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603900, "Version", newJString(Version))
  result = call_603899.call(nil, query_603900, nil, formData_603901, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603880(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603881, base: "/",
    url: url_PostDescribeDBLogFiles_603882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603859 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBLogFiles_603861(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_603860(path: JsonNode; query: JsonNode;
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
  var valid_603862 = query.getOrDefault("FileLastWritten")
  valid_603862 = validateParameter(valid_603862, JInt, required = false, default = nil)
  if valid_603862 != nil:
    section.add "FileLastWritten", valid_603862
  var valid_603863 = query.getOrDefault("MaxRecords")
  valid_603863 = validateParameter(valid_603863, JInt, required = false, default = nil)
  if valid_603863 != nil:
    section.add "MaxRecords", valid_603863
  var valid_603864 = query.getOrDefault("FilenameContains")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "FilenameContains", valid_603864
  var valid_603865 = query.getOrDefault("FileSize")
  valid_603865 = validateParameter(valid_603865, JInt, required = false, default = nil)
  if valid_603865 != nil:
    section.add "FileSize", valid_603865
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603866 = query.getOrDefault("Action")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603866 != nil:
    section.add "Action", valid_603866
  var valid_603867 = query.getOrDefault("Marker")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "Marker", valid_603867
  var valid_603868 = query.getOrDefault("Version")
  valid_603868 = validateParameter(valid_603868, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603868 != nil:
    section.add "Version", valid_603868
  var valid_603869 = query.getOrDefault("DBInstanceIdentifier")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = nil)
  if valid_603869 != nil:
    section.add "DBInstanceIdentifier", valid_603869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603870 = header.getOrDefault("X-Amz-Date")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Date", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Security-Token")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Security-Token", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Content-Sha256", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Algorithm")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Algorithm", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Signature")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Signature", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-SignedHeaders", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Credential")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Credential", valid_603876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603877: Call_GetDescribeDBLogFiles_603859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603877.validator(path, query, header, formData, body)
  let scheme = call_603877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603877.url(scheme.get, call_603877.host, call_603877.base,
                         call_603877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603877, url, valid)

proc call*(call_603878: Call_GetDescribeDBLogFiles_603859;
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
  var query_603879 = newJObject()
  add(query_603879, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603879, "MaxRecords", newJInt(MaxRecords))
  add(query_603879, "FilenameContains", newJString(FilenameContains))
  add(query_603879, "FileSize", newJInt(FileSize))
  add(query_603879, "Action", newJString(Action))
  add(query_603879, "Marker", newJString(Marker))
  add(query_603879, "Version", newJString(Version))
  add(query_603879, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603878.call(nil, query_603879, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603859(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603860, base: "/",
    url: url_GetDescribeDBLogFiles_603861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_603920 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameterGroups_603922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_603921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603923 = query.getOrDefault("Action")
  valid_603923 = validateParameter(valid_603923, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603923 != nil:
    section.add "Action", valid_603923
  var valid_603924 = query.getOrDefault("Version")
  valid_603924 = validateParameter(valid_603924, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603924 != nil:
    section.add "Version", valid_603924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603925 = header.getOrDefault("X-Amz-Date")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Date", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Security-Token")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Security-Token", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Content-Sha256", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Algorithm")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Algorithm", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Signature")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Signature", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-SignedHeaders", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Credential")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Credential", valid_603931
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603932 = formData.getOrDefault("DBParameterGroupName")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "DBParameterGroupName", valid_603932
  var valid_603933 = formData.getOrDefault("Marker")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "Marker", valid_603933
  var valid_603934 = formData.getOrDefault("MaxRecords")
  valid_603934 = validateParameter(valid_603934, JInt, required = false, default = nil)
  if valid_603934 != nil:
    section.add "MaxRecords", valid_603934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603935: Call_PostDescribeDBParameterGroups_603920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603935.validator(path, query, header, formData, body)
  let scheme = call_603935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603935.url(scheme.get, call_603935.host, call_603935.base,
                         call_603935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603935, url, valid)

proc call*(call_603936: Call_PostDescribeDBParameterGroups_603920;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603937 = newJObject()
  var formData_603938 = newJObject()
  add(formData_603938, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603938, "Marker", newJString(Marker))
  add(query_603937, "Action", newJString(Action))
  add(formData_603938, "MaxRecords", newJInt(MaxRecords))
  add(query_603937, "Version", newJString(Version))
  result = call_603936.call(nil, query_603937, nil, formData_603938, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_603920(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_603921, base: "/",
    url: url_PostDescribeDBParameterGroups_603922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603902 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameterGroups_603904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_603903(path: JsonNode; query: JsonNode;
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
  var valid_603905 = query.getOrDefault("MaxRecords")
  valid_603905 = validateParameter(valid_603905, JInt, required = false, default = nil)
  if valid_603905 != nil:
    section.add "MaxRecords", valid_603905
  var valid_603906 = query.getOrDefault("DBParameterGroupName")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "DBParameterGroupName", valid_603906
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603907 = query.getOrDefault("Action")
  valid_603907 = validateParameter(valid_603907, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603907 != nil:
    section.add "Action", valid_603907
  var valid_603908 = query.getOrDefault("Marker")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "Marker", valid_603908
  var valid_603909 = query.getOrDefault("Version")
  valid_603909 = validateParameter(valid_603909, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603909 != nil:
    section.add "Version", valid_603909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603910 = header.getOrDefault("X-Amz-Date")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Date", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Security-Token")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Security-Token", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Content-Sha256", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Algorithm")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Algorithm", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Signature")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Signature", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-SignedHeaders", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Credential")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Credential", valid_603916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603917: Call_GetDescribeDBParameterGroups_603902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603917.validator(path, query, header, formData, body)
  let scheme = call_603917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603917.url(scheme.get, call_603917.host, call_603917.base,
                         call_603917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603917, url, valid)

proc call*(call_603918: Call_GetDescribeDBParameterGroups_603902;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603919 = newJObject()
  add(query_603919, "MaxRecords", newJInt(MaxRecords))
  add(query_603919, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603919, "Action", newJString(Action))
  add(query_603919, "Marker", newJString(Marker))
  add(query_603919, "Version", newJString(Version))
  result = call_603918.call(nil, query_603919, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603902(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603903, base: "/",
    url: url_GetDescribeDBParameterGroups_603904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_603958 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameters_603960(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_603959(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DescribeDBParameters"))
  if valid_603961 != nil:
    section.add "Action", valid_603961
  var valid_603962 = query.getOrDefault("Version")
  valid_603962 = validateParameter(valid_603962, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603970 = formData.getOrDefault("DBParameterGroupName")
  valid_603970 = validateParameter(valid_603970, JString, required = true,
                                 default = nil)
  if valid_603970 != nil:
    section.add "DBParameterGroupName", valid_603970
  var valid_603971 = formData.getOrDefault("Marker")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "Marker", valid_603971
  var valid_603972 = formData.getOrDefault("MaxRecords")
  valid_603972 = validateParameter(valid_603972, JInt, required = false, default = nil)
  if valid_603972 != nil:
    section.add "MaxRecords", valid_603972
  var valid_603973 = formData.getOrDefault("Source")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "Source", valid_603973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603974: Call_PostDescribeDBParameters_603958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603974.validator(path, query, header, formData, body)
  let scheme = call_603974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603974.url(scheme.get, call_603974.host, call_603974.base,
                         call_603974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603974, url, valid)

proc call*(call_603975: Call_PostDescribeDBParameters_603958;
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
  var query_603976 = newJObject()
  var formData_603977 = newJObject()
  add(formData_603977, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603977, "Marker", newJString(Marker))
  add(query_603976, "Action", newJString(Action))
  add(formData_603977, "MaxRecords", newJInt(MaxRecords))
  add(query_603976, "Version", newJString(Version))
  add(formData_603977, "Source", newJString(Source))
  result = call_603975.call(nil, query_603976, nil, formData_603977, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_603958(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_603959, base: "/",
    url: url_PostDescribeDBParameters_603960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_603939 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameters_603941(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_603940(path: JsonNode; query: JsonNode;
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
  var valid_603942 = query.getOrDefault("MaxRecords")
  valid_603942 = validateParameter(valid_603942, JInt, required = false, default = nil)
  if valid_603942 != nil:
    section.add "MaxRecords", valid_603942
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603943 = query.getOrDefault("DBParameterGroupName")
  valid_603943 = validateParameter(valid_603943, JString, required = true,
                                 default = nil)
  if valid_603943 != nil:
    section.add "DBParameterGroupName", valid_603943
  var valid_603944 = query.getOrDefault("Action")
  valid_603944 = validateParameter(valid_603944, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603944 != nil:
    section.add "Action", valid_603944
  var valid_603945 = query.getOrDefault("Marker")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "Marker", valid_603945
  var valid_603946 = query.getOrDefault("Source")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "Source", valid_603946
  var valid_603947 = query.getOrDefault("Version")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603947 != nil:
    section.add "Version", valid_603947
  result.add "query", section
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

proc call*(call_603955: Call_GetDescribeDBParameters_603939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603955.validator(path, query, header, formData, body)
  let scheme = call_603955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603955.url(scheme.get, call_603955.host, call_603955.base,
                         call_603955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603955, url, valid)

proc call*(call_603956: Call_GetDescribeDBParameters_603939;
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
  var query_603957 = newJObject()
  add(query_603957, "MaxRecords", newJInt(MaxRecords))
  add(query_603957, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603957, "Action", newJString(Action))
  add(query_603957, "Marker", newJString(Marker))
  add(query_603957, "Source", newJString(Source))
  add(query_603957, "Version", newJString(Version))
  result = call_603956.call(nil, query_603957, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_603939(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_603940, base: "/",
    url: url_GetDescribeDBParameters_603941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_603996 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSecurityGroups_603998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_603997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603999 = query.getOrDefault("Action")
  valid_603999 = validateParameter(valid_603999, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603999 != nil:
    section.add "Action", valid_603999
  var valid_604000 = query.getOrDefault("Version")
  valid_604000 = validateParameter(valid_604000, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604000 != nil:
    section.add "Version", valid_604000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604001 = header.getOrDefault("X-Amz-Date")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Date", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Security-Token")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Security-Token", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Content-Sha256", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Algorithm")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Algorithm", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Signature")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Signature", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Credential")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Credential", valid_604007
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604008 = formData.getOrDefault("DBSecurityGroupName")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "DBSecurityGroupName", valid_604008
  var valid_604009 = formData.getOrDefault("Marker")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "Marker", valid_604009
  var valid_604010 = formData.getOrDefault("MaxRecords")
  valid_604010 = validateParameter(valid_604010, JInt, required = false, default = nil)
  if valid_604010 != nil:
    section.add "MaxRecords", valid_604010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604011: Call_PostDescribeDBSecurityGroups_603996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604011.validator(path, query, header, formData, body)
  let scheme = call_604011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604011.url(scheme.get, call_604011.host, call_604011.base,
                         call_604011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604011, url, valid)

proc call*(call_604012: Call_PostDescribeDBSecurityGroups_603996;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604013 = newJObject()
  var formData_604014 = newJObject()
  add(formData_604014, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604014, "Marker", newJString(Marker))
  add(query_604013, "Action", newJString(Action))
  add(formData_604014, "MaxRecords", newJInt(MaxRecords))
  add(query_604013, "Version", newJString(Version))
  result = call_604012.call(nil, query_604013, nil, formData_604014, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_603996(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_603997, base: "/",
    url: url_PostDescribeDBSecurityGroups_603998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_603978 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSecurityGroups_603980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_603979(path: JsonNode; query: JsonNode;
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
  var valid_603981 = query.getOrDefault("MaxRecords")
  valid_603981 = validateParameter(valid_603981, JInt, required = false, default = nil)
  if valid_603981 != nil:
    section.add "MaxRecords", valid_603981
  var valid_603982 = query.getOrDefault("DBSecurityGroupName")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "DBSecurityGroupName", valid_603982
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603983 = query.getOrDefault("Action")
  valid_603983 = validateParameter(valid_603983, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603983 != nil:
    section.add "Action", valid_603983
  var valid_603984 = query.getOrDefault("Marker")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "Marker", valid_603984
  var valid_603985 = query.getOrDefault("Version")
  valid_603985 = validateParameter(valid_603985, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603985 != nil:
    section.add "Version", valid_603985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603986 = header.getOrDefault("X-Amz-Date")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Date", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Security-Token")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Security-Token", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Content-Sha256", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Algorithm")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Algorithm", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Signature")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Signature", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-SignedHeaders", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Credential")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Credential", valid_603992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603993: Call_GetDescribeDBSecurityGroups_603978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603993.validator(path, query, header, formData, body)
  let scheme = call_603993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603993.url(scheme.get, call_603993.host, call_603993.base,
                         call_603993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603993, url, valid)

proc call*(call_603994: Call_GetDescribeDBSecurityGroups_603978;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603995 = newJObject()
  add(query_603995, "MaxRecords", newJInt(MaxRecords))
  add(query_603995, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603995, "Action", newJString(Action))
  add(query_603995, "Marker", newJString(Marker))
  add(query_603995, "Version", newJString(Version))
  result = call_603994.call(nil, query_603995, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_603978(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_603979, base: "/",
    url: url_GetDescribeDBSecurityGroups_603980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604035 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSnapshots_604037(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

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
                                 default = newJString("2013-02-12"))
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
  var valid_604051 = formData.getOrDefault("MaxRecords")
  valid_604051 = validateParameter(valid_604051, JInt, required = false, default = nil)
  if valid_604051 != nil:
    section.add "MaxRecords", valid_604051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604052: Call_PostDescribeDBSnapshots_604035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604052.validator(path, query, header, formData, body)
  let scheme = call_604052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604052.url(scheme.get, call_604052.host, call_604052.base,
                         call_604052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604052, url, valid)

proc call*(call_604053: Call_PostDescribeDBSnapshots_604035;
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
  var query_604054 = newJObject()
  var formData_604055 = newJObject()
  add(formData_604055, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604055, "SnapshotType", newJString(SnapshotType))
  add(formData_604055, "Marker", newJString(Marker))
  add(formData_604055, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604054, "Action", newJString(Action))
  add(formData_604055, "MaxRecords", newJInt(MaxRecords))
  add(query_604054, "Version", newJString(Version))
  result = call_604053.call(nil, query_604054, nil, formData_604055, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604035(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604036, base: "/",
    url: url_PostDescribeDBSnapshots_604037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_604015 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSnapshots_604017(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_604016(path: JsonNode; query: JsonNode;
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
  var valid_604018 = query.getOrDefault("MaxRecords")
  valid_604018 = validateParameter(valid_604018, JInt, required = false, default = nil)
  if valid_604018 != nil:
    section.add "MaxRecords", valid_604018
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
                                 default = newJString("2013-02-12"))
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

proc call*(call_604032: Call_GetDescribeDBSnapshots_604015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604032.validator(path, query, header, formData, body)
  let scheme = call_604032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604032.url(scheme.get, call_604032.host, call_604032.base,
                         call_604032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604032, url, valid)

proc call*(call_604033: Call_GetDescribeDBSnapshots_604015; MaxRecords: int = 0;
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
  var query_604034 = newJObject()
  add(query_604034, "MaxRecords", newJInt(MaxRecords))
  add(query_604034, "Action", newJString(Action))
  add(query_604034, "Marker", newJString(Marker))
  add(query_604034, "SnapshotType", newJString(SnapshotType))
  add(query_604034, "Version", newJString(Version))
  add(query_604034, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604034, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604033.call(nil, query_604034, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_604015(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_604016, base: "/",
    url: url_GetDescribeDBSnapshots_604017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604074 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSubnetGroups_604076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_604075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604077 = query.getOrDefault("Action")
  valid_604077 = validateParameter(valid_604077, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604077 != nil:
    section.add "Action", valid_604077
  var valid_604078 = query.getOrDefault("Version")
  valid_604078 = validateParameter(valid_604078, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604078 != nil:
    section.add "Version", valid_604078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604079 = header.getOrDefault("X-Amz-Date")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Date", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Security-Token")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Security-Token", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Content-Sha256", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Algorithm")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Algorithm", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Signature")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Signature", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-SignedHeaders", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Credential")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Credential", valid_604085
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604086 = formData.getOrDefault("DBSubnetGroupName")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "DBSubnetGroupName", valid_604086
  var valid_604087 = formData.getOrDefault("Marker")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "Marker", valid_604087
  var valid_604088 = formData.getOrDefault("MaxRecords")
  valid_604088 = validateParameter(valid_604088, JInt, required = false, default = nil)
  if valid_604088 != nil:
    section.add "MaxRecords", valid_604088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604089: Call_PostDescribeDBSubnetGroups_604074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604089.validator(path, query, header, formData, body)
  let scheme = call_604089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604089.url(scheme.get, call_604089.host, call_604089.base,
                         call_604089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604089, url, valid)

proc call*(call_604090: Call_PostDescribeDBSubnetGroups_604074;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604091 = newJObject()
  var formData_604092 = newJObject()
  add(formData_604092, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604092, "Marker", newJString(Marker))
  add(query_604091, "Action", newJString(Action))
  add(formData_604092, "MaxRecords", newJInt(MaxRecords))
  add(query_604091, "Version", newJString(Version))
  result = call_604090.call(nil, query_604091, nil, formData_604092, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604074(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604075, base: "/",
    url: url_PostDescribeDBSubnetGroups_604076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604056 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSubnetGroups_604058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_604057(path: JsonNode; query: JsonNode;
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
  var valid_604059 = query.getOrDefault("MaxRecords")
  valid_604059 = validateParameter(valid_604059, JInt, required = false, default = nil)
  if valid_604059 != nil:
    section.add "MaxRecords", valid_604059
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604060 = query.getOrDefault("Action")
  valid_604060 = validateParameter(valid_604060, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604060 != nil:
    section.add "Action", valid_604060
  var valid_604061 = query.getOrDefault("Marker")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "Marker", valid_604061
  var valid_604062 = query.getOrDefault("DBSubnetGroupName")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "DBSubnetGroupName", valid_604062
  var valid_604063 = query.getOrDefault("Version")
  valid_604063 = validateParameter(valid_604063, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604063 != nil:
    section.add "Version", valid_604063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604064 = header.getOrDefault("X-Amz-Date")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Date", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Security-Token")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Security-Token", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Content-Sha256", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Algorithm")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Algorithm", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-Signature")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Signature", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-SignedHeaders", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Credential")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Credential", valid_604070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604071: Call_GetDescribeDBSubnetGroups_604056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604071.validator(path, query, header, formData, body)
  let scheme = call_604071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604071.url(scheme.get, call_604071.host, call_604071.base,
                         call_604071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604071, url, valid)

proc call*(call_604072: Call_GetDescribeDBSubnetGroups_604056; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_604073 = newJObject()
  add(query_604073, "MaxRecords", newJInt(MaxRecords))
  add(query_604073, "Action", newJString(Action))
  add(query_604073, "Marker", newJString(Marker))
  add(query_604073, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604073, "Version", newJString(Version))
  result = call_604072.call(nil, query_604073, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604056(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604057, base: "/",
    url: url_GetDescribeDBSubnetGroups_604058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604111 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEngineDefaultParameters_604113(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_604112(path: JsonNode;
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
  var valid_604114 = query.getOrDefault("Action")
  valid_604114 = validateParameter(valid_604114, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604114 != nil:
    section.add "Action", valid_604114
  var valid_604115 = query.getOrDefault("Version")
  valid_604115 = validateParameter(valid_604115, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604115 != nil:
    section.add "Version", valid_604115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604116 = header.getOrDefault("X-Amz-Date")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Date", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Security-Token")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Security-Token", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Content-Sha256", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Algorithm")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Algorithm", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Signature")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Signature", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-SignedHeaders", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Credential")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Credential", valid_604122
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604123 = formData.getOrDefault("Marker")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "Marker", valid_604123
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604124 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604124 = validateParameter(valid_604124, JString, required = true,
                                 default = nil)
  if valid_604124 != nil:
    section.add "DBParameterGroupFamily", valid_604124
  var valid_604125 = formData.getOrDefault("MaxRecords")
  valid_604125 = validateParameter(valid_604125, JInt, required = false, default = nil)
  if valid_604125 != nil:
    section.add "MaxRecords", valid_604125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604126: Call_PostDescribeEngineDefaultParameters_604111;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604126.validator(path, query, header, formData, body)
  let scheme = call_604126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604126.url(scheme.get, call_604126.host, call_604126.base,
                         call_604126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604126, url, valid)

proc call*(call_604127: Call_PostDescribeEngineDefaultParameters_604111;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604128 = newJObject()
  var formData_604129 = newJObject()
  add(formData_604129, "Marker", newJString(Marker))
  add(query_604128, "Action", newJString(Action))
  add(formData_604129, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_604129, "MaxRecords", newJInt(MaxRecords))
  add(query_604128, "Version", newJString(Version))
  result = call_604127.call(nil, query_604128, nil, formData_604129, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604111(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604112, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604093 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEngineDefaultParameters_604095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_604094(path: JsonNode;
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
  var valid_604096 = query.getOrDefault("MaxRecords")
  valid_604096 = validateParameter(valid_604096, JInt, required = false, default = nil)
  if valid_604096 != nil:
    section.add "MaxRecords", valid_604096
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604097 = query.getOrDefault("DBParameterGroupFamily")
  valid_604097 = validateParameter(valid_604097, JString, required = true,
                                 default = nil)
  if valid_604097 != nil:
    section.add "DBParameterGroupFamily", valid_604097
  var valid_604098 = query.getOrDefault("Action")
  valid_604098 = validateParameter(valid_604098, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604098 != nil:
    section.add "Action", valid_604098
  var valid_604099 = query.getOrDefault("Marker")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "Marker", valid_604099
  var valid_604100 = query.getOrDefault("Version")
  valid_604100 = validateParameter(valid_604100, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604100 != nil:
    section.add "Version", valid_604100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604101 = header.getOrDefault("X-Amz-Date")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Date", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Security-Token")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Security-Token", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Content-Sha256", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-Algorithm")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-Algorithm", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Signature")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Signature", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-SignedHeaders", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Credential")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Credential", valid_604107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604108: Call_GetDescribeEngineDefaultParameters_604093;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604108.validator(path, query, header, formData, body)
  let scheme = call_604108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604108.url(scheme.get, call_604108.host, call_604108.base,
                         call_604108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604108, url, valid)

proc call*(call_604109: Call_GetDescribeEngineDefaultParameters_604093;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_604110 = newJObject()
  add(query_604110, "MaxRecords", newJInt(MaxRecords))
  add(query_604110, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_604110, "Action", newJString(Action))
  add(query_604110, "Marker", newJString(Marker))
  add(query_604110, "Version", newJString(Version))
  result = call_604109.call(nil, query_604110, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604093(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604094, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604146 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventCategories_604148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_604147(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604149 = query.getOrDefault("Action")
  valid_604149 = validateParameter(valid_604149, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604149 != nil:
    section.add "Action", valid_604149
  var valid_604150 = query.getOrDefault("Version")
  valid_604150 = validateParameter(valid_604150, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604150 != nil:
    section.add "Version", valid_604150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604151 = header.getOrDefault("X-Amz-Date")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Date", valid_604151
  var valid_604152 = header.getOrDefault("X-Amz-Security-Token")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Security-Token", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Content-Sha256", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Algorithm")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Algorithm", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Signature")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Signature", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-SignedHeaders", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Credential")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Credential", valid_604157
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_604158 = formData.getOrDefault("SourceType")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "SourceType", valid_604158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604159: Call_PostDescribeEventCategories_604146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604159.validator(path, query, header, formData, body)
  let scheme = call_604159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604159.url(scheme.get, call_604159.host, call_604159.base,
                         call_604159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604159, url, valid)

proc call*(call_604160: Call_PostDescribeEventCategories_604146;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_604161 = newJObject()
  var formData_604162 = newJObject()
  add(query_604161, "Action", newJString(Action))
  add(query_604161, "Version", newJString(Version))
  add(formData_604162, "SourceType", newJString(SourceType))
  result = call_604160.call(nil, query_604161, nil, formData_604162, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604146(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604147, base: "/",
    url: url_PostDescribeEventCategories_604148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604130 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventCategories_604132(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_604131(path: JsonNode; query: JsonNode;
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
  var valid_604133 = query.getOrDefault("SourceType")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "SourceType", valid_604133
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604134 = query.getOrDefault("Action")
  valid_604134 = validateParameter(valid_604134, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604134 != nil:
    section.add "Action", valid_604134
  var valid_604135 = query.getOrDefault("Version")
  valid_604135 = validateParameter(valid_604135, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604135 != nil:
    section.add "Version", valid_604135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604136 = header.getOrDefault("X-Amz-Date")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Date", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-Security-Token")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-Security-Token", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Content-Sha256", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Algorithm")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Algorithm", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Signature")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Signature", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Credential")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Credential", valid_604142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604143: Call_GetDescribeEventCategories_604130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604143.validator(path, query, header, formData, body)
  let scheme = call_604143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604143.url(scheme.get, call_604143.host, call_604143.base,
                         call_604143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604143, url, valid)

proc call*(call_604144: Call_GetDescribeEventCategories_604130;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604145 = newJObject()
  add(query_604145, "SourceType", newJString(SourceType))
  add(query_604145, "Action", newJString(Action))
  add(query_604145, "Version", newJString(Version))
  result = call_604144.call(nil, query_604145, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604130(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604131, base: "/",
    url: url_GetDescribeEventCategories_604132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604181 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventSubscriptions_604183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_604182(path: JsonNode;
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
  var valid_604184 = query.getOrDefault("Action")
  valid_604184 = validateParameter(valid_604184, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604184 != nil:
    section.add "Action", valid_604184
  var valid_604185 = query.getOrDefault("Version")
  valid_604185 = validateParameter(valid_604185, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604185 != nil:
    section.add "Version", valid_604185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604186 = header.getOrDefault("X-Amz-Date")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Date", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Security-Token")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Security-Token", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Content-Sha256", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Algorithm")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Algorithm", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Signature")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Signature", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-SignedHeaders", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Credential")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Credential", valid_604192
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604193 = formData.getOrDefault("Marker")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "Marker", valid_604193
  var valid_604194 = formData.getOrDefault("SubscriptionName")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "SubscriptionName", valid_604194
  var valid_604195 = formData.getOrDefault("MaxRecords")
  valid_604195 = validateParameter(valid_604195, JInt, required = false, default = nil)
  if valid_604195 != nil:
    section.add "MaxRecords", valid_604195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604196: Call_PostDescribeEventSubscriptions_604181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604196.validator(path, query, header, formData, body)
  let scheme = call_604196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604196.url(scheme.get, call_604196.host, call_604196.base,
                         call_604196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604196, url, valid)

proc call*(call_604197: Call_PostDescribeEventSubscriptions_604181;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604198 = newJObject()
  var formData_604199 = newJObject()
  add(formData_604199, "Marker", newJString(Marker))
  add(formData_604199, "SubscriptionName", newJString(SubscriptionName))
  add(query_604198, "Action", newJString(Action))
  add(formData_604199, "MaxRecords", newJInt(MaxRecords))
  add(query_604198, "Version", newJString(Version))
  result = call_604197.call(nil, query_604198, nil, formData_604199, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604181(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604182, base: "/",
    url: url_PostDescribeEventSubscriptions_604183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604163 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventSubscriptions_604165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_604164(path: JsonNode; query: JsonNode;
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
  var valid_604166 = query.getOrDefault("MaxRecords")
  valid_604166 = validateParameter(valid_604166, JInt, required = false, default = nil)
  if valid_604166 != nil:
    section.add "MaxRecords", valid_604166
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604167 = query.getOrDefault("Action")
  valid_604167 = validateParameter(valid_604167, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604167 != nil:
    section.add "Action", valid_604167
  var valid_604168 = query.getOrDefault("Marker")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "Marker", valid_604168
  var valid_604169 = query.getOrDefault("SubscriptionName")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "SubscriptionName", valid_604169
  var valid_604170 = query.getOrDefault("Version")
  valid_604170 = validateParameter(valid_604170, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604170 != nil:
    section.add "Version", valid_604170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604171 = header.getOrDefault("X-Amz-Date")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Date", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Security-Token")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Security-Token", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Content-Sha256", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Algorithm")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Algorithm", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Signature")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Signature", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-SignedHeaders", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Credential")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Credential", valid_604177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604178: Call_GetDescribeEventSubscriptions_604163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604178.validator(path, query, header, formData, body)
  let scheme = call_604178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604178.url(scheme.get, call_604178.host, call_604178.base,
                         call_604178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604178, url, valid)

proc call*(call_604179: Call_GetDescribeEventSubscriptions_604163;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_604180 = newJObject()
  add(query_604180, "MaxRecords", newJInt(MaxRecords))
  add(query_604180, "Action", newJString(Action))
  add(query_604180, "Marker", newJString(Marker))
  add(query_604180, "SubscriptionName", newJString(SubscriptionName))
  add(query_604180, "Version", newJString(Version))
  result = call_604179.call(nil, query_604180, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604163(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604164, base: "/",
    url: url_GetDescribeEventSubscriptions_604165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604223 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEvents_604225(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604224(path: JsonNode; query: JsonNode;
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
  var valid_604226 = query.getOrDefault("Action")
  valid_604226 = validateParameter(valid_604226, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604226 != nil:
    section.add "Action", valid_604226
  var valid_604227 = query.getOrDefault("Version")
  valid_604227 = validateParameter(valid_604227, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_604235 = formData.getOrDefault("SourceIdentifier")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "SourceIdentifier", valid_604235
  var valid_604236 = formData.getOrDefault("EventCategories")
  valid_604236 = validateParameter(valid_604236, JArray, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "EventCategories", valid_604236
  var valid_604237 = formData.getOrDefault("Marker")
  valid_604237 = validateParameter(valid_604237, JString, required = false,
                                 default = nil)
  if valid_604237 != nil:
    section.add "Marker", valid_604237
  var valid_604238 = formData.getOrDefault("StartTime")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "StartTime", valid_604238
  var valid_604239 = formData.getOrDefault("Duration")
  valid_604239 = validateParameter(valid_604239, JInt, required = false, default = nil)
  if valid_604239 != nil:
    section.add "Duration", valid_604239
  var valid_604240 = formData.getOrDefault("EndTime")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "EndTime", valid_604240
  var valid_604241 = formData.getOrDefault("MaxRecords")
  valid_604241 = validateParameter(valid_604241, JInt, required = false, default = nil)
  if valid_604241 != nil:
    section.add "MaxRecords", valid_604241
  var valid_604242 = formData.getOrDefault("SourceType")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604242 != nil:
    section.add "SourceType", valid_604242
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604243: Call_PostDescribeEvents_604223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604243.validator(path, query, header, formData, body)
  let scheme = call_604243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604243.url(scheme.get, call_604243.host, call_604243.base,
                         call_604243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604243, url, valid)

proc call*(call_604244: Call_PostDescribeEvents_604223;
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
  var query_604245 = newJObject()
  var formData_604246 = newJObject()
  add(formData_604246, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604246.add "EventCategories", EventCategories
  add(formData_604246, "Marker", newJString(Marker))
  add(formData_604246, "StartTime", newJString(StartTime))
  add(query_604245, "Action", newJString(Action))
  add(formData_604246, "Duration", newJInt(Duration))
  add(formData_604246, "EndTime", newJString(EndTime))
  add(formData_604246, "MaxRecords", newJInt(MaxRecords))
  add(query_604245, "Version", newJString(Version))
  add(formData_604246, "SourceType", newJString(SourceType))
  result = call_604244.call(nil, query_604245, nil, formData_604246, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604223(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604224, base: "/",
    url: url_PostDescribeEvents_604225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604200 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEvents_604202(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604201(path: JsonNode; query: JsonNode;
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
  var valid_604203 = query.getOrDefault("SourceType")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604203 != nil:
    section.add "SourceType", valid_604203
  var valid_604204 = query.getOrDefault("MaxRecords")
  valid_604204 = validateParameter(valid_604204, JInt, required = false, default = nil)
  if valid_604204 != nil:
    section.add "MaxRecords", valid_604204
  var valid_604205 = query.getOrDefault("StartTime")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "StartTime", valid_604205
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604206 = query.getOrDefault("Action")
  valid_604206 = validateParameter(valid_604206, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604206 != nil:
    section.add "Action", valid_604206
  var valid_604207 = query.getOrDefault("SourceIdentifier")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "SourceIdentifier", valid_604207
  var valid_604208 = query.getOrDefault("Marker")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "Marker", valid_604208
  var valid_604209 = query.getOrDefault("EventCategories")
  valid_604209 = validateParameter(valid_604209, JArray, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "EventCategories", valid_604209
  var valid_604210 = query.getOrDefault("Duration")
  valid_604210 = validateParameter(valid_604210, JInt, required = false, default = nil)
  if valid_604210 != nil:
    section.add "Duration", valid_604210
  var valid_604211 = query.getOrDefault("EndTime")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "EndTime", valid_604211
  var valid_604212 = query.getOrDefault("Version")
  valid_604212 = validateParameter(valid_604212, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604212 != nil:
    section.add "Version", valid_604212
  result.add "query", section
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

proc call*(call_604220: Call_GetDescribeEvents_604200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604220.validator(path, query, header, formData, body)
  let scheme = call_604220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604220.url(scheme.get, call_604220.host, call_604220.base,
                         call_604220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604220, url, valid)

proc call*(call_604221: Call_GetDescribeEvents_604200;
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
  var query_604222 = newJObject()
  add(query_604222, "SourceType", newJString(SourceType))
  add(query_604222, "MaxRecords", newJInt(MaxRecords))
  add(query_604222, "StartTime", newJString(StartTime))
  add(query_604222, "Action", newJString(Action))
  add(query_604222, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604222, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604222.add "EventCategories", EventCategories
  add(query_604222, "Duration", newJInt(Duration))
  add(query_604222, "EndTime", newJString(EndTime))
  add(query_604222, "Version", newJString(Version))
  result = call_604221.call(nil, query_604222, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604200(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604201,
    base: "/", url: url_GetDescribeEvents_604202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604266 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroupOptions_604268(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_604267(path: JsonNode;
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
  var valid_604269 = query.getOrDefault("Action")
  valid_604269 = validateParameter(valid_604269, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604269 != nil:
    section.add "Action", valid_604269
  var valid_604270 = query.getOrDefault("Version")
  valid_604270 = validateParameter(valid_604270, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604270 != nil:
    section.add "Version", valid_604270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604271 = header.getOrDefault("X-Amz-Date")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Date", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Security-Token")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Security-Token", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-Content-Sha256", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Algorithm")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Algorithm", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Signature")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Signature", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-SignedHeaders", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Credential")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Credential", valid_604277
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604278 = formData.getOrDefault("MajorEngineVersion")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "MajorEngineVersion", valid_604278
  var valid_604279 = formData.getOrDefault("Marker")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "Marker", valid_604279
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604280 = formData.getOrDefault("EngineName")
  valid_604280 = validateParameter(valid_604280, JString, required = true,
                                 default = nil)
  if valid_604280 != nil:
    section.add "EngineName", valid_604280
  var valid_604281 = formData.getOrDefault("MaxRecords")
  valid_604281 = validateParameter(valid_604281, JInt, required = false, default = nil)
  if valid_604281 != nil:
    section.add "MaxRecords", valid_604281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604282: Call_PostDescribeOptionGroupOptions_604266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604282.validator(path, query, header, formData, body)
  let scheme = call_604282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604282.url(scheme.get, call_604282.host, call_604282.base,
                         call_604282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604282, url, valid)

proc call*(call_604283: Call_PostDescribeOptionGroupOptions_604266;
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
  var query_604284 = newJObject()
  var formData_604285 = newJObject()
  add(formData_604285, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604285, "Marker", newJString(Marker))
  add(query_604284, "Action", newJString(Action))
  add(formData_604285, "EngineName", newJString(EngineName))
  add(formData_604285, "MaxRecords", newJInt(MaxRecords))
  add(query_604284, "Version", newJString(Version))
  result = call_604283.call(nil, query_604284, nil, formData_604285, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604266(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604267, base: "/",
    url: url_PostDescribeOptionGroupOptions_604268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604247 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroupOptions_604249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_604248(path: JsonNode; query: JsonNode;
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
  var valid_604250 = query.getOrDefault("MaxRecords")
  valid_604250 = validateParameter(valid_604250, JInt, required = false, default = nil)
  if valid_604250 != nil:
    section.add "MaxRecords", valid_604250
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604251 = query.getOrDefault("Action")
  valid_604251 = validateParameter(valid_604251, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604251 != nil:
    section.add "Action", valid_604251
  var valid_604252 = query.getOrDefault("Marker")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "Marker", valid_604252
  var valid_604253 = query.getOrDefault("Version")
  valid_604253 = validateParameter(valid_604253, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604253 != nil:
    section.add "Version", valid_604253
  var valid_604254 = query.getOrDefault("EngineName")
  valid_604254 = validateParameter(valid_604254, JString, required = true,
                                 default = nil)
  if valid_604254 != nil:
    section.add "EngineName", valid_604254
  var valid_604255 = query.getOrDefault("MajorEngineVersion")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "MajorEngineVersion", valid_604255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604256 = header.getOrDefault("X-Amz-Date")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Date", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Security-Token")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Security-Token", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-Content-Sha256", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Algorithm")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Algorithm", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Signature")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Signature", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-SignedHeaders", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Credential")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Credential", valid_604262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604263: Call_GetDescribeOptionGroupOptions_604247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604263.validator(path, query, header, formData, body)
  let scheme = call_604263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604263.url(scheme.get, call_604263.host, call_604263.base,
                         call_604263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604263, url, valid)

proc call*(call_604264: Call_GetDescribeOptionGroupOptions_604247;
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
  var query_604265 = newJObject()
  add(query_604265, "MaxRecords", newJInt(MaxRecords))
  add(query_604265, "Action", newJString(Action))
  add(query_604265, "Marker", newJString(Marker))
  add(query_604265, "Version", newJString(Version))
  add(query_604265, "EngineName", newJString(EngineName))
  add(query_604265, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604264.call(nil, query_604265, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604247(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604248, base: "/",
    url: url_GetDescribeOptionGroupOptions_604249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604306 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroups_604308(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_604307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_604309 = validateParameter(valid_604309, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604309 != nil:
    section.add "Action", valid_604309
  var valid_604310 = query.getOrDefault("Version")
  valid_604310 = validateParameter(valid_604310, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604318 = formData.getOrDefault("MajorEngineVersion")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "MajorEngineVersion", valid_604318
  var valid_604319 = formData.getOrDefault("OptionGroupName")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "OptionGroupName", valid_604319
  var valid_604320 = formData.getOrDefault("Marker")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "Marker", valid_604320
  var valid_604321 = formData.getOrDefault("EngineName")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "EngineName", valid_604321
  var valid_604322 = formData.getOrDefault("MaxRecords")
  valid_604322 = validateParameter(valid_604322, JInt, required = false, default = nil)
  if valid_604322 != nil:
    section.add "MaxRecords", valid_604322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604323: Call_PostDescribeOptionGroups_604306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604323.validator(path, query, header, formData, body)
  let scheme = call_604323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604323.url(scheme.get, call_604323.host, call_604323.base,
                         call_604323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604323, url, valid)

proc call*(call_604324: Call_PostDescribeOptionGroups_604306;
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
  var query_604325 = newJObject()
  var formData_604326 = newJObject()
  add(formData_604326, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604326, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604326, "Marker", newJString(Marker))
  add(query_604325, "Action", newJString(Action))
  add(formData_604326, "EngineName", newJString(EngineName))
  add(formData_604326, "MaxRecords", newJInt(MaxRecords))
  add(query_604325, "Version", newJString(Version))
  result = call_604324.call(nil, query_604325, nil, formData_604326, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604306(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604307, base: "/",
    url: url_PostDescribeOptionGroups_604308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604286 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroups_604288(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_604287(path: JsonNode; query: JsonNode;
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
  var valid_604289 = query.getOrDefault("MaxRecords")
  valid_604289 = validateParameter(valid_604289, JInt, required = false, default = nil)
  if valid_604289 != nil:
    section.add "MaxRecords", valid_604289
  var valid_604290 = query.getOrDefault("OptionGroupName")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "OptionGroupName", valid_604290
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604291 = query.getOrDefault("Action")
  valid_604291 = validateParameter(valid_604291, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604291 != nil:
    section.add "Action", valid_604291
  var valid_604292 = query.getOrDefault("Marker")
  valid_604292 = validateParameter(valid_604292, JString, required = false,
                                 default = nil)
  if valid_604292 != nil:
    section.add "Marker", valid_604292
  var valid_604293 = query.getOrDefault("Version")
  valid_604293 = validateParameter(valid_604293, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604293 != nil:
    section.add "Version", valid_604293
  var valid_604294 = query.getOrDefault("EngineName")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "EngineName", valid_604294
  var valid_604295 = query.getOrDefault("MajorEngineVersion")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "MajorEngineVersion", valid_604295
  result.add "query", section
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

proc call*(call_604303: Call_GetDescribeOptionGroups_604286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604303.validator(path, query, header, formData, body)
  let scheme = call_604303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604303.url(scheme.get, call_604303.host, call_604303.base,
                         call_604303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604303, url, valid)

proc call*(call_604304: Call_GetDescribeOptionGroups_604286; MaxRecords: int = 0;
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
  var query_604305 = newJObject()
  add(query_604305, "MaxRecords", newJInt(MaxRecords))
  add(query_604305, "OptionGroupName", newJString(OptionGroupName))
  add(query_604305, "Action", newJString(Action))
  add(query_604305, "Marker", newJString(Marker))
  add(query_604305, "Version", newJString(Version))
  add(query_604305, "EngineName", newJString(EngineName))
  add(query_604305, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604304.call(nil, query_604305, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604286(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604287, base: "/",
    url: url_GetDescribeOptionGroups_604288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604349 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOrderableDBInstanceOptions_604351(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604350(path: JsonNode;
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
  var valid_604352 = query.getOrDefault("Action")
  valid_604352 = validateParameter(valid_604352, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604352 != nil:
    section.add "Action", valid_604352
  var valid_604353 = query.getOrDefault("Version")
  valid_604353 = validateParameter(valid_604353, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604353 != nil:
    section.add "Version", valid_604353
  result.add "query", section
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
  var valid_604361 = formData.getOrDefault("Engine")
  valid_604361 = validateParameter(valid_604361, JString, required = true,
                                 default = nil)
  if valid_604361 != nil:
    section.add "Engine", valid_604361
  var valid_604362 = formData.getOrDefault("Marker")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "Marker", valid_604362
  var valid_604363 = formData.getOrDefault("Vpc")
  valid_604363 = validateParameter(valid_604363, JBool, required = false, default = nil)
  if valid_604363 != nil:
    section.add "Vpc", valid_604363
  var valid_604364 = formData.getOrDefault("DBInstanceClass")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "DBInstanceClass", valid_604364
  var valid_604365 = formData.getOrDefault("LicenseModel")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "LicenseModel", valid_604365
  var valid_604366 = formData.getOrDefault("MaxRecords")
  valid_604366 = validateParameter(valid_604366, JInt, required = false, default = nil)
  if valid_604366 != nil:
    section.add "MaxRecords", valid_604366
  var valid_604367 = formData.getOrDefault("EngineVersion")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "EngineVersion", valid_604367
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604368: Call_PostDescribeOrderableDBInstanceOptions_604349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604368.validator(path, query, header, formData, body)
  let scheme = call_604368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604368.url(scheme.get, call_604368.host, call_604368.base,
                         call_604368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604368, url, valid)

proc call*(call_604369: Call_PostDescribeOrderableDBInstanceOptions_604349;
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
  var query_604370 = newJObject()
  var formData_604371 = newJObject()
  add(formData_604371, "Engine", newJString(Engine))
  add(formData_604371, "Marker", newJString(Marker))
  add(query_604370, "Action", newJString(Action))
  add(formData_604371, "Vpc", newJBool(Vpc))
  add(formData_604371, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604371, "LicenseModel", newJString(LicenseModel))
  add(formData_604371, "MaxRecords", newJInt(MaxRecords))
  add(formData_604371, "EngineVersion", newJString(EngineVersion))
  add(query_604370, "Version", newJString(Version))
  result = call_604369.call(nil, query_604370, nil, formData_604371, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604349(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604350, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604327 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOrderableDBInstanceOptions_604329(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604328(path: JsonNode;
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
  var valid_604330 = query.getOrDefault("Engine")
  valid_604330 = validateParameter(valid_604330, JString, required = true,
                                 default = nil)
  if valid_604330 != nil:
    section.add "Engine", valid_604330
  var valid_604331 = query.getOrDefault("MaxRecords")
  valid_604331 = validateParameter(valid_604331, JInt, required = false, default = nil)
  if valid_604331 != nil:
    section.add "MaxRecords", valid_604331
  var valid_604332 = query.getOrDefault("LicenseModel")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "LicenseModel", valid_604332
  var valid_604333 = query.getOrDefault("Vpc")
  valid_604333 = validateParameter(valid_604333, JBool, required = false, default = nil)
  if valid_604333 != nil:
    section.add "Vpc", valid_604333
  var valid_604334 = query.getOrDefault("DBInstanceClass")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "DBInstanceClass", valid_604334
  var valid_604335 = query.getOrDefault("Action")
  valid_604335 = validateParameter(valid_604335, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604335 != nil:
    section.add "Action", valid_604335
  var valid_604336 = query.getOrDefault("Marker")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "Marker", valid_604336
  var valid_604337 = query.getOrDefault("EngineVersion")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "EngineVersion", valid_604337
  var valid_604338 = query.getOrDefault("Version")
  valid_604338 = validateParameter(valid_604338, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604338 != nil:
    section.add "Version", valid_604338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604339 = header.getOrDefault("X-Amz-Date")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "X-Amz-Date", valid_604339
  var valid_604340 = header.getOrDefault("X-Amz-Security-Token")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "X-Amz-Security-Token", valid_604340
  var valid_604341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "X-Amz-Content-Sha256", valid_604341
  var valid_604342 = header.getOrDefault("X-Amz-Algorithm")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Algorithm", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Signature")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Signature", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-SignedHeaders", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Credential")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Credential", valid_604345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604346: Call_GetDescribeOrderableDBInstanceOptions_604327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604346.validator(path, query, header, formData, body)
  let scheme = call_604346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604346.url(scheme.get, call_604346.host, call_604346.base,
                         call_604346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604346, url, valid)

proc call*(call_604347: Call_GetDescribeOrderableDBInstanceOptions_604327;
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
  var query_604348 = newJObject()
  add(query_604348, "Engine", newJString(Engine))
  add(query_604348, "MaxRecords", newJInt(MaxRecords))
  add(query_604348, "LicenseModel", newJString(LicenseModel))
  add(query_604348, "Vpc", newJBool(Vpc))
  add(query_604348, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604348, "Action", newJString(Action))
  add(query_604348, "Marker", newJString(Marker))
  add(query_604348, "EngineVersion", newJString(EngineVersion))
  add(query_604348, "Version", newJString(Version))
  result = call_604347.call(nil, query_604348, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604327(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604328, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604396 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstances_604398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_604397(path: JsonNode;
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
  var valid_604399 = query.getOrDefault("Action")
  valid_604399 = validateParameter(valid_604399, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604399 != nil:
    section.add "Action", valid_604399
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
  var valid_604408 = formData.getOrDefault("OfferingType")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "OfferingType", valid_604408
  var valid_604409 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "ReservedDBInstanceId", valid_604409
  var valid_604410 = formData.getOrDefault("Marker")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "Marker", valid_604410
  var valid_604411 = formData.getOrDefault("MultiAZ")
  valid_604411 = validateParameter(valid_604411, JBool, required = false, default = nil)
  if valid_604411 != nil:
    section.add "MultiAZ", valid_604411
  var valid_604412 = formData.getOrDefault("Duration")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "Duration", valid_604412
  var valid_604413 = formData.getOrDefault("DBInstanceClass")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "DBInstanceClass", valid_604413
  var valid_604414 = formData.getOrDefault("ProductDescription")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "ProductDescription", valid_604414
  var valid_604415 = formData.getOrDefault("MaxRecords")
  valid_604415 = validateParameter(valid_604415, JInt, required = false, default = nil)
  if valid_604415 != nil:
    section.add "MaxRecords", valid_604415
  var valid_604416 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604417: Call_PostDescribeReservedDBInstances_604396;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604417.validator(path, query, header, formData, body)
  let scheme = call_604417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604417.url(scheme.get, call_604417.host, call_604417.base,
                         call_604417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604417, url, valid)

proc call*(call_604418: Call_PostDescribeReservedDBInstances_604396;
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
  var query_604419 = newJObject()
  var formData_604420 = newJObject()
  add(formData_604420, "OfferingType", newJString(OfferingType))
  add(formData_604420, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604420, "Marker", newJString(Marker))
  add(formData_604420, "MultiAZ", newJBool(MultiAZ))
  add(query_604419, "Action", newJString(Action))
  add(formData_604420, "Duration", newJString(Duration))
  add(formData_604420, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604420, "ProductDescription", newJString(ProductDescription))
  add(formData_604420, "MaxRecords", newJInt(MaxRecords))
  add(formData_604420, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604419, "Version", newJString(Version))
  result = call_604418.call(nil, query_604419, nil, formData_604420, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604396(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604397, base: "/",
    url: url_PostDescribeReservedDBInstances_604398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604372 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstances_604374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_604373(path: JsonNode;
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
  var valid_604375 = query.getOrDefault("ProductDescription")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "ProductDescription", valid_604375
  var valid_604376 = query.getOrDefault("MaxRecords")
  valid_604376 = validateParameter(valid_604376, JInt, required = false, default = nil)
  if valid_604376 != nil:
    section.add "MaxRecords", valid_604376
  var valid_604377 = query.getOrDefault("OfferingType")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "OfferingType", valid_604377
  var valid_604378 = query.getOrDefault("MultiAZ")
  valid_604378 = validateParameter(valid_604378, JBool, required = false, default = nil)
  if valid_604378 != nil:
    section.add "MultiAZ", valid_604378
  var valid_604379 = query.getOrDefault("ReservedDBInstanceId")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "ReservedDBInstanceId", valid_604379
  var valid_604380 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604380
  var valid_604381 = query.getOrDefault("DBInstanceClass")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "DBInstanceClass", valid_604381
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604382 = query.getOrDefault("Action")
  valid_604382 = validateParameter(valid_604382, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604382 != nil:
    section.add "Action", valid_604382
  var valid_604383 = query.getOrDefault("Marker")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "Marker", valid_604383
  var valid_604384 = query.getOrDefault("Duration")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "Duration", valid_604384
  var valid_604385 = query.getOrDefault("Version")
  valid_604385 = validateParameter(valid_604385, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604385 != nil:
    section.add "Version", valid_604385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604386 = header.getOrDefault("X-Amz-Date")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-Date", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Security-Token")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Security-Token", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Content-Sha256", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Algorithm")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Algorithm", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Signature")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Signature", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-SignedHeaders", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Credential")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Credential", valid_604392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604393: Call_GetDescribeReservedDBInstances_604372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604393.validator(path, query, header, formData, body)
  let scheme = call_604393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604393.url(scheme.get, call_604393.host, call_604393.base,
                         call_604393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604393, url, valid)

proc call*(call_604394: Call_GetDescribeReservedDBInstances_604372;
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
  var query_604395 = newJObject()
  add(query_604395, "ProductDescription", newJString(ProductDescription))
  add(query_604395, "MaxRecords", newJInt(MaxRecords))
  add(query_604395, "OfferingType", newJString(OfferingType))
  add(query_604395, "MultiAZ", newJBool(MultiAZ))
  add(query_604395, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604395, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604395, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604395, "Action", newJString(Action))
  add(query_604395, "Marker", newJString(Marker))
  add(query_604395, "Duration", newJString(Duration))
  add(query_604395, "Version", newJString(Version))
  result = call_604394.call(nil, query_604395, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604372(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604373, base: "/",
    url: url_GetDescribeReservedDBInstances_604374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604444 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstancesOfferings_604446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604445(path: JsonNode;
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
  var valid_604447 = query.getOrDefault("Action")
  valid_604447 = validateParameter(valid_604447, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604447 != nil:
    section.add "Action", valid_604447
  var valid_604448 = query.getOrDefault("Version")
  valid_604448 = validateParameter(valid_604448, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604448 != nil:
    section.add "Version", valid_604448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604449 = header.getOrDefault("X-Amz-Date")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-Date", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Security-Token")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Security-Token", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Content-Sha256", valid_604451
  var valid_604452 = header.getOrDefault("X-Amz-Algorithm")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-Algorithm", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Signature")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Signature", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-SignedHeaders", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Credential")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Credential", valid_604455
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
  var valid_604456 = formData.getOrDefault("OfferingType")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "OfferingType", valid_604456
  var valid_604457 = formData.getOrDefault("Marker")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "Marker", valid_604457
  var valid_604458 = formData.getOrDefault("MultiAZ")
  valid_604458 = validateParameter(valid_604458, JBool, required = false, default = nil)
  if valid_604458 != nil:
    section.add "MultiAZ", valid_604458
  var valid_604459 = formData.getOrDefault("Duration")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "Duration", valid_604459
  var valid_604460 = formData.getOrDefault("DBInstanceClass")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "DBInstanceClass", valid_604460
  var valid_604461 = formData.getOrDefault("ProductDescription")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "ProductDescription", valid_604461
  var valid_604462 = formData.getOrDefault("MaxRecords")
  valid_604462 = validateParameter(valid_604462, JInt, required = false, default = nil)
  if valid_604462 != nil:
    section.add "MaxRecords", valid_604462
  var valid_604463 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604463
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604464: Call_PostDescribeReservedDBInstancesOfferings_604444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604464.validator(path, query, header, formData, body)
  let scheme = call_604464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604464.url(scheme.get, call_604464.host, call_604464.base,
                         call_604464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604464, url, valid)

proc call*(call_604465: Call_PostDescribeReservedDBInstancesOfferings_604444;
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
  var query_604466 = newJObject()
  var formData_604467 = newJObject()
  add(formData_604467, "OfferingType", newJString(OfferingType))
  add(formData_604467, "Marker", newJString(Marker))
  add(formData_604467, "MultiAZ", newJBool(MultiAZ))
  add(query_604466, "Action", newJString(Action))
  add(formData_604467, "Duration", newJString(Duration))
  add(formData_604467, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604467, "ProductDescription", newJString(ProductDescription))
  add(formData_604467, "MaxRecords", newJInt(MaxRecords))
  add(formData_604467, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604466, "Version", newJString(Version))
  result = call_604465.call(nil, query_604466, nil, formData_604467, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604444(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604445,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604421 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstancesOfferings_604423(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604422(path: JsonNode;
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
  var valid_604424 = query.getOrDefault("ProductDescription")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "ProductDescription", valid_604424
  var valid_604425 = query.getOrDefault("MaxRecords")
  valid_604425 = validateParameter(valid_604425, JInt, required = false, default = nil)
  if valid_604425 != nil:
    section.add "MaxRecords", valid_604425
  var valid_604426 = query.getOrDefault("OfferingType")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "OfferingType", valid_604426
  var valid_604427 = query.getOrDefault("MultiAZ")
  valid_604427 = validateParameter(valid_604427, JBool, required = false, default = nil)
  if valid_604427 != nil:
    section.add "MultiAZ", valid_604427
  var valid_604428 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604428
  var valid_604429 = query.getOrDefault("DBInstanceClass")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "DBInstanceClass", valid_604429
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604430 = query.getOrDefault("Action")
  valid_604430 = validateParameter(valid_604430, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604430 != nil:
    section.add "Action", valid_604430
  var valid_604431 = query.getOrDefault("Marker")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "Marker", valid_604431
  var valid_604432 = query.getOrDefault("Duration")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "Duration", valid_604432
  var valid_604433 = query.getOrDefault("Version")
  valid_604433 = validateParameter(valid_604433, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604433 != nil:
    section.add "Version", valid_604433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604434 = header.getOrDefault("X-Amz-Date")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-Date", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-Security-Token")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Security-Token", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Content-Sha256", valid_604436
  var valid_604437 = header.getOrDefault("X-Amz-Algorithm")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Algorithm", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Signature")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Signature", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-SignedHeaders", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Credential")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Credential", valid_604440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604441: Call_GetDescribeReservedDBInstancesOfferings_604421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604441.validator(path, query, header, formData, body)
  let scheme = call_604441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604441.url(scheme.get, call_604441.host, call_604441.base,
                         call_604441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604441, url, valid)

proc call*(call_604442: Call_GetDescribeReservedDBInstancesOfferings_604421;
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
  var query_604443 = newJObject()
  add(query_604443, "ProductDescription", newJString(ProductDescription))
  add(query_604443, "MaxRecords", newJInt(MaxRecords))
  add(query_604443, "OfferingType", newJString(OfferingType))
  add(query_604443, "MultiAZ", newJBool(MultiAZ))
  add(query_604443, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604443, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604443, "Action", newJString(Action))
  add(query_604443, "Marker", newJString(Marker))
  add(query_604443, "Duration", newJString(Duration))
  add(query_604443, "Version", newJString(Version))
  result = call_604442.call(nil, query_604443, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604421(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604422, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604487 = ref object of OpenApiRestCall_602450
proc url_PostDownloadDBLogFilePortion_604489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_604488(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604490 = query.getOrDefault("Action")
  valid_604490 = validateParameter(valid_604490, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604490 != nil:
    section.add "Action", valid_604490
  var valid_604491 = query.getOrDefault("Version")
  valid_604491 = validateParameter(valid_604491, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604491 != nil:
    section.add "Version", valid_604491
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604492 = header.getOrDefault("X-Amz-Date")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Date", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Security-Token")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Security-Token", valid_604493
  var valid_604494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-Content-Sha256", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Algorithm")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Algorithm", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Signature")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Signature", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-SignedHeaders", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Credential")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Credential", valid_604498
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604499 = formData.getOrDefault("NumberOfLines")
  valid_604499 = validateParameter(valid_604499, JInt, required = false, default = nil)
  if valid_604499 != nil:
    section.add "NumberOfLines", valid_604499
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604500 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604500 = validateParameter(valid_604500, JString, required = true,
                                 default = nil)
  if valid_604500 != nil:
    section.add "DBInstanceIdentifier", valid_604500
  var valid_604501 = formData.getOrDefault("Marker")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "Marker", valid_604501
  var valid_604502 = formData.getOrDefault("LogFileName")
  valid_604502 = validateParameter(valid_604502, JString, required = true,
                                 default = nil)
  if valid_604502 != nil:
    section.add "LogFileName", valid_604502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604503: Call_PostDownloadDBLogFilePortion_604487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604503.validator(path, query, header, formData, body)
  let scheme = call_604503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604503.url(scheme.get, call_604503.host, call_604503.base,
                         call_604503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604503, url, valid)

proc call*(call_604504: Call_PostDownloadDBLogFilePortion_604487;
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
  var query_604505 = newJObject()
  var formData_604506 = newJObject()
  add(formData_604506, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604506, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604506, "Marker", newJString(Marker))
  add(query_604505, "Action", newJString(Action))
  add(formData_604506, "LogFileName", newJString(LogFileName))
  add(query_604505, "Version", newJString(Version))
  result = call_604504.call(nil, query_604505, nil, formData_604506, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604487(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604488, base: "/",
    url: url_PostDownloadDBLogFilePortion_604489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604468 = ref object of OpenApiRestCall_602450
proc url_GetDownloadDBLogFilePortion_604470(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_604469(path: JsonNode; query: JsonNode;
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
  var valid_604471 = query.getOrDefault("NumberOfLines")
  valid_604471 = validateParameter(valid_604471, JInt, required = false, default = nil)
  if valid_604471 != nil:
    section.add "NumberOfLines", valid_604471
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604472 = query.getOrDefault("LogFileName")
  valid_604472 = validateParameter(valid_604472, JString, required = true,
                                 default = nil)
  if valid_604472 != nil:
    section.add "LogFileName", valid_604472
  var valid_604473 = query.getOrDefault("Action")
  valid_604473 = validateParameter(valid_604473, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604473 != nil:
    section.add "Action", valid_604473
  var valid_604474 = query.getOrDefault("Marker")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "Marker", valid_604474
  var valid_604475 = query.getOrDefault("Version")
  valid_604475 = validateParameter(valid_604475, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604475 != nil:
    section.add "Version", valid_604475
  var valid_604476 = query.getOrDefault("DBInstanceIdentifier")
  valid_604476 = validateParameter(valid_604476, JString, required = true,
                                 default = nil)
  if valid_604476 != nil:
    section.add "DBInstanceIdentifier", valid_604476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604477 = header.getOrDefault("X-Amz-Date")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Date", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Security-Token")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Security-Token", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Content-Sha256", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Algorithm")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Algorithm", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Signature")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Signature", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-SignedHeaders", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Credential")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Credential", valid_604483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604484: Call_GetDownloadDBLogFilePortion_604468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604484.validator(path, query, header, formData, body)
  let scheme = call_604484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604484.url(scheme.get, call_604484.host, call_604484.base,
                         call_604484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604484, url, valid)

proc call*(call_604485: Call_GetDownloadDBLogFilePortion_604468;
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
  var query_604486 = newJObject()
  add(query_604486, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604486, "LogFileName", newJString(LogFileName))
  add(query_604486, "Action", newJString(Action))
  add(query_604486, "Marker", newJString(Marker))
  add(query_604486, "Version", newJString(Version))
  add(query_604486, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604485.call(nil, query_604486, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604468(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604469, base: "/",
    url: url_GetDownloadDBLogFilePortion_604470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604523 = ref object of OpenApiRestCall_602450
proc url_PostListTagsForResource_604525(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604526 = query.getOrDefault("Action")
  valid_604526 = validateParameter(valid_604526, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604526 != nil:
    section.add "Action", valid_604526
  var valid_604527 = query.getOrDefault("Version")
  valid_604527 = validateParameter(valid_604527, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604527 != nil:
    section.add "Version", valid_604527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604528 = header.getOrDefault("X-Amz-Date")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Date", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Security-Token")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Security-Token", valid_604529
  var valid_604530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Content-Sha256", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-Algorithm")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-Algorithm", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Signature")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Signature", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-SignedHeaders", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Credential")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Credential", valid_604534
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604535 = formData.getOrDefault("ResourceName")
  valid_604535 = validateParameter(valid_604535, JString, required = true,
                                 default = nil)
  if valid_604535 != nil:
    section.add "ResourceName", valid_604535
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604536: Call_PostListTagsForResource_604523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604536.validator(path, query, header, formData, body)
  let scheme = call_604536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604536.url(scheme.get, call_604536.host, call_604536.base,
                         call_604536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604536, url, valid)

proc call*(call_604537: Call_PostListTagsForResource_604523; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604538 = newJObject()
  var formData_604539 = newJObject()
  add(query_604538, "Action", newJString(Action))
  add(formData_604539, "ResourceName", newJString(ResourceName))
  add(query_604538, "Version", newJString(Version))
  result = call_604537.call(nil, query_604538, nil, formData_604539, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604523(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604524, base: "/",
    url: url_PostListTagsForResource_604525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604507 = ref object of OpenApiRestCall_602450
proc url_GetListTagsForResource_604509(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604508(path: JsonNode; query: JsonNode;
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
  var valid_604510 = query.getOrDefault("ResourceName")
  valid_604510 = validateParameter(valid_604510, JString, required = true,
                                 default = nil)
  if valid_604510 != nil:
    section.add "ResourceName", valid_604510
  var valid_604511 = query.getOrDefault("Action")
  valid_604511 = validateParameter(valid_604511, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604511 != nil:
    section.add "Action", valid_604511
  var valid_604512 = query.getOrDefault("Version")
  valid_604512 = validateParameter(valid_604512, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604520: Call_GetListTagsForResource_604507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604520.validator(path, query, header, formData, body)
  let scheme = call_604520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604520.url(scheme.get, call_604520.host, call_604520.base,
                         call_604520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604520, url, valid)

proc call*(call_604521: Call_GetListTagsForResource_604507; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604522 = newJObject()
  add(query_604522, "ResourceName", newJString(ResourceName))
  add(query_604522, "Action", newJString(Action))
  add(query_604522, "Version", newJString(Version))
  result = call_604521.call(nil, query_604522, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604507(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604508, base: "/",
    url: url_GetListTagsForResource_604509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604573 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBInstance_604575(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_604574(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604576 = query.getOrDefault("Action")
  valid_604576 = validateParameter(valid_604576, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604576 != nil:
    section.add "Action", valid_604576
  var valid_604577 = query.getOrDefault("Version")
  valid_604577 = validateParameter(valid_604577, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604577 != nil:
    section.add "Version", valid_604577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604578 = header.getOrDefault("X-Amz-Date")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-Date", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Security-Token")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Security-Token", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Content-Sha256", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-Algorithm")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Algorithm", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Signature")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Signature", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-SignedHeaders", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-Credential")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Credential", valid_604584
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
  var valid_604585 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "PreferredMaintenanceWindow", valid_604585
  var valid_604586 = formData.getOrDefault("DBSecurityGroups")
  valid_604586 = validateParameter(valid_604586, JArray, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "DBSecurityGroups", valid_604586
  var valid_604587 = formData.getOrDefault("ApplyImmediately")
  valid_604587 = validateParameter(valid_604587, JBool, required = false, default = nil)
  if valid_604587 != nil:
    section.add "ApplyImmediately", valid_604587
  var valid_604588 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604588 = validateParameter(valid_604588, JArray, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "VpcSecurityGroupIds", valid_604588
  var valid_604589 = formData.getOrDefault("Iops")
  valid_604589 = validateParameter(valid_604589, JInt, required = false, default = nil)
  if valid_604589 != nil:
    section.add "Iops", valid_604589
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604590 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604590 = validateParameter(valid_604590, JString, required = true,
                                 default = nil)
  if valid_604590 != nil:
    section.add "DBInstanceIdentifier", valid_604590
  var valid_604591 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604591 = validateParameter(valid_604591, JInt, required = false, default = nil)
  if valid_604591 != nil:
    section.add "BackupRetentionPeriod", valid_604591
  var valid_604592 = formData.getOrDefault("DBParameterGroupName")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "DBParameterGroupName", valid_604592
  var valid_604593 = formData.getOrDefault("OptionGroupName")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "OptionGroupName", valid_604593
  var valid_604594 = formData.getOrDefault("MasterUserPassword")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "MasterUserPassword", valid_604594
  var valid_604595 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "NewDBInstanceIdentifier", valid_604595
  var valid_604596 = formData.getOrDefault("MultiAZ")
  valid_604596 = validateParameter(valid_604596, JBool, required = false, default = nil)
  if valid_604596 != nil:
    section.add "MultiAZ", valid_604596
  var valid_604597 = formData.getOrDefault("AllocatedStorage")
  valid_604597 = validateParameter(valid_604597, JInt, required = false, default = nil)
  if valid_604597 != nil:
    section.add "AllocatedStorage", valid_604597
  var valid_604598 = formData.getOrDefault("DBInstanceClass")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "DBInstanceClass", valid_604598
  var valid_604599 = formData.getOrDefault("PreferredBackupWindow")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "PreferredBackupWindow", valid_604599
  var valid_604600 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604600 = validateParameter(valid_604600, JBool, required = false, default = nil)
  if valid_604600 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604600
  var valid_604601 = formData.getOrDefault("EngineVersion")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "EngineVersion", valid_604601
  var valid_604602 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604602 = validateParameter(valid_604602, JBool, required = false, default = nil)
  if valid_604602 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604603: Call_PostModifyDBInstance_604573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604603.validator(path, query, header, formData, body)
  let scheme = call_604603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604603.url(scheme.get, call_604603.host, call_604603.base,
                         call_604603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604603, url, valid)

proc call*(call_604604: Call_PostModifyDBInstance_604573;
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
  var query_604605 = newJObject()
  var formData_604606 = newJObject()
  add(formData_604606, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604606.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604606, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604606.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604606, "Iops", newJInt(Iops))
  add(formData_604606, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604606, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604606, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604606, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604606, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604606, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604606, "MultiAZ", newJBool(MultiAZ))
  add(query_604605, "Action", newJString(Action))
  add(formData_604606, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604606, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604606, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604606, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604606, "EngineVersion", newJString(EngineVersion))
  add(query_604605, "Version", newJString(Version))
  add(formData_604606, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604604.call(nil, query_604605, nil, formData_604606, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604573(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604574, base: "/",
    url: url_PostModifyDBInstance_604575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604540 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBInstance_604542(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_604541(path: JsonNode; query: JsonNode;
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
  var valid_604543 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "PreferredMaintenanceWindow", valid_604543
  var valid_604544 = query.getOrDefault("AllocatedStorage")
  valid_604544 = validateParameter(valid_604544, JInt, required = false, default = nil)
  if valid_604544 != nil:
    section.add "AllocatedStorage", valid_604544
  var valid_604545 = query.getOrDefault("OptionGroupName")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "OptionGroupName", valid_604545
  var valid_604546 = query.getOrDefault("DBSecurityGroups")
  valid_604546 = validateParameter(valid_604546, JArray, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "DBSecurityGroups", valid_604546
  var valid_604547 = query.getOrDefault("MasterUserPassword")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "MasterUserPassword", valid_604547
  var valid_604548 = query.getOrDefault("Iops")
  valid_604548 = validateParameter(valid_604548, JInt, required = false, default = nil)
  if valid_604548 != nil:
    section.add "Iops", valid_604548
  var valid_604549 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604549 = validateParameter(valid_604549, JArray, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "VpcSecurityGroupIds", valid_604549
  var valid_604550 = query.getOrDefault("MultiAZ")
  valid_604550 = validateParameter(valid_604550, JBool, required = false, default = nil)
  if valid_604550 != nil:
    section.add "MultiAZ", valid_604550
  var valid_604551 = query.getOrDefault("BackupRetentionPeriod")
  valid_604551 = validateParameter(valid_604551, JInt, required = false, default = nil)
  if valid_604551 != nil:
    section.add "BackupRetentionPeriod", valid_604551
  var valid_604552 = query.getOrDefault("DBParameterGroupName")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "DBParameterGroupName", valid_604552
  var valid_604553 = query.getOrDefault("DBInstanceClass")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "DBInstanceClass", valid_604553
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604554 = query.getOrDefault("Action")
  valid_604554 = validateParameter(valid_604554, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604554 != nil:
    section.add "Action", valid_604554
  var valid_604555 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604555 = validateParameter(valid_604555, JBool, required = false, default = nil)
  if valid_604555 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604555
  var valid_604556 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "NewDBInstanceIdentifier", valid_604556
  var valid_604557 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604557 = validateParameter(valid_604557, JBool, required = false, default = nil)
  if valid_604557 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604557
  var valid_604558 = query.getOrDefault("EngineVersion")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "EngineVersion", valid_604558
  var valid_604559 = query.getOrDefault("PreferredBackupWindow")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "PreferredBackupWindow", valid_604559
  var valid_604560 = query.getOrDefault("Version")
  valid_604560 = validateParameter(valid_604560, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604560 != nil:
    section.add "Version", valid_604560
  var valid_604561 = query.getOrDefault("DBInstanceIdentifier")
  valid_604561 = validateParameter(valid_604561, JString, required = true,
                                 default = nil)
  if valid_604561 != nil:
    section.add "DBInstanceIdentifier", valid_604561
  var valid_604562 = query.getOrDefault("ApplyImmediately")
  valid_604562 = validateParameter(valid_604562, JBool, required = false, default = nil)
  if valid_604562 != nil:
    section.add "ApplyImmediately", valid_604562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604563 = header.getOrDefault("X-Amz-Date")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "X-Amz-Date", valid_604563
  var valid_604564 = header.getOrDefault("X-Amz-Security-Token")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "X-Amz-Security-Token", valid_604564
  var valid_604565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "X-Amz-Content-Sha256", valid_604565
  var valid_604566 = header.getOrDefault("X-Amz-Algorithm")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "X-Amz-Algorithm", valid_604566
  var valid_604567 = header.getOrDefault("X-Amz-Signature")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "X-Amz-Signature", valid_604567
  var valid_604568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "X-Amz-SignedHeaders", valid_604568
  var valid_604569 = header.getOrDefault("X-Amz-Credential")
  valid_604569 = validateParameter(valid_604569, JString, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "X-Amz-Credential", valid_604569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604570: Call_GetModifyDBInstance_604540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604570.validator(path, query, header, formData, body)
  let scheme = call_604570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604570.url(scheme.get, call_604570.host, call_604570.base,
                         call_604570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604570, url, valid)

proc call*(call_604571: Call_GetModifyDBInstance_604540;
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
  var query_604572 = newJObject()
  add(query_604572, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604572, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604572, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604572.add "DBSecurityGroups", DBSecurityGroups
  add(query_604572, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604572, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604572.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604572, "MultiAZ", newJBool(MultiAZ))
  add(query_604572, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604572, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604572, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604572, "Action", newJString(Action))
  add(query_604572, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604572, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604572, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604572, "EngineVersion", newJString(EngineVersion))
  add(query_604572, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604572, "Version", newJString(Version))
  add(query_604572, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604572, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604571.call(nil, query_604572, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604540(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604541, base: "/",
    url: url_GetModifyDBInstance_604542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604624 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBParameterGroup_604626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_604625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604627 = query.getOrDefault("Action")
  valid_604627 = validateParameter(valid_604627, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604627 != nil:
    section.add "Action", valid_604627
  var valid_604628 = query.getOrDefault("Version")
  valid_604628 = validateParameter(valid_604628, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604628 != nil:
    section.add "Version", valid_604628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604629 = header.getOrDefault("X-Amz-Date")
  valid_604629 = validateParameter(valid_604629, JString, required = false,
                                 default = nil)
  if valid_604629 != nil:
    section.add "X-Amz-Date", valid_604629
  var valid_604630 = header.getOrDefault("X-Amz-Security-Token")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Security-Token", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Content-Sha256", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-Algorithm")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Algorithm", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Signature")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Signature", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-SignedHeaders", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Credential")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Credential", valid_604635
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604636 = formData.getOrDefault("DBParameterGroupName")
  valid_604636 = validateParameter(valid_604636, JString, required = true,
                                 default = nil)
  if valid_604636 != nil:
    section.add "DBParameterGroupName", valid_604636
  var valid_604637 = formData.getOrDefault("Parameters")
  valid_604637 = validateParameter(valid_604637, JArray, required = true, default = nil)
  if valid_604637 != nil:
    section.add "Parameters", valid_604637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604638: Call_PostModifyDBParameterGroup_604624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604638.validator(path, query, header, formData, body)
  let scheme = call_604638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604638.url(scheme.get, call_604638.host, call_604638.base,
                         call_604638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604638, url, valid)

proc call*(call_604639: Call_PostModifyDBParameterGroup_604624;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604640 = newJObject()
  var formData_604641 = newJObject()
  add(formData_604641, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604641.add "Parameters", Parameters
  add(query_604640, "Action", newJString(Action))
  add(query_604640, "Version", newJString(Version))
  result = call_604639.call(nil, query_604640, nil, formData_604641, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604624(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604625, base: "/",
    url: url_PostModifyDBParameterGroup_604626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604607 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBParameterGroup_604609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_604608(path: JsonNode; query: JsonNode;
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
  var valid_604610 = query.getOrDefault("DBParameterGroupName")
  valid_604610 = validateParameter(valid_604610, JString, required = true,
                                 default = nil)
  if valid_604610 != nil:
    section.add "DBParameterGroupName", valid_604610
  var valid_604611 = query.getOrDefault("Parameters")
  valid_604611 = validateParameter(valid_604611, JArray, required = true, default = nil)
  if valid_604611 != nil:
    section.add "Parameters", valid_604611
  var valid_604612 = query.getOrDefault("Action")
  valid_604612 = validateParameter(valid_604612, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604612 != nil:
    section.add "Action", valid_604612
  var valid_604613 = query.getOrDefault("Version")
  valid_604613 = validateParameter(valid_604613, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604613 != nil:
    section.add "Version", valid_604613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604614 = header.getOrDefault("X-Amz-Date")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "X-Amz-Date", valid_604614
  var valid_604615 = header.getOrDefault("X-Amz-Security-Token")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Security-Token", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Content-Sha256", valid_604616
  var valid_604617 = header.getOrDefault("X-Amz-Algorithm")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-Algorithm", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Signature")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Signature", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-SignedHeaders", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Credential")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Credential", valid_604620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604621: Call_GetModifyDBParameterGroup_604607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604621.validator(path, query, header, formData, body)
  let scheme = call_604621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604621.url(scheme.get, call_604621.host, call_604621.base,
                         call_604621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604621, url, valid)

proc call*(call_604622: Call_GetModifyDBParameterGroup_604607;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604623 = newJObject()
  add(query_604623, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604623.add "Parameters", Parameters
  add(query_604623, "Action", newJString(Action))
  add(query_604623, "Version", newJString(Version))
  result = call_604622.call(nil, query_604623, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604607(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604608, base: "/",
    url: url_GetModifyDBParameterGroup_604609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604660 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBSubnetGroup_604662(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_604661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604663 = query.getOrDefault("Action")
  valid_604663 = validateParameter(valid_604663, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604663 != nil:
    section.add "Action", valid_604663
  var valid_604664 = query.getOrDefault("Version")
  valid_604664 = validateParameter(valid_604664, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604664 != nil:
    section.add "Version", valid_604664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604665 = header.getOrDefault("X-Amz-Date")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Date", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-Security-Token")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-Security-Token", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-Content-Sha256", valid_604667
  var valid_604668 = header.getOrDefault("X-Amz-Algorithm")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "X-Amz-Algorithm", valid_604668
  var valid_604669 = header.getOrDefault("X-Amz-Signature")
  valid_604669 = validateParameter(valid_604669, JString, required = false,
                                 default = nil)
  if valid_604669 != nil:
    section.add "X-Amz-Signature", valid_604669
  var valid_604670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "X-Amz-SignedHeaders", valid_604670
  var valid_604671 = header.getOrDefault("X-Amz-Credential")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "X-Amz-Credential", valid_604671
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604672 = formData.getOrDefault("DBSubnetGroupName")
  valid_604672 = validateParameter(valid_604672, JString, required = true,
                                 default = nil)
  if valid_604672 != nil:
    section.add "DBSubnetGroupName", valid_604672
  var valid_604673 = formData.getOrDefault("SubnetIds")
  valid_604673 = validateParameter(valid_604673, JArray, required = true, default = nil)
  if valid_604673 != nil:
    section.add "SubnetIds", valid_604673
  var valid_604674 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "DBSubnetGroupDescription", valid_604674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604675: Call_PostModifyDBSubnetGroup_604660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604675.validator(path, query, header, formData, body)
  let scheme = call_604675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604675.url(scheme.get, call_604675.host, call_604675.base,
                         call_604675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604675, url, valid)

proc call*(call_604676: Call_PostModifyDBSubnetGroup_604660;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604677 = newJObject()
  var formData_604678 = newJObject()
  add(formData_604678, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604678.add "SubnetIds", SubnetIds
  add(query_604677, "Action", newJString(Action))
  add(formData_604678, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604677, "Version", newJString(Version))
  result = call_604676.call(nil, query_604677, nil, formData_604678, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604660(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604661, base: "/",
    url: url_PostModifyDBSubnetGroup_604662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604642 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBSubnetGroup_604644(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_604643(path: JsonNode; query: JsonNode;
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
  var valid_604645 = query.getOrDefault("Action")
  valid_604645 = validateParameter(valid_604645, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604645 != nil:
    section.add "Action", valid_604645
  var valid_604646 = query.getOrDefault("DBSubnetGroupName")
  valid_604646 = validateParameter(valid_604646, JString, required = true,
                                 default = nil)
  if valid_604646 != nil:
    section.add "DBSubnetGroupName", valid_604646
  var valid_604647 = query.getOrDefault("SubnetIds")
  valid_604647 = validateParameter(valid_604647, JArray, required = true, default = nil)
  if valid_604647 != nil:
    section.add "SubnetIds", valid_604647
  var valid_604648 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "DBSubnetGroupDescription", valid_604648
  var valid_604649 = query.getOrDefault("Version")
  valid_604649 = validateParameter(valid_604649, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604649 != nil:
    section.add "Version", valid_604649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604650 = header.getOrDefault("X-Amz-Date")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Date", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-Security-Token")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-Security-Token", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Content-Sha256", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Algorithm")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Algorithm", valid_604653
  var valid_604654 = header.getOrDefault("X-Amz-Signature")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Signature", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-SignedHeaders", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Credential")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Credential", valid_604656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604657: Call_GetModifyDBSubnetGroup_604642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604657.validator(path, query, header, formData, body)
  let scheme = call_604657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604657.url(scheme.get, call_604657.host, call_604657.base,
                         call_604657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604657, url, valid)

proc call*(call_604658: Call_GetModifyDBSubnetGroup_604642;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604659 = newJObject()
  add(query_604659, "Action", newJString(Action))
  add(query_604659, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604659.add "SubnetIds", SubnetIds
  add(query_604659, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604659, "Version", newJString(Version))
  result = call_604658.call(nil, query_604659, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604642(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604643, base: "/",
    url: url_GetModifyDBSubnetGroup_604644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604699 = ref object of OpenApiRestCall_602450
proc url_PostModifyEventSubscription_604701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_604700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604702 = query.getOrDefault("Action")
  valid_604702 = validateParameter(valid_604702, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604702 != nil:
    section.add "Action", valid_604702
  var valid_604703 = query.getOrDefault("Version")
  valid_604703 = validateParameter(valid_604703, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604703 != nil:
    section.add "Version", valid_604703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604704 = header.getOrDefault("X-Amz-Date")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "X-Amz-Date", valid_604704
  var valid_604705 = header.getOrDefault("X-Amz-Security-Token")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-Security-Token", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Content-Sha256", valid_604706
  var valid_604707 = header.getOrDefault("X-Amz-Algorithm")
  valid_604707 = validateParameter(valid_604707, JString, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "X-Amz-Algorithm", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Signature")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Signature", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-SignedHeaders", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Credential")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Credential", valid_604710
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604711 = formData.getOrDefault("Enabled")
  valid_604711 = validateParameter(valid_604711, JBool, required = false, default = nil)
  if valid_604711 != nil:
    section.add "Enabled", valid_604711
  var valid_604712 = formData.getOrDefault("EventCategories")
  valid_604712 = validateParameter(valid_604712, JArray, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "EventCategories", valid_604712
  var valid_604713 = formData.getOrDefault("SnsTopicArn")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "SnsTopicArn", valid_604713
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604714 = formData.getOrDefault("SubscriptionName")
  valid_604714 = validateParameter(valid_604714, JString, required = true,
                                 default = nil)
  if valid_604714 != nil:
    section.add "SubscriptionName", valid_604714
  var valid_604715 = formData.getOrDefault("SourceType")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "SourceType", valid_604715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604716: Call_PostModifyEventSubscription_604699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604716.validator(path, query, header, formData, body)
  let scheme = call_604716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604716.url(scheme.get, call_604716.host, call_604716.base,
                         call_604716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604716, url, valid)

proc call*(call_604717: Call_PostModifyEventSubscription_604699;
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
  var query_604718 = newJObject()
  var formData_604719 = newJObject()
  add(formData_604719, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604719.add "EventCategories", EventCategories
  add(formData_604719, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604719, "SubscriptionName", newJString(SubscriptionName))
  add(query_604718, "Action", newJString(Action))
  add(query_604718, "Version", newJString(Version))
  add(formData_604719, "SourceType", newJString(SourceType))
  result = call_604717.call(nil, query_604718, nil, formData_604719, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604699(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604700, base: "/",
    url: url_PostModifyEventSubscription_604701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604679 = ref object of OpenApiRestCall_602450
proc url_GetModifyEventSubscription_604681(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_604680(path: JsonNode; query: JsonNode;
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
  var valid_604682 = query.getOrDefault("SourceType")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "SourceType", valid_604682
  var valid_604683 = query.getOrDefault("Enabled")
  valid_604683 = validateParameter(valid_604683, JBool, required = false, default = nil)
  if valid_604683 != nil:
    section.add "Enabled", valid_604683
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604684 = query.getOrDefault("Action")
  valid_604684 = validateParameter(valid_604684, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604684 != nil:
    section.add "Action", valid_604684
  var valid_604685 = query.getOrDefault("SnsTopicArn")
  valid_604685 = validateParameter(valid_604685, JString, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "SnsTopicArn", valid_604685
  var valid_604686 = query.getOrDefault("EventCategories")
  valid_604686 = validateParameter(valid_604686, JArray, required = false,
                                 default = nil)
  if valid_604686 != nil:
    section.add "EventCategories", valid_604686
  var valid_604687 = query.getOrDefault("SubscriptionName")
  valid_604687 = validateParameter(valid_604687, JString, required = true,
                                 default = nil)
  if valid_604687 != nil:
    section.add "SubscriptionName", valid_604687
  var valid_604688 = query.getOrDefault("Version")
  valid_604688 = validateParameter(valid_604688, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604688 != nil:
    section.add "Version", valid_604688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604689 = header.getOrDefault("X-Amz-Date")
  valid_604689 = validateParameter(valid_604689, JString, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "X-Amz-Date", valid_604689
  var valid_604690 = header.getOrDefault("X-Amz-Security-Token")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Security-Token", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Content-Sha256", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Algorithm")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Algorithm", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Signature")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Signature", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-SignedHeaders", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Credential")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Credential", valid_604695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604696: Call_GetModifyEventSubscription_604679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604696.validator(path, query, header, formData, body)
  let scheme = call_604696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604696.url(scheme.get, call_604696.host, call_604696.base,
                         call_604696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604696, url, valid)

proc call*(call_604697: Call_GetModifyEventSubscription_604679;
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
  var query_604698 = newJObject()
  add(query_604698, "SourceType", newJString(SourceType))
  add(query_604698, "Enabled", newJBool(Enabled))
  add(query_604698, "Action", newJString(Action))
  add(query_604698, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604698.add "EventCategories", EventCategories
  add(query_604698, "SubscriptionName", newJString(SubscriptionName))
  add(query_604698, "Version", newJString(Version))
  result = call_604697.call(nil, query_604698, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604679(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604680, base: "/",
    url: url_GetModifyEventSubscription_604681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604739 = ref object of OpenApiRestCall_602450
proc url_PostModifyOptionGroup_604741(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_604740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("ModifyOptionGroup"))
  if valid_604742 != nil:
    section.add "Action", valid_604742
  var valid_604743 = query.getOrDefault("Version")
  valid_604743 = validateParameter(valid_604743, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604751 = formData.getOrDefault("OptionsToRemove")
  valid_604751 = validateParameter(valid_604751, JArray, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "OptionsToRemove", valid_604751
  var valid_604752 = formData.getOrDefault("ApplyImmediately")
  valid_604752 = validateParameter(valid_604752, JBool, required = false, default = nil)
  if valid_604752 != nil:
    section.add "ApplyImmediately", valid_604752
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604753 = formData.getOrDefault("OptionGroupName")
  valid_604753 = validateParameter(valid_604753, JString, required = true,
                                 default = nil)
  if valid_604753 != nil:
    section.add "OptionGroupName", valid_604753
  var valid_604754 = formData.getOrDefault("OptionsToInclude")
  valid_604754 = validateParameter(valid_604754, JArray, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "OptionsToInclude", valid_604754
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604755: Call_PostModifyOptionGroup_604739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604755.validator(path, query, header, formData, body)
  let scheme = call_604755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604755.url(scheme.get, call_604755.host, call_604755.base,
                         call_604755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604755, url, valid)

proc call*(call_604756: Call_PostModifyOptionGroup_604739; OptionGroupName: string;
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
  var query_604757 = newJObject()
  var formData_604758 = newJObject()
  if OptionsToRemove != nil:
    formData_604758.add "OptionsToRemove", OptionsToRemove
  add(formData_604758, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604758, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604758.add "OptionsToInclude", OptionsToInclude
  add(query_604757, "Action", newJString(Action))
  add(query_604757, "Version", newJString(Version))
  result = call_604756.call(nil, query_604757, nil, formData_604758, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604739(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604740, base: "/",
    url: url_PostModifyOptionGroup_604741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604720 = ref object of OpenApiRestCall_602450
proc url_GetModifyOptionGroup_604722(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_604721(path: JsonNode; query: JsonNode;
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
  var valid_604723 = query.getOrDefault("OptionGroupName")
  valid_604723 = validateParameter(valid_604723, JString, required = true,
                                 default = nil)
  if valid_604723 != nil:
    section.add "OptionGroupName", valid_604723
  var valid_604724 = query.getOrDefault("OptionsToRemove")
  valid_604724 = validateParameter(valid_604724, JArray, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "OptionsToRemove", valid_604724
  var valid_604725 = query.getOrDefault("Action")
  valid_604725 = validateParameter(valid_604725, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604725 != nil:
    section.add "Action", valid_604725
  var valid_604726 = query.getOrDefault("Version")
  valid_604726 = validateParameter(valid_604726, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604726 != nil:
    section.add "Version", valid_604726
  var valid_604727 = query.getOrDefault("ApplyImmediately")
  valid_604727 = validateParameter(valid_604727, JBool, required = false, default = nil)
  if valid_604727 != nil:
    section.add "ApplyImmediately", valid_604727
  var valid_604728 = query.getOrDefault("OptionsToInclude")
  valid_604728 = validateParameter(valid_604728, JArray, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "OptionsToInclude", valid_604728
  result.add "query", section
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

proc call*(call_604736: Call_GetModifyOptionGroup_604720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604736.validator(path, query, header, formData, body)
  let scheme = call_604736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604736.url(scheme.get, call_604736.host, call_604736.base,
                         call_604736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604736, url, valid)

proc call*(call_604737: Call_GetModifyOptionGroup_604720; OptionGroupName: string;
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
  var query_604738 = newJObject()
  add(query_604738, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604738.add "OptionsToRemove", OptionsToRemove
  add(query_604738, "Action", newJString(Action))
  add(query_604738, "Version", newJString(Version))
  add(query_604738, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604738.add "OptionsToInclude", OptionsToInclude
  result = call_604737.call(nil, query_604738, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604720(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604721, base: "/",
    url: url_GetModifyOptionGroup_604722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604777 = ref object of OpenApiRestCall_602450
proc url_PostPromoteReadReplica_604779(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_604778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604780 = query.getOrDefault("Action")
  valid_604780 = validateParameter(valid_604780, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604780 != nil:
    section.add "Action", valid_604780
  var valid_604781 = query.getOrDefault("Version")
  valid_604781 = validateParameter(valid_604781, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604781 != nil:
    section.add "Version", valid_604781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604782 = header.getOrDefault("X-Amz-Date")
  valid_604782 = validateParameter(valid_604782, JString, required = false,
                                 default = nil)
  if valid_604782 != nil:
    section.add "X-Amz-Date", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Security-Token")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Security-Token", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Content-Sha256", valid_604784
  var valid_604785 = header.getOrDefault("X-Amz-Algorithm")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-Algorithm", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-Signature")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Signature", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-SignedHeaders", valid_604787
  var valid_604788 = header.getOrDefault("X-Amz-Credential")
  valid_604788 = validateParameter(valid_604788, JString, required = false,
                                 default = nil)
  if valid_604788 != nil:
    section.add "X-Amz-Credential", valid_604788
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604789 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604789 = validateParameter(valid_604789, JString, required = true,
                                 default = nil)
  if valid_604789 != nil:
    section.add "DBInstanceIdentifier", valid_604789
  var valid_604790 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604790 = validateParameter(valid_604790, JInt, required = false, default = nil)
  if valid_604790 != nil:
    section.add "BackupRetentionPeriod", valid_604790
  var valid_604791 = formData.getOrDefault("PreferredBackupWindow")
  valid_604791 = validateParameter(valid_604791, JString, required = false,
                                 default = nil)
  if valid_604791 != nil:
    section.add "PreferredBackupWindow", valid_604791
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604792: Call_PostPromoteReadReplica_604777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604792.validator(path, query, header, formData, body)
  let scheme = call_604792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604792.url(scheme.get, call_604792.host, call_604792.base,
                         call_604792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604792, url, valid)

proc call*(call_604793: Call_PostPromoteReadReplica_604777;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604794 = newJObject()
  var formData_604795 = newJObject()
  add(formData_604795, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604795, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604794, "Action", newJString(Action))
  add(formData_604795, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604794, "Version", newJString(Version))
  result = call_604793.call(nil, query_604794, nil, formData_604795, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604777(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604778, base: "/",
    url: url_PostPromoteReadReplica_604779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604759 = ref object of OpenApiRestCall_602450
proc url_GetPromoteReadReplica_604761(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_604760(path: JsonNode; query: JsonNode;
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
  var valid_604762 = query.getOrDefault("BackupRetentionPeriod")
  valid_604762 = validateParameter(valid_604762, JInt, required = false, default = nil)
  if valid_604762 != nil:
    section.add "BackupRetentionPeriod", valid_604762
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604763 = query.getOrDefault("Action")
  valid_604763 = validateParameter(valid_604763, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604763 != nil:
    section.add "Action", valid_604763
  var valid_604764 = query.getOrDefault("PreferredBackupWindow")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "PreferredBackupWindow", valid_604764
  var valid_604765 = query.getOrDefault("Version")
  valid_604765 = validateParameter(valid_604765, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604765 != nil:
    section.add "Version", valid_604765
  var valid_604766 = query.getOrDefault("DBInstanceIdentifier")
  valid_604766 = validateParameter(valid_604766, JString, required = true,
                                 default = nil)
  if valid_604766 != nil:
    section.add "DBInstanceIdentifier", valid_604766
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604774: Call_GetPromoteReadReplica_604759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604774.validator(path, query, header, formData, body)
  let scheme = call_604774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604774.url(scheme.get, call_604774.host, call_604774.base,
                         call_604774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604774, url, valid)

proc call*(call_604775: Call_GetPromoteReadReplica_604759;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604776 = newJObject()
  add(query_604776, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604776, "Action", newJString(Action))
  add(query_604776, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604776, "Version", newJString(Version))
  add(query_604776, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604775.call(nil, query_604776, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604759(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604760, base: "/",
    url: url_GetPromoteReadReplica_604761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604814 = ref object of OpenApiRestCall_602450
proc url_PostPurchaseReservedDBInstancesOffering_604816(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604815(path: JsonNode;
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
  var valid_604817 = query.getOrDefault("Action")
  valid_604817 = validateParameter(valid_604817, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604817 != nil:
    section.add "Action", valid_604817
  var valid_604818 = query.getOrDefault("Version")
  valid_604818 = validateParameter(valid_604818, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604826 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "ReservedDBInstanceId", valid_604826
  var valid_604827 = formData.getOrDefault("DBInstanceCount")
  valid_604827 = validateParameter(valid_604827, JInt, required = false, default = nil)
  if valid_604827 != nil:
    section.add "DBInstanceCount", valid_604827
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604828 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604828 = validateParameter(valid_604828, JString, required = true,
                                 default = nil)
  if valid_604828 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604829: Call_PostPurchaseReservedDBInstancesOffering_604814;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604829.validator(path, query, header, formData, body)
  let scheme = call_604829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604829.url(scheme.get, call_604829.host, call_604829.base,
                         call_604829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604829, url, valid)

proc call*(call_604830: Call_PostPurchaseReservedDBInstancesOffering_604814;
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
  var query_604831 = newJObject()
  var formData_604832 = newJObject()
  add(formData_604832, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604832, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604831, "Action", newJString(Action))
  add(formData_604832, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604831, "Version", newJString(Version))
  result = call_604830.call(nil, query_604831, nil, formData_604832, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604814(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604815, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604796 = ref object of OpenApiRestCall_602450
proc url_GetPurchaseReservedDBInstancesOffering_604798(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604797(path: JsonNode;
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
  var valid_604799 = query.getOrDefault("DBInstanceCount")
  valid_604799 = validateParameter(valid_604799, JInt, required = false, default = nil)
  if valid_604799 != nil:
    section.add "DBInstanceCount", valid_604799
  var valid_604800 = query.getOrDefault("ReservedDBInstanceId")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "ReservedDBInstanceId", valid_604800
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604801 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604801 = validateParameter(valid_604801, JString, required = true,
                                 default = nil)
  if valid_604801 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604801
  var valid_604802 = query.getOrDefault("Action")
  valid_604802 = validateParameter(valid_604802, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604802 != nil:
    section.add "Action", valid_604802
  var valid_604803 = query.getOrDefault("Version")
  valid_604803 = validateParameter(valid_604803, JString, required = true,
                                 default = newJString("2013-02-12"))
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

proc call*(call_604811: Call_GetPurchaseReservedDBInstancesOffering_604796;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604811.validator(path, query, header, formData, body)
  let scheme = call_604811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604811.url(scheme.get, call_604811.host, call_604811.base,
                         call_604811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604811, url, valid)

proc call*(call_604812: Call_GetPurchaseReservedDBInstancesOffering_604796;
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
  var query_604813 = newJObject()
  add(query_604813, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604813, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604813, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604813, "Action", newJString(Action))
  add(query_604813, "Version", newJString(Version))
  result = call_604812.call(nil, query_604813, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604796(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604797, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604850 = ref object of OpenApiRestCall_602450
proc url_PostRebootDBInstance_604852(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_604851(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604853 = query.getOrDefault("Action")
  valid_604853 = validateParameter(valid_604853, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604853 != nil:
    section.add "Action", valid_604853
  var valid_604854 = query.getOrDefault("Version")
  valid_604854 = validateParameter(valid_604854, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604854 != nil:
    section.add "Version", valid_604854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604855 = header.getOrDefault("X-Amz-Date")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Date", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Security-Token")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Security-Token", valid_604856
  var valid_604857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-Content-Sha256", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Algorithm")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Algorithm", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Signature")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Signature", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-SignedHeaders", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Credential")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Credential", valid_604861
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604862 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604862 = validateParameter(valid_604862, JString, required = true,
                                 default = nil)
  if valid_604862 != nil:
    section.add "DBInstanceIdentifier", valid_604862
  var valid_604863 = formData.getOrDefault("ForceFailover")
  valid_604863 = validateParameter(valid_604863, JBool, required = false, default = nil)
  if valid_604863 != nil:
    section.add "ForceFailover", valid_604863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604864: Call_PostRebootDBInstance_604850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604864.validator(path, query, header, formData, body)
  let scheme = call_604864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604864.url(scheme.get, call_604864.host, call_604864.base,
                         call_604864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604864, url, valid)

proc call*(call_604865: Call_PostRebootDBInstance_604850;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604866 = newJObject()
  var formData_604867 = newJObject()
  add(formData_604867, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604866, "Action", newJString(Action))
  add(formData_604867, "ForceFailover", newJBool(ForceFailover))
  add(query_604866, "Version", newJString(Version))
  result = call_604865.call(nil, query_604866, nil, formData_604867, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604850(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604851, base: "/",
    url: url_PostRebootDBInstance_604852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604833 = ref object of OpenApiRestCall_602450
proc url_GetRebootDBInstance_604835(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_604834(path: JsonNode; query: JsonNode;
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
  var valid_604836 = query.getOrDefault("Action")
  valid_604836 = validateParameter(valid_604836, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604836 != nil:
    section.add "Action", valid_604836
  var valid_604837 = query.getOrDefault("ForceFailover")
  valid_604837 = validateParameter(valid_604837, JBool, required = false, default = nil)
  if valid_604837 != nil:
    section.add "ForceFailover", valid_604837
  var valid_604838 = query.getOrDefault("Version")
  valid_604838 = validateParameter(valid_604838, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604838 != nil:
    section.add "Version", valid_604838
  var valid_604839 = query.getOrDefault("DBInstanceIdentifier")
  valid_604839 = validateParameter(valid_604839, JString, required = true,
                                 default = nil)
  if valid_604839 != nil:
    section.add "DBInstanceIdentifier", valid_604839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604840 = header.getOrDefault("X-Amz-Date")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Date", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Security-Token")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Security-Token", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Content-Sha256", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Algorithm")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Algorithm", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Signature")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Signature", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-SignedHeaders", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Credential")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Credential", valid_604846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604847: Call_GetRebootDBInstance_604833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604847.validator(path, query, header, formData, body)
  let scheme = call_604847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604847.url(scheme.get, call_604847.host, call_604847.base,
                         call_604847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604847, url, valid)

proc call*(call_604848: Call_GetRebootDBInstance_604833;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604849 = newJObject()
  add(query_604849, "Action", newJString(Action))
  add(query_604849, "ForceFailover", newJBool(ForceFailover))
  add(query_604849, "Version", newJString(Version))
  add(query_604849, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604848.call(nil, query_604849, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604833(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604834, base: "/",
    url: url_GetRebootDBInstance_604835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_604885 = ref object of OpenApiRestCall_602450
proc url_PostRemoveSourceIdentifierFromSubscription_604887(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_604886(path: JsonNode;
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
  var valid_604888 = query.getOrDefault("Action")
  valid_604888 = validateParameter(valid_604888, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604888 != nil:
    section.add "Action", valid_604888
  var valid_604889 = query.getOrDefault("Version")
  valid_604889 = validateParameter(valid_604889, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604889 != nil:
    section.add "Version", valid_604889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604890 = header.getOrDefault("X-Amz-Date")
  valid_604890 = validateParameter(valid_604890, JString, required = false,
                                 default = nil)
  if valid_604890 != nil:
    section.add "X-Amz-Date", valid_604890
  var valid_604891 = header.getOrDefault("X-Amz-Security-Token")
  valid_604891 = validateParameter(valid_604891, JString, required = false,
                                 default = nil)
  if valid_604891 != nil:
    section.add "X-Amz-Security-Token", valid_604891
  var valid_604892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604892 = validateParameter(valid_604892, JString, required = false,
                                 default = nil)
  if valid_604892 != nil:
    section.add "X-Amz-Content-Sha256", valid_604892
  var valid_604893 = header.getOrDefault("X-Amz-Algorithm")
  valid_604893 = validateParameter(valid_604893, JString, required = false,
                                 default = nil)
  if valid_604893 != nil:
    section.add "X-Amz-Algorithm", valid_604893
  var valid_604894 = header.getOrDefault("X-Amz-Signature")
  valid_604894 = validateParameter(valid_604894, JString, required = false,
                                 default = nil)
  if valid_604894 != nil:
    section.add "X-Amz-Signature", valid_604894
  var valid_604895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604895 = validateParameter(valid_604895, JString, required = false,
                                 default = nil)
  if valid_604895 != nil:
    section.add "X-Amz-SignedHeaders", valid_604895
  var valid_604896 = header.getOrDefault("X-Amz-Credential")
  valid_604896 = validateParameter(valid_604896, JString, required = false,
                                 default = nil)
  if valid_604896 != nil:
    section.add "X-Amz-Credential", valid_604896
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_604897 = formData.getOrDefault("SourceIdentifier")
  valid_604897 = validateParameter(valid_604897, JString, required = true,
                                 default = nil)
  if valid_604897 != nil:
    section.add "SourceIdentifier", valid_604897
  var valid_604898 = formData.getOrDefault("SubscriptionName")
  valid_604898 = validateParameter(valid_604898, JString, required = true,
                                 default = nil)
  if valid_604898 != nil:
    section.add "SubscriptionName", valid_604898
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604899: Call_PostRemoveSourceIdentifierFromSubscription_604885;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604899.validator(path, query, header, formData, body)
  let scheme = call_604899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604899.url(scheme.get, call_604899.host, call_604899.base,
                         call_604899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604899, url, valid)

proc call*(call_604900: Call_PostRemoveSourceIdentifierFromSubscription_604885;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604901 = newJObject()
  var formData_604902 = newJObject()
  add(formData_604902, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_604902, "SubscriptionName", newJString(SubscriptionName))
  add(query_604901, "Action", newJString(Action))
  add(query_604901, "Version", newJString(Version))
  result = call_604900.call(nil, query_604901, nil, formData_604902, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_604885(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_604886,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_604887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604868 = ref object of OpenApiRestCall_602450
proc url_GetRemoveSourceIdentifierFromSubscription_604870(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604869(path: JsonNode;
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
  var valid_604871 = query.getOrDefault("Action")
  valid_604871 = validateParameter(valid_604871, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604871 != nil:
    section.add "Action", valid_604871
  var valid_604872 = query.getOrDefault("SourceIdentifier")
  valid_604872 = validateParameter(valid_604872, JString, required = true,
                                 default = nil)
  if valid_604872 != nil:
    section.add "SourceIdentifier", valid_604872
  var valid_604873 = query.getOrDefault("SubscriptionName")
  valid_604873 = validateParameter(valid_604873, JString, required = true,
                                 default = nil)
  if valid_604873 != nil:
    section.add "SubscriptionName", valid_604873
  var valid_604874 = query.getOrDefault("Version")
  valid_604874 = validateParameter(valid_604874, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604874 != nil:
    section.add "Version", valid_604874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604875 = header.getOrDefault("X-Amz-Date")
  valid_604875 = validateParameter(valid_604875, JString, required = false,
                                 default = nil)
  if valid_604875 != nil:
    section.add "X-Amz-Date", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-Security-Token")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-Security-Token", valid_604876
  var valid_604877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-Content-Sha256", valid_604877
  var valid_604878 = header.getOrDefault("X-Amz-Algorithm")
  valid_604878 = validateParameter(valid_604878, JString, required = false,
                                 default = nil)
  if valid_604878 != nil:
    section.add "X-Amz-Algorithm", valid_604878
  var valid_604879 = header.getOrDefault("X-Amz-Signature")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "X-Amz-Signature", valid_604879
  var valid_604880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-SignedHeaders", valid_604880
  var valid_604881 = header.getOrDefault("X-Amz-Credential")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-Credential", valid_604881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604882: Call_GetRemoveSourceIdentifierFromSubscription_604868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604882.validator(path, query, header, formData, body)
  let scheme = call_604882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604882.url(scheme.get, call_604882.host, call_604882.base,
                         call_604882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604882, url, valid)

proc call*(call_604883: Call_GetRemoveSourceIdentifierFromSubscription_604868;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_604884 = newJObject()
  add(query_604884, "Action", newJString(Action))
  add(query_604884, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604884, "SubscriptionName", newJString(SubscriptionName))
  add(query_604884, "Version", newJString(Version))
  result = call_604883.call(nil, query_604884, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604868(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604869,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604920 = ref object of OpenApiRestCall_602450
proc url_PostRemoveTagsFromResource_604922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_604921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604923 = query.getOrDefault("Action")
  valid_604923 = validateParameter(valid_604923, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604923 != nil:
    section.add "Action", valid_604923
  var valid_604924 = query.getOrDefault("Version")
  valid_604924 = validateParameter(valid_604924, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604924 != nil:
    section.add "Version", valid_604924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604925 = header.getOrDefault("X-Amz-Date")
  valid_604925 = validateParameter(valid_604925, JString, required = false,
                                 default = nil)
  if valid_604925 != nil:
    section.add "X-Amz-Date", valid_604925
  var valid_604926 = header.getOrDefault("X-Amz-Security-Token")
  valid_604926 = validateParameter(valid_604926, JString, required = false,
                                 default = nil)
  if valid_604926 != nil:
    section.add "X-Amz-Security-Token", valid_604926
  var valid_604927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604927 = validateParameter(valid_604927, JString, required = false,
                                 default = nil)
  if valid_604927 != nil:
    section.add "X-Amz-Content-Sha256", valid_604927
  var valid_604928 = header.getOrDefault("X-Amz-Algorithm")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "X-Amz-Algorithm", valid_604928
  var valid_604929 = header.getOrDefault("X-Amz-Signature")
  valid_604929 = validateParameter(valid_604929, JString, required = false,
                                 default = nil)
  if valid_604929 != nil:
    section.add "X-Amz-Signature", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-SignedHeaders", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Credential")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Credential", valid_604931
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604932 = formData.getOrDefault("TagKeys")
  valid_604932 = validateParameter(valid_604932, JArray, required = true, default = nil)
  if valid_604932 != nil:
    section.add "TagKeys", valid_604932
  var valid_604933 = formData.getOrDefault("ResourceName")
  valid_604933 = validateParameter(valid_604933, JString, required = true,
                                 default = nil)
  if valid_604933 != nil:
    section.add "ResourceName", valid_604933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604934: Call_PostRemoveTagsFromResource_604920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604934.validator(path, query, header, formData, body)
  let scheme = call_604934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604934.url(scheme.get, call_604934.host, call_604934.base,
                         call_604934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604934, url, valid)

proc call*(call_604935: Call_PostRemoveTagsFromResource_604920; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604936 = newJObject()
  var formData_604937 = newJObject()
  add(query_604936, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604937.add "TagKeys", TagKeys
  add(formData_604937, "ResourceName", newJString(ResourceName))
  add(query_604936, "Version", newJString(Version))
  result = call_604935.call(nil, query_604936, nil, formData_604937, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604920(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604921, base: "/",
    url: url_PostRemoveTagsFromResource_604922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604903 = ref object of OpenApiRestCall_602450
proc url_GetRemoveTagsFromResource_604905(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_604904(path: JsonNode; query: JsonNode;
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
  var valid_604906 = query.getOrDefault("ResourceName")
  valid_604906 = validateParameter(valid_604906, JString, required = true,
                                 default = nil)
  if valid_604906 != nil:
    section.add "ResourceName", valid_604906
  var valid_604907 = query.getOrDefault("Action")
  valid_604907 = validateParameter(valid_604907, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604907 != nil:
    section.add "Action", valid_604907
  var valid_604908 = query.getOrDefault("TagKeys")
  valid_604908 = validateParameter(valid_604908, JArray, required = true, default = nil)
  if valid_604908 != nil:
    section.add "TagKeys", valid_604908
  var valid_604909 = query.getOrDefault("Version")
  valid_604909 = validateParameter(valid_604909, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604909 != nil:
    section.add "Version", valid_604909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604910 = header.getOrDefault("X-Amz-Date")
  valid_604910 = validateParameter(valid_604910, JString, required = false,
                                 default = nil)
  if valid_604910 != nil:
    section.add "X-Amz-Date", valid_604910
  var valid_604911 = header.getOrDefault("X-Amz-Security-Token")
  valid_604911 = validateParameter(valid_604911, JString, required = false,
                                 default = nil)
  if valid_604911 != nil:
    section.add "X-Amz-Security-Token", valid_604911
  var valid_604912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604912 = validateParameter(valid_604912, JString, required = false,
                                 default = nil)
  if valid_604912 != nil:
    section.add "X-Amz-Content-Sha256", valid_604912
  var valid_604913 = header.getOrDefault("X-Amz-Algorithm")
  valid_604913 = validateParameter(valid_604913, JString, required = false,
                                 default = nil)
  if valid_604913 != nil:
    section.add "X-Amz-Algorithm", valid_604913
  var valid_604914 = header.getOrDefault("X-Amz-Signature")
  valid_604914 = validateParameter(valid_604914, JString, required = false,
                                 default = nil)
  if valid_604914 != nil:
    section.add "X-Amz-Signature", valid_604914
  var valid_604915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-SignedHeaders", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Credential")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Credential", valid_604916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604917: Call_GetRemoveTagsFromResource_604903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604917.validator(path, query, header, formData, body)
  let scheme = call_604917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604917.url(scheme.get, call_604917.host, call_604917.base,
                         call_604917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604917, url, valid)

proc call*(call_604918: Call_GetRemoveTagsFromResource_604903;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_604919 = newJObject()
  add(query_604919, "ResourceName", newJString(ResourceName))
  add(query_604919, "Action", newJString(Action))
  if TagKeys != nil:
    query_604919.add "TagKeys", TagKeys
  add(query_604919, "Version", newJString(Version))
  result = call_604918.call(nil, query_604919, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604903(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604904, base: "/",
    url: url_GetRemoveTagsFromResource_604905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_604956 = ref object of OpenApiRestCall_602450
proc url_PostResetDBParameterGroup_604958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_604957(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604959 = query.getOrDefault("Action")
  valid_604959 = validateParameter(valid_604959, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604959 != nil:
    section.add "Action", valid_604959
  var valid_604960 = query.getOrDefault("Version")
  valid_604960 = validateParameter(valid_604960, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604960 != nil:
    section.add "Version", valid_604960
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604968 = formData.getOrDefault("DBParameterGroupName")
  valid_604968 = validateParameter(valid_604968, JString, required = true,
                                 default = nil)
  if valid_604968 != nil:
    section.add "DBParameterGroupName", valid_604968
  var valid_604969 = formData.getOrDefault("Parameters")
  valid_604969 = validateParameter(valid_604969, JArray, required = false,
                                 default = nil)
  if valid_604969 != nil:
    section.add "Parameters", valid_604969
  var valid_604970 = formData.getOrDefault("ResetAllParameters")
  valid_604970 = validateParameter(valid_604970, JBool, required = false, default = nil)
  if valid_604970 != nil:
    section.add "ResetAllParameters", valid_604970
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604971: Call_PostResetDBParameterGroup_604956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604971.validator(path, query, header, formData, body)
  let scheme = call_604971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604971.url(scheme.get, call_604971.host, call_604971.base,
                         call_604971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604971, url, valid)

proc call*(call_604972: Call_PostResetDBParameterGroup_604956;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604973 = newJObject()
  var formData_604974 = newJObject()
  add(formData_604974, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604974.add "Parameters", Parameters
  add(query_604973, "Action", newJString(Action))
  add(formData_604974, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604973, "Version", newJString(Version))
  result = call_604972.call(nil, query_604973, nil, formData_604974, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_604956(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_604957, base: "/",
    url: url_PostResetDBParameterGroup_604958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604938 = ref object of OpenApiRestCall_602450
proc url_GetResetDBParameterGroup_604940(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_604939(path: JsonNode; query: JsonNode;
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
  var valid_604941 = query.getOrDefault("DBParameterGroupName")
  valid_604941 = validateParameter(valid_604941, JString, required = true,
                                 default = nil)
  if valid_604941 != nil:
    section.add "DBParameterGroupName", valid_604941
  var valid_604942 = query.getOrDefault("Parameters")
  valid_604942 = validateParameter(valid_604942, JArray, required = false,
                                 default = nil)
  if valid_604942 != nil:
    section.add "Parameters", valid_604942
  var valid_604943 = query.getOrDefault("Action")
  valid_604943 = validateParameter(valid_604943, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604943 != nil:
    section.add "Action", valid_604943
  var valid_604944 = query.getOrDefault("ResetAllParameters")
  valid_604944 = validateParameter(valid_604944, JBool, required = false, default = nil)
  if valid_604944 != nil:
    section.add "ResetAllParameters", valid_604944
  var valid_604945 = query.getOrDefault("Version")
  valid_604945 = validateParameter(valid_604945, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604945 != nil:
    section.add "Version", valid_604945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604946 = header.getOrDefault("X-Amz-Date")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "X-Amz-Date", valid_604946
  var valid_604947 = header.getOrDefault("X-Amz-Security-Token")
  valid_604947 = validateParameter(valid_604947, JString, required = false,
                                 default = nil)
  if valid_604947 != nil:
    section.add "X-Amz-Security-Token", valid_604947
  var valid_604948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604948 = validateParameter(valid_604948, JString, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "X-Amz-Content-Sha256", valid_604948
  var valid_604949 = header.getOrDefault("X-Amz-Algorithm")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "X-Amz-Algorithm", valid_604949
  var valid_604950 = header.getOrDefault("X-Amz-Signature")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Signature", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-SignedHeaders", valid_604951
  var valid_604952 = header.getOrDefault("X-Amz-Credential")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "X-Amz-Credential", valid_604952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604953: Call_GetResetDBParameterGroup_604938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604953.validator(path, query, header, formData, body)
  let scheme = call_604953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604953.url(scheme.get, call_604953.host, call_604953.base,
                         call_604953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604953, url, valid)

proc call*(call_604954: Call_GetResetDBParameterGroup_604938;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604955 = newJObject()
  add(query_604955, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604955.add "Parameters", Parameters
  add(query_604955, "Action", newJString(Action))
  add(query_604955, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604955, "Version", newJString(Version))
  result = call_604954.call(nil, query_604955, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604938(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604939, base: "/",
    url: url_GetResetDBParameterGroup_604940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_605004 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceFromDBSnapshot_605006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_605005(path: JsonNode;
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
  var valid_605007 = query.getOrDefault("Action")
  valid_605007 = validateParameter(valid_605007, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605007 != nil:
    section.add "Action", valid_605007
  var valid_605008 = query.getOrDefault("Version")
  valid_605008 = validateParameter(valid_605008, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605008 != nil:
    section.add "Version", valid_605008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605009 = header.getOrDefault("X-Amz-Date")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-Date", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-Security-Token")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-Security-Token", valid_605010
  var valid_605011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "X-Amz-Content-Sha256", valid_605011
  var valid_605012 = header.getOrDefault("X-Amz-Algorithm")
  valid_605012 = validateParameter(valid_605012, JString, required = false,
                                 default = nil)
  if valid_605012 != nil:
    section.add "X-Amz-Algorithm", valid_605012
  var valid_605013 = header.getOrDefault("X-Amz-Signature")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "X-Amz-Signature", valid_605013
  var valid_605014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605014 = validateParameter(valid_605014, JString, required = false,
                                 default = nil)
  if valid_605014 != nil:
    section.add "X-Amz-SignedHeaders", valid_605014
  var valid_605015 = header.getOrDefault("X-Amz-Credential")
  valid_605015 = validateParameter(valid_605015, JString, required = false,
                                 default = nil)
  if valid_605015 != nil:
    section.add "X-Amz-Credential", valid_605015
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
  var valid_605016 = formData.getOrDefault("Port")
  valid_605016 = validateParameter(valid_605016, JInt, required = false, default = nil)
  if valid_605016 != nil:
    section.add "Port", valid_605016
  var valid_605017 = formData.getOrDefault("Engine")
  valid_605017 = validateParameter(valid_605017, JString, required = false,
                                 default = nil)
  if valid_605017 != nil:
    section.add "Engine", valid_605017
  var valid_605018 = formData.getOrDefault("Iops")
  valid_605018 = validateParameter(valid_605018, JInt, required = false, default = nil)
  if valid_605018 != nil:
    section.add "Iops", valid_605018
  var valid_605019 = formData.getOrDefault("DBName")
  valid_605019 = validateParameter(valid_605019, JString, required = false,
                                 default = nil)
  if valid_605019 != nil:
    section.add "DBName", valid_605019
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605020 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605020 = validateParameter(valid_605020, JString, required = true,
                                 default = nil)
  if valid_605020 != nil:
    section.add "DBInstanceIdentifier", valid_605020
  var valid_605021 = formData.getOrDefault("OptionGroupName")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "OptionGroupName", valid_605021
  var valid_605022 = formData.getOrDefault("DBSubnetGroupName")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "DBSubnetGroupName", valid_605022
  var valid_605023 = formData.getOrDefault("AvailabilityZone")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "AvailabilityZone", valid_605023
  var valid_605024 = formData.getOrDefault("MultiAZ")
  valid_605024 = validateParameter(valid_605024, JBool, required = false, default = nil)
  if valid_605024 != nil:
    section.add "MultiAZ", valid_605024
  var valid_605025 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_605025 = validateParameter(valid_605025, JString, required = true,
                                 default = nil)
  if valid_605025 != nil:
    section.add "DBSnapshotIdentifier", valid_605025
  var valid_605026 = formData.getOrDefault("PubliclyAccessible")
  valid_605026 = validateParameter(valid_605026, JBool, required = false, default = nil)
  if valid_605026 != nil:
    section.add "PubliclyAccessible", valid_605026
  var valid_605027 = formData.getOrDefault("DBInstanceClass")
  valid_605027 = validateParameter(valid_605027, JString, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "DBInstanceClass", valid_605027
  var valid_605028 = formData.getOrDefault("LicenseModel")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "LicenseModel", valid_605028
  var valid_605029 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605029 = validateParameter(valid_605029, JBool, required = false, default = nil)
  if valid_605029 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605029
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605030: Call_PostRestoreDBInstanceFromDBSnapshot_605004;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605030.validator(path, query, header, formData, body)
  let scheme = call_605030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605030.url(scheme.get, call_605030.host, call_605030.base,
                         call_605030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605030, url, valid)

proc call*(call_605031: Call_PostRestoreDBInstanceFromDBSnapshot_605004;
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
  var query_605032 = newJObject()
  var formData_605033 = newJObject()
  add(formData_605033, "Port", newJInt(Port))
  add(formData_605033, "Engine", newJString(Engine))
  add(formData_605033, "Iops", newJInt(Iops))
  add(formData_605033, "DBName", newJString(DBName))
  add(formData_605033, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605033, "OptionGroupName", newJString(OptionGroupName))
  add(formData_605033, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605033, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605033, "MultiAZ", newJBool(MultiAZ))
  add(formData_605033, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_605032, "Action", newJString(Action))
  add(formData_605033, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605033, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605033, "LicenseModel", newJString(LicenseModel))
  add(formData_605033, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605032, "Version", newJString(Version))
  result = call_605031.call(nil, query_605032, nil, formData_605033, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_605004(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_605005, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_605006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_604975 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceFromDBSnapshot_604977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_604976(path: JsonNode;
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
  var valid_604978 = query.getOrDefault("Engine")
  valid_604978 = validateParameter(valid_604978, JString, required = false,
                                 default = nil)
  if valid_604978 != nil:
    section.add "Engine", valid_604978
  var valid_604979 = query.getOrDefault("OptionGroupName")
  valid_604979 = validateParameter(valid_604979, JString, required = false,
                                 default = nil)
  if valid_604979 != nil:
    section.add "OptionGroupName", valid_604979
  var valid_604980 = query.getOrDefault("AvailabilityZone")
  valid_604980 = validateParameter(valid_604980, JString, required = false,
                                 default = nil)
  if valid_604980 != nil:
    section.add "AvailabilityZone", valid_604980
  var valid_604981 = query.getOrDefault("Iops")
  valid_604981 = validateParameter(valid_604981, JInt, required = false, default = nil)
  if valid_604981 != nil:
    section.add "Iops", valid_604981
  var valid_604982 = query.getOrDefault("MultiAZ")
  valid_604982 = validateParameter(valid_604982, JBool, required = false, default = nil)
  if valid_604982 != nil:
    section.add "MultiAZ", valid_604982
  var valid_604983 = query.getOrDefault("LicenseModel")
  valid_604983 = validateParameter(valid_604983, JString, required = false,
                                 default = nil)
  if valid_604983 != nil:
    section.add "LicenseModel", valid_604983
  var valid_604984 = query.getOrDefault("DBName")
  valid_604984 = validateParameter(valid_604984, JString, required = false,
                                 default = nil)
  if valid_604984 != nil:
    section.add "DBName", valid_604984
  var valid_604985 = query.getOrDefault("DBInstanceClass")
  valid_604985 = validateParameter(valid_604985, JString, required = false,
                                 default = nil)
  if valid_604985 != nil:
    section.add "DBInstanceClass", valid_604985
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604986 = query.getOrDefault("Action")
  valid_604986 = validateParameter(valid_604986, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604986 != nil:
    section.add "Action", valid_604986
  var valid_604987 = query.getOrDefault("DBSubnetGroupName")
  valid_604987 = validateParameter(valid_604987, JString, required = false,
                                 default = nil)
  if valid_604987 != nil:
    section.add "DBSubnetGroupName", valid_604987
  var valid_604988 = query.getOrDefault("PubliclyAccessible")
  valid_604988 = validateParameter(valid_604988, JBool, required = false, default = nil)
  if valid_604988 != nil:
    section.add "PubliclyAccessible", valid_604988
  var valid_604989 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604989 = validateParameter(valid_604989, JBool, required = false, default = nil)
  if valid_604989 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604989
  var valid_604990 = query.getOrDefault("Port")
  valid_604990 = validateParameter(valid_604990, JInt, required = false, default = nil)
  if valid_604990 != nil:
    section.add "Port", valid_604990
  var valid_604991 = query.getOrDefault("Version")
  valid_604991 = validateParameter(valid_604991, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604991 != nil:
    section.add "Version", valid_604991
  var valid_604992 = query.getOrDefault("DBInstanceIdentifier")
  valid_604992 = validateParameter(valid_604992, JString, required = true,
                                 default = nil)
  if valid_604992 != nil:
    section.add "DBInstanceIdentifier", valid_604992
  var valid_604993 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604993 = validateParameter(valid_604993, JString, required = true,
                                 default = nil)
  if valid_604993 != nil:
    section.add "DBSnapshotIdentifier", valid_604993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604994 = header.getOrDefault("X-Amz-Date")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Date", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-Security-Token")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-Security-Token", valid_604995
  var valid_604996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604996 = validateParameter(valid_604996, JString, required = false,
                                 default = nil)
  if valid_604996 != nil:
    section.add "X-Amz-Content-Sha256", valid_604996
  var valid_604997 = header.getOrDefault("X-Amz-Algorithm")
  valid_604997 = validateParameter(valid_604997, JString, required = false,
                                 default = nil)
  if valid_604997 != nil:
    section.add "X-Amz-Algorithm", valid_604997
  var valid_604998 = header.getOrDefault("X-Amz-Signature")
  valid_604998 = validateParameter(valid_604998, JString, required = false,
                                 default = nil)
  if valid_604998 != nil:
    section.add "X-Amz-Signature", valid_604998
  var valid_604999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604999 = validateParameter(valid_604999, JString, required = false,
                                 default = nil)
  if valid_604999 != nil:
    section.add "X-Amz-SignedHeaders", valid_604999
  var valid_605000 = header.getOrDefault("X-Amz-Credential")
  valid_605000 = validateParameter(valid_605000, JString, required = false,
                                 default = nil)
  if valid_605000 != nil:
    section.add "X-Amz-Credential", valid_605000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605001: Call_GetRestoreDBInstanceFromDBSnapshot_604975;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605001.validator(path, query, header, formData, body)
  let scheme = call_605001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605001.url(scheme.get, call_605001.host, call_605001.base,
                         call_605001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605001, url, valid)

proc call*(call_605002: Call_GetRestoreDBInstanceFromDBSnapshot_604975;
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
  var query_605003 = newJObject()
  add(query_605003, "Engine", newJString(Engine))
  add(query_605003, "OptionGroupName", newJString(OptionGroupName))
  add(query_605003, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605003, "Iops", newJInt(Iops))
  add(query_605003, "MultiAZ", newJBool(MultiAZ))
  add(query_605003, "LicenseModel", newJString(LicenseModel))
  add(query_605003, "DBName", newJString(DBName))
  add(query_605003, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605003, "Action", newJString(Action))
  add(query_605003, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605003, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605003, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605003, "Port", newJInt(Port))
  add(query_605003, "Version", newJString(Version))
  add(query_605003, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605003, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_605002.call(nil, query_605003, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_604975(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_604976, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_604977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605065 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceToPointInTime_605067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_605066(path: JsonNode;
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
  var valid_605068 = query.getOrDefault("Action")
  valid_605068 = validateParameter(valid_605068, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605068 != nil:
    section.add "Action", valid_605068
  var valid_605069 = query.getOrDefault("Version")
  valid_605069 = validateParameter(valid_605069, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605069 != nil:
    section.add "Version", valid_605069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605070 = header.getOrDefault("X-Amz-Date")
  valid_605070 = validateParameter(valid_605070, JString, required = false,
                                 default = nil)
  if valid_605070 != nil:
    section.add "X-Amz-Date", valid_605070
  var valid_605071 = header.getOrDefault("X-Amz-Security-Token")
  valid_605071 = validateParameter(valid_605071, JString, required = false,
                                 default = nil)
  if valid_605071 != nil:
    section.add "X-Amz-Security-Token", valid_605071
  var valid_605072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605072 = validateParameter(valid_605072, JString, required = false,
                                 default = nil)
  if valid_605072 != nil:
    section.add "X-Amz-Content-Sha256", valid_605072
  var valid_605073 = header.getOrDefault("X-Amz-Algorithm")
  valid_605073 = validateParameter(valid_605073, JString, required = false,
                                 default = nil)
  if valid_605073 != nil:
    section.add "X-Amz-Algorithm", valid_605073
  var valid_605074 = header.getOrDefault("X-Amz-Signature")
  valid_605074 = validateParameter(valid_605074, JString, required = false,
                                 default = nil)
  if valid_605074 != nil:
    section.add "X-Amz-Signature", valid_605074
  var valid_605075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605075 = validateParameter(valid_605075, JString, required = false,
                                 default = nil)
  if valid_605075 != nil:
    section.add "X-Amz-SignedHeaders", valid_605075
  var valid_605076 = header.getOrDefault("X-Amz-Credential")
  valid_605076 = validateParameter(valid_605076, JString, required = false,
                                 default = nil)
  if valid_605076 != nil:
    section.add "X-Amz-Credential", valid_605076
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
  var valid_605077 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605077 = validateParameter(valid_605077, JBool, required = false, default = nil)
  if valid_605077 != nil:
    section.add "UseLatestRestorableTime", valid_605077
  var valid_605078 = formData.getOrDefault("Port")
  valid_605078 = validateParameter(valid_605078, JInt, required = false, default = nil)
  if valid_605078 != nil:
    section.add "Port", valid_605078
  var valid_605079 = formData.getOrDefault("Engine")
  valid_605079 = validateParameter(valid_605079, JString, required = false,
                                 default = nil)
  if valid_605079 != nil:
    section.add "Engine", valid_605079
  var valid_605080 = formData.getOrDefault("Iops")
  valid_605080 = validateParameter(valid_605080, JInt, required = false, default = nil)
  if valid_605080 != nil:
    section.add "Iops", valid_605080
  var valid_605081 = formData.getOrDefault("DBName")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "DBName", valid_605081
  var valid_605082 = formData.getOrDefault("OptionGroupName")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "OptionGroupName", valid_605082
  var valid_605083 = formData.getOrDefault("DBSubnetGroupName")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "DBSubnetGroupName", valid_605083
  var valid_605084 = formData.getOrDefault("AvailabilityZone")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "AvailabilityZone", valid_605084
  var valid_605085 = formData.getOrDefault("MultiAZ")
  valid_605085 = validateParameter(valid_605085, JBool, required = false, default = nil)
  if valid_605085 != nil:
    section.add "MultiAZ", valid_605085
  var valid_605086 = formData.getOrDefault("RestoreTime")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "RestoreTime", valid_605086
  var valid_605087 = formData.getOrDefault("PubliclyAccessible")
  valid_605087 = validateParameter(valid_605087, JBool, required = false, default = nil)
  if valid_605087 != nil:
    section.add "PubliclyAccessible", valid_605087
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605088 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605088 = validateParameter(valid_605088, JString, required = true,
                                 default = nil)
  if valid_605088 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605088
  var valid_605089 = formData.getOrDefault("DBInstanceClass")
  valid_605089 = validateParameter(valid_605089, JString, required = false,
                                 default = nil)
  if valid_605089 != nil:
    section.add "DBInstanceClass", valid_605089
  var valid_605090 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605090 = validateParameter(valid_605090, JString, required = true,
                                 default = nil)
  if valid_605090 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605090
  var valid_605091 = formData.getOrDefault("LicenseModel")
  valid_605091 = validateParameter(valid_605091, JString, required = false,
                                 default = nil)
  if valid_605091 != nil:
    section.add "LicenseModel", valid_605091
  var valid_605092 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605092 = validateParameter(valid_605092, JBool, required = false, default = nil)
  if valid_605092 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605093: Call_PostRestoreDBInstanceToPointInTime_605065;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605093.validator(path, query, header, formData, body)
  let scheme = call_605093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605093.url(scheme.get, call_605093.host, call_605093.base,
                         call_605093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605093, url, valid)

proc call*(call_605094: Call_PostRestoreDBInstanceToPointInTime_605065;
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
  var query_605095 = newJObject()
  var formData_605096 = newJObject()
  add(formData_605096, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605096, "Port", newJInt(Port))
  add(formData_605096, "Engine", newJString(Engine))
  add(formData_605096, "Iops", newJInt(Iops))
  add(formData_605096, "DBName", newJString(DBName))
  add(formData_605096, "OptionGroupName", newJString(OptionGroupName))
  add(formData_605096, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605096, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605096, "MultiAZ", newJBool(MultiAZ))
  add(query_605095, "Action", newJString(Action))
  add(formData_605096, "RestoreTime", newJString(RestoreTime))
  add(formData_605096, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605096, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605096, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605096, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605096, "LicenseModel", newJString(LicenseModel))
  add(formData_605096, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605095, "Version", newJString(Version))
  result = call_605094.call(nil, query_605095, nil, formData_605096, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605065(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605066, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605034 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceToPointInTime_605036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_605035(path: JsonNode;
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
  var valid_605037 = query.getOrDefault("Engine")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "Engine", valid_605037
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605038 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605038 = validateParameter(valid_605038, JString, required = true,
                                 default = nil)
  if valid_605038 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605038
  var valid_605039 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605039 = validateParameter(valid_605039, JString, required = true,
                                 default = nil)
  if valid_605039 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605039
  var valid_605040 = query.getOrDefault("AvailabilityZone")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "AvailabilityZone", valid_605040
  var valid_605041 = query.getOrDefault("Iops")
  valid_605041 = validateParameter(valid_605041, JInt, required = false, default = nil)
  if valid_605041 != nil:
    section.add "Iops", valid_605041
  var valid_605042 = query.getOrDefault("OptionGroupName")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "OptionGroupName", valid_605042
  var valid_605043 = query.getOrDefault("RestoreTime")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "RestoreTime", valid_605043
  var valid_605044 = query.getOrDefault("MultiAZ")
  valid_605044 = validateParameter(valid_605044, JBool, required = false, default = nil)
  if valid_605044 != nil:
    section.add "MultiAZ", valid_605044
  var valid_605045 = query.getOrDefault("LicenseModel")
  valid_605045 = validateParameter(valid_605045, JString, required = false,
                                 default = nil)
  if valid_605045 != nil:
    section.add "LicenseModel", valid_605045
  var valid_605046 = query.getOrDefault("DBName")
  valid_605046 = validateParameter(valid_605046, JString, required = false,
                                 default = nil)
  if valid_605046 != nil:
    section.add "DBName", valid_605046
  var valid_605047 = query.getOrDefault("DBInstanceClass")
  valid_605047 = validateParameter(valid_605047, JString, required = false,
                                 default = nil)
  if valid_605047 != nil:
    section.add "DBInstanceClass", valid_605047
  var valid_605048 = query.getOrDefault("Action")
  valid_605048 = validateParameter(valid_605048, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605048 != nil:
    section.add "Action", valid_605048
  var valid_605049 = query.getOrDefault("UseLatestRestorableTime")
  valid_605049 = validateParameter(valid_605049, JBool, required = false, default = nil)
  if valid_605049 != nil:
    section.add "UseLatestRestorableTime", valid_605049
  var valid_605050 = query.getOrDefault("DBSubnetGroupName")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "DBSubnetGroupName", valid_605050
  var valid_605051 = query.getOrDefault("PubliclyAccessible")
  valid_605051 = validateParameter(valid_605051, JBool, required = false, default = nil)
  if valid_605051 != nil:
    section.add "PubliclyAccessible", valid_605051
  var valid_605052 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605052 = validateParameter(valid_605052, JBool, required = false, default = nil)
  if valid_605052 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605052
  var valid_605053 = query.getOrDefault("Port")
  valid_605053 = validateParameter(valid_605053, JInt, required = false, default = nil)
  if valid_605053 != nil:
    section.add "Port", valid_605053
  var valid_605054 = query.getOrDefault("Version")
  valid_605054 = validateParameter(valid_605054, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605054 != nil:
    section.add "Version", valid_605054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605055 = header.getOrDefault("X-Amz-Date")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "X-Amz-Date", valid_605055
  var valid_605056 = header.getOrDefault("X-Amz-Security-Token")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "X-Amz-Security-Token", valid_605056
  var valid_605057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605057 = validateParameter(valid_605057, JString, required = false,
                                 default = nil)
  if valid_605057 != nil:
    section.add "X-Amz-Content-Sha256", valid_605057
  var valid_605058 = header.getOrDefault("X-Amz-Algorithm")
  valid_605058 = validateParameter(valid_605058, JString, required = false,
                                 default = nil)
  if valid_605058 != nil:
    section.add "X-Amz-Algorithm", valid_605058
  var valid_605059 = header.getOrDefault("X-Amz-Signature")
  valid_605059 = validateParameter(valid_605059, JString, required = false,
                                 default = nil)
  if valid_605059 != nil:
    section.add "X-Amz-Signature", valid_605059
  var valid_605060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605060 = validateParameter(valid_605060, JString, required = false,
                                 default = nil)
  if valid_605060 != nil:
    section.add "X-Amz-SignedHeaders", valid_605060
  var valid_605061 = header.getOrDefault("X-Amz-Credential")
  valid_605061 = validateParameter(valid_605061, JString, required = false,
                                 default = nil)
  if valid_605061 != nil:
    section.add "X-Amz-Credential", valid_605061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605062: Call_GetRestoreDBInstanceToPointInTime_605034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605062.validator(path, query, header, formData, body)
  let scheme = call_605062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605062.url(scheme.get, call_605062.host, call_605062.base,
                         call_605062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605062, url, valid)

proc call*(call_605063: Call_GetRestoreDBInstanceToPointInTime_605034;
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
  var query_605064 = newJObject()
  add(query_605064, "Engine", newJString(Engine))
  add(query_605064, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605064, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605064, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605064, "Iops", newJInt(Iops))
  add(query_605064, "OptionGroupName", newJString(OptionGroupName))
  add(query_605064, "RestoreTime", newJString(RestoreTime))
  add(query_605064, "MultiAZ", newJBool(MultiAZ))
  add(query_605064, "LicenseModel", newJString(LicenseModel))
  add(query_605064, "DBName", newJString(DBName))
  add(query_605064, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605064, "Action", newJString(Action))
  add(query_605064, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605064, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605064, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605064, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605064, "Port", newJInt(Port))
  add(query_605064, "Version", newJString(Version))
  result = call_605063.call(nil, query_605064, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605034(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605035, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605117 = ref object of OpenApiRestCall_602450
proc url_PostRevokeDBSecurityGroupIngress_605119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_605118(path: JsonNode;
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
  var valid_605120 = query.getOrDefault("Action")
  valid_605120 = validateParameter(valid_605120, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605120 != nil:
    section.add "Action", valid_605120
  var valid_605121 = query.getOrDefault("Version")
  valid_605121 = validateParameter(valid_605121, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605121 != nil:
    section.add "Version", valid_605121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605122 = header.getOrDefault("X-Amz-Date")
  valid_605122 = validateParameter(valid_605122, JString, required = false,
                                 default = nil)
  if valid_605122 != nil:
    section.add "X-Amz-Date", valid_605122
  var valid_605123 = header.getOrDefault("X-Amz-Security-Token")
  valid_605123 = validateParameter(valid_605123, JString, required = false,
                                 default = nil)
  if valid_605123 != nil:
    section.add "X-Amz-Security-Token", valid_605123
  var valid_605124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605124 = validateParameter(valid_605124, JString, required = false,
                                 default = nil)
  if valid_605124 != nil:
    section.add "X-Amz-Content-Sha256", valid_605124
  var valid_605125 = header.getOrDefault("X-Amz-Algorithm")
  valid_605125 = validateParameter(valid_605125, JString, required = false,
                                 default = nil)
  if valid_605125 != nil:
    section.add "X-Amz-Algorithm", valid_605125
  var valid_605126 = header.getOrDefault("X-Amz-Signature")
  valid_605126 = validateParameter(valid_605126, JString, required = false,
                                 default = nil)
  if valid_605126 != nil:
    section.add "X-Amz-Signature", valid_605126
  var valid_605127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605127 = validateParameter(valid_605127, JString, required = false,
                                 default = nil)
  if valid_605127 != nil:
    section.add "X-Amz-SignedHeaders", valid_605127
  var valid_605128 = header.getOrDefault("X-Amz-Credential")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "X-Amz-Credential", valid_605128
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605129 = formData.getOrDefault("DBSecurityGroupName")
  valid_605129 = validateParameter(valid_605129, JString, required = true,
                                 default = nil)
  if valid_605129 != nil:
    section.add "DBSecurityGroupName", valid_605129
  var valid_605130 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "EC2SecurityGroupName", valid_605130
  var valid_605131 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "EC2SecurityGroupId", valid_605131
  var valid_605132 = formData.getOrDefault("CIDRIP")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "CIDRIP", valid_605132
  var valid_605133 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605134: Call_PostRevokeDBSecurityGroupIngress_605117;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605134.validator(path, query, header, formData, body)
  let scheme = call_605134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605134.url(scheme.get, call_605134.host, call_605134.base,
                         call_605134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605134, url, valid)

proc call*(call_605135: Call_PostRevokeDBSecurityGroupIngress_605117;
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
  var query_605136 = newJObject()
  var formData_605137 = newJObject()
  add(formData_605137, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605136, "Action", newJString(Action))
  add(formData_605137, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605137, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605137, "CIDRIP", newJString(CIDRIP))
  add(query_605136, "Version", newJString(Version))
  add(formData_605137, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605135.call(nil, query_605136, nil, formData_605137, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605117(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605118, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605097 = ref object of OpenApiRestCall_602450
proc url_GetRevokeDBSecurityGroupIngress_605099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_605098(path: JsonNode;
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
  var valid_605100 = query.getOrDefault("EC2SecurityGroupId")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "EC2SecurityGroupId", valid_605100
  var valid_605101 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605101
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605102 = query.getOrDefault("DBSecurityGroupName")
  valid_605102 = validateParameter(valid_605102, JString, required = true,
                                 default = nil)
  if valid_605102 != nil:
    section.add "DBSecurityGroupName", valid_605102
  var valid_605103 = query.getOrDefault("Action")
  valid_605103 = validateParameter(valid_605103, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605103 != nil:
    section.add "Action", valid_605103
  var valid_605104 = query.getOrDefault("CIDRIP")
  valid_605104 = validateParameter(valid_605104, JString, required = false,
                                 default = nil)
  if valid_605104 != nil:
    section.add "CIDRIP", valid_605104
  var valid_605105 = query.getOrDefault("EC2SecurityGroupName")
  valid_605105 = validateParameter(valid_605105, JString, required = false,
                                 default = nil)
  if valid_605105 != nil:
    section.add "EC2SecurityGroupName", valid_605105
  var valid_605106 = query.getOrDefault("Version")
  valid_605106 = validateParameter(valid_605106, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605106 != nil:
    section.add "Version", valid_605106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605107 = header.getOrDefault("X-Amz-Date")
  valid_605107 = validateParameter(valid_605107, JString, required = false,
                                 default = nil)
  if valid_605107 != nil:
    section.add "X-Amz-Date", valid_605107
  var valid_605108 = header.getOrDefault("X-Amz-Security-Token")
  valid_605108 = validateParameter(valid_605108, JString, required = false,
                                 default = nil)
  if valid_605108 != nil:
    section.add "X-Amz-Security-Token", valid_605108
  var valid_605109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605109 = validateParameter(valid_605109, JString, required = false,
                                 default = nil)
  if valid_605109 != nil:
    section.add "X-Amz-Content-Sha256", valid_605109
  var valid_605110 = header.getOrDefault("X-Amz-Algorithm")
  valid_605110 = validateParameter(valid_605110, JString, required = false,
                                 default = nil)
  if valid_605110 != nil:
    section.add "X-Amz-Algorithm", valid_605110
  var valid_605111 = header.getOrDefault("X-Amz-Signature")
  valid_605111 = validateParameter(valid_605111, JString, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "X-Amz-Signature", valid_605111
  var valid_605112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605112 = validateParameter(valid_605112, JString, required = false,
                                 default = nil)
  if valid_605112 != nil:
    section.add "X-Amz-SignedHeaders", valid_605112
  var valid_605113 = header.getOrDefault("X-Amz-Credential")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "X-Amz-Credential", valid_605113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605114: Call_GetRevokeDBSecurityGroupIngress_605097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605114.validator(path, query, header, formData, body)
  let scheme = call_605114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605114.url(scheme.get, call_605114.host, call_605114.base,
                         call_605114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605114, url, valid)

proc call*(call_605115: Call_GetRevokeDBSecurityGroupIngress_605097;
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
  var query_605116 = newJObject()
  add(query_605116, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605116, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605116, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605116, "Action", newJString(Action))
  add(query_605116, "CIDRIP", newJString(CIDRIP))
  add(query_605116, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605116, "Version", newJString(Version))
  result = call_605115.call(nil, query_605116, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605097(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605098, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605099,
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


import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
                                 default = newJString("2014-09-01"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
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
  Call_PostCopyDBParameterGroup_603172 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBParameterGroup_603174(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBParameterGroup_603173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603175 = query.getOrDefault("Action")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_603175 != nil:
    section.add "Action", valid_603175
  var valid_603176 = query.getOrDefault("Version")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603176 != nil:
    section.add "Version", valid_603176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Content-Sha256", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Algorithm")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Algorithm", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Signature")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Signature", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-SignedHeaders", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Credential")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Credential", valid_603183
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_603184 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_603184 = validateParameter(valid_603184, JString, required = true,
                                 default = nil)
  if valid_603184 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_603184
  var valid_603185 = formData.getOrDefault("Tags")
  valid_603185 = validateParameter(valid_603185, JArray, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "Tags", valid_603185
  var valid_603186 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "TargetDBParameterGroupDescription", valid_603186
  var valid_603187 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = nil)
  if valid_603187 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_603187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603188: Call_PostCopyDBParameterGroup_603172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603188.validator(path, query, header, formData, body)
  let scheme = call_603188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603188.url(scheme.get, call_603188.host, call_603188.base,
                         call_603188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603188, url, valid)

proc call*(call_603189: Call_PostCopyDBParameterGroup_603172;
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
  var query_603190 = newJObject()
  var formData_603191 = newJObject()
  add(formData_603191, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_603191.add "Tags", Tags
  add(query_603190, "Action", newJString(Action))
  add(formData_603191, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_603191, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_603190, "Version", newJString(Version))
  result = call_603189.call(nil, query_603190, nil, formData_603191, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_603172(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_603173, base: "/",
    url: url_PostCopyDBParameterGroup_603174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_603153 = ref object of OpenApiRestCall_602450
proc url_GetCopyDBParameterGroup_603155(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBParameterGroup_603154(path: JsonNode; query: JsonNode;
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
  var valid_603156 = query.getOrDefault("Tags")
  valid_603156 = validateParameter(valid_603156, JArray, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "Tags", valid_603156
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603157 = query.getOrDefault("Action")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_603157 != nil:
    section.add "Action", valid_603157
  var valid_603158 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_603158
  var valid_603159 = query.getOrDefault("Version")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603159 != nil:
    section.add "Version", valid_603159
  var valid_603160 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = nil)
  if valid_603160 != nil:
    section.add "TargetDBParameterGroupDescription", valid_603160
  var valid_603161 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_603161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Content-Sha256", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Algorithm")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Algorithm", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Signature")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Signature", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-SignedHeaders", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Credential")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Credential", valid_603168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603169: Call_GetCopyDBParameterGroup_603153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603169.validator(path, query, header, formData, body)
  let scheme = call_603169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603169.url(scheme.get, call_603169.host, call_603169.base,
                         call_603169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603169, url, valid)

proc call*(call_603170: Call_GetCopyDBParameterGroup_603153;
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
  var query_603171 = newJObject()
  if Tags != nil:
    query_603171.add "Tags", Tags
  add(query_603171, "Action", newJString(Action))
  add(query_603171, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_603171, "Version", newJString(Version))
  add(query_603171, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_603171, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_603170.call(nil, query_603171, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_603153(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_603154, base: "/",
    url: url_GetCopyDBParameterGroup_603155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_603210 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBSnapshot_603212(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_603211(path: JsonNode; query: JsonNode;
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
  var valid_603213 = query.getOrDefault("Action")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603213 != nil:
    section.add "Action", valid_603213
  var valid_603214 = query.getOrDefault("Version")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603214 != nil:
    section.add "Version", valid_603214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Security-Token")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Security-Token", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Signature", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-SignedHeaders", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Credential")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Credential", valid_603221
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603222 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603222
  var valid_603223 = formData.getOrDefault("Tags")
  valid_603223 = validateParameter(valid_603223, JArray, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Tags", valid_603223
  var valid_603224 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = nil)
  if valid_603224 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603225: Call_PostCopyDBSnapshot_603210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603225.validator(path, query, header, formData, body)
  let scheme = call_603225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603225.url(scheme.get, call_603225.host, call_603225.base,
                         call_603225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603225, url, valid)

proc call*(call_603226: Call_PostCopyDBSnapshot_603210;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603227 = newJObject()
  var formData_603228 = newJObject()
  add(formData_603228, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_603228.add "Tags", Tags
  add(query_603227, "Action", newJString(Action))
  add(formData_603228, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603227, "Version", newJString(Version))
  result = call_603226.call(nil, query_603227, nil, formData_603228, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603210(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603211, base: "/",
    url: url_PostCopyDBSnapshot_603212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_603192 = ref object of OpenApiRestCall_602450
proc url_GetCopyDBSnapshot_603194(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = query.getOrDefault("Tags")
  valid_603195 = validateParameter(valid_603195, JArray, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "Tags", valid_603195
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603196 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = nil)
  if valid_603196 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603196
  var valid_603197 = query.getOrDefault("Action")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603197 != nil:
    section.add "Action", valid_603197
  var valid_603198 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603198 = validateParameter(valid_603198, JString, required = true,
                                 default = nil)
  if valid_603198 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603198
  var valid_603199 = query.getOrDefault("Version")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603199 != nil:
    section.add "Version", valid_603199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Security-Token")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Security-Token", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603207: Call_GetCopyDBSnapshot_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603207.validator(path, query, header, formData, body)
  let scheme = call_603207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603207.url(scheme.get, call_603207.host, call_603207.base,
                         call_603207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603207, url, valid)

proc call*(call_603208: Call_GetCopyDBSnapshot_603192;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603209 = newJObject()
  if Tags != nil:
    query_603209.add "Tags", Tags
  add(query_603209, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603209, "Action", newJString(Action))
  add(query_603209, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603209, "Version", newJString(Version))
  result = call_603208.call(nil, query_603209, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603192(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603193,
    base: "/", url: url_GetCopyDBSnapshot_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_603248 = ref object of OpenApiRestCall_602450
proc url_PostCopyOptionGroup_603250(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyOptionGroup_603249(path: JsonNode; query: JsonNode;
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
  var valid_603251 = query.getOrDefault("Action")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
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
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_603260 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "TargetOptionGroupDescription", valid_603260
  var valid_603261 = formData.getOrDefault("Tags")
  valid_603261 = validateParameter(valid_603261, JArray, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "Tags", valid_603261
  var valid_603262 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = nil)
  if valid_603262 != nil:
    section.add "SourceOptionGroupIdentifier", valid_603262
  var valid_603263 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = nil)
  if valid_603263 != nil:
    section.add "TargetOptionGroupIdentifier", valid_603263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_PostCopyOptionGroup_603248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_PostCopyOptionGroup_603248;
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
  var query_603266 = newJObject()
  var formData_603267 = newJObject()
  add(formData_603267, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_603267.add "Tags", Tags
  add(formData_603267, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_603266, "Action", newJString(Action))
  add(formData_603267, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_603266, "Version", newJString(Version))
  result = call_603265.call(nil, query_603266, nil, formData_603267, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_603248(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_603249, base: "/",
    url: url_PostCopyOptionGroup_603250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_603229 = ref object of OpenApiRestCall_602450
proc url_GetCopyOptionGroup_603231(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyOptionGroup_603230(path: JsonNode; query: JsonNode;
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
  var valid_603232 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_603232 = validateParameter(valid_603232, JString, required = true,
                                 default = nil)
  if valid_603232 != nil:
    section.add "SourceOptionGroupIdentifier", valid_603232
  var valid_603233 = query.getOrDefault("Tags")
  valid_603233 = validateParameter(valid_603233, JArray, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "Tags", valid_603233
  var valid_603234 = query.getOrDefault("Action")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_603234 != nil:
    section.add "Action", valid_603234
  var valid_603235 = query.getOrDefault("TargetOptionGroupDescription")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = nil)
  if valid_603235 != nil:
    section.add "TargetOptionGroupDescription", valid_603235
  var valid_603236 = query.getOrDefault("Version")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603236 != nil:
    section.add "Version", valid_603236
  var valid_603237 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "TargetOptionGroupIdentifier", valid_603237
  result.add "query", section
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

proc call*(call_603245: Call_GetCopyOptionGroup_603229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_GetCopyOptionGroup_603229;
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
  var query_603247 = newJObject()
  add(query_603247, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_603247.add "Tags", Tags
  add(query_603247, "Action", newJString(Action))
  add(query_603247, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_603247, "Version", newJString(Version))
  add(query_603247, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_603246.call(nil, query_603247, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_603229(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_603230,
    base: "/", url: url_GetCopyOptionGroup_603231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603311 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstance_603313(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_603312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603314 = query.getOrDefault("Action")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603314 != nil:
    section.add "Action", valid_603314
  var valid_603315 = query.getOrDefault("Version")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603315 != nil:
    section.add "Version", valid_603315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
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
  var valid_603323 = formData.getOrDefault("DBSecurityGroups")
  valid_603323 = validateParameter(valid_603323, JArray, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "DBSecurityGroups", valid_603323
  var valid_603324 = formData.getOrDefault("Port")
  valid_603324 = validateParameter(valid_603324, JInt, required = false, default = nil)
  if valid_603324 != nil:
    section.add "Port", valid_603324
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603325 = formData.getOrDefault("Engine")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "Engine", valid_603325
  var valid_603326 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603326 = validateParameter(valid_603326, JArray, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "VpcSecurityGroupIds", valid_603326
  var valid_603327 = formData.getOrDefault("Iops")
  valid_603327 = validateParameter(valid_603327, JInt, required = false, default = nil)
  if valid_603327 != nil:
    section.add "Iops", valid_603327
  var valid_603328 = formData.getOrDefault("DBName")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "DBName", valid_603328
  var valid_603329 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = nil)
  if valid_603329 != nil:
    section.add "DBInstanceIdentifier", valid_603329
  var valid_603330 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603330 = validateParameter(valid_603330, JInt, required = false, default = nil)
  if valid_603330 != nil:
    section.add "BackupRetentionPeriod", valid_603330
  var valid_603331 = formData.getOrDefault("DBParameterGroupName")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "DBParameterGroupName", valid_603331
  var valid_603332 = formData.getOrDefault("OptionGroupName")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "OptionGroupName", valid_603332
  var valid_603333 = formData.getOrDefault("Tags")
  valid_603333 = validateParameter(valid_603333, JArray, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "Tags", valid_603333
  var valid_603334 = formData.getOrDefault("MasterUserPassword")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = nil)
  if valid_603334 != nil:
    section.add "MasterUserPassword", valid_603334
  var valid_603335 = formData.getOrDefault("TdeCredentialArn")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "TdeCredentialArn", valid_603335
  var valid_603336 = formData.getOrDefault("DBSubnetGroupName")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "DBSubnetGroupName", valid_603336
  var valid_603337 = formData.getOrDefault("TdeCredentialPassword")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "TdeCredentialPassword", valid_603337
  var valid_603338 = formData.getOrDefault("AvailabilityZone")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "AvailabilityZone", valid_603338
  var valid_603339 = formData.getOrDefault("MultiAZ")
  valid_603339 = validateParameter(valid_603339, JBool, required = false, default = nil)
  if valid_603339 != nil:
    section.add "MultiAZ", valid_603339
  var valid_603340 = formData.getOrDefault("AllocatedStorage")
  valid_603340 = validateParameter(valid_603340, JInt, required = true, default = nil)
  if valid_603340 != nil:
    section.add "AllocatedStorage", valid_603340
  var valid_603341 = formData.getOrDefault("PubliclyAccessible")
  valid_603341 = validateParameter(valid_603341, JBool, required = false, default = nil)
  if valid_603341 != nil:
    section.add "PubliclyAccessible", valid_603341
  var valid_603342 = formData.getOrDefault("MasterUsername")
  valid_603342 = validateParameter(valid_603342, JString, required = true,
                                 default = nil)
  if valid_603342 != nil:
    section.add "MasterUsername", valid_603342
  var valid_603343 = formData.getOrDefault("StorageType")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "StorageType", valid_603343
  var valid_603344 = formData.getOrDefault("DBInstanceClass")
  valid_603344 = validateParameter(valid_603344, JString, required = true,
                                 default = nil)
  if valid_603344 != nil:
    section.add "DBInstanceClass", valid_603344
  var valid_603345 = formData.getOrDefault("CharacterSetName")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "CharacterSetName", valid_603345
  var valid_603346 = formData.getOrDefault("PreferredBackupWindow")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "PreferredBackupWindow", valid_603346
  var valid_603347 = formData.getOrDefault("LicenseModel")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "LicenseModel", valid_603347
  var valid_603348 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603348 = validateParameter(valid_603348, JBool, required = false, default = nil)
  if valid_603348 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603348
  var valid_603349 = formData.getOrDefault("EngineVersion")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "EngineVersion", valid_603349
  var valid_603350 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "PreferredMaintenanceWindow", valid_603350
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_PostCreateDBInstance_603311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_PostCreateDBInstance_603311; Engine: string;
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
  var query_603353 = newJObject()
  var formData_603354 = newJObject()
  if DBSecurityGroups != nil:
    formData_603354.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603354, "Port", newJInt(Port))
  add(formData_603354, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603354.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603354, "Iops", newJInt(Iops))
  add(formData_603354, "DBName", newJString(DBName))
  add(formData_603354, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603354, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603354, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603354, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603354.add "Tags", Tags
  add(formData_603354, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603354, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603354, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603354, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603354, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603354, "MultiAZ", newJBool(MultiAZ))
  add(query_603353, "Action", newJString(Action))
  add(formData_603354, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603354, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603354, "MasterUsername", newJString(MasterUsername))
  add(formData_603354, "StorageType", newJString(StorageType))
  add(formData_603354, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603354, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603354, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603354, "LicenseModel", newJString(LicenseModel))
  add(formData_603354, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603354, "EngineVersion", newJString(EngineVersion))
  add(query_603353, "Version", newJString(Version))
  add(formData_603354, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603352.call(nil, query_603353, nil, formData_603354, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603311(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603312, base: "/",
    url: url_PostCreateDBInstance_603313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603268 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstance_603270(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_603269(path: JsonNode; query: JsonNode;
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
  var valid_603271 = query.getOrDefault("Engine")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = nil)
  if valid_603271 != nil:
    section.add "Engine", valid_603271
  var valid_603272 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "PreferredMaintenanceWindow", valid_603272
  var valid_603273 = query.getOrDefault("AllocatedStorage")
  valid_603273 = validateParameter(valid_603273, JInt, required = true, default = nil)
  if valid_603273 != nil:
    section.add "AllocatedStorage", valid_603273
  var valid_603274 = query.getOrDefault("StorageType")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "StorageType", valid_603274
  var valid_603275 = query.getOrDefault("OptionGroupName")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "OptionGroupName", valid_603275
  var valid_603276 = query.getOrDefault("DBSecurityGroups")
  valid_603276 = validateParameter(valid_603276, JArray, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "DBSecurityGroups", valid_603276
  var valid_603277 = query.getOrDefault("MasterUserPassword")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = nil)
  if valid_603277 != nil:
    section.add "MasterUserPassword", valid_603277
  var valid_603278 = query.getOrDefault("AvailabilityZone")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "AvailabilityZone", valid_603278
  var valid_603279 = query.getOrDefault("Iops")
  valid_603279 = validateParameter(valid_603279, JInt, required = false, default = nil)
  if valid_603279 != nil:
    section.add "Iops", valid_603279
  var valid_603280 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603280 = validateParameter(valid_603280, JArray, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "VpcSecurityGroupIds", valid_603280
  var valid_603281 = query.getOrDefault("MultiAZ")
  valid_603281 = validateParameter(valid_603281, JBool, required = false, default = nil)
  if valid_603281 != nil:
    section.add "MultiAZ", valid_603281
  var valid_603282 = query.getOrDefault("TdeCredentialPassword")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "TdeCredentialPassword", valid_603282
  var valid_603283 = query.getOrDefault("LicenseModel")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "LicenseModel", valid_603283
  var valid_603284 = query.getOrDefault("BackupRetentionPeriod")
  valid_603284 = validateParameter(valid_603284, JInt, required = false, default = nil)
  if valid_603284 != nil:
    section.add "BackupRetentionPeriod", valid_603284
  var valid_603285 = query.getOrDefault("DBName")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "DBName", valid_603285
  var valid_603286 = query.getOrDefault("DBParameterGroupName")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "DBParameterGroupName", valid_603286
  var valid_603287 = query.getOrDefault("Tags")
  valid_603287 = validateParameter(valid_603287, JArray, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "Tags", valid_603287
  var valid_603288 = query.getOrDefault("DBInstanceClass")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = nil)
  if valid_603288 != nil:
    section.add "DBInstanceClass", valid_603288
  var valid_603289 = query.getOrDefault("Action")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603289 != nil:
    section.add "Action", valid_603289
  var valid_603290 = query.getOrDefault("DBSubnetGroupName")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "DBSubnetGroupName", valid_603290
  var valid_603291 = query.getOrDefault("CharacterSetName")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "CharacterSetName", valid_603291
  var valid_603292 = query.getOrDefault("TdeCredentialArn")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "TdeCredentialArn", valid_603292
  var valid_603293 = query.getOrDefault("PubliclyAccessible")
  valid_603293 = validateParameter(valid_603293, JBool, required = false, default = nil)
  if valid_603293 != nil:
    section.add "PubliclyAccessible", valid_603293
  var valid_603294 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603294 = validateParameter(valid_603294, JBool, required = false, default = nil)
  if valid_603294 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603294
  var valid_603295 = query.getOrDefault("EngineVersion")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "EngineVersion", valid_603295
  var valid_603296 = query.getOrDefault("Port")
  valid_603296 = validateParameter(valid_603296, JInt, required = false, default = nil)
  if valid_603296 != nil:
    section.add "Port", valid_603296
  var valid_603297 = query.getOrDefault("PreferredBackupWindow")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "PreferredBackupWindow", valid_603297
  var valid_603298 = query.getOrDefault("Version")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603298 != nil:
    section.add "Version", valid_603298
  var valid_603299 = query.getOrDefault("DBInstanceIdentifier")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = nil)
  if valid_603299 != nil:
    section.add "DBInstanceIdentifier", valid_603299
  var valid_603300 = query.getOrDefault("MasterUsername")
  valid_603300 = validateParameter(valid_603300, JString, required = true,
                                 default = nil)
  if valid_603300 != nil:
    section.add "MasterUsername", valid_603300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603301 = header.getOrDefault("X-Amz-Date")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Date", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Security-Token")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Security-Token", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603308: Call_GetCreateDBInstance_603268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603308.validator(path, query, header, formData, body)
  let scheme = call_603308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603308.url(scheme.get, call_603308.host, call_603308.base,
                         call_603308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603308, url, valid)

proc call*(call_603309: Call_GetCreateDBInstance_603268; Engine: string;
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
  var query_603310 = newJObject()
  add(query_603310, "Engine", newJString(Engine))
  add(query_603310, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603310, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603310, "StorageType", newJString(StorageType))
  add(query_603310, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603310.add "DBSecurityGroups", DBSecurityGroups
  add(query_603310, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603310, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603310, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603310.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603310, "MultiAZ", newJBool(MultiAZ))
  add(query_603310, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603310, "LicenseModel", newJString(LicenseModel))
  add(query_603310, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603310, "DBName", newJString(DBName))
  add(query_603310, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_603310.add "Tags", Tags
  add(query_603310, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603310, "Action", newJString(Action))
  add(query_603310, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603310, "CharacterSetName", newJString(CharacterSetName))
  add(query_603310, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603310, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603310, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603310, "EngineVersion", newJString(EngineVersion))
  add(query_603310, "Port", newJInt(Port))
  add(query_603310, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603310, "Version", newJString(Version))
  add(query_603310, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603310, "MasterUsername", newJString(MasterUsername))
  result = call_603309.call(nil, query_603310, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603268(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603269, base: "/",
    url: url_GetCreateDBInstance_603270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603382 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstanceReadReplica_603384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_603383(path: JsonNode;
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
  var valid_603385 = query.getOrDefault("Action")
  valid_603385 = validateParameter(valid_603385, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603385 != nil:
    section.add "Action", valid_603385
  var valid_603386 = query.getOrDefault("Version")
  valid_603386 = validateParameter(valid_603386, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603386 != nil:
    section.add "Version", valid_603386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603387 = header.getOrDefault("X-Amz-Date")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Date", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Security-Token")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Security-Token", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Content-Sha256", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Algorithm")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Algorithm", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Signature")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Signature", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-SignedHeaders", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Credential")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Credential", valid_603393
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
  var valid_603394 = formData.getOrDefault("Port")
  valid_603394 = validateParameter(valid_603394, JInt, required = false, default = nil)
  if valid_603394 != nil:
    section.add "Port", valid_603394
  var valid_603395 = formData.getOrDefault("Iops")
  valid_603395 = validateParameter(valid_603395, JInt, required = false, default = nil)
  if valid_603395 != nil:
    section.add "Iops", valid_603395
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603396 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = nil)
  if valid_603396 != nil:
    section.add "DBInstanceIdentifier", valid_603396
  var valid_603397 = formData.getOrDefault("OptionGroupName")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "OptionGroupName", valid_603397
  var valid_603398 = formData.getOrDefault("Tags")
  valid_603398 = validateParameter(valid_603398, JArray, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "Tags", valid_603398
  var valid_603399 = formData.getOrDefault("DBSubnetGroupName")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "DBSubnetGroupName", valid_603399
  var valid_603400 = formData.getOrDefault("AvailabilityZone")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "AvailabilityZone", valid_603400
  var valid_603401 = formData.getOrDefault("PubliclyAccessible")
  valid_603401 = validateParameter(valid_603401, JBool, required = false, default = nil)
  if valid_603401 != nil:
    section.add "PubliclyAccessible", valid_603401
  var valid_603402 = formData.getOrDefault("StorageType")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "StorageType", valid_603402
  var valid_603403 = formData.getOrDefault("DBInstanceClass")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "DBInstanceClass", valid_603403
  var valid_603404 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603404
  var valid_603405 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603405 = validateParameter(valid_603405, JBool, required = false, default = nil)
  if valid_603405 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603406: Call_PostCreateDBInstanceReadReplica_603382;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603406.validator(path, query, header, formData, body)
  let scheme = call_603406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603406.url(scheme.get, call_603406.host, call_603406.base,
                         call_603406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603406, url, valid)

proc call*(call_603407: Call_PostCreateDBInstanceReadReplica_603382;
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
  var query_603408 = newJObject()
  var formData_603409 = newJObject()
  add(formData_603409, "Port", newJInt(Port))
  add(formData_603409, "Iops", newJInt(Iops))
  add(formData_603409, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603409, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603409.add "Tags", Tags
  add(formData_603409, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603409, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603408, "Action", newJString(Action))
  add(formData_603409, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603409, "StorageType", newJString(StorageType))
  add(formData_603409, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603409, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603409, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603408, "Version", newJString(Version))
  result = call_603407.call(nil, query_603408, nil, formData_603409, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603382(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603383, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603355 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstanceReadReplica_603357(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_603356(path: JsonNode;
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
  var valid_603358 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = nil)
  if valid_603358 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603358
  var valid_603359 = query.getOrDefault("StorageType")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "StorageType", valid_603359
  var valid_603360 = query.getOrDefault("OptionGroupName")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "OptionGroupName", valid_603360
  var valid_603361 = query.getOrDefault("AvailabilityZone")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "AvailabilityZone", valid_603361
  var valid_603362 = query.getOrDefault("Iops")
  valid_603362 = validateParameter(valid_603362, JInt, required = false, default = nil)
  if valid_603362 != nil:
    section.add "Iops", valid_603362
  var valid_603363 = query.getOrDefault("Tags")
  valid_603363 = validateParameter(valid_603363, JArray, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "Tags", valid_603363
  var valid_603364 = query.getOrDefault("DBInstanceClass")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "DBInstanceClass", valid_603364
  var valid_603365 = query.getOrDefault("Action")
  valid_603365 = validateParameter(valid_603365, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603365 != nil:
    section.add "Action", valid_603365
  var valid_603366 = query.getOrDefault("DBSubnetGroupName")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "DBSubnetGroupName", valid_603366
  var valid_603367 = query.getOrDefault("PubliclyAccessible")
  valid_603367 = validateParameter(valid_603367, JBool, required = false, default = nil)
  if valid_603367 != nil:
    section.add "PubliclyAccessible", valid_603367
  var valid_603368 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603368 = validateParameter(valid_603368, JBool, required = false, default = nil)
  if valid_603368 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603368
  var valid_603369 = query.getOrDefault("Port")
  valid_603369 = validateParameter(valid_603369, JInt, required = false, default = nil)
  if valid_603369 != nil:
    section.add "Port", valid_603369
  var valid_603370 = query.getOrDefault("Version")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603370 != nil:
    section.add "Version", valid_603370
  var valid_603371 = query.getOrDefault("DBInstanceIdentifier")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "DBInstanceIdentifier", valid_603371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Content-Sha256", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Algorithm")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Algorithm", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Signature")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Signature", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-SignedHeaders", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Credential")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Credential", valid_603378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603379: Call_GetCreateDBInstanceReadReplica_603355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603379.validator(path, query, header, formData, body)
  let scheme = call_603379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603379.url(scheme.get, call_603379.host, call_603379.base,
                         call_603379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603379, url, valid)

proc call*(call_603380: Call_GetCreateDBInstanceReadReplica_603355;
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
  var query_603381 = newJObject()
  add(query_603381, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603381, "StorageType", newJString(StorageType))
  add(query_603381, "OptionGroupName", newJString(OptionGroupName))
  add(query_603381, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603381, "Iops", newJInt(Iops))
  if Tags != nil:
    query_603381.add "Tags", Tags
  add(query_603381, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603381, "Action", newJString(Action))
  add(query_603381, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603381, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603381, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603381, "Port", newJInt(Port))
  add(query_603381, "Version", newJString(Version))
  add(query_603381, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603380.call(nil, query_603381, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603355(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603356, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603429 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBParameterGroup_603431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_603430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603432 = query.getOrDefault("Action")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603432 != nil:
    section.add "Action", valid_603432
  var valid_603433 = query.getOrDefault("Version")
  valid_603433 = validateParameter(valid_603433, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603433 != nil:
    section.add "Version", valid_603433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603434 = header.getOrDefault("X-Amz-Date")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Date", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Security-Token")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Security-Token", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603441 = formData.getOrDefault("DBParameterGroupName")
  valid_603441 = validateParameter(valid_603441, JString, required = true,
                                 default = nil)
  if valid_603441 != nil:
    section.add "DBParameterGroupName", valid_603441
  var valid_603442 = formData.getOrDefault("Tags")
  valid_603442 = validateParameter(valid_603442, JArray, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "Tags", valid_603442
  var valid_603443 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = nil)
  if valid_603443 != nil:
    section.add "DBParameterGroupFamily", valid_603443
  var valid_603444 = formData.getOrDefault("Description")
  valid_603444 = validateParameter(valid_603444, JString, required = true,
                                 default = nil)
  if valid_603444 != nil:
    section.add "Description", valid_603444
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_PostCreateDBParameterGroup_603429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_PostCreateDBParameterGroup_603429;
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
  var query_603447 = newJObject()
  var formData_603448 = newJObject()
  add(formData_603448, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_603448.add "Tags", Tags
  add(query_603447, "Action", newJString(Action))
  add(formData_603448, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603447, "Version", newJString(Version))
  add(formData_603448, "Description", newJString(Description))
  result = call_603446.call(nil, query_603447, nil, formData_603448, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603429(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603430, base: "/",
    url: url_PostCreateDBParameterGroup_603431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603410 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBParameterGroup_603412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_603411(path: JsonNode; query: JsonNode;
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
  var valid_603413 = query.getOrDefault("Description")
  valid_603413 = validateParameter(valid_603413, JString, required = true,
                                 default = nil)
  if valid_603413 != nil:
    section.add "Description", valid_603413
  var valid_603414 = query.getOrDefault("DBParameterGroupFamily")
  valid_603414 = validateParameter(valid_603414, JString, required = true,
                                 default = nil)
  if valid_603414 != nil:
    section.add "DBParameterGroupFamily", valid_603414
  var valid_603415 = query.getOrDefault("Tags")
  valid_603415 = validateParameter(valid_603415, JArray, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "Tags", valid_603415
  var valid_603416 = query.getOrDefault("DBParameterGroupName")
  valid_603416 = validateParameter(valid_603416, JString, required = true,
                                 default = nil)
  if valid_603416 != nil:
    section.add "DBParameterGroupName", valid_603416
  var valid_603417 = query.getOrDefault("Action")
  valid_603417 = validateParameter(valid_603417, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603417 != nil:
    section.add "Action", valid_603417
  var valid_603418 = query.getOrDefault("Version")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603418 != nil:
    section.add "Version", valid_603418
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603419 = header.getOrDefault("X-Amz-Date")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Date", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Security-Token")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Security-Token", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Content-Sha256", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Algorithm")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Algorithm", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Signature")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Signature", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-SignedHeaders", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Credential")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Credential", valid_603425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603426: Call_GetCreateDBParameterGroup_603410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603426.validator(path, query, header, formData, body)
  let scheme = call_603426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603426.url(scheme.get, call_603426.host, call_603426.base,
                         call_603426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603426, url, valid)

proc call*(call_603427: Call_GetCreateDBParameterGroup_603410; Description: string;
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
  var query_603428 = newJObject()
  add(query_603428, "Description", newJString(Description))
  add(query_603428, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603428.add "Tags", Tags
  add(query_603428, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603428, "Action", newJString(Action))
  add(query_603428, "Version", newJString(Version))
  result = call_603427.call(nil, query_603428, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603410(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603411, base: "/",
    url: url_GetCreateDBParameterGroup_603412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603467 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSecurityGroup_603469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_603468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603470 = query.getOrDefault("Action")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603470 != nil:
    section.add "Action", valid_603470
  var valid_603471 = query.getOrDefault("Version")
  valid_603471 = validateParameter(valid_603471, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603471 != nil:
    section.add "Version", valid_603471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Security-Token")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Security-Token", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Content-Sha256", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Algorithm")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Algorithm", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Signature")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Signature", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-SignedHeaders", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Credential")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Credential", valid_603478
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603479 = formData.getOrDefault("DBSecurityGroupName")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = nil)
  if valid_603479 != nil:
    section.add "DBSecurityGroupName", valid_603479
  var valid_603480 = formData.getOrDefault("Tags")
  valid_603480 = validateParameter(valid_603480, JArray, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "Tags", valid_603480
  var valid_603481 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603481 = validateParameter(valid_603481, JString, required = true,
                                 default = nil)
  if valid_603481 != nil:
    section.add "DBSecurityGroupDescription", valid_603481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603482: Call_PostCreateDBSecurityGroup_603467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603482.validator(path, query, header, formData, body)
  let scheme = call_603482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603482.url(scheme.get, call_603482.host, call_603482.base,
                         call_603482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603482, url, valid)

proc call*(call_603483: Call_PostCreateDBSecurityGroup_603467;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603484 = newJObject()
  var formData_603485 = newJObject()
  add(formData_603485, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_603485.add "Tags", Tags
  add(query_603484, "Action", newJString(Action))
  add(formData_603485, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603484, "Version", newJString(Version))
  result = call_603483.call(nil, query_603484, nil, formData_603485, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603467(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603468, base: "/",
    url: url_PostCreateDBSecurityGroup_603469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603449 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSecurityGroup_603451(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_603450(path: JsonNode; query: JsonNode;
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
  var valid_603452 = query.getOrDefault("DBSecurityGroupName")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = nil)
  if valid_603452 != nil:
    section.add "DBSecurityGroupName", valid_603452
  var valid_603453 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "DBSecurityGroupDescription", valid_603453
  var valid_603454 = query.getOrDefault("Tags")
  valid_603454 = validateParameter(valid_603454, JArray, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "Tags", valid_603454
  var valid_603455 = query.getOrDefault("Action")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603455 != nil:
    section.add "Action", valid_603455
  var valid_603456 = query.getOrDefault("Version")
  valid_603456 = validateParameter(valid_603456, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603456 != nil:
    section.add "Version", valid_603456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Security-Token")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Security-Token", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Signature")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Signature", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603464: Call_GetCreateDBSecurityGroup_603449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603464.validator(path, query, header, formData, body)
  let scheme = call_603464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603464.url(scheme.get, call_603464.host, call_603464.base,
                         call_603464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603464, url, valid)

proc call*(call_603465: Call_GetCreateDBSecurityGroup_603449;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603466 = newJObject()
  add(query_603466, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603466, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_603466.add "Tags", Tags
  add(query_603466, "Action", newJString(Action))
  add(query_603466, "Version", newJString(Version))
  result = call_603465.call(nil, query_603466, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603449(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603450, base: "/",
    url: url_GetCreateDBSecurityGroup_603451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603504 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSnapshot_603506(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_603505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603507 = query.getOrDefault("Action")
  valid_603507 = validateParameter(valid_603507, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603507 != nil:
    section.add "Action", valid_603507
  var valid_603508 = query.getOrDefault("Version")
  valid_603508 = validateParameter(valid_603508, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603508 != nil:
    section.add "Version", valid_603508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603509 = header.getOrDefault("X-Amz-Date")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Date", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Security-Token")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Security-Token", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Content-Sha256", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Algorithm")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Algorithm", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Signature")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Signature", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-SignedHeaders", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603516 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = nil)
  if valid_603516 != nil:
    section.add "DBInstanceIdentifier", valid_603516
  var valid_603517 = formData.getOrDefault("Tags")
  valid_603517 = validateParameter(valid_603517, JArray, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "Tags", valid_603517
  var valid_603518 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603518 = validateParameter(valid_603518, JString, required = true,
                                 default = nil)
  if valid_603518 != nil:
    section.add "DBSnapshotIdentifier", valid_603518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_PostCreateDBSnapshot_603504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_PostCreateDBSnapshot_603504;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603521 = newJObject()
  var formData_603522 = newJObject()
  add(formData_603522, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603522.add "Tags", Tags
  add(formData_603522, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603521, "Action", newJString(Action))
  add(query_603521, "Version", newJString(Version))
  result = call_603520.call(nil, query_603521, nil, formData_603522, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603504(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603505, base: "/",
    url: url_PostCreateDBSnapshot_603506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603486 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSnapshot_603488(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_603487(path: JsonNode; query: JsonNode;
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
  var valid_603489 = query.getOrDefault("Tags")
  valid_603489 = validateParameter(valid_603489, JArray, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "Tags", valid_603489
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603490 = query.getOrDefault("Action")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603490 != nil:
    section.add "Action", valid_603490
  var valid_603491 = query.getOrDefault("Version")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603491 != nil:
    section.add "Version", valid_603491
  var valid_603492 = query.getOrDefault("DBInstanceIdentifier")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "DBInstanceIdentifier", valid_603492
  var valid_603493 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = nil)
  if valid_603493 != nil:
    section.add "DBSnapshotIdentifier", valid_603493
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603501: Call_GetCreateDBSnapshot_603486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603501.validator(path, query, header, formData, body)
  let scheme = call_603501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603501.url(scheme.get, call_603501.host, call_603501.base,
                         call_603501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603501, url, valid)

proc call*(call_603502: Call_GetCreateDBSnapshot_603486;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603503 = newJObject()
  if Tags != nil:
    query_603503.add "Tags", Tags
  add(query_603503, "Action", newJString(Action))
  add(query_603503, "Version", newJString(Version))
  add(query_603503, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603503, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603502.call(nil, query_603503, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603486(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603487, base: "/",
    url: url_GetCreateDBSnapshot_603488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603542 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSubnetGroup_603544(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_603543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603545 = query.getOrDefault("Action")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603545 != nil:
    section.add "Action", valid_603545
  var valid_603546 = query.getOrDefault("Version")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603546 != nil:
    section.add "Version", valid_603546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Content-Sha256", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Algorithm")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Algorithm", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-SignedHeaders", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Credential")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Credential", valid_603553
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_603554 = formData.getOrDefault("Tags")
  valid_603554 = validateParameter(valid_603554, JArray, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "Tags", valid_603554
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603555 = formData.getOrDefault("DBSubnetGroupName")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = nil)
  if valid_603555 != nil:
    section.add "DBSubnetGroupName", valid_603555
  var valid_603556 = formData.getOrDefault("SubnetIds")
  valid_603556 = validateParameter(valid_603556, JArray, required = true, default = nil)
  if valid_603556 != nil:
    section.add "SubnetIds", valid_603556
  var valid_603557 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603557 = validateParameter(valid_603557, JString, required = true,
                                 default = nil)
  if valid_603557 != nil:
    section.add "DBSubnetGroupDescription", valid_603557
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603558: Call_PostCreateDBSubnetGroup_603542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603558.validator(path, query, header, formData, body)
  let scheme = call_603558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603558.url(scheme.get, call_603558.host, call_603558.base,
                         call_603558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603558, url, valid)

proc call*(call_603559: Call_PostCreateDBSubnetGroup_603542;
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
  var query_603560 = newJObject()
  var formData_603561 = newJObject()
  if Tags != nil:
    formData_603561.add "Tags", Tags
  add(formData_603561, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603561.add "SubnetIds", SubnetIds
  add(query_603560, "Action", newJString(Action))
  add(formData_603561, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603560, "Version", newJString(Version))
  result = call_603559.call(nil, query_603560, nil, formData_603561, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603542(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603543, base: "/",
    url: url_PostCreateDBSubnetGroup_603544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603523 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSubnetGroup_603525(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_603524(path: JsonNode; query: JsonNode;
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
  var valid_603526 = query.getOrDefault("Tags")
  valid_603526 = validateParameter(valid_603526, JArray, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "Tags", valid_603526
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603527 = query.getOrDefault("Action")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603527 != nil:
    section.add "Action", valid_603527
  var valid_603528 = query.getOrDefault("DBSubnetGroupName")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = nil)
  if valid_603528 != nil:
    section.add "DBSubnetGroupName", valid_603528
  var valid_603529 = query.getOrDefault("SubnetIds")
  valid_603529 = validateParameter(valid_603529, JArray, required = true, default = nil)
  if valid_603529 != nil:
    section.add "SubnetIds", valid_603529
  var valid_603530 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = nil)
  if valid_603530 != nil:
    section.add "DBSubnetGroupDescription", valid_603530
  var valid_603531 = query.getOrDefault("Version")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603539: Call_GetCreateDBSubnetGroup_603523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603539.validator(path, query, header, formData, body)
  let scheme = call_603539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603539.url(scheme.get, call_603539.host, call_603539.base,
                         call_603539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603539, url, valid)

proc call*(call_603540: Call_GetCreateDBSubnetGroup_603523;
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
  var query_603541 = newJObject()
  if Tags != nil:
    query_603541.add "Tags", Tags
  add(query_603541, "Action", newJString(Action))
  add(query_603541, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603541.add "SubnetIds", SubnetIds
  add(query_603541, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603541, "Version", newJString(Version))
  result = call_603540.call(nil, query_603541, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603523(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603524, base: "/",
    url: url_GetCreateDBSubnetGroup_603525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603584 = ref object of OpenApiRestCall_602450
proc url_PostCreateEventSubscription_603586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_603585(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603587 = query.getOrDefault("Action")
  valid_603587 = validateParameter(valid_603587, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603587 != nil:
    section.add "Action", valid_603587
  var valid_603588 = query.getOrDefault("Version")
  valid_603588 = validateParameter(valid_603588, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603588 != nil:
    section.add "Version", valid_603588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603589 = header.getOrDefault("X-Amz-Date")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Date", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Content-Sha256", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Algorithm")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Algorithm", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Signature")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Signature", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-SignedHeaders", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Credential")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Credential", valid_603595
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
  var valid_603596 = formData.getOrDefault("Enabled")
  valid_603596 = validateParameter(valid_603596, JBool, required = false, default = nil)
  if valid_603596 != nil:
    section.add "Enabled", valid_603596
  var valid_603597 = formData.getOrDefault("EventCategories")
  valid_603597 = validateParameter(valid_603597, JArray, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "EventCategories", valid_603597
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603598 = formData.getOrDefault("SnsTopicArn")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = nil)
  if valid_603598 != nil:
    section.add "SnsTopicArn", valid_603598
  var valid_603599 = formData.getOrDefault("SourceIds")
  valid_603599 = validateParameter(valid_603599, JArray, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "SourceIds", valid_603599
  var valid_603600 = formData.getOrDefault("Tags")
  valid_603600 = validateParameter(valid_603600, JArray, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "Tags", valid_603600
  var valid_603601 = formData.getOrDefault("SubscriptionName")
  valid_603601 = validateParameter(valid_603601, JString, required = true,
                                 default = nil)
  if valid_603601 != nil:
    section.add "SubscriptionName", valid_603601
  var valid_603602 = formData.getOrDefault("SourceType")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "SourceType", valid_603602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603603: Call_PostCreateEventSubscription_603584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603603.validator(path, query, header, formData, body)
  let scheme = call_603603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603603.url(scheme.get, call_603603.host, call_603603.base,
                         call_603603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603603, url, valid)

proc call*(call_603604: Call_PostCreateEventSubscription_603584;
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
  var query_603605 = newJObject()
  var formData_603606 = newJObject()
  add(formData_603606, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603606.add "EventCategories", EventCategories
  add(formData_603606, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603606.add "SourceIds", SourceIds
  if Tags != nil:
    formData_603606.add "Tags", Tags
  add(formData_603606, "SubscriptionName", newJString(SubscriptionName))
  add(query_603605, "Action", newJString(Action))
  add(query_603605, "Version", newJString(Version))
  add(formData_603606, "SourceType", newJString(SourceType))
  result = call_603604.call(nil, query_603605, nil, formData_603606, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603584(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603585, base: "/",
    url: url_PostCreateEventSubscription_603586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603562 = ref object of OpenApiRestCall_602450
proc url_GetCreateEventSubscription_603564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_603563(path: JsonNode; query: JsonNode;
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
  var valid_603565 = query.getOrDefault("SourceType")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "SourceType", valid_603565
  var valid_603566 = query.getOrDefault("SourceIds")
  valid_603566 = validateParameter(valid_603566, JArray, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "SourceIds", valid_603566
  var valid_603567 = query.getOrDefault("Enabled")
  valid_603567 = validateParameter(valid_603567, JBool, required = false, default = nil)
  if valid_603567 != nil:
    section.add "Enabled", valid_603567
  var valid_603568 = query.getOrDefault("Tags")
  valid_603568 = validateParameter(valid_603568, JArray, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "Tags", valid_603568
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603569 = query.getOrDefault("Action")
  valid_603569 = validateParameter(valid_603569, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603569 != nil:
    section.add "Action", valid_603569
  var valid_603570 = query.getOrDefault("SnsTopicArn")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = nil)
  if valid_603570 != nil:
    section.add "SnsTopicArn", valid_603570
  var valid_603571 = query.getOrDefault("EventCategories")
  valid_603571 = validateParameter(valid_603571, JArray, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "EventCategories", valid_603571
  var valid_603572 = query.getOrDefault("SubscriptionName")
  valid_603572 = validateParameter(valid_603572, JString, required = true,
                                 default = nil)
  if valid_603572 != nil:
    section.add "SubscriptionName", valid_603572
  var valid_603573 = query.getOrDefault("Version")
  valid_603573 = validateParameter(valid_603573, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603573 != nil:
    section.add "Version", valid_603573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603574 = header.getOrDefault("X-Amz-Date")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Date", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Security-Token")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Security-Token", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Content-Sha256", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Algorithm")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Algorithm", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Signature")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Signature", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-SignedHeaders", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Credential")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Credential", valid_603580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603581: Call_GetCreateEventSubscription_603562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603581.validator(path, query, header, formData, body)
  let scheme = call_603581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603581.url(scheme.get, call_603581.host, call_603581.base,
                         call_603581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603581, url, valid)

proc call*(call_603582: Call_GetCreateEventSubscription_603562;
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
  var query_603583 = newJObject()
  add(query_603583, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603583.add "SourceIds", SourceIds
  add(query_603583, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_603583.add "Tags", Tags
  add(query_603583, "Action", newJString(Action))
  add(query_603583, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603583.add "EventCategories", EventCategories
  add(query_603583, "SubscriptionName", newJString(SubscriptionName))
  add(query_603583, "Version", newJString(Version))
  result = call_603582.call(nil, query_603583, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603562(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603563, base: "/",
    url: url_GetCreateEventSubscription_603564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603627 = ref object of OpenApiRestCall_602450
proc url_PostCreateOptionGroup_603629(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_603628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603630 = query.getOrDefault("Action")
  valid_603630 = validateParameter(valid_603630, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603630 != nil:
    section.add "Action", valid_603630
  var valid_603631 = query.getOrDefault("Version")
  valid_603631 = validateParameter(valid_603631, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603631 != nil:
    section.add "Version", valid_603631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603632 = header.getOrDefault("X-Amz-Date")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Date", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Security-Token")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Security-Token", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Content-Sha256", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Signature")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Signature", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-SignedHeaders", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Credential")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Credential", valid_603638
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603639 = formData.getOrDefault("MajorEngineVersion")
  valid_603639 = validateParameter(valid_603639, JString, required = true,
                                 default = nil)
  if valid_603639 != nil:
    section.add "MajorEngineVersion", valid_603639
  var valid_603640 = formData.getOrDefault("OptionGroupName")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = nil)
  if valid_603640 != nil:
    section.add "OptionGroupName", valid_603640
  var valid_603641 = formData.getOrDefault("Tags")
  valid_603641 = validateParameter(valid_603641, JArray, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "Tags", valid_603641
  var valid_603642 = formData.getOrDefault("EngineName")
  valid_603642 = validateParameter(valid_603642, JString, required = true,
                                 default = nil)
  if valid_603642 != nil:
    section.add "EngineName", valid_603642
  var valid_603643 = formData.getOrDefault("OptionGroupDescription")
  valid_603643 = validateParameter(valid_603643, JString, required = true,
                                 default = nil)
  if valid_603643 != nil:
    section.add "OptionGroupDescription", valid_603643
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603644: Call_PostCreateOptionGroup_603627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603644.validator(path, query, header, formData, body)
  let scheme = call_603644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603644.url(scheme.get, call_603644.host, call_603644.base,
                         call_603644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603644, url, valid)

proc call*(call_603645: Call_PostCreateOptionGroup_603627;
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
  var query_603646 = newJObject()
  var formData_603647 = newJObject()
  add(formData_603647, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603647, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603647.add "Tags", Tags
  add(query_603646, "Action", newJString(Action))
  add(formData_603647, "EngineName", newJString(EngineName))
  add(formData_603647, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603646, "Version", newJString(Version))
  result = call_603645.call(nil, query_603646, nil, formData_603647, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603627(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603628, base: "/",
    url: url_PostCreateOptionGroup_603629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603607 = ref object of OpenApiRestCall_602450
proc url_GetCreateOptionGroup_603609(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_603608(path: JsonNode; query: JsonNode;
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
  var valid_603610 = query.getOrDefault("OptionGroupName")
  valid_603610 = validateParameter(valid_603610, JString, required = true,
                                 default = nil)
  if valid_603610 != nil:
    section.add "OptionGroupName", valid_603610
  var valid_603611 = query.getOrDefault("Tags")
  valid_603611 = validateParameter(valid_603611, JArray, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "Tags", valid_603611
  var valid_603612 = query.getOrDefault("OptionGroupDescription")
  valid_603612 = validateParameter(valid_603612, JString, required = true,
                                 default = nil)
  if valid_603612 != nil:
    section.add "OptionGroupDescription", valid_603612
  var valid_603613 = query.getOrDefault("Action")
  valid_603613 = validateParameter(valid_603613, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603613 != nil:
    section.add "Action", valid_603613
  var valid_603614 = query.getOrDefault("Version")
  valid_603614 = validateParameter(valid_603614, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603614 != nil:
    section.add "Version", valid_603614
  var valid_603615 = query.getOrDefault("EngineName")
  valid_603615 = validateParameter(valid_603615, JString, required = true,
                                 default = nil)
  if valid_603615 != nil:
    section.add "EngineName", valid_603615
  var valid_603616 = query.getOrDefault("MajorEngineVersion")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = nil)
  if valid_603616 != nil:
    section.add "MajorEngineVersion", valid_603616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603617 = header.getOrDefault("X-Amz-Date")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Date", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Security-Token")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Security-Token", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Content-Sha256", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Algorithm")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Algorithm", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Signature")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Signature", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-SignedHeaders", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Credential")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Credential", valid_603623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_GetCreateOptionGroup_603607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_GetCreateOptionGroup_603607; OptionGroupName: string;
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
  var query_603626 = newJObject()
  add(query_603626, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_603626.add "Tags", Tags
  add(query_603626, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603626, "Action", newJString(Action))
  add(query_603626, "Version", newJString(Version))
  add(query_603626, "EngineName", newJString(EngineName))
  add(query_603626, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603625.call(nil, query_603626, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603607(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603608, base: "/",
    url: url_GetCreateOptionGroup_603609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603666 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBInstance_603668(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_603667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603669 = query.getOrDefault("Action")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603669 != nil:
    section.add "Action", valid_603669
  var valid_603670 = query.getOrDefault("Version")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603678 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603678 = validateParameter(valid_603678, JString, required = true,
                                 default = nil)
  if valid_603678 != nil:
    section.add "DBInstanceIdentifier", valid_603678
  var valid_603679 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603679
  var valid_603680 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603680 = validateParameter(valid_603680, JBool, required = false, default = nil)
  if valid_603680 != nil:
    section.add "SkipFinalSnapshot", valid_603680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603681: Call_PostDeleteDBInstance_603666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603681.validator(path, query, header, formData, body)
  let scheme = call_603681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603681.url(scheme.get, call_603681.host, call_603681.base,
                         call_603681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603681, url, valid)

proc call*(call_603682: Call_PostDeleteDBInstance_603666;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603683 = newJObject()
  var formData_603684 = newJObject()
  add(formData_603684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603684, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603683, "Action", newJString(Action))
  add(query_603683, "Version", newJString(Version))
  add(formData_603684, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603682.call(nil, query_603683, nil, formData_603684, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603666(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603667, base: "/",
    url: url_PostDeleteDBInstance_603668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603648 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBInstance_603650(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_603649(path: JsonNode; query: JsonNode;
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
  var valid_603651 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603651
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603652 = query.getOrDefault("Action")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603652 != nil:
    section.add "Action", valid_603652
  var valid_603653 = query.getOrDefault("SkipFinalSnapshot")
  valid_603653 = validateParameter(valid_603653, JBool, required = false, default = nil)
  if valid_603653 != nil:
    section.add "SkipFinalSnapshot", valid_603653
  var valid_603654 = query.getOrDefault("Version")
  valid_603654 = validateParameter(valid_603654, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603654 != nil:
    section.add "Version", valid_603654
  var valid_603655 = query.getOrDefault("DBInstanceIdentifier")
  valid_603655 = validateParameter(valid_603655, JString, required = true,
                                 default = nil)
  if valid_603655 != nil:
    section.add "DBInstanceIdentifier", valid_603655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603656 = header.getOrDefault("X-Amz-Date")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Date", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Content-Sha256", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Algorithm")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Algorithm", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Signature")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Signature", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-SignedHeaders", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Credential")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Credential", valid_603662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603663: Call_GetDeleteDBInstance_603648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603663.validator(path, query, header, formData, body)
  let scheme = call_603663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603663.url(scheme.get, call_603663.host, call_603663.base,
                         call_603663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603663, url, valid)

proc call*(call_603664: Call_GetDeleteDBInstance_603648;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603665 = newJObject()
  add(query_603665, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603665, "Action", newJString(Action))
  add(query_603665, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603665, "Version", newJString(Version))
  add(query_603665, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603664.call(nil, query_603665, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603648(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603649, base: "/",
    url: url_GetDeleteDBInstance_603650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603701 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBParameterGroup_603703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_603702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBParameterGroup"))
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
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603713 = formData.getOrDefault("DBParameterGroupName")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "DBParameterGroupName", valid_603713
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_PostDeleteDBParameterGroup_603701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_PostDeleteDBParameterGroup_603701;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603716 = newJObject()
  var formData_603717 = newJObject()
  add(formData_603717, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603716, "Action", newJString(Action))
  add(query_603716, "Version", newJString(Version))
  result = call_603715.call(nil, query_603716, nil, formData_603717, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603701(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603702, base: "/",
    url: url_PostDeleteDBParameterGroup_603703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603685 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBParameterGroup_603687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_603686(path: JsonNode; query: JsonNode;
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
  var valid_603688 = query.getOrDefault("DBParameterGroupName")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = nil)
  if valid_603688 != nil:
    section.add "DBParameterGroupName", valid_603688
  var valid_603689 = query.getOrDefault("Action")
  valid_603689 = validateParameter(valid_603689, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
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

proc call*(call_603698: Call_GetDeleteDBParameterGroup_603685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_GetDeleteDBParameterGroup_603685;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603700 = newJObject()
  add(query_603700, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603700, "Action", newJString(Action))
  add(query_603700, "Version", newJString(Version))
  result = call_603699.call(nil, query_603700, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603685(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603686, base: "/",
    url: url_GetDeleteDBParameterGroup_603687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603734 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSecurityGroup_603736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_603735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSecurityGroup"))
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
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603746 = formData.getOrDefault("DBSecurityGroupName")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "DBSecurityGroupName", valid_603746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603747: Call_PostDeleteDBSecurityGroup_603734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603747.validator(path, query, header, formData, body)
  let scheme = call_603747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603747.url(scheme.get, call_603747.host, call_603747.base,
                         call_603747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603747, url, valid)

proc call*(call_603748: Call_PostDeleteDBSecurityGroup_603734;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603749 = newJObject()
  var formData_603750 = newJObject()
  add(formData_603750, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603749, "Action", newJString(Action))
  add(query_603749, "Version", newJString(Version))
  result = call_603748.call(nil, query_603749, nil, formData_603750, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603734(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603735, base: "/",
    url: url_PostDeleteDBSecurityGroup_603736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603718 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSecurityGroup_603720(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_603719(path: JsonNode; query: JsonNode;
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
  var valid_603721 = query.getOrDefault("DBSecurityGroupName")
  valid_603721 = validateParameter(valid_603721, JString, required = true,
                                 default = nil)
  if valid_603721 != nil:
    section.add "DBSecurityGroupName", valid_603721
  var valid_603722 = query.getOrDefault("Action")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603722 != nil:
    section.add "Action", valid_603722
  var valid_603723 = query.getOrDefault("Version")
  valid_603723 = validateParameter(valid_603723, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603723 != nil:
    section.add "Version", valid_603723
  result.add "query", section
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

proc call*(call_603731: Call_GetDeleteDBSecurityGroup_603718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_GetDeleteDBSecurityGroup_603718;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603733 = newJObject()
  add(query_603733, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603733, "Action", newJString(Action))
  add(query_603733, "Version", newJString(Version))
  result = call_603732.call(nil, query_603733, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603718(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603719, base: "/",
    url: url_GetDeleteDBSecurityGroup_603720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603767 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSnapshot_603769(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_603768(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSnapshot"))
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
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603779 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603779 = validateParameter(valid_603779, JString, required = true,
                                 default = nil)
  if valid_603779 != nil:
    section.add "DBSnapshotIdentifier", valid_603779
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603780: Call_PostDeleteDBSnapshot_603767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603780.validator(path, query, header, formData, body)
  let scheme = call_603780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603780.url(scheme.get, call_603780.host, call_603780.base,
                         call_603780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603780, url, valid)

proc call*(call_603781: Call_PostDeleteDBSnapshot_603767;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603782 = newJObject()
  var formData_603783 = newJObject()
  add(formData_603783, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603782, "Action", newJString(Action))
  add(query_603782, "Version", newJString(Version))
  result = call_603781.call(nil, query_603782, nil, formData_603783, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603767(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603768, base: "/",
    url: url_PostDeleteDBSnapshot_603769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603751 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSnapshot_603753(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_603752(path: JsonNode; query: JsonNode;
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
  var valid_603754 = query.getOrDefault("Action")
  valid_603754 = validateParameter(valid_603754, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603754 != nil:
    section.add "Action", valid_603754
  var valid_603755 = query.getOrDefault("Version")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603755 != nil:
    section.add "Version", valid_603755
  var valid_603756 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = nil)
  if valid_603756 != nil:
    section.add "DBSnapshotIdentifier", valid_603756
  result.add "query", section
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

proc call*(call_603764: Call_GetDeleteDBSnapshot_603751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603764.validator(path, query, header, formData, body)
  let scheme = call_603764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603764.url(scheme.get, call_603764.host, call_603764.base,
                         call_603764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603764, url, valid)

proc call*(call_603765: Call_GetDeleteDBSnapshot_603751;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603766 = newJObject()
  add(query_603766, "Action", newJString(Action))
  add(query_603766, "Version", newJString(Version))
  add(query_603766, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603765.call(nil, query_603766, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603751(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603752, base: "/",
    url: url_GetDeleteDBSnapshot_603753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603800 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSubnetGroup_603802(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_603801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603803 = validateParameter(valid_603803, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
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
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603812 = formData.getOrDefault("DBSubnetGroupName")
  valid_603812 = validateParameter(valid_603812, JString, required = true,
                                 default = nil)
  if valid_603812 != nil:
    section.add "DBSubnetGroupName", valid_603812
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603813: Call_PostDeleteDBSubnetGroup_603800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603813.validator(path, query, header, formData, body)
  let scheme = call_603813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603813.url(scheme.get, call_603813.host, call_603813.base,
                         call_603813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603813, url, valid)

proc call*(call_603814: Call_PostDeleteDBSubnetGroup_603800;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603815 = newJObject()
  var formData_603816 = newJObject()
  add(formData_603816, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603815, "Action", newJString(Action))
  add(query_603815, "Version", newJString(Version))
  result = call_603814.call(nil, query_603815, nil, formData_603816, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603800(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603801, base: "/",
    url: url_PostDeleteDBSubnetGroup_603802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603784 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSubnetGroup_603786(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_603785(path: JsonNode; query: JsonNode;
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
  var valid_603787 = query.getOrDefault("Action")
  valid_603787 = validateParameter(valid_603787, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603787 != nil:
    section.add "Action", valid_603787
  var valid_603788 = query.getOrDefault("DBSubnetGroupName")
  valid_603788 = validateParameter(valid_603788, JString, required = true,
                                 default = nil)
  if valid_603788 != nil:
    section.add "DBSubnetGroupName", valid_603788
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

proc call*(call_603797: Call_GetDeleteDBSubnetGroup_603784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603797.validator(path, query, header, formData, body)
  let scheme = call_603797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603797.url(scheme.get, call_603797.host, call_603797.base,
                         call_603797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603797, url, valid)

proc call*(call_603798: Call_GetDeleteDBSubnetGroup_603784;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603799 = newJObject()
  add(query_603799, "Action", newJString(Action))
  add(query_603799, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603799, "Version", newJString(Version))
  result = call_603798.call(nil, query_603799, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603784(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603785, base: "/",
    url: url_GetDeleteDBSubnetGroup_603786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603833 = ref object of OpenApiRestCall_602450
proc url_PostDeleteEventSubscription_603835(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_603834(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603836 = validateParameter(valid_603836, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
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
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603845 = formData.getOrDefault("SubscriptionName")
  valid_603845 = validateParameter(valid_603845, JString, required = true,
                                 default = nil)
  if valid_603845 != nil:
    section.add "SubscriptionName", valid_603845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_PostDeleteEventSubscription_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603846, url, valid)

proc call*(call_603847: Call_PostDeleteEventSubscription_603833;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603848 = newJObject()
  var formData_603849 = newJObject()
  add(formData_603849, "SubscriptionName", newJString(SubscriptionName))
  add(query_603848, "Action", newJString(Action))
  add(query_603848, "Version", newJString(Version))
  result = call_603847.call(nil, query_603848, nil, formData_603849, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603833(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603834, base: "/",
    url: url_PostDeleteEventSubscription_603835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603817 = ref object of OpenApiRestCall_602450
proc url_GetDeleteEventSubscription_603819(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_603818(path: JsonNode; query: JsonNode;
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
  var valid_603820 = query.getOrDefault("Action")
  valid_603820 = validateParameter(valid_603820, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603820 != nil:
    section.add "Action", valid_603820
  var valid_603821 = query.getOrDefault("SubscriptionName")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = nil)
  if valid_603821 != nil:
    section.add "SubscriptionName", valid_603821
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

proc call*(call_603830: Call_GetDeleteEventSubscription_603817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_GetDeleteEventSubscription_603817;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603832 = newJObject()
  add(query_603832, "Action", newJString(Action))
  add(query_603832, "SubscriptionName", newJString(SubscriptionName))
  add(query_603832, "Version", newJString(Version))
  result = call_603831.call(nil, query_603832, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603817(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603818, base: "/",
    url: url_GetDeleteEventSubscription_603819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603866 = ref object of OpenApiRestCall_602450
proc url_PostDeleteOptionGroup_603868(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_603867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603869 = query.getOrDefault("Action")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603869 != nil:
    section.add "Action", valid_603869
  var valid_603870 = query.getOrDefault("Version")
  valid_603870 = validateParameter(valid_603870, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603870 != nil:
    section.add "Version", valid_603870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603871 = header.getOrDefault("X-Amz-Date")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Date", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Security-Token")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Security-Token", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Content-Sha256", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Algorithm")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Algorithm", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Signature")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Signature", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Credential")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Credential", valid_603877
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603878 = formData.getOrDefault("OptionGroupName")
  valid_603878 = validateParameter(valid_603878, JString, required = true,
                                 default = nil)
  if valid_603878 != nil:
    section.add "OptionGroupName", valid_603878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603879: Call_PostDeleteOptionGroup_603866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603879.validator(path, query, header, formData, body)
  let scheme = call_603879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603879.url(scheme.get, call_603879.host, call_603879.base,
                         call_603879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603879, url, valid)

proc call*(call_603880: Call_PostDeleteOptionGroup_603866; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603881 = newJObject()
  var formData_603882 = newJObject()
  add(formData_603882, "OptionGroupName", newJString(OptionGroupName))
  add(query_603881, "Action", newJString(Action))
  add(query_603881, "Version", newJString(Version))
  result = call_603880.call(nil, query_603881, nil, formData_603882, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603866(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603867, base: "/",
    url: url_PostDeleteOptionGroup_603868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603850 = ref object of OpenApiRestCall_602450
proc url_GetDeleteOptionGroup_603852(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_603851(path: JsonNode; query: JsonNode;
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
  var valid_603853 = query.getOrDefault("OptionGroupName")
  valid_603853 = validateParameter(valid_603853, JString, required = true,
                                 default = nil)
  if valid_603853 != nil:
    section.add "OptionGroupName", valid_603853
  var valid_603854 = query.getOrDefault("Action")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603854 != nil:
    section.add "Action", valid_603854
  var valid_603855 = query.getOrDefault("Version")
  valid_603855 = validateParameter(valid_603855, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603855 != nil:
    section.add "Version", valid_603855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603856 = header.getOrDefault("X-Amz-Date")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Date", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Security-Token")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Security-Token", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Content-Sha256", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Algorithm")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Algorithm", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Signature")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Signature", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Credential")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Credential", valid_603862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603863: Call_GetDeleteOptionGroup_603850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603863.validator(path, query, header, formData, body)
  let scheme = call_603863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603863.url(scheme.get, call_603863.host, call_603863.base,
                         call_603863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603863, url, valid)

proc call*(call_603864: Call_GetDeleteOptionGroup_603850; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603865 = newJObject()
  add(query_603865, "OptionGroupName", newJString(OptionGroupName))
  add(query_603865, "Action", newJString(Action))
  add(query_603865, "Version", newJString(Version))
  result = call_603864.call(nil, query_603865, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603850(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603851, base: "/",
    url: url_GetDeleteOptionGroup_603852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603906 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBEngineVersions_603908(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_603907(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603909 = query.getOrDefault("Action")
  valid_603909 = validateParameter(valid_603909, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603909 != nil:
    section.add "Action", valid_603909
  var valid_603910 = query.getOrDefault("Version")
  valid_603910 = validateParameter(valid_603910, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603910 != nil:
    section.add "Version", valid_603910
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603911 = header.getOrDefault("X-Amz-Date")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Date", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Security-Token")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Security-Token", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Content-Sha256", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Algorithm")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Algorithm", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Signature")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Signature", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-SignedHeaders", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Credential")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Credential", valid_603917
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
  var valid_603918 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603918 = validateParameter(valid_603918, JBool, required = false, default = nil)
  if valid_603918 != nil:
    section.add "ListSupportedCharacterSets", valid_603918
  var valid_603919 = formData.getOrDefault("Engine")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "Engine", valid_603919
  var valid_603920 = formData.getOrDefault("Marker")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "Marker", valid_603920
  var valid_603921 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "DBParameterGroupFamily", valid_603921
  var valid_603922 = formData.getOrDefault("Filters")
  valid_603922 = validateParameter(valid_603922, JArray, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "Filters", valid_603922
  var valid_603923 = formData.getOrDefault("MaxRecords")
  valid_603923 = validateParameter(valid_603923, JInt, required = false, default = nil)
  if valid_603923 != nil:
    section.add "MaxRecords", valid_603923
  var valid_603924 = formData.getOrDefault("EngineVersion")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "EngineVersion", valid_603924
  var valid_603925 = formData.getOrDefault("DefaultOnly")
  valid_603925 = validateParameter(valid_603925, JBool, required = false, default = nil)
  if valid_603925 != nil:
    section.add "DefaultOnly", valid_603925
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603926: Call_PostDescribeDBEngineVersions_603906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603926.validator(path, query, header, formData, body)
  let scheme = call_603926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603926.url(scheme.get, call_603926.host, call_603926.base,
                         call_603926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603926, url, valid)

proc call*(call_603927: Call_PostDescribeDBEngineVersions_603906;
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
  var query_603928 = newJObject()
  var formData_603929 = newJObject()
  add(formData_603929, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603929, "Engine", newJString(Engine))
  add(formData_603929, "Marker", newJString(Marker))
  add(query_603928, "Action", newJString(Action))
  add(formData_603929, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603929.add "Filters", Filters
  add(formData_603929, "MaxRecords", newJInt(MaxRecords))
  add(formData_603929, "EngineVersion", newJString(EngineVersion))
  add(query_603928, "Version", newJString(Version))
  add(formData_603929, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603927.call(nil, query_603928, nil, formData_603929, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603906(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603907, base: "/",
    url: url_PostDescribeDBEngineVersions_603908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603883 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBEngineVersions_603885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_603884(path: JsonNode; query: JsonNode;
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
  var valid_603886 = query.getOrDefault("Engine")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "Engine", valid_603886
  var valid_603887 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603887 = validateParameter(valid_603887, JBool, required = false, default = nil)
  if valid_603887 != nil:
    section.add "ListSupportedCharacterSets", valid_603887
  var valid_603888 = query.getOrDefault("MaxRecords")
  valid_603888 = validateParameter(valid_603888, JInt, required = false, default = nil)
  if valid_603888 != nil:
    section.add "MaxRecords", valid_603888
  var valid_603889 = query.getOrDefault("DBParameterGroupFamily")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "DBParameterGroupFamily", valid_603889
  var valid_603890 = query.getOrDefault("Filters")
  valid_603890 = validateParameter(valid_603890, JArray, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "Filters", valid_603890
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603891 = query.getOrDefault("Action")
  valid_603891 = validateParameter(valid_603891, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603891 != nil:
    section.add "Action", valid_603891
  var valid_603892 = query.getOrDefault("Marker")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "Marker", valid_603892
  var valid_603893 = query.getOrDefault("EngineVersion")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "EngineVersion", valid_603893
  var valid_603894 = query.getOrDefault("DefaultOnly")
  valid_603894 = validateParameter(valid_603894, JBool, required = false, default = nil)
  if valid_603894 != nil:
    section.add "DefaultOnly", valid_603894
  var valid_603895 = query.getOrDefault("Version")
  valid_603895 = validateParameter(valid_603895, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603895 != nil:
    section.add "Version", valid_603895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603896 = header.getOrDefault("X-Amz-Date")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Date", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Security-Token")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Security-Token", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Content-Sha256", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Algorithm")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Algorithm", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Signature")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Signature", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-SignedHeaders", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Credential")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Credential", valid_603902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603903: Call_GetDescribeDBEngineVersions_603883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603903.validator(path, query, header, formData, body)
  let scheme = call_603903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603903.url(scheme.get, call_603903.host, call_603903.base,
                         call_603903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603903, url, valid)

proc call*(call_603904: Call_GetDescribeDBEngineVersions_603883;
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
  var query_603905 = newJObject()
  add(query_603905, "Engine", newJString(Engine))
  add(query_603905, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603905, "MaxRecords", newJInt(MaxRecords))
  add(query_603905, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603905.add "Filters", Filters
  add(query_603905, "Action", newJString(Action))
  add(query_603905, "Marker", newJString(Marker))
  add(query_603905, "EngineVersion", newJString(EngineVersion))
  add(query_603905, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603905, "Version", newJString(Version))
  result = call_603904.call(nil, query_603905, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603883(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603884, base: "/",
    url: url_GetDescribeDBEngineVersions_603885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603949 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBInstances_603951(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_603950(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603952 = query.getOrDefault("Action")
  valid_603952 = validateParameter(valid_603952, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603952 != nil:
    section.add "Action", valid_603952
  var valid_603953 = query.getOrDefault("Version")
  valid_603953 = validateParameter(valid_603953, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603953 != nil:
    section.add "Version", valid_603953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603954 = header.getOrDefault("X-Amz-Date")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Date", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Security-Token")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Security-Token", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Content-Sha256", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Algorithm")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Algorithm", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Signature")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Signature", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-SignedHeaders", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Credential")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Credential", valid_603960
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603961 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "DBInstanceIdentifier", valid_603961
  var valid_603962 = formData.getOrDefault("Marker")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "Marker", valid_603962
  var valid_603963 = formData.getOrDefault("Filters")
  valid_603963 = validateParameter(valid_603963, JArray, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "Filters", valid_603963
  var valid_603964 = formData.getOrDefault("MaxRecords")
  valid_603964 = validateParameter(valid_603964, JInt, required = false, default = nil)
  if valid_603964 != nil:
    section.add "MaxRecords", valid_603964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603965: Call_PostDescribeDBInstances_603949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603965.validator(path, query, header, formData, body)
  let scheme = call_603965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603965.url(scheme.get, call_603965.host, call_603965.base,
                         call_603965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603965, url, valid)

proc call*(call_603966: Call_PostDescribeDBInstances_603949;
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
  var query_603967 = newJObject()
  var formData_603968 = newJObject()
  add(formData_603968, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603968, "Marker", newJString(Marker))
  add(query_603967, "Action", newJString(Action))
  if Filters != nil:
    formData_603968.add "Filters", Filters
  add(formData_603968, "MaxRecords", newJInt(MaxRecords))
  add(query_603967, "Version", newJString(Version))
  result = call_603966.call(nil, query_603967, nil, formData_603968, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603949(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603950, base: "/",
    url: url_PostDescribeDBInstances_603951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603930 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBInstances_603932(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_603931(path: JsonNode; query: JsonNode;
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
  var valid_603933 = query.getOrDefault("MaxRecords")
  valid_603933 = validateParameter(valid_603933, JInt, required = false, default = nil)
  if valid_603933 != nil:
    section.add "MaxRecords", valid_603933
  var valid_603934 = query.getOrDefault("Filters")
  valid_603934 = validateParameter(valid_603934, JArray, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "Filters", valid_603934
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603935 = query.getOrDefault("Action")
  valid_603935 = validateParameter(valid_603935, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603935 != nil:
    section.add "Action", valid_603935
  var valid_603936 = query.getOrDefault("Marker")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "Marker", valid_603936
  var valid_603937 = query.getOrDefault("Version")
  valid_603937 = validateParameter(valid_603937, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603937 != nil:
    section.add "Version", valid_603937
  var valid_603938 = query.getOrDefault("DBInstanceIdentifier")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "DBInstanceIdentifier", valid_603938
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603939 = header.getOrDefault("X-Amz-Date")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Date", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Security-Token")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Security-Token", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Content-Sha256", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Algorithm")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Algorithm", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Signature")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Signature", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-SignedHeaders", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Credential")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Credential", valid_603945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603946: Call_GetDescribeDBInstances_603930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603946.validator(path, query, header, formData, body)
  let scheme = call_603946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603946.url(scheme.get, call_603946.host, call_603946.base,
                         call_603946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603946, url, valid)

proc call*(call_603947: Call_GetDescribeDBInstances_603930; MaxRecords: int = 0;
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
  var query_603948 = newJObject()
  add(query_603948, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603948.add "Filters", Filters
  add(query_603948, "Action", newJString(Action))
  add(query_603948, "Marker", newJString(Marker))
  add(query_603948, "Version", newJString(Version))
  add(query_603948, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603947.call(nil, query_603948, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603930(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603931, base: "/",
    url: url_GetDescribeDBInstances_603932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_603991 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBLogFiles_603993(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_603992(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603994 = query.getOrDefault("Action")
  valid_603994 = validateParameter(valid_603994, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603994 != nil:
    section.add "Action", valid_603994
  var valid_603995 = query.getOrDefault("Version")
  valid_603995 = validateParameter(valid_603995, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603995 != nil:
    section.add "Version", valid_603995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603996 = header.getOrDefault("X-Amz-Date")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Date", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Security-Token")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Security-Token", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Content-Sha256", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Algorithm")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Algorithm", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Signature")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Signature", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-SignedHeaders", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Credential")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Credential", valid_604002
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
  var valid_604003 = formData.getOrDefault("FilenameContains")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "FilenameContains", valid_604003
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604004 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604004 = validateParameter(valid_604004, JString, required = true,
                                 default = nil)
  if valid_604004 != nil:
    section.add "DBInstanceIdentifier", valid_604004
  var valid_604005 = formData.getOrDefault("FileSize")
  valid_604005 = validateParameter(valid_604005, JInt, required = false, default = nil)
  if valid_604005 != nil:
    section.add "FileSize", valid_604005
  var valid_604006 = formData.getOrDefault("Marker")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "Marker", valid_604006
  var valid_604007 = formData.getOrDefault("Filters")
  valid_604007 = validateParameter(valid_604007, JArray, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "Filters", valid_604007
  var valid_604008 = formData.getOrDefault("MaxRecords")
  valid_604008 = validateParameter(valid_604008, JInt, required = false, default = nil)
  if valid_604008 != nil:
    section.add "MaxRecords", valid_604008
  var valid_604009 = formData.getOrDefault("FileLastWritten")
  valid_604009 = validateParameter(valid_604009, JInt, required = false, default = nil)
  if valid_604009 != nil:
    section.add "FileLastWritten", valid_604009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604010: Call_PostDescribeDBLogFiles_603991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604010.validator(path, query, header, formData, body)
  let scheme = call_604010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604010.url(scheme.get, call_604010.host, call_604010.base,
                         call_604010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604010, url, valid)

proc call*(call_604011: Call_PostDescribeDBLogFiles_603991;
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
  var query_604012 = newJObject()
  var formData_604013 = newJObject()
  add(formData_604013, "FilenameContains", newJString(FilenameContains))
  add(formData_604013, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604013, "FileSize", newJInt(FileSize))
  add(formData_604013, "Marker", newJString(Marker))
  add(query_604012, "Action", newJString(Action))
  if Filters != nil:
    formData_604013.add "Filters", Filters
  add(formData_604013, "MaxRecords", newJInt(MaxRecords))
  add(formData_604013, "FileLastWritten", newJInt(FileLastWritten))
  add(query_604012, "Version", newJString(Version))
  result = call_604011.call(nil, query_604012, nil, formData_604013, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603991(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603992, base: "/",
    url: url_PostDescribeDBLogFiles_603993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603969 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBLogFiles_603971(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_603970(path: JsonNode; query: JsonNode;
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
  var valid_603972 = query.getOrDefault("FileLastWritten")
  valid_603972 = validateParameter(valid_603972, JInt, required = false, default = nil)
  if valid_603972 != nil:
    section.add "FileLastWritten", valid_603972
  var valid_603973 = query.getOrDefault("MaxRecords")
  valid_603973 = validateParameter(valid_603973, JInt, required = false, default = nil)
  if valid_603973 != nil:
    section.add "MaxRecords", valid_603973
  var valid_603974 = query.getOrDefault("FilenameContains")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "FilenameContains", valid_603974
  var valid_603975 = query.getOrDefault("FileSize")
  valid_603975 = validateParameter(valid_603975, JInt, required = false, default = nil)
  if valid_603975 != nil:
    section.add "FileSize", valid_603975
  var valid_603976 = query.getOrDefault("Filters")
  valid_603976 = validateParameter(valid_603976, JArray, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "Filters", valid_603976
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603977 = query.getOrDefault("Action")
  valid_603977 = validateParameter(valid_603977, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603977 != nil:
    section.add "Action", valid_603977
  var valid_603978 = query.getOrDefault("Marker")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "Marker", valid_603978
  var valid_603979 = query.getOrDefault("Version")
  valid_603979 = validateParameter(valid_603979, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603979 != nil:
    section.add "Version", valid_603979
  var valid_603980 = query.getOrDefault("DBInstanceIdentifier")
  valid_603980 = validateParameter(valid_603980, JString, required = true,
                                 default = nil)
  if valid_603980 != nil:
    section.add "DBInstanceIdentifier", valid_603980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603981 = header.getOrDefault("X-Amz-Date")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Date", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-Security-Token")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Security-Token", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Content-Sha256", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Algorithm")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Algorithm", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Signature")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Signature", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-SignedHeaders", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Credential")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Credential", valid_603987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603988: Call_GetDescribeDBLogFiles_603969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603988.validator(path, query, header, formData, body)
  let scheme = call_603988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603988.url(scheme.get, call_603988.host, call_603988.base,
                         call_603988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603988, url, valid)

proc call*(call_603989: Call_GetDescribeDBLogFiles_603969;
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
  var query_603990 = newJObject()
  add(query_603990, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603990, "MaxRecords", newJInt(MaxRecords))
  add(query_603990, "FilenameContains", newJString(FilenameContains))
  add(query_603990, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_603990.add "Filters", Filters
  add(query_603990, "Action", newJString(Action))
  add(query_603990, "Marker", newJString(Marker))
  add(query_603990, "Version", newJString(Version))
  add(query_603990, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603989.call(nil, query_603990, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603969(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603970, base: "/",
    url: url_GetDescribeDBLogFiles_603971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_604033 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameterGroups_604035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_604034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604036 = query.getOrDefault("Action")
  valid_604036 = validateParameter(valid_604036, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_604036 != nil:
    section.add "Action", valid_604036
  var valid_604037 = query.getOrDefault("Version")
  valid_604037 = validateParameter(valid_604037, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604037 != nil:
    section.add "Version", valid_604037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604038 = header.getOrDefault("X-Amz-Date")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Date", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Security-Token")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Security-Token", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Content-Sha256", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Algorithm")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Algorithm", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Signature")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Signature", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-SignedHeaders", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Credential")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Credential", valid_604044
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604045 = formData.getOrDefault("DBParameterGroupName")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "DBParameterGroupName", valid_604045
  var valid_604046 = formData.getOrDefault("Marker")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "Marker", valid_604046
  var valid_604047 = formData.getOrDefault("Filters")
  valid_604047 = validateParameter(valid_604047, JArray, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "Filters", valid_604047
  var valid_604048 = formData.getOrDefault("MaxRecords")
  valid_604048 = validateParameter(valid_604048, JInt, required = false, default = nil)
  if valid_604048 != nil:
    section.add "MaxRecords", valid_604048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604049: Call_PostDescribeDBParameterGroups_604033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604049.validator(path, query, header, formData, body)
  let scheme = call_604049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604049.url(scheme.get, call_604049.host, call_604049.base,
                         call_604049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604049, url, valid)

proc call*(call_604050: Call_PostDescribeDBParameterGroups_604033;
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
  var query_604051 = newJObject()
  var formData_604052 = newJObject()
  add(formData_604052, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604052, "Marker", newJString(Marker))
  add(query_604051, "Action", newJString(Action))
  if Filters != nil:
    formData_604052.add "Filters", Filters
  add(formData_604052, "MaxRecords", newJInt(MaxRecords))
  add(query_604051, "Version", newJString(Version))
  result = call_604050.call(nil, query_604051, nil, formData_604052, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_604033(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_604034, base: "/",
    url: url_PostDescribeDBParameterGroups_604035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_604014 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameterGroups_604016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_604015(path: JsonNode; query: JsonNode;
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
  var valid_604017 = query.getOrDefault("MaxRecords")
  valid_604017 = validateParameter(valid_604017, JInt, required = false, default = nil)
  if valid_604017 != nil:
    section.add "MaxRecords", valid_604017
  var valid_604018 = query.getOrDefault("Filters")
  valid_604018 = validateParameter(valid_604018, JArray, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "Filters", valid_604018
  var valid_604019 = query.getOrDefault("DBParameterGroupName")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "DBParameterGroupName", valid_604019
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604020 = query.getOrDefault("Action")
  valid_604020 = validateParameter(valid_604020, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_604020 != nil:
    section.add "Action", valid_604020
  var valid_604021 = query.getOrDefault("Marker")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "Marker", valid_604021
  var valid_604022 = query.getOrDefault("Version")
  valid_604022 = validateParameter(valid_604022, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604022 != nil:
    section.add "Version", valid_604022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604023 = header.getOrDefault("X-Amz-Date")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Date", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Security-Token")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Security-Token", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Content-Sha256", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Algorithm")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Algorithm", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Signature")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Signature", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-SignedHeaders", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Credential")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Credential", valid_604029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604030: Call_GetDescribeDBParameterGroups_604014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604030.validator(path, query, header, formData, body)
  let scheme = call_604030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604030.url(scheme.get, call_604030.host, call_604030.base,
                         call_604030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604030, url, valid)

proc call*(call_604031: Call_GetDescribeDBParameterGroups_604014;
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
  var query_604032 = newJObject()
  add(query_604032, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604032.add "Filters", Filters
  add(query_604032, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604032, "Action", newJString(Action))
  add(query_604032, "Marker", newJString(Marker))
  add(query_604032, "Version", newJString(Version))
  result = call_604031.call(nil, query_604032, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_604014(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_604015, base: "/",
    url: url_GetDescribeDBParameterGroups_604016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_604073 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameters_604075(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_604074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604076 = query.getOrDefault("Action")
  valid_604076 = validateParameter(valid_604076, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_604076 != nil:
    section.add "Action", valid_604076
  var valid_604077 = query.getOrDefault("Version")
  valid_604077 = validateParameter(valid_604077, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604077 != nil:
    section.add "Version", valid_604077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604078 = header.getOrDefault("X-Amz-Date")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Date", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Security-Token")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Security-Token", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Content-Sha256", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Algorithm")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Algorithm", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Signature")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Signature", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-SignedHeaders", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Credential")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Credential", valid_604084
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604085 = formData.getOrDefault("DBParameterGroupName")
  valid_604085 = validateParameter(valid_604085, JString, required = true,
                                 default = nil)
  if valid_604085 != nil:
    section.add "DBParameterGroupName", valid_604085
  var valid_604086 = formData.getOrDefault("Marker")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "Marker", valid_604086
  var valid_604087 = formData.getOrDefault("Filters")
  valid_604087 = validateParameter(valid_604087, JArray, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "Filters", valid_604087
  var valid_604088 = formData.getOrDefault("MaxRecords")
  valid_604088 = validateParameter(valid_604088, JInt, required = false, default = nil)
  if valid_604088 != nil:
    section.add "MaxRecords", valid_604088
  var valid_604089 = formData.getOrDefault("Source")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "Source", valid_604089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604090: Call_PostDescribeDBParameters_604073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604090.validator(path, query, header, formData, body)
  let scheme = call_604090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604090.url(scheme.get, call_604090.host, call_604090.base,
                         call_604090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604090, url, valid)

proc call*(call_604091: Call_PostDescribeDBParameters_604073;
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
  var query_604092 = newJObject()
  var formData_604093 = newJObject()
  add(formData_604093, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604093, "Marker", newJString(Marker))
  add(query_604092, "Action", newJString(Action))
  if Filters != nil:
    formData_604093.add "Filters", Filters
  add(formData_604093, "MaxRecords", newJInt(MaxRecords))
  add(query_604092, "Version", newJString(Version))
  add(formData_604093, "Source", newJString(Source))
  result = call_604091.call(nil, query_604092, nil, formData_604093, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_604073(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_604074, base: "/",
    url: url_PostDescribeDBParameters_604075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_604053 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameters_604055(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_604054(path: JsonNode; query: JsonNode;
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
  var valid_604056 = query.getOrDefault("MaxRecords")
  valid_604056 = validateParameter(valid_604056, JInt, required = false, default = nil)
  if valid_604056 != nil:
    section.add "MaxRecords", valid_604056
  var valid_604057 = query.getOrDefault("Filters")
  valid_604057 = validateParameter(valid_604057, JArray, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "Filters", valid_604057
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_604058 = query.getOrDefault("DBParameterGroupName")
  valid_604058 = validateParameter(valid_604058, JString, required = true,
                                 default = nil)
  if valid_604058 != nil:
    section.add "DBParameterGroupName", valid_604058
  var valid_604059 = query.getOrDefault("Action")
  valid_604059 = validateParameter(valid_604059, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_604059 != nil:
    section.add "Action", valid_604059
  var valid_604060 = query.getOrDefault("Marker")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "Marker", valid_604060
  var valid_604061 = query.getOrDefault("Source")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "Source", valid_604061
  var valid_604062 = query.getOrDefault("Version")
  valid_604062 = validateParameter(valid_604062, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604062 != nil:
    section.add "Version", valid_604062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604063 = header.getOrDefault("X-Amz-Date")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Date", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Security-Token")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Security-Token", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Content-Sha256", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-Algorithm")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Algorithm", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Signature")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Signature", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-SignedHeaders", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Credential")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Credential", valid_604069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604070: Call_GetDescribeDBParameters_604053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604070.validator(path, query, header, formData, body)
  let scheme = call_604070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604070.url(scheme.get, call_604070.host, call_604070.base,
                         call_604070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604070, url, valid)

proc call*(call_604071: Call_GetDescribeDBParameters_604053;
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
  var query_604072 = newJObject()
  add(query_604072, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604072.add "Filters", Filters
  add(query_604072, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604072, "Action", newJString(Action))
  add(query_604072, "Marker", newJString(Marker))
  add(query_604072, "Source", newJString(Source))
  add(query_604072, "Version", newJString(Version))
  result = call_604071.call(nil, query_604072, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_604053(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_604054, base: "/",
    url: url_GetDescribeDBParameters_604055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_604113 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSecurityGroups_604115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_604114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
      "DescribeDBSecurityGroups"))
  if valid_604116 != nil:
    section.add "Action", valid_604116
  var valid_604117 = query.getOrDefault("Version")
  valid_604117 = validateParameter(valid_604117, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604125 = formData.getOrDefault("DBSecurityGroupName")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "DBSecurityGroupName", valid_604125
  var valid_604126 = formData.getOrDefault("Marker")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "Marker", valid_604126
  var valid_604127 = formData.getOrDefault("Filters")
  valid_604127 = validateParameter(valid_604127, JArray, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "Filters", valid_604127
  var valid_604128 = formData.getOrDefault("MaxRecords")
  valid_604128 = validateParameter(valid_604128, JInt, required = false, default = nil)
  if valid_604128 != nil:
    section.add "MaxRecords", valid_604128
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604129: Call_PostDescribeDBSecurityGroups_604113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604129.validator(path, query, header, formData, body)
  let scheme = call_604129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604129.url(scheme.get, call_604129.host, call_604129.base,
                         call_604129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604129, url, valid)

proc call*(call_604130: Call_PostDescribeDBSecurityGroups_604113;
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
  var query_604131 = newJObject()
  var formData_604132 = newJObject()
  add(formData_604132, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604132, "Marker", newJString(Marker))
  add(query_604131, "Action", newJString(Action))
  if Filters != nil:
    formData_604132.add "Filters", Filters
  add(formData_604132, "MaxRecords", newJInt(MaxRecords))
  add(query_604131, "Version", newJString(Version))
  result = call_604130.call(nil, query_604131, nil, formData_604132, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_604113(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_604114, base: "/",
    url: url_PostDescribeDBSecurityGroups_604115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_604094 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSecurityGroups_604096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_604095(path: JsonNode; query: JsonNode;
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
  var valid_604097 = query.getOrDefault("MaxRecords")
  valid_604097 = validateParameter(valid_604097, JInt, required = false, default = nil)
  if valid_604097 != nil:
    section.add "MaxRecords", valid_604097
  var valid_604098 = query.getOrDefault("DBSecurityGroupName")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "DBSecurityGroupName", valid_604098
  var valid_604099 = query.getOrDefault("Filters")
  valid_604099 = validateParameter(valid_604099, JArray, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "Filters", valid_604099
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604100 = query.getOrDefault("Action")
  valid_604100 = validateParameter(valid_604100, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_604100 != nil:
    section.add "Action", valid_604100
  var valid_604101 = query.getOrDefault("Marker")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "Marker", valid_604101
  var valid_604102 = query.getOrDefault("Version")
  valid_604102 = validateParameter(valid_604102, JString, required = true,
                                 default = newJString("2014-09-01"))
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

proc call*(call_604110: Call_GetDescribeDBSecurityGroups_604094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604110.validator(path, query, header, formData, body)
  let scheme = call_604110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604110.url(scheme.get, call_604110.host, call_604110.base,
                         call_604110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604110, url, valid)

proc call*(call_604111: Call_GetDescribeDBSecurityGroups_604094;
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
  var query_604112 = newJObject()
  add(query_604112, "MaxRecords", newJInt(MaxRecords))
  add(query_604112, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_604112.add "Filters", Filters
  add(query_604112, "Action", newJString(Action))
  add(query_604112, "Marker", newJString(Marker))
  add(query_604112, "Version", newJString(Version))
  result = call_604111.call(nil, query_604112, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_604094(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_604095, base: "/",
    url: url_GetDescribeDBSecurityGroups_604096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604154 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSnapshots_604156(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_604155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604157 = query.getOrDefault("Action")
  valid_604157 = validateParameter(valid_604157, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604157 != nil:
    section.add "Action", valid_604157
  var valid_604158 = query.getOrDefault("Version")
  valid_604158 = validateParameter(valid_604158, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604158 != nil:
    section.add "Version", valid_604158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604159 = header.getOrDefault("X-Amz-Date")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Date", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Security-Token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Security-Token", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Content-Sha256", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Algorithm")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Algorithm", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Signature")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Signature", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-SignedHeaders", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Credential")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Credential", valid_604165
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604166 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "DBInstanceIdentifier", valid_604166
  var valid_604167 = formData.getOrDefault("SnapshotType")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "SnapshotType", valid_604167
  var valid_604168 = formData.getOrDefault("Marker")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "Marker", valid_604168
  var valid_604169 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "DBSnapshotIdentifier", valid_604169
  var valid_604170 = formData.getOrDefault("Filters")
  valid_604170 = validateParameter(valid_604170, JArray, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "Filters", valid_604170
  var valid_604171 = formData.getOrDefault("MaxRecords")
  valid_604171 = validateParameter(valid_604171, JInt, required = false, default = nil)
  if valid_604171 != nil:
    section.add "MaxRecords", valid_604171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604172: Call_PostDescribeDBSnapshots_604154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604172.validator(path, query, header, formData, body)
  let scheme = call_604172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604172.url(scheme.get, call_604172.host, call_604172.base,
                         call_604172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604172, url, valid)

proc call*(call_604173: Call_PostDescribeDBSnapshots_604154;
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
  var query_604174 = newJObject()
  var formData_604175 = newJObject()
  add(formData_604175, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604175, "SnapshotType", newJString(SnapshotType))
  add(formData_604175, "Marker", newJString(Marker))
  add(formData_604175, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604174, "Action", newJString(Action))
  if Filters != nil:
    formData_604175.add "Filters", Filters
  add(formData_604175, "MaxRecords", newJInt(MaxRecords))
  add(query_604174, "Version", newJString(Version))
  result = call_604173.call(nil, query_604174, nil, formData_604175, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604154(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604155, base: "/",
    url: url_PostDescribeDBSnapshots_604156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_604133 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSnapshots_604135(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_604134(path: JsonNode; query: JsonNode;
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
  var valid_604136 = query.getOrDefault("MaxRecords")
  valid_604136 = validateParameter(valid_604136, JInt, required = false, default = nil)
  if valid_604136 != nil:
    section.add "MaxRecords", valid_604136
  var valid_604137 = query.getOrDefault("Filters")
  valid_604137 = validateParameter(valid_604137, JArray, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "Filters", valid_604137
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604138 = query.getOrDefault("Action")
  valid_604138 = validateParameter(valid_604138, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604138 != nil:
    section.add "Action", valid_604138
  var valid_604139 = query.getOrDefault("Marker")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "Marker", valid_604139
  var valid_604140 = query.getOrDefault("SnapshotType")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "SnapshotType", valid_604140
  var valid_604141 = query.getOrDefault("Version")
  valid_604141 = validateParameter(valid_604141, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604141 != nil:
    section.add "Version", valid_604141
  var valid_604142 = query.getOrDefault("DBInstanceIdentifier")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "DBInstanceIdentifier", valid_604142
  var valid_604143 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "DBSnapshotIdentifier", valid_604143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604144 = header.getOrDefault("X-Amz-Date")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Date", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Content-Sha256", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Algorithm")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Algorithm", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Signature")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Signature", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-SignedHeaders", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Credential")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Credential", valid_604150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604151: Call_GetDescribeDBSnapshots_604133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604151.validator(path, query, header, formData, body)
  let scheme = call_604151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604151.url(scheme.get, call_604151.host, call_604151.base,
                         call_604151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604151, url, valid)

proc call*(call_604152: Call_GetDescribeDBSnapshots_604133; MaxRecords: int = 0;
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
  var query_604153 = newJObject()
  add(query_604153, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604153.add "Filters", Filters
  add(query_604153, "Action", newJString(Action))
  add(query_604153, "Marker", newJString(Marker))
  add(query_604153, "SnapshotType", newJString(SnapshotType))
  add(query_604153, "Version", newJString(Version))
  add(query_604153, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604153, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604152.call(nil, query_604153, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_604133(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_604134, base: "/",
    url: url_GetDescribeDBSnapshots_604135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604195 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSubnetGroups_604197(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_604196(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604198 = query.getOrDefault("Action")
  valid_604198 = validateParameter(valid_604198, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604198 != nil:
    section.add "Action", valid_604198
  var valid_604199 = query.getOrDefault("Version")
  valid_604199 = validateParameter(valid_604199, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604199 != nil:
    section.add "Version", valid_604199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604200 = header.getOrDefault("X-Amz-Date")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Date", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Security-Token")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Security-Token", valid_604201
  var valid_604202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "X-Amz-Content-Sha256", valid_604202
  var valid_604203 = header.getOrDefault("X-Amz-Algorithm")
  valid_604203 = validateParameter(valid_604203, JString, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "X-Amz-Algorithm", valid_604203
  var valid_604204 = header.getOrDefault("X-Amz-Signature")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Signature", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-SignedHeaders", valid_604205
  var valid_604206 = header.getOrDefault("X-Amz-Credential")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Credential", valid_604206
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604207 = formData.getOrDefault("DBSubnetGroupName")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "DBSubnetGroupName", valid_604207
  var valid_604208 = formData.getOrDefault("Marker")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "Marker", valid_604208
  var valid_604209 = formData.getOrDefault("Filters")
  valid_604209 = validateParameter(valid_604209, JArray, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "Filters", valid_604209
  var valid_604210 = formData.getOrDefault("MaxRecords")
  valid_604210 = validateParameter(valid_604210, JInt, required = false, default = nil)
  if valid_604210 != nil:
    section.add "MaxRecords", valid_604210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604211: Call_PostDescribeDBSubnetGroups_604195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604211.validator(path, query, header, formData, body)
  let scheme = call_604211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604211.url(scheme.get, call_604211.host, call_604211.base,
                         call_604211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604211, url, valid)

proc call*(call_604212: Call_PostDescribeDBSubnetGroups_604195;
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
  var query_604213 = newJObject()
  var formData_604214 = newJObject()
  add(formData_604214, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604214, "Marker", newJString(Marker))
  add(query_604213, "Action", newJString(Action))
  if Filters != nil:
    formData_604214.add "Filters", Filters
  add(formData_604214, "MaxRecords", newJInt(MaxRecords))
  add(query_604213, "Version", newJString(Version))
  result = call_604212.call(nil, query_604213, nil, formData_604214, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604195(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604196, base: "/",
    url: url_PostDescribeDBSubnetGroups_604197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604176 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSubnetGroups_604178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_604177(path: JsonNode; query: JsonNode;
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
  var valid_604179 = query.getOrDefault("MaxRecords")
  valid_604179 = validateParameter(valid_604179, JInt, required = false, default = nil)
  if valid_604179 != nil:
    section.add "MaxRecords", valid_604179
  var valid_604180 = query.getOrDefault("Filters")
  valid_604180 = validateParameter(valid_604180, JArray, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "Filters", valid_604180
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604181 = query.getOrDefault("Action")
  valid_604181 = validateParameter(valid_604181, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604181 != nil:
    section.add "Action", valid_604181
  var valid_604182 = query.getOrDefault("Marker")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "Marker", valid_604182
  var valid_604183 = query.getOrDefault("DBSubnetGroupName")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "DBSubnetGroupName", valid_604183
  var valid_604184 = query.getOrDefault("Version")
  valid_604184 = validateParameter(valid_604184, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604192: Call_GetDescribeDBSubnetGroups_604176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604192.validator(path, query, header, formData, body)
  let scheme = call_604192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604192.url(scheme.get, call_604192.host, call_604192.base,
                         call_604192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604192, url, valid)

proc call*(call_604193: Call_GetDescribeDBSubnetGroups_604176; MaxRecords: int = 0;
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
  var query_604194 = newJObject()
  add(query_604194, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604194.add "Filters", Filters
  add(query_604194, "Action", newJString(Action))
  add(query_604194, "Marker", newJString(Marker))
  add(query_604194, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604194, "Version", newJString(Version))
  result = call_604193.call(nil, query_604194, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604176(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604177, base: "/",
    url: url_GetDescribeDBSubnetGroups_604178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604234 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEngineDefaultParameters_604236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_604235(path: JsonNode;
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
  var valid_604237 = query.getOrDefault("Action")
  valid_604237 = validateParameter(valid_604237, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604237 != nil:
    section.add "Action", valid_604237
  var valid_604238 = query.getOrDefault("Version")
  valid_604238 = validateParameter(valid_604238, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604238 != nil:
    section.add "Version", valid_604238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604239 = header.getOrDefault("X-Amz-Date")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-Date", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Security-Token")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Security-Token", valid_604240
  var valid_604241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "X-Amz-Content-Sha256", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Algorithm")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Algorithm", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-Signature")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Signature", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-SignedHeaders", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Credential")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Credential", valid_604245
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604246 = formData.getOrDefault("Marker")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "Marker", valid_604246
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604247 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604247 = validateParameter(valid_604247, JString, required = true,
                                 default = nil)
  if valid_604247 != nil:
    section.add "DBParameterGroupFamily", valid_604247
  var valid_604248 = formData.getOrDefault("Filters")
  valid_604248 = validateParameter(valid_604248, JArray, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "Filters", valid_604248
  var valid_604249 = formData.getOrDefault("MaxRecords")
  valid_604249 = validateParameter(valid_604249, JInt, required = false, default = nil)
  if valid_604249 != nil:
    section.add "MaxRecords", valid_604249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604250: Call_PostDescribeEngineDefaultParameters_604234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604250.validator(path, query, header, formData, body)
  let scheme = call_604250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604250.url(scheme.get, call_604250.host, call_604250.base,
                         call_604250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604250, url, valid)

proc call*(call_604251: Call_PostDescribeEngineDefaultParameters_604234;
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
  var query_604252 = newJObject()
  var formData_604253 = newJObject()
  add(formData_604253, "Marker", newJString(Marker))
  add(query_604252, "Action", newJString(Action))
  add(formData_604253, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_604253.add "Filters", Filters
  add(formData_604253, "MaxRecords", newJInt(MaxRecords))
  add(query_604252, "Version", newJString(Version))
  result = call_604251.call(nil, query_604252, nil, formData_604253, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604234(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604235, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604215 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEngineDefaultParameters_604217(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_604216(path: JsonNode;
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
  var valid_604218 = query.getOrDefault("MaxRecords")
  valid_604218 = validateParameter(valid_604218, JInt, required = false, default = nil)
  if valid_604218 != nil:
    section.add "MaxRecords", valid_604218
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604219 = query.getOrDefault("DBParameterGroupFamily")
  valid_604219 = validateParameter(valid_604219, JString, required = true,
                                 default = nil)
  if valid_604219 != nil:
    section.add "DBParameterGroupFamily", valid_604219
  var valid_604220 = query.getOrDefault("Filters")
  valid_604220 = validateParameter(valid_604220, JArray, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "Filters", valid_604220
  var valid_604221 = query.getOrDefault("Action")
  valid_604221 = validateParameter(valid_604221, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604221 != nil:
    section.add "Action", valid_604221
  var valid_604222 = query.getOrDefault("Marker")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "Marker", valid_604222
  var valid_604223 = query.getOrDefault("Version")
  valid_604223 = validateParameter(valid_604223, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604223 != nil:
    section.add "Version", valid_604223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604224 = header.getOrDefault("X-Amz-Date")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Date", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Security-Token")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Security-Token", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Content-Sha256", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Algorithm")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Algorithm", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Signature")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Signature", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-SignedHeaders", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Credential")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Credential", valid_604230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604231: Call_GetDescribeEngineDefaultParameters_604215;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604231.validator(path, query, header, formData, body)
  let scheme = call_604231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604231.url(scheme.get, call_604231.host, call_604231.base,
                         call_604231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604231, url, valid)

proc call*(call_604232: Call_GetDescribeEngineDefaultParameters_604215;
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
  var query_604233 = newJObject()
  add(query_604233, "MaxRecords", newJInt(MaxRecords))
  add(query_604233, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_604233.add "Filters", Filters
  add(query_604233, "Action", newJString(Action))
  add(query_604233, "Marker", newJString(Marker))
  add(query_604233, "Version", newJString(Version))
  result = call_604232.call(nil, query_604233, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604215(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604216, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604271 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventCategories_604273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_604272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604274 = query.getOrDefault("Action")
  valid_604274 = validateParameter(valid_604274, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604274 != nil:
    section.add "Action", valid_604274
  var valid_604275 = query.getOrDefault("Version")
  valid_604275 = validateParameter(valid_604275, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604275 != nil:
    section.add "Version", valid_604275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604276 = header.getOrDefault("X-Amz-Date")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-Date", valid_604276
  var valid_604277 = header.getOrDefault("X-Amz-Security-Token")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "X-Amz-Security-Token", valid_604277
  var valid_604278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Content-Sha256", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Algorithm")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Algorithm", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Signature")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Signature", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-SignedHeaders", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Credential")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Credential", valid_604282
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_604283 = formData.getOrDefault("Filters")
  valid_604283 = validateParameter(valid_604283, JArray, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "Filters", valid_604283
  var valid_604284 = formData.getOrDefault("SourceType")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "SourceType", valid_604284
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604285: Call_PostDescribeEventCategories_604271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604285.validator(path, query, header, formData, body)
  let scheme = call_604285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604285.url(scheme.get, call_604285.host, call_604285.base,
                         call_604285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604285, url, valid)

proc call*(call_604286: Call_PostDescribeEventCategories_604271;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_604287 = newJObject()
  var formData_604288 = newJObject()
  add(query_604287, "Action", newJString(Action))
  if Filters != nil:
    formData_604288.add "Filters", Filters
  add(query_604287, "Version", newJString(Version))
  add(formData_604288, "SourceType", newJString(SourceType))
  result = call_604286.call(nil, query_604287, nil, formData_604288, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604271(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604272, base: "/",
    url: url_PostDescribeEventCategories_604273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604254 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventCategories_604256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_604255(path: JsonNode; query: JsonNode;
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
  var valid_604257 = query.getOrDefault("SourceType")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "SourceType", valid_604257
  var valid_604258 = query.getOrDefault("Filters")
  valid_604258 = validateParameter(valid_604258, JArray, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "Filters", valid_604258
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604259 = query.getOrDefault("Action")
  valid_604259 = validateParameter(valid_604259, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604259 != nil:
    section.add "Action", valid_604259
  var valid_604260 = query.getOrDefault("Version")
  valid_604260 = validateParameter(valid_604260, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604260 != nil:
    section.add "Version", valid_604260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604261 = header.getOrDefault("X-Amz-Date")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Date", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Security-Token")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Security-Token", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Content-Sha256", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Algorithm")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Algorithm", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Signature")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Signature", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-SignedHeaders", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Credential")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Credential", valid_604267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604268: Call_GetDescribeEventCategories_604254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604268.validator(path, query, header, formData, body)
  let scheme = call_604268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604268.url(scheme.get, call_604268.host, call_604268.base,
                         call_604268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604268, url, valid)

proc call*(call_604269: Call_GetDescribeEventCategories_604254;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604270 = newJObject()
  add(query_604270, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_604270.add "Filters", Filters
  add(query_604270, "Action", newJString(Action))
  add(query_604270, "Version", newJString(Version))
  result = call_604269.call(nil, query_604270, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604254(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604255, base: "/",
    url: url_GetDescribeEventCategories_604256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604308 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventSubscriptions_604310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_604309(path: JsonNode;
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
  var valid_604311 = query.getOrDefault("Action")
  valid_604311 = validateParameter(valid_604311, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604311 != nil:
    section.add "Action", valid_604311
  var valid_604312 = query.getOrDefault("Version")
  valid_604312 = validateParameter(valid_604312, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604312 != nil:
    section.add "Version", valid_604312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604313 = header.getOrDefault("X-Amz-Date")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Date", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-Security-Token")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Security-Token", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Content-Sha256", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Algorithm")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Algorithm", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Signature")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Signature", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-SignedHeaders", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Credential")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Credential", valid_604319
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604320 = formData.getOrDefault("Marker")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "Marker", valid_604320
  var valid_604321 = formData.getOrDefault("SubscriptionName")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "SubscriptionName", valid_604321
  var valid_604322 = formData.getOrDefault("Filters")
  valid_604322 = validateParameter(valid_604322, JArray, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "Filters", valid_604322
  var valid_604323 = formData.getOrDefault("MaxRecords")
  valid_604323 = validateParameter(valid_604323, JInt, required = false, default = nil)
  if valid_604323 != nil:
    section.add "MaxRecords", valid_604323
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604324: Call_PostDescribeEventSubscriptions_604308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604324.validator(path, query, header, formData, body)
  let scheme = call_604324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604324.url(scheme.get, call_604324.host, call_604324.base,
                         call_604324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604324, url, valid)

proc call*(call_604325: Call_PostDescribeEventSubscriptions_604308;
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
  var query_604326 = newJObject()
  var formData_604327 = newJObject()
  add(formData_604327, "Marker", newJString(Marker))
  add(formData_604327, "SubscriptionName", newJString(SubscriptionName))
  add(query_604326, "Action", newJString(Action))
  if Filters != nil:
    formData_604327.add "Filters", Filters
  add(formData_604327, "MaxRecords", newJInt(MaxRecords))
  add(query_604326, "Version", newJString(Version))
  result = call_604325.call(nil, query_604326, nil, formData_604327, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604308(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604309, base: "/",
    url: url_PostDescribeEventSubscriptions_604310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604289 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventSubscriptions_604291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_604290(path: JsonNode; query: JsonNode;
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
  var valid_604292 = query.getOrDefault("MaxRecords")
  valid_604292 = validateParameter(valid_604292, JInt, required = false, default = nil)
  if valid_604292 != nil:
    section.add "MaxRecords", valid_604292
  var valid_604293 = query.getOrDefault("Filters")
  valid_604293 = validateParameter(valid_604293, JArray, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "Filters", valid_604293
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604294 = query.getOrDefault("Action")
  valid_604294 = validateParameter(valid_604294, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604294 != nil:
    section.add "Action", valid_604294
  var valid_604295 = query.getOrDefault("Marker")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "Marker", valid_604295
  var valid_604296 = query.getOrDefault("SubscriptionName")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "SubscriptionName", valid_604296
  var valid_604297 = query.getOrDefault("Version")
  valid_604297 = validateParameter(valid_604297, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604297 != nil:
    section.add "Version", valid_604297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604298 = header.getOrDefault("X-Amz-Date")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Date", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Security-Token")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Security-Token", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Content-Sha256", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Algorithm")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Algorithm", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Signature")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Signature", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-SignedHeaders", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Credential")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Credential", valid_604304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604305: Call_GetDescribeEventSubscriptions_604289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604305.validator(path, query, header, formData, body)
  let scheme = call_604305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604305.url(scheme.get, call_604305.host, call_604305.base,
                         call_604305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604305, url, valid)

proc call*(call_604306: Call_GetDescribeEventSubscriptions_604289;
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
  var query_604307 = newJObject()
  add(query_604307, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604307.add "Filters", Filters
  add(query_604307, "Action", newJString(Action))
  add(query_604307, "Marker", newJString(Marker))
  add(query_604307, "SubscriptionName", newJString(SubscriptionName))
  add(query_604307, "Version", newJString(Version))
  result = call_604306.call(nil, query_604307, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604289(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604290, base: "/",
    url: url_GetDescribeEventSubscriptions_604291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604352 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEvents_604354(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604353(path: JsonNode; query: JsonNode;
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
  var valid_604355 = query.getOrDefault("Action")
  valid_604355 = validateParameter(valid_604355, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604355 != nil:
    section.add "Action", valid_604355
  var valid_604356 = query.getOrDefault("Version")
  valid_604356 = validateParameter(valid_604356, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604356 != nil:
    section.add "Version", valid_604356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604357 = header.getOrDefault("X-Amz-Date")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Date", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Security-Token")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Security-Token", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Content-Sha256", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Algorithm")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Algorithm", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Signature")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Signature", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-SignedHeaders", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Credential")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Credential", valid_604363
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
  var valid_604364 = formData.getOrDefault("SourceIdentifier")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "SourceIdentifier", valid_604364
  var valid_604365 = formData.getOrDefault("EventCategories")
  valid_604365 = validateParameter(valid_604365, JArray, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "EventCategories", valid_604365
  var valid_604366 = formData.getOrDefault("Marker")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "Marker", valid_604366
  var valid_604367 = formData.getOrDefault("StartTime")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "StartTime", valid_604367
  var valid_604368 = formData.getOrDefault("Duration")
  valid_604368 = validateParameter(valid_604368, JInt, required = false, default = nil)
  if valid_604368 != nil:
    section.add "Duration", valid_604368
  var valid_604369 = formData.getOrDefault("Filters")
  valid_604369 = validateParameter(valid_604369, JArray, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "Filters", valid_604369
  var valid_604370 = formData.getOrDefault("EndTime")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "EndTime", valid_604370
  var valid_604371 = formData.getOrDefault("MaxRecords")
  valid_604371 = validateParameter(valid_604371, JInt, required = false, default = nil)
  if valid_604371 != nil:
    section.add "MaxRecords", valid_604371
  var valid_604372 = formData.getOrDefault("SourceType")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604372 != nil:
    section.add "SourceType", valid_604372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604373: Call_PostDescribeEvents_604352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604373.validator(path, query, header, formData, body)
  let scheme = call_604373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604373.url(scheme.get, call_604373.host, call_604373.base,
                         call_604373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604373, url, valid)

proc call*(call_604374: Call_PostDescribeEvents_604352;
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
  var query_604375 = newJObject()
  var formData_604376 = newJObject()
  add(formData_604376, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604376.add "EventCategories", EventCategories
  add(formData_604376, "Marker", newJString(Marker))
  add(formData_604376, "StartTime", newJString(StartTime))
  add(query_604375, "Action", newJString(Action))
  add(formData_604376, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604376.add "Filters", Filters
  add(formData_604376, "EndTime", newJString(EndTime))
  add(formData_604376, "MaxRecords", newJInt(MaxRecords))
  add(query_604375, "Version", newJString(Version))
  add(formData_604376, "SourceType", newJString(SourceType))
  result = call_604374.call(nil, query_604375, nil, formData_604376, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604352(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604353, base: "/",
    url: url_PostDescribeEvents_604354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604328 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEvents_604330(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604329(path: JsonNode; query: JsonNode;
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
  var valid_604331 = query.getOrDefault("SourceType")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604331 != nil:
    section.add "SourceType", valid_604331
  var valid_604332 = query.getOrDefault("MaxRecords")
  valid_604332 = validateParameter(valid_604332, JInt, required = false, default = nil)
  if valid_604332 != nil:
    section.add "MaxRecords", valid_604332
  var valid_604333 = query.getOrDefault("StartTime")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "StartTime", valid_604333
  var valid_604334 = query.getOrDefault("Filters")
  valid_604334 = validateParameter(valid_604334, JArray, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "Filters", valid_604334
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604335 = query.getOrDefault("Action")
  valid_604335 = validateParameter(valid_604335, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604335 != nil:
    section.add "Action", valid_604335
  var valid_604336 = query.getOrDefault("SourceIdentifier")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "SourceIdentifier", valid_604336
  var valid_604337 = query.getOrDefault("Marker")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "Marker", valid_604337
  var valid_604338 = query.getOrDefault("EventCategories")
  valid_604338 = validateParameter(valid_604338, JArray, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "EventCategories", valid_604338
  var valid_604339 = query.getOrDefault("Duration")
  valid_604339 = validateParameter(valid_604339, JInt, required = false, default = nil)
  if valid_604339 != nil:
    section.add "Duration", valid_604339
  var valid_604340 = query.getOrDefault("EndTime")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "EndTime", valid_604340
  var valid_604341 = query.getOrDefault("Version")
  valid_604341 = validateParameter(valid_604341, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604341 != nil:
    section.add "Version", valid_604341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604342 = header.getOrDefault("X-Amz-Date")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "X-Amz-Date", valid_604342
  var valid_604343 = header.getOrDefault("X-Amz-Security-Token")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Security-Token", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Content-Sha256", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Algorithm")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Algorithm", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Signature")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Signature", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-SignedHeaders", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Credential")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Credential", valid_604348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604349: Call_GetDescribeEvents_604328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604349.validator(path, query, header, formData, body)
  let scheme = call_604349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604349.url(scheme.get, call_604349.host, call_604349.base,
                         call_604349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604349, url, valid)

proc call*(call_604350: Call_GetDescribeEvents_604328;
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
  var query_604351 = newJObject()
  add(query_604351, "SourceType", newJString(SourceType))
  add(query_604351, "MaxRecords", newJInt(MaxRecords))
  add(query_604351, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_604351.add "Filters", Filters
  add(query_604351, "Action", newJString(Action))
  add(query_604351, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604351, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604351.add "EventCategories", EventCategories
  add(query_604351, "Duration", newJInt(Duration))
  add(query_604351, "EndTime", newJString(EndTime))
  add(query_604351, "Version", newJString(Version))
  result = call_604350.call(nil, query_604351, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604328(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604329,
    base: "/", url: url_GetDescribeEvents_604330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604397 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroupOptions_604399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_604398(path: JsonNode;
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
  var valid_604400 = query.getOrDefault("Action")
  valid_604400 = validateParameter(valid_604400, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604400 != nil:
    section.add "Action", valid_604400
  var valid_604401 = query.getOrDefault("Version")
  valid_604401 = validateParameter(valid_604401, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604401 != nil:
    section.add "Version", valid_604401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604402 = header.getOrDefault("X-Amz-Date")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Date", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Security-Token")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Security-Token", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Content-Sha256", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Algorithm")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Algorithm", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Signature")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Signature", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-SignedHeaders", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Credential")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Credential", valid_604408
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604409 = formData.getOrDefault("MajorEngineVersion")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "MajorEngineVersion", valid_604409
  var valid_604410 = formData.getOrDefault("Marker")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "Marker", valid_604410
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604411 = formData.getOrDefault("EngineName")
  valid_604411 = validateParameter(valid_604411, JString, required = true,
                                 default = nil)
  if valid_604411 != nil:
    section.add "EngineName", valid_604411
  var valid_604412 = formData.getOrDefault("Filters")
  valid_604412 = validateParameter(valid_604412, JArray, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "Filters", valid_604412
  var valid_604413 = formData.getOrDefault("MaxRecords")
  valid_604413 = validateParameter(valid_604413, JInt, required = false, default = nil)
  if valid_604413 != nil:
    section.add "MaxRecords", valid_604413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604414: Call_PostDescribeOptionGroupOptions_604397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604414.validator(path, query, header, formData, body)
  let scheme = call_604414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604414.url(scheme.get, call_604414.host, call_604414.base,
                         call_604414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604414, url, valid)

proc call*(call_604415: Call_PostDescribeOptionGroupOptions_604397;
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
  var query_604416 = newJObject()
  var formData_604417 = newJObject()
  add(formData_604417, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604417, "Marker", newJString(Marker))
  add(query_604416, "Action", newJString(Action))
  add(formData_604417, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604417.add "Filters", Filters
  add(formData_604417, "MaxRecords", newJInt(MaxRecords))
  add(query_604416, "Version", newJString(Version))
  result = call_604415.call(nil, query_604416, nil, formData_604417, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604397(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604398, base: "/",
    url: url_PostDescribeOptionGroupOptions_604399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604377 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroupOptions_604379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_604378(path: JsonNode; query: JsonNode;
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
  var valid_604380 = query.getOrDefault("MaxRecords")
  valid_604380 = validateParameter(valid_604380, JInt, required = false, default = nil)
  if valid_604380 != nil:
    section.add "MaxRecords", valid_604380
  var valid_604381 = query.getOrDefault("Filters")
  valid_604381 = validateParameter(valid_604381, JArray, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "Filters", valid_604381
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604382 = query.getOrDefault("Action")
  valid_604382 = validateParameter(valid_604382, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604382 != nil:
    section.add "Action", valid_604382
  var valid_604383 = query.getOrDefault("Marker")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "Marker", valid_604383
  var valid_604384 = query.getOrDefault("Version")
  valid_604384 = validateParameter(valid_604384, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604384 != nil:
    section.add "Version", valid_604384
  var valid_604385 = query.getOrDefault("EngineName")
  valid_604385 = validateParameter(valid_604385, JString, required = true,
                                 default = nil)
  if valid_604385 != nil:
    section.add "EngineName", valid_604385
  var valid_604386 = query.getOrDefault("MajorEngineVersion")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "MajorEngineVersion", valid_604386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604387 = header.getOrDefault("X-Amz-Date")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Date", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Security-Token")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Security-Token", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Content-Sha256", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Algorithm")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Algorithm", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Signature")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Signature", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-SignedHeaders", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Credential")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Credential", valid_604393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604394: Call_GetDescribeOptionGroupOptions_604377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604394.validator(path, query, header, formData, body)
  let scheme = call_604394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604394.url(scheme.get, call_604394.host, call_604394.base,
                         call_604394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604394, url, valid)

proc call*(call_604395: Call_GetDescribeOptionGroupOptions_604377;
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
  var query_604396 = newJObject()
  add(query_604396, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604396.add "Filters", Filters
  add(query_604396, "Action", newJString(Action))
  add(query_604396, "Marker", newJString(Marker))
  add(query_604396, "Version", newJString(Version))
  add(query_604396, "EngineName", newJString(EngineName))
  add(query_604396, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604395.call(nil, query_604396, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604377(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604378, base: "/",
    url: url_GetDescribeOptionGroupOptions_604379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604439 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroups_604441(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_604440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604442 = query.getOrDefault("Action")
  valid_604442 = validateParameter(valid_604442, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604442 != nil:
    section.add "Action", valid_604442
  var valid_604443 = query.getOrDefault("Version")
  valid_604443 = validateParameter(valid_604443, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604443 != nil:
    section.add "Version", valid_604443
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604451 = formData.getOrDefault("MajorEngineVersion")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "MajorEngineVersion", valid_604451
  var valid_604452 = formData.getOrDefault("OptionGroupName")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "OptionGroupName", valid_604452
  var valid_604453 = formData.getOrDefault("Marker")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "Marker", valid_604453
  var valid_604454 = formData.getOrDefault("EngineName")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "EngineName", valid_604454
  var valid_604455 = formData.getOrDefault("Filters")
  valid_604455 = validateParameter(valid_604455, JArray, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "Filters", valid_604455
  var valid_604456 = formData.getOrDefault("MaxRecords")
  valid_604456 = validateParameter(valid_604456, JInt, required = false, default = nil)
  if valid_604456 != nil:
    section.add "MaxRecords", valid_604456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604457: Call_PostDescribeOptionGroups_604439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604457.validator(path, query, header, formData, body)
  let scheme = call_604457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604457.url(scheme.get, call_604457.host, call_604457.base,
                         call_604457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604457, url, valid)

proc call*(call_604458: Call_PostDescribeOptionGroups_604439;
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
  var query_604459 = newJObject()
  var formData_604460 = newJObject()
  add(formData_604460, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604460, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604460, "Marker", newJString(Marker))
  add(query_604459, "Action", newJString(Action))
  add(formData_604460, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604460.add "Filters", Filters
  add(formData_604460, "MaxRecords", newJInt(MaxRecords))
  add(query_604459, "Version", newJString(Version))
  result = call_604458.call(nil, query_604459, nil, formData_604460, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604439(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604440, base: "/",
    url: url_PostDescribeOptionGroups_604441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604418 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroups_604420(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_604419(path: JsonNode; query: JsonNode;
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
  var valid_604421 = query.getOrDefault("MaxRecords")
  valid_604421 = validateParameter(valid_604421, JInt, required = false, default = nil)
  if valid_604421 != nil:
    section.add "MaxRecords", valid_604421
  var valid_604422 = query.getOrDefault("OptionGroupName")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "OptionGroupName", valid_604422
  var valid_604423 = query.getOrDefault("Filters")
  valid_604423 = validateParameter(valid_604423, JArray, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "Filters", valid_604423
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604424 = query.getOrDefault("Action")
  valid_604424 = validateParameter(valid_604424, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604424 != nil:
    section.add "Action", valid_604424
  var valid_604425 = query.getOrDefault("Marker")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "Marker", valid_604425
  var valid_604426 = query.getOrDefault("Version")
  valid_604426 = validateParameter(valid_604426, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604426 != nil:
    section.add "Version", valid_604426
  var valid_604427 = query.getOrDefault("EngineName")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "EngineName", valid_604427
  var valid_604428 = query.getOrDefault("MajorEngineVersion")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "MajorEngineVersion", valid_604428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604429 = header.getOrDefault("X-Amz-Date")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-Date", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Security-Token")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Security-Token", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Content-Sha256", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Algorithm")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Algorithm", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Signature")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Signature", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-SignedHeaders", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-Credential")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Credential", valid_604435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604436: Call_GetDescribeOptionGroups_604418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604436.validator(path, query, header, formData, body)
  let scheme = call_604436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604436.url(scheme.get, call_604436.host, call_604436.base,
                         call_604436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604436, url, valid)

proc call*(call_604437: Call_GetDescribeOptionGroups_604418; MaxRecords: int = 0;
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
  var query_604438 = newJObject()
  add(query_604438, "MaxRecords", newJInt(MaxRecords))
  add(query_604438, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_604438.add "Filters", Filters
  add(query_604438, "Action", newJString(Action))
  add(query_604438, "Marker", newJString(Marker))
  add(query_604438, "Version", newJString(Version))
  add(query_604438, "EngineName", newJString(EngineName))
  add(query_604438, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604437.call(nil, query_604438, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604418(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604419, base: "/",
    url: url_GetDescribeOptionGroups_604420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604484 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOrderableDBInstanceOptions_604486(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604485(path: JsonNode;
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
  var valid_604487 = query.getOrDefault("Action")
  valid_604487 = validateParameter(valid_604487, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604487 != nil:
    section.add "Action", valid_604487
  var valid_604488 = query.getOrDefault("Version")
  valid_604488 = validateParameter(valid_604488, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604488 != nil:
    section.add "Version", valid_604488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604489 = header.getOrDefault("X-Amz-Date")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-Date", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Security-Token")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Security-Token", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-Content-Sha256", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-Algorithm")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Algorithm", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Signature")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Signature", valid_604493
  var valid_604494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-SignedHeaders", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Credential")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Credential", valid_604495
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
  var valid_604496 = formData.getOrDefault("Engine")
  valid_604496 = validateParameter(valid_604496, JString, required = true,
                                 default = nil)
  if valid_604496 != nil:
    section.add "Engine", valid_604496
  var valid_604497 = formData.getOrDefault("Marker")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "Marker", valid_604497
  var valid_604498 = formData.getOrDefault("Vpc")
  valid_604498 = validateParameter(valid_604498, JBool, required = false, default = nil)
  if valid_604498 != nil:
    section.add "Vpc", valid_604498
  var valid_604499 = formData.getOrDefault("DBInstanceClass")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "DBInstanceClass", valid_604499
  var valid_604500 = formData.getOrDefault("Filters")
  valid_604500 = validateParameter(valid_604500, JArray, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "Filters", valid_604500
  var valid_604501 = formData.getOrDefault("LicenseModel")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "LicenseModel", valid_604501
  var valid_604502 = formData.getOrDefault("MaxRecords")
  valid_604502 = validateParameter(valid_604502, JInt, required = false, default = nil)
  if valid_604502 != nil:
    section.add "MaxRecords", valid_604502
  var valid_604503 = formData.getOrDefault("EngineVersion")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "EngineVersion", valid_604503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604504: Call_PostDescribeOrderableDBInstanceOptions_604484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604504.validator(path, query, header, formData, body)
  let scheme = call_604504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604504.url(scheme.get, call_604504.host, call_604504.base,
                         call_604504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604504, url, valid)

proc call*(call_604505: Call_PostDescribeOrderableDBInstanceOptions_604484;
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
  var query_604506 = newJObject()
  var formData_604507 = newJObject()
  add(formData_604507, "Engine", newJString(Engine))
  add(formData_604507, "Marker", newJString(Marker))
  add(query_604506, "Action", newJString(Action))
  add(formData_604507, "Vpc", newJBool(Vpc))
  add(formData_604507, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604507.add "Filters", Filters
  add(formData_604507, "LicenseModel", newJString(LicenseModel))
  add(formData_604507, "MaxRecords", newJInt(MaxRecords))
  add(formData_604507, "EngineVersion", newJString(EngineVersion))
  add(query_604506, "Version", newJString(Version))
  result = call_604505.call(nil, query_604506, nil, formData_604507, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604484(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604485, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604461 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOrderableDBInstanceOptions_604463(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604462(path: JsonNode;
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
  var valid_604464 = query.getOrDefault("Engine")
  valid_604464 = validateParameter(valid_604464, JString, required = true,
                                 default = nil)
  if valid_604464 != nil:
    section.add "Engine", valid_604464
  var valid_604465 = query.getOrDefault("MaxRecords")
  valid_604465 = validateParameter(valid_604465, JInt, required = false, default = nil)
  if valid_604465 != nil:
    section.add "MaxRecords", valid_604465
  var valid_604466 = query.getOrDefault("Filters")
  valid_604466 = validateParameter(valid_604466, JArray, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "Filters", valid_604466
  var valid_604467 = query.getOrDefault("LicenseModel")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "LicenseModel", valid_604467
  var valid_604468 = query.getOrDefault("Vpc")
  valid_604468 = validateParameter(valid_604468, JBool, required = false, default = nil)
  if valid_604468 != nil:
    section.add "Vpc", valid_604468
  var valid_604469 = query.getOrDefault("DBInstanceClass")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "DBInstanceClass", valid_604469
  var valid_604470 = query.getOrDefault("Action")
  valid_604470 = validateParameter(valid_604470, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604470 != nil:
    section.add "Action", valid_604470
  var valid_604471 = query.getOrDefault("Marker")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "Marker", valid_604471
  var valid_604472 = query.getOrDefault("EngineVersion")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "EngineVersion", valid_604472
  var valid_604473 = query.getOrDefault("Version")
  valid_604473 = validateParameter(valid_604473, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604473 != nil:
    section.add "Version", valid_604473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604474 = header.getOrDefault("X-Amz-Date")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-Date", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Security-Token")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Security-Token", valid_604475
  var valid_604476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "X-Amz-Content-Sha256", valid_604476
  var valid_604477 = header.getOrDefault("X-Amz-Algorithm")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "X-Amz-Algorithm", valid_604477
  var valid_604478 = header.getOrDefault("X-Amz-Signature")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Signature", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-SignedHeaders", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Credential")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Credential", valid_604480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604481: Call_GetDescribeOrderableDBInstanceOptions_604461;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604481.validator(path, query, header, formData, body)
  let scheme = call_604481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604481.url(scheme.get, call_604481.host, call_604481.base,
                         call_604481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604481, url, valid)

proc call*(call_604482: Call_GetDescribeOrderableDBInstanceOptions_604461;
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
  var query_604483 = newJObject()
  add(query_604483, "Engine", newJString(Engine))
  add(query_604483, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604483.add "Filters", Filters
  add(query_604483, "LicenseModel", newJString(LicenseModel))
  add(query_604483, "Vpc", newJBool(Vpc))
  add(query_604483, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604483, "Action", newJString(Action))
  add(query_604483, "Marker", newJString(Marker))
  add(query_604483, "EngineVersion", newJString(EngineVersion))
  add(query_604483, "Version", newJString(Version))
  result = call_604482.call(nil, query_604483, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604461(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604462, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604533 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstances_604535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_604534(path: JsonNode;
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
  var valid_604536 = query.getOrDefault("Action")
  valid_604536 = validateParameter(valid_604536, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604536 != nil:
    section.add "Action", valid_604536
  var valid_604537 = query.getOrDefault("Version")
  valid_604537 = validateParameter(valid_604537, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604537 != nil:
    section.add "Version", valid_604537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604538 = header.getOrDefault("X-Amz-Date")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Date", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-Security-Token")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-Security-Token", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Content-Sha256", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Algorithm")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Algorithm", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Signature")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Signature", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-SignedHeaders", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Credential")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Credential", valid_604544
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
  var valid_604545 = formData.getOrDefault("OfferingType")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "OfferingType", valid_604545
  var valid_604546 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "ReservedDBInstanceId", valid_604546
  var valid_604547 = formData.getOrDefault("Marker")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "Marker", valid_604547
  var valid_604548 = formData.getOrDefault("MultiAZ")
  valid_604548 = validateParameter(valid_604548, JBool, required = false, default = nil)
  if valid_604548 != nil:
    section.add "MultiAZ", valid_604548
  var valid_604549 = formData.getOrDefault("Duration")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "Duration", valid_604549
  var valid_604550 = formData.getOrDefault("DBInstanceClass")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "DBInstanceClass", valid_604550
  var valid_604551 = formData.getOrDefault("Filters")
  valid_604551 = validateParameter(valid_604551, JArray, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "Filters", valid_604551
  var valid_604552 = formData.getOrDefault("ProductDescription")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "ProductDescription", valid_604552
  var valid_604553 = formData.getOrDefault("MaxRecords")
  valid_604553 = validateParameter(valid_604553, JInt, required = false, default = nil)
  if valid_604553 != nil:
    section.add "MaxRecords", valid_604553
  var valid_604554 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604554
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604555: Call_PostDescribeReservedDBInstances_604533;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604555.validator(path, query, header, formData, body)
  let scheme = call_604555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604555.url(scheme.get, call_604555.host, call_604555.base,
                         call_604555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604555, url, valid)

proc call*(call_604556: Call_PostDescribeReservedDBInstances_604533;
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
  var query_604557 = newJObject()
  var formData_604558 = newJObject()
  add(formData_604558, "OfferingType", newJString(OfferingType))
  add(formData_604558, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604558, "Marker", newJString(Marker))
  add(formData_604558, "MultiAZ", newJBool(MultiAZ))
  add(query_604557, "Action", newJString(Action))
  add(formData_604558, "Duration", newJString(Duration))
  add(formData_604558, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604558.add "Filters", Filters
  add(formData_604558, "ProductDescription", newJString(ProductDescription))
  add(formData_604558, "MaxRecords", newJInt(MaxRecords))
  add(formData_604558, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604557, "Version", newJString(Version))
  result = call_604556.call(nil, query_604557, nil, formData_604558, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604533(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604534, base: "/",
    url: url_PostDescribeReservedDBInstances_604535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604508 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstances_604510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_604509(path: JsonNode;
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
  var valid_604511 = query.getOrDefault("ProductDescription")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "ProductDescription", valid_604511
  var valid_604512 = query.getOrDefault("MaxRecords")
  valid_604512 = validateParameter(valid_604512, JInt, required = false, default = nil)
  if valid_604512 != nil:
    section.add "MaxRecords", valid_604512
  var valid_604513 = query.getOrDefault("OfferingType")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "OfferingType", valid_604513
  var valid_604514 = query.getOrDefault("Filters")
  valid_604514 = validateParameter(valid_604514, JArray, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "Filters", valid_604514
  var valid_604515 = query.getOrDefault("MultiAZ")
  valid_604515 = validateParameter(valid_604515, JBool, required = false, default = nil)
  if valid_604515 != nil:
    section.add "MultiAZ", valid_604515
  var valid_604516 = query.getOrDefault("ReservedDBInstanceId")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "ReservedDBInstanceId", valid_604516
  var valid_604517 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604517
  var valid_604518 = query.getOrDefault("DBInstanceClass")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "DBInstanceClass", valid_604518
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604519 = query.getOrDefault("Action")
  valid_604519 = validateParameter(valid_604519, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604519 != nil:
    section.add "Action", valid_604519
  var valid_604520 = query.getOrDefault("Marker")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "Marker", valid_604520
  var valid_604521 = query.getOrDefault("Duration")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "Duration", valid_604521
  var valid_604522 = query.getOrDefault("Version")
  valid_604522 = validateParameter(valid_604522, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604522 != nil:
    section.add "Version", valid_604522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604523 = header.getOrDefault("X-Amz-Date")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-Date", valid_604523
  var valid_604524 = header.getOrDefault("X-Amz-Security-Token")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-Security-Token", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Content-Sha256", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Algorithm")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Algorithm", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Signature")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Signature", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-SignedHeaders", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Credential")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Credential", valid_604529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604530: Call_GetDescribeReservedDBInstances_604508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604530.validator(path, query, header, formData, body)
  let scheme = call_604530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604530.url(scheme.get, call_604530.host, call_604530.base,
                         call_604530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604530, url, valid)

proc call*(call_604531: Call_GetDescribeReservedDBInstances_604508;
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
  var query_604532 = newJObject()
  add(query_604532, "ProductDescription", newJString(ProductDescription))
  add(query_604532, "MaxRecords", newJInt(MaxRecords))
  add(query_604532, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604532.add "Filters", Filters
  add(query_604532, "MultiAZ", newJBool(MultiAZ))
  add(query_604532, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604532, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604532, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604532, "Action", newJString(Action))
  add(query_604532, "Marker", newJString(Marker))
  add(query_604532, "Duration", newJString(Duration))
  add(query_604532, "Version", newJString(Version))
  result = call_604531.call(nil, query_604532, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604508(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604509, base: "/",
    url: url_GetDescribeReservedDBInstances_604510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604583 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstancesOfferings_604585(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604584(path: JsonNode;
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
  var valid_604586 = query.getOrDefault("Action")
  valid_604586 = validateParameter(valid_604586, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604586 != nil:
    section.add "Action", valid_604586
  var valid_604587 = query.getOrDefault("Version")
  valid_604587 = validateParameter(valid_604587, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604587 != nil:
    section.add "Version", valid_604587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604588 = header.getOrDefault("X-Amz-Date")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Date", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Security-Token")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Security-Token", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Content-Sha256", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-Algorithm")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-Algorithm", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Signature")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Signature", valid_604592
  var valid_604593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-SignedHeaders", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-Credential")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Credential", valid_604594
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
  var valid_604595 = formData.getOrDefault("OfferingType")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "OfferingType", valid_604595
  var valid_604596 = formData.getOrDefault("Marker")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "Marker", valid_604596
  var valid_604597 = formData.getOrDefault("MultiAZ")
  valid_604597 = validateParameter(valid_604597, JBool, required = false, default = nil)
  if valid_604597 != nil:
    section.add "MultiAZ", valid_604597
  var valid_604598 = formData.getOrDefault("Duration")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "Duration", valid_604598
  var valid_604599 = formData.getOrDefault("DBInstanceClass")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "DBInstanceClass", valid_604599
  var valid_604600 = formData.getOrDefault("Filters")
  valid_604600 = validateParameter(valid_604600, JArray, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "Filters", valid_604600
  var valid_604601 = formData.getOrDefault("ProductDescription")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "ProductDescription", valid_604601
  var valid_604602 = formData.getOrDefault("MaxRecords")
  valid_604602 = validateParameter(valid_604602, JInt, required = false, default = nil)
  if valid_604602 != nil:
    section.add "MaxRecords", valid_604602
  var valid_604603 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604604: Call_PostDescribeReservedDBInstancesOfferings_604583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604604.validator(path, query, header, formData, body)
  let scheme = call_604604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604604.url(scheme.get, call_604604.host, call_604604.base,
                         call_604604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604604, url, valid)

proc call*(call_604605: Call_PostDescribeReservedDBInstancesOfferings_604583;
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
  var query_604606 = newJObject()
  var formData_604607 = newJObject()
  add(formData_604607, "OfferingType", newJString(OfferingType))
  add(formData_604607, "Marker", newJString(Marker))
  add(formData_604607, "MultiAZ", newJBool(MultiAZ))
  add(query_604606, "Action", newJString(Action))
  add(formData_604607, "Duration", newJString(Duration))
  add(formData_604607, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604607.add "Filters", Filters
  add(formData_604607, "ProductDescription", newJString(ProductDescription))
  add(formData_604607, "MaxRecords", newJInt(MaxRecords))
  add(formData_604607, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604606, "Version", newJString(Version))
  result = call_604605.call(nil, query_604606, nil, formData_604607, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604583(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604584,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604559 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstancesOfferings_604561(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604560(path: JsonNode;
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
  var valid_604562 = query.getOrDefault("ProductDescription")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "ProductDescription", valid_604562
  var valid_604563 = query.getOrDefault("MaxRecords")
  valid_604563 = validateParameter(valid_604563, JInt, required = false, default = nil)
  if valid_604563 != nil:
    section.add "MaxRecords", valid_604563
  var valid_604564 = query.getOrDefault("OfferingType")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "OfferingType", valid_604564
  var valid_604565 = query.getOrDefault("Filters")
  valid_604565 = validateParameter(valid_604565, JArray, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "Filters", valid_604565
  var valid_604566 = query.getOrDefault("MultiAZ")
  valid_604566 = validateParameter(valid_604566, JBool, required = false, default = nil)
  if valid_604566 != nil:
    section.add "MultiAZ", valid_604566
  var valid_604567 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604567 = validateParameter(valid_604567, JString, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604567
  var valid_604568 = query.getOrDefault("DBInstanceClass")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "DBInstanceClass", valid_604568
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604569 = query.getOrDefault("Action")
  valid_604569 = validateParameter(valid_604569, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604569 != nil:
    section.add "Action", valid_604569
  var valid_604570 = query.getOrDefault("Marker")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "Marker", valid_604570
  var valid_604571 = query.getOrDefault("Duration")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "Duration", valid_604571
  var valid_604572 = query.getOrDefault("Version")
  valid_604572 = validateParameter(valid_604572, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604572 != nil:
    section.add "Version", valid_604572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604573 = header.getOrDefault("X-Amz-Date")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Date", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Security-Token")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Security-Token", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Content-Sha256", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-Algorithm")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-Algorithm", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Signature")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Signature", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-SignedHeaders", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Credential")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Credential", valid_604579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604580: Call_GetDescribeReservedDBInstancesOfferings_604559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604580.validator(path, query, header, formData, body)
  let scheme = call_604580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604580.url(scheme.get, call_604580.host, call_604580.base,
                         call_604580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604580, url, valid)

proc call*(call_604581: Call_GetDescribeReservedDBInstancesOfferings_604559;
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
  var query_604582 = newJObject()
  add(query_604582, "ProductDescription", newJString(ProductDescription))
  add(query_604582, "MaxRecords", newJInt(MaxRecords))
  add(query_604582, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604582.add "Filters", Filters
  add(query_604582, "MultiAZ", newJBool(MultiAZ))
  add(query_604582, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604582, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604582, "Action", newJString(Action))
  add(query_604582, "Marker", newJString(Marker))
  add(query_604582, "Duration", newJString(Duration))
  add(query_604582, "Version", newJString(Version))
  result = call_604581.call(nil, query_604582, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604559(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604560, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604627 = ref object of OpenApiRestCall_602450
proc url_PostDownloadDBLogFilePortion_604629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_604628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_604630 = validateParameter(valid_604630, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604630 != nil:
    section.add "Action", valid_604630
  var valid_604631 = query.getOrDefault("Version")
  valid_604631 = validateParameter(valid_604631, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604639 = formData.getOrDefault("NumberOfLines")
  valid_604639 = validateParameter(valid_604639, JInt, required = false, default = nil)
  if valid_604639 != nil:
    section.add "NumberOfLines", valid_604639
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604640 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604640 = validateParameter(valid_604640, JString, required = true,
                                 default = nil)
  if valid_604640 != nil:
    section.add "DBInstanceIdentifier", valid_604640
  var valid_604641 = formData.getOrDefault("Marker")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "Marker", valid_604641
  var valid_604642 = formData.getOrDefault("LogFileName")
  valid_604642 = validateParameter(valid_604642, JString, required = true,
                                 default = nil)
  if valid_604642 != nil:
    section.add "LogFileName", valid_604642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604643: Call_PostDownloadDBLogFilePortion_604627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604643.validator(path, query, header, formData, body)
  let scheme = call_604643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604643.url(scheme.get, call_604643.host, call_604643.base,
                         call_604643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604643, url, valid)

proc call*(call_604644: Call_PostDownloadDBLogFilePortion_604627;
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
  var query_604645 = newJObject()
  var formData_604646 = newJObject()
  add(formData_604646, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604646, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604646, "Marker", newJString(Marker))
  add(query_604645, "Action", newJString(Action))
  add(formData_604646, "LogFileName", newJString(LogFileName))
  add(query_604645, "Version", newJString(Version))
  result = call_604644.call(nil, query_604645, nil, formData_604646, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604627(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604628, base: "/",
    url: url_PostDownloadDBLogFilePortion_604629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604608 = ref object of OpenApiRestCall_602450
proc url_GetDownloadDBLogFilePortion_604610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_604609(path: JsonNode; query: JsonNode;
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
  var valid_604611 = query.getOrDefault("NumberOfLines")
  valid_604611 = validateParameter(valid_604611, JInt, required = false, default = nil)
  if valid_604611 != nil:
    section.add "NumberOfLines", valid_604611
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604612 = query.getOrDefault("LogFileName")
  valid_604612 = validateParameter(valid_604612, JString, required = true,
                                 default = nil)
  if valid_604612 != nil:
    section.add "LogFileName", valid_604612
  var valid_604613 = query.getOrDefault("Action")
  valid_604613 = validateParameter(valid_604613, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604613 != nil:
    section.add "Action", valid_604613
  var valid_604614 = query.getOrDefault("Marker")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "Marker", valid_604614
  var valid_604615 = query.getOrDefault("Version")
  valid_604615 = validateParameter(valid_604615, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604615 != nil:
    section.add "Version", valid_604615
  var valid_604616 = query.getOrDefault("DBInstanceIdentifier")
  valid_604616 = validateParameter(valid_604616, JString, required = true,
                                 default = nil)
  if valid_604616 != nil:
    section.add "DBInstanceIdentifier", valid_604616
  result.add "query", section
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

proc call*(call_604624: Call_GetDownloadDBLogFilePortion_604608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604624.validator(path, query, header, formData, body)
  let scheme = call_604624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604624.url(scheme.get, call_604624.host, call_604624.base,
                         call_604624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604624, url, valid)

proc call*(call_604625: Call_GetDownloadDBLogFilePortion_604608;
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
  var query_604626 = newJObject()
  add(query_604626, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604626, "LogFileName", newJString(LogFileName))
  add(query_604626, "Action", newJString(Action))
  add(query_604626, "Marker", newJString(Marker))
  add(query_604626, "Version", newJString(Version))
  add(query_604626, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604625.call(nil, query_604626, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604608(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604609, base: "/",
    url: url_GetDownloadDBLogFilePortion_604610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604664 = ref object of OpenApiRestCall_602450
proc url_PostListTagsForResource_604666(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604667 = query.getOrDefault("Action")
  valid_604667 = validateParameter(valid_604667, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604667 != nil:
    section.add "Action", valid_604667
  var valid_604668 = query.getOrDefault("Version")
  valid_604668 = validateParameter(valid_604668, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604668 != nil:
    section.add "Version", valid_604668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604669 = header.getOrDefault("X-Amz-Date")
  valid_604669 = validateParameter(valid_604669, JString, required = false,
                                 default = nil)
  if valid_604669 != nil:
    section.add "X-Amz-Date", valid_604669
  var valid_604670 = header.getOrDefault("X-Amz-Security-Token")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "X-Amz-Security-Token", valid_604670
  var valid_604671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "X-Amz-Content-Sha256", valid_604671
  var valid_604672 = header.getOrDefault("X-Amz-Algorithm")
  valid_604672 = validateParameter(valid_604672, JString, required = false,
                                 default = nil)
  if valid_604672 != nil:
    section.add "X-Amz-Algorithm", valid_604672
  var valid_604673 = header.getOrDefault("X-Amz-Signature")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Signature", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-SignedHeaders", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-Credential")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Credential", valid_604675
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_604676 = formData.getOrDefault("Filters")
  valid_604676 = validateParameter(valid_604676, JArray, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "Filters", valid_604676
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604677 = formData.getOrDefault("ResourceName")
  valid_604677 = validateParameter(valid_604677, JString, required = true,
                                 default = nil)
  if valid_604677 != nil:
    section.add "ResourceName", valid_604677
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604678: Call_PostListTagsForResource_604664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604678.validator(path, query, header, formData, body)
  let scheme = call_604678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604678.url(scheme.get, call_604678.host, call_604678.base,
                         call_604678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604678, url, valid)

proc call*(call_604679: Call_PostListTagsForResource_604664; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604680 = newJObject()
  var formData_604681 = newJObject()
  add(query_604680, "Action", newJString(Action))
  if Filters != nil:
    formData_604681.add "Filters", Filters
  add(formData_604681, "ResourceName", newJString(ResourceName))
  add(query_604680, "Version", newJString(Version))
  result = call_604679.call(nil, query_604680, nil, formData_604681, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604664(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604665, base: "/",
    url: url_PostListTagsForResource_604666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604647 = ref object of OpenApiRestCall_602450
proc url_GetListTagsForResource_604649(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604648(path: JsonNode; query: JsonNode;
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
  var valid_604650 = query.getOrDefault("Filters")
  valid_604650 = validateParameter(valid_604650, JArray, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "Filters", valid_604650
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604651 = query.getOrDefault("ResourceName")
  valid_604651 = validateParameter(valid_604651, JString, required = true,
                                 default = nil)
  if valid_604651 != nil:
    section.add "ResourceName", valid_604651
  var valid_604652 = query.getOrDefault("Action")
  valid_604652 = validateParameter(valid_604652, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604652 != nil:
    section.add "Action", valid_604652
  var valid_604653 = query.getOrDefault("Version")
  valid_604653 = validateParameter(valid_604653, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604653 != nil:
    section.add "Version", valid_604653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604654 = header.getOrDefault("X-Amz-Date")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Date", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-Security-Token")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-Security-Token", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Content-Sha256", valid_604656
  var valid_604657 = header.getOrDefault("X-Amz-Algorithm")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "X-Amz-Algorithm", valid_604657
  var valid_604658 = header.getOrDefault("X-Amz-Signature")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Signature", valid_604658
  var valid_604659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "X-Amz-SignedHeaders", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-Credential")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Credential", valid_604660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604661: Call_GetListTagsForResource_604647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604661.validator(path, query, header, formData, body)
  let scheme = call_604661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604661.url(scheme.get, call_604661.host, call_604661.base,
                         call_604661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604661, url, valid)

proc call*(call_604662: Call_GetListTagsForResource_604647; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604663 = newJObject()
  if Filters != nil:
    query_604663.add "Filters", Filters
  add(query_604663, "ResourceName", newJString(ResourceName))
  add(query_604663, "Action", newJString(Action))
  add(query_604663, "Version", newJString(Version))
  result = call_604662.call(nil, query_604663, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604647(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604648, base: "/",
    url: url_GetListTagsForResource_604649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604718 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBInstance_604720(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_604719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604721 = query.getOrDefault("Action")
  valid_604721 = validateParameter(valid_604721, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604721 != nil:
    section.add "Action", valid_604721
  var valid_604722 = query.getOrDefault("Version")
  valid_604722 = validateParameter(valid_604722, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604722 != nil:
    section.add "Version", valid_604722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604723 = header.getOrDefault("X-Amz-Date")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Date", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Security-Token")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Security-Token", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Content-Sha256", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-Algorithm")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-Algorithm", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Signature")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Signature", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-SignedHeaders", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-Credential")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Credential", valid_604729
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
  var valid_604730 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "PreferredMaintenanceWindow", valid_604730
  var valid_604731 = formData.getOrDefault("DBSecurityGroups")
  valid_604731 = validateParameter(valid_604731, JArray, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "DBSecurityGroups", valid_604731
  var valid_604732 = formData.getOrDefault("ApplyImmediately")
  valid_604732 = validateParameter(valid_604732, JBool, required = false, default = nil)
  if valid_604732 != nil:
    section.add "ApplyImmediately", valid_604732
  var valid_604733 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604733 = validateParameter(valid_604733, JArray, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "VpcSecurityGroupIds", valid_604733
  var valid_604734 = formData.getOrDefault("Iops")
  valid_604734 = validateParameter(valid_604734, JInt, required = false, default = nil)
  if valid_604734 != nil:
    section.add "Iops", valid_604734
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604735 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604735 = validateParameter(valid_604735, JString, required = true,
                                 default = nil)
  if valid_604735 != nil:
    section.add "DBInstanceIdentifier", valid_604735
  var valid_604736 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604736 = validateParameter(valid_604736, JInt, required = false, default = nil)
  if valid_604736 != nil:
    section.add "BackupRetentionPeriod", valid_604736
  var valid_604737 = formData.getOrDefault("DBParameterGroupName")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "DBParameterGroupName", valid_604737
  var valid_604738 = formData.getOrDefault("OptionGroupName")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "OptionGroupName", valid_604738
  var valid_604739 = formData.getOrDefault("MasterUserPassword")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "MasterUserPassword", valid_604739
  var valid_604740 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "NewDBInstanceIdentifier", valid_604740
  var valid_604741 = formData.getOrDefault("TdeCredentialArn")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "TdeCredentialArn", valid_604741
  var valid_604742 = formData.getOrDefault("TdeCredentialPassword")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "TdeCredentialPassword", valid_604742
  var valid_604743 = formData.getOrDefault("MultiAZ")
  valid_604743 = validateParameter(valid_604743, JBool, required = false, default = nil)
  if valid_604743 != nil:
    section.add "MultiAZ", valid_604743
  var valid_604744 = formData.getOrDefault("AllocatedStorage")
  valid_604744 = validateParameter(valid_604744, JInt, required = false, default = nil)
  if valid_604744 != nil:
    section.add "AllocatedStorage", valid_604744
  var valid_604745 = formData.getOrDefault("StorageType")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "StorageType", valid_604745
  var valid_604746 = formData.getOrDefault("DBInstanceClass")
  valid_604746 = validateParameter(valid_604746, JString, required = false,
                                 default = nil)
  if valid_604746 != nil:
    section.add "DBInstanceClass", valid_604746
  var valid_604747 = formData.getOrDefault("PreferredBackupWindow")
  valid_604747 = validateParameter(valid_604747, JString, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "PreferredBackupWindow", valid_604747
  var valid_604748 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604748 = validateParameter(valid_604748, JBool, required = false, default = nil)
  if valid_604748 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604748
  var valid_604749 = formData.getOrDefault("EngineVersion")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "EngineVersion", valid_604749
  var valid_604750 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604750 = validateParameter(valid_604750, JBool, required = false, default = nil)
  if valid_604750 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604751: Call_PostModifyDBInstance_604718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604751.validator(path, query, header, formData, body)
  let scheme = call_604751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604751.url(scheme.get, call_604751.host, call_604751.base,
                         call_604751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604751, url, valid)

proc call*(call_604752: Call_PostModifyDBInstance_604718;
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
  var query_604753 = newJObject()
  var formData_604754 = newJObject()
  add(formData_604754, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604754.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604754, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604754.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604754, "Iops", newJInt(Iops))
  add(formData_604754, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604754, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604754, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604754, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604754, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604754, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604754, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_604754, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_604754, "MultiAZ", newJBool(MultiAZ))
  add(query_604753, "Action", newJString(Action))
  add(formData_604754, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604754, "StorageType", newJString(StorageType))
  add(formData_604754, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604754, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604754, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604754, "EngineVersion", newJString(EngineVersion))
  add(query_604753, "Version", newJString(Version))
  add(formData_604754, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604752.call(nil, query_604753, nil, formData_604754, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604718(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604719, base: "/",
    url: url_PostModifyDBInstance_604720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604682 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBInstance_604684(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_604683(path: JsonNode; query: JsonNode;
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
  var valid_604685 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604685 = validateParameter(valid_604685, JString, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "PreferredMaintenanceWindow", valid_604685
  var valid_604686 = query.getOrDefault("AllocatedStorage")
  valid_604686 = validateParameter(valid_604686, JInt, required = false, default = nil)
  if valid_604686 != nil:
    section.add "AllocatedStorage", valid_604686
  var valid_604687 = query.getOrDefault("StorageType")
  valid_604687 = validateParameter(valid_604687, JString, required = false,
                                 default = nil)
  if valid_604687 != nil:
    section.add "StorageType", valid_604687
  var valid_604688 = query.getOrDefault("OptionGroupName")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "OptionGroupName", valid_604688
  var valid_604689 = query.getOrDefault("DBSecurityGroups")
  valid_604689 = validateParameter(valid_604689, JArray, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "DBSecurityGroups", valid_604689
  var valid_604690 = query.getOrDefault("MasterUserPassword")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "MasterUserPassword", valid_604690
  var valid_604691 = query.getOrDefault("Iops")
  valid_604691 = validateParameter(valid_604691, JInt, required = false, default = nil)
  if valid_604691 != nil:
    section.add "Iops", valid_604691
  var valid_604692 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604692 = validateParameter(valid_604692, JArray, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "VpcSecurityGroupIds", valid_604692
  var valid_604693 = query.getOrDefault("MultiAZ")
  valid_604693 = validateParameter(valid_604693, JBool, required = false, default = nil)
  if valid_604693 != nil:
    section.add "MultiAZ", valid_604693
  var valid_604694 = query.getOrDefault("TdeCredentialPassword")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "TdeCredentialPassword", valid_604694
  var valid_604695 = query.getOrDefault("BackupRetentionPeriod")
  valid_604695 = validateParameter(valid_604695, JInt, required = false, default = nil)
  if valid_604695 != nil:
    section.add "BackupRetentionPeriod", valid_604695
  var valid_604696 = query.getOrDefault("DBParameterGroupName")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "DBParameterGroupName", valid_604696
  var valid_604697 = query.getOrDefault("DBInstanceClass")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "DBInstanceClass", valid_604697
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604698 = query.getOrDefault("Action")
  valid_604698 = validateParameter(valid_604698, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604698 != nil:
    section.add "Action", valid_604698
  var valid_604699 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604699 = validateParameter(valid_604699, JBool, required = false, default = nil)
  if valid_604699 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604699
  var valid_604700 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "NewDBInstanceIdentifier", valid_604700
  var valid_604701 = query.getOrDefault("TdeCredentialArn")
  valid_604701 = validateParameter(valid_604701, JString, required = false,
                                 default = nil)
  if valid_604701 != nil:
    section.add "TdeCredentialArn", valid_604701
  var valid_604702 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604702 = validateParameter(valid_604702, JBool, required = false, default = nil)
  if valid_604702 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604702
  var valid_604703 = query.getOrDefault("EngineVersion")
  valid_604703 = validateParameter(valid_604703, JString, required = false,
                                 default = nil)
  if valid_604703 != nil:
    section.add "EngineVersion", valid_604703
  var valid_604704 = query.getOrDefault("PreferredBackupWindow")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "PreferredBackupWindow", valid_604704
  var valid_604705 = query.getOrDefault("Version")
  valid_604705 = validateParameter(valid_604705, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604705 != nil:
    section.add "Version", valid_604705
  var valid_604706 = query.getOrDefault("DBInstanceIdentifier")
  valid_604706 = validateParameter(valid_604706, JString, required = true,
                                 default = nil)
  if valid_604706 != nil:
    section.add "DBInstanceIdentifier", valid_604706
  var valid_604707 = query.getOrDefault("ApplyImmediately")
  valid_604707 = validateParameter(valid_604707, JBool, required = false, default = nil)
  if valid_604707 != nil:
    section.add "ApplyImmediately", valid_604707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604708 = header.getOrDefault("X-Amz-Date")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Date", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Security-Token")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Security-Token", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Content-Sha256", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-Algorithm")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-Algorithm", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Signature")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Signature", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-SignedHeaders", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Credential")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Credential", valid_604714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604715: Call_GetModifyDBInstance_604682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604715.validator(path, query, header, formData, body)
  let scheme = call_604715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604715.url(scheme.get, call_604715.host, call_604715.base,
                         call_604715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604715, url, valid)

proc call*(call_604716: Call_GetModifyDBInstance_604682;
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
  var query_604717 = newJObject()
  add(query_604717, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604717, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604717, "StorageType", newJString(StorageType))
  add(query_604717, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604717.add "DBSecurityGroups", DBSecurityGroups
  add(query_604717, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604717, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604717.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604717, "MultiAZ", newJBool(MultiAZ))
  add(query_604717, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_604717, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604717, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604717, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604717, "Action", newJString(Action))
  add(query_604717, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604717, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604717, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_604717, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604717, "EngineVersion", newJString(EngineVersion))
  add(query_604717, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604717, "Version", newJString(Version))
  add(query_604717, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604717, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604716.call(nil, query_604717, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604682(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604683, base: "/",
    url: url_GetModifyDBInstance_604684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604772 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBParameterGroup_604774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_604773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604775 = query.getOrDefault("Action")
  valid_604775 = validateParameter(valid_604775, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604775 != nil:
    section.add "Action", valid_604775
  var valid_604776 = query.getOrDefault("Version")
  valid_604776 = validateParameter(valid_604776, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604776 != nil:
    section.add "Version", valid_604776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604777 = header.getOrDefault("X-Amz-Date")
  valid_604777 = validateParameter(valid_604777, JString, required = false,
                                 default = nil)
  if valid_604777 != nil:
    section.add "X-Amz-Date", valid_604777
  var valid_604778 = header.getOrDefault("X-Amz-Security-Token")
  valid_604778 = validateParameter(valid_604778, JString, required = false,
                                 default = nil)
  if valid_604778 != nil:
    section.add "X-Amz-Security-Token", valid_604778
  var valid_604779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604779 = validateParameter(valid_604779, JString, required = false,
                                 default = nil)
  if valid_604779 != nil:
    section.add "X-Amz-Content-Sha256", valid_604779
  var valid_604780 = header.getOrDefault("X-Amz-Algorithm")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Algorithm", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-Signature")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-Signature", valid_604781
  var valid_604782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604782 = validateParameter(valid_604782, JString, required = false,
                                 default = nil)
  if valid_604782 != nil:
    section.add "X-Amz-SignedHeaders", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Credential")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Credential", valid_604783
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604784 = formData.getOrDefault("DBParameterGroupName")
  valid_604784 = validateParameter(valid_604784, JString, required = true,
                                 default = nil)
  if valid_604784 != nil:
    section.add "DBParameterGroupName", valid_604784
  var valid_604785 = formData.getOrDefault("Parameters")
  valid_604785 = validateParameter(valid_604785, JArray, required = true, default = nil)
  if valid_604785 != nil:
    section.add "Parameters", valid_604785
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604786: Call_PostModifyDBParameterGroup_604772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604786.validator(path, query, header, formData, body)
  let scheme = call_604786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604786.url(scheme.get, call_604786.host, call_604786.base,
                         call_604786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604786, url, valid)

proc call*(call_604787: Call_PostModifyDBParameterGroup_604772;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604788 = newJObject()
  var formData_604789 = newJObject()
  add(formData_604789, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604789.add "Parameters", Parameters
  add(query_604788, "Action", newJString(Action))
  add(query_604788, "Version", newJString(Version))
  result = call_604787.call(nil, query_604788, nil, formData_604789, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604772(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604773, base: "/",
    url: url_PostModifyDBParameterGroup_604774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604755 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBParameterGroup_604757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_604756(path: JsonNode; query: JsonNode;
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
  var valid_604758 = query.getOrDefault("DBParameterGroupName")
  valid_604758 = validateParameter(valid_604758, JString, required = true,
                                 default = nil)
  if valid_604758 != nil:
    section.add "DBParameterGroupName", valid_604758
  var valid_604759 = query.getOrDefault("Parameters")
  valid_604759 = validateParameter(valid_604759, JArray, required = true, default = nil)
  if valid_604759 != nil:
    section.add "Parameters", valid_604759
  var valid_604760 = query.getOrDefault("Action")
  valid_604760 = validateParameter(valid_604760, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604760 != nil:
    section.add "Action", valid_604760
  var valid_604761 = query.getOrDefault("Version")
  valid_604761 = validateParameter(valid_604761, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604761 != nil:
    section.add "Version", valid_604761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604762 = header.getOrDefault("X-Amz-Date")
  valid_604762 = validateParameter(valid_604762, JString, required = false,
                                 default = nil)
  if valid_604762 != nil:
    section.add "X-Amz-Date", valid_604762
  var valid_604763 = header.getOrDefault("X-Amz-Security-Token")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "X-Amz-Security-Token", valid_604763
  var valid_604764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "X-Amz-Content-Sha256", valid_604764
  var valid_604765 = header.getOrDefault("X-Amz-Algorithm")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Algorithm", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Signature")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Signature", valid_604766
  var valid_604767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "X-Amz-SignedHeaders", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Credential")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Credential", valid_604768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604769: Call_GetModifyDBParameterGroup_604755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604769.validator(path, query, header, formData, body)
  let scheme = call_604769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604769.url(scheme.get, call_604769.host, call_604769.base,
                         call_604769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604769, url, valid)

proc call*(call_604770: Call_GetModifyDBParameterGroup_604755;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604771 = newJObject()
  add(query_604771, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604771.add "Parameters", Parameters
  add(query_604771, "Action", newJString(Action))
  add(query_604771, "Version", newJString(Version))
  result = call_604770.call(nil, query_604771, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604755(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604756, base: "/",
    url: url_GetModifyDBParameterGroup_604757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604808 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBSubnetGroup_604810(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_604809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604811 = query.getOrDefault("Action")
  valid_604811 = validateParameter(valid_604811, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604811 != nil:
    section.add "Action", valid_604811
  var valid_604812 = query.getOrDefault("Version")
  valid_604812 = validateParameter(valid_604812, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604812 != nil:
    section.add "Version", valid_604812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604813 = header.getOrDefault("X-Amz-Date")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Date", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Security-Token")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Security-Token", valid_604814
  var valid_604815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604815 = validateParameter(valid_604815, JString, required = false,
                                 default = nil)
  if valid_604815 != nil:
    section.add "X-Amz-Content-Sha256", valid_604815
  var valid_604816 = header.getOrDefault("X-Amz-Algorithm")
  valid_604816 = validateParameter(valid_604816, JString, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "X-Amz-Algorithm", valid_604816
  var valid_604817 = header.getOrDefault("X-Amz-Signature")
  valid_604817 = validateParameter(valid_604817, JString, required = false,
                                 default = nil)
  if valid_604817 != nil:
    section.add "X-Amz-Signature", valid_604817
  var valid_604818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604818 = validateParameter(valid_604818, JString, required = false,
                                 default = nil)
  if valid_604818 != nil:
    section.add "X-Amz-SignedHeaders", valid_604818
  var valid_604819 = header.getOrDefault("X-Amz-Credential")
  valid_604819 = validateParameter(valid_604819, JString, required = false,
                                 default = nil)
  if valid_604819 != nil:
    section.add "X-Amz-Credential", valid_604819
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604820 = formData.getOrDefault("DBSubnetGroupName")
  valid_604820 = validateParameter(valid_604820, JString, required = true,
                                 default = nil)
  if valid_604820 != nil:
    section.add "DBSubnetGroupName", valid_604820
  var valid_604821 = formData.getOrDefault("SubnetIds")
  valid_604821 = validateParameter(valid_604821, JArray, required = true, default = nil)
  if valid_604821 != nil:
    section.add "SubnetIds", valid_604821
  var valid_604822 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604822 = validateParameter(valid_604822, JString, required = false,
                                 default = nil)
  if valid_604822 != nil:
    section.add "DBSubnetGroupDescription", valid_604822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604823: Call_PostModifyDBSubnetGroup_604808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604823.validator(path, query, header, formData, body)
  let scheme = call_604823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604823.url(scheme.get, call_604823.host, call_604823.base,
                         call_604823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604823, url, valid)

proc call*(call_604824: Call_PostModifyDBSubnetGroup_604808;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604825 = newJObject()
  var formData_604826 = newJObject()
  add(formData_604826, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604826.add "SubnetIds", SubnetIds
  add(query_604825, "Action", newJString(Action))
  add(formData_604826, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604825, "Version", newJString(Version))
  result = call_604824.call(nil, query_604825, nil, formData_604826, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604808(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604809, base: "/",
    url: url_PostModifyDBSubnetGroup_604810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604790 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBSubnetGroup_604792(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_604791(path: JsonNode; query: JsonNode;
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
  var valid_604793 = query.getOrDefault("Action")
  valid_604793 = validateParameter(valid_604793, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604793 != nil:
    section.add "Action", valid_604793
  var valid_604794 = query.getOrDefault("DBSubnetGroupName")
  valid_604794 = validateParameter(valid_604794, JString, required = true,
                                 default = nil)
  if valid_604794 != nil:
    section.add "DBSubnetGroupName", valid_604794
  var valid_604795 = query.getOrDefault("SubnetIds")
  valid_604795 = validateParameter(valid_604795, JArray, required = true, default = nil)
  if valid_604795 != nil:
    section.add "SubnetIds", valid_604795
  var valid_604796 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "DBSubnetGroupDescription", valid_604796
  var valid_604797 = query.getOrDefault("Version")
  valid_604797 = validateParameter(valid_604797, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604797 != nil:
    section.add "Version", valid_604797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604798 = header.getOrDefault("X-Amz-Date")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Date", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Security-Token")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Security-Token", valid_604799
  var valid_604800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "X-Amz-Content-Sha256", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-Algorithm")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-Algorithm", valid_604801
  var valid_604802 = header.getOrDefault("X-Amz-Signature")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Signature", valid_604802
  var valid_604803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604803 = validateParameter(valid_604803, JString, required = false,
                                 default = nil)
  if valid_604803 != nil:
    section.add "X-Amz-SignedHeaders", valid_604803
  var valid_604804 = header.getOrDefault("X-Amz-Credential")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "X-Amz-Credential", valid_604804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604805: Call_GetModifyDBSubnetGroup_604790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604805.validator(path, query, header, formData, body)
  let scheme = call_604805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604805.url(scheme.get, call_604805.host, call_604805.base,
                         call_604805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604805, url, valid)

proc call*(call_604806: Call_GetModifyDBSubnetGroup_604790;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604807 = newJObject()
  add(query_604807, "Action", newJString(Action))
  add(query_604807, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604807.add "SubnetIds", SubnetIds
  add(query_604807, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604807, "Version", newJString(Version))
  result = call_604806.call(nil, query_604807, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604790(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604791, base: "/",
    url: url_GetModifyDBSubnetGroup_604792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604847 = ref object of OpenApiRestCall_602450
proc url_PostModifyEventSubscription_604849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_604848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604850 = query.getOrDefault("Action")
  valid_604850 = validateParameter(valid_604850, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604850 != nil:
    section.add "Action", valid_604850
  var valid_604851 = query.getOrDefault("Version")
  valid_604851 = validateParameter(valid_604851, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604851 != nil:
    section.add "Version", valid_604851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604852 = header.getOrDefault("X-Amz-Date")
  valid_604852 = validateParameter(valid_604852, JString, required = false,
                                 default = nil)
  if valid_604852 != nil:
    section.add "X-Amz-Date", valid_604852
  var valid_604853 = header.getOrDefault("X-Amz-Security-Token")
  valid_604853 = validateParameter(valid_604853, JString, required = false,
                                 default = nil)
  if valid_604853 != nil:
    section.add "X-Amz-Security-Token", valid_604853
  var valid_604854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604854 = validateParameter(valid_604854, JString, required = false,
                                 default = nil)
  if valid_604854 != nil:
    section.add "X-Amz-Content-Sha256", valid_604854
  var valid_604855 = header.getOrDefault("X-Amz-Algorithm")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Algorithm", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Signature")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Signature", valid_604856
  var valid_604857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-SignedHeaders", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Credential")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Credential", valid_604858
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604859 = formData.getOrDefault("Enabled")
  valid_604859 = validateParameter(valid_604859, JBool, required = false, default = nil)
  if valid_604859 != nil:
    section.add "Enabled", valid_604859
  var valid_604860 = formData.getOrDefault("EventCategories")
  valid_604860 = validateParameter(valid_604860, JArray, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "EventCategories", valid_604860
  var valid_604861 = formData.getOrDefault("SnsTopicArn")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "SnsTopicArn", valid_604861
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604862 = formData.getOrDefault("SubscriptionName")
  valid_604862 = validateParameter(valid_604862, JString, required = true,
                                 default = nil)
  if valid_604862 != nil:
    section.add "SubscriptionName", valid_604862
  var valid_604863 = formData.getOrDefault("SourceType")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "SourceType", valid_604863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604864: Call_PostModifyEventSubscription_604847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604864.validator(path, query, header, formData, body)
  let scheme = call_604864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604864.url(scheme.get, call_604864.host, call_604864.base,
                         call_604864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604864, url, valid)

proc call*(call_604865: Call_PostModifyEventSubscription_604847;
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
  var query_604866 = newJObject()
  var formData_604867 = newJObject()
  add(formData_604867, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604867.add "EventCategories", EventCategories
  add(formData_604867, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604867, "SubscriptionName", newJString(SubscriptionName))
  add(query_604866, "Action", newJString(Action))
  add(query_604866, "Version", newJString(Version))
  add(formData_604867, "SourceType", newJString(SourceType))
  result = call_604865.call(nil, query_604866, nil, formData_604867, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604847(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604848, base: "/",
    url: url_PostModifyEventSubscription_604849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604827 = ref object of OpenApiRestCall_602450
proc url_GetModifyEventSubscription_604829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_604828(path: JsonNode; query: JsonNode;
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
  var valid_604830 = query.getOrDefault("SourceType")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "SourceType", valid_604830
  var valid_604831 = query.getOrDefault("Enabled")
  valid_604831 = validateParameter(valid_604831, JBool, required = false, default = nil)
  if valid_604831 != nil:
    section.add "Enabled", valid_604831
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604832 = query.getOrDefault("Action")
  valid_604832 = validateParameter(valid_604832, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604832 != nil:
    section.add "Action", valid_604832
  var valid_604833 = query.getOrDefault("SnsTopicArn")
  valid_604833 = validateParameter(valid_604833, JString, required = false,
                                 default = nil)
  if valid_604833 != nil:
    section.add "SnsTopicArn", valid_604833
  var valid_604834 = query.getOrDefault("EventCategories")
  valid_604834 = validateParameter(valid_604834, JArray, required = false,
                                 default = nil)
  if valid_604834 != nil:
    section.add "EventCategories", valid_604834
  var valid_604835 = query.getOrDefault("SubscriptionName")
  valid_604835 = validateParameter(valid_604835, JString, required = true,
                                 default = nil)
  if valid_604835 != nil:
    section.add "SubscriptionName", valid_604835
  var valid_604836 = query.getOrDefault("Version")
  valid_604836 = validateParameter(valid_604836, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604836 != nil:
    section.add "Version", valid_604836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604837 = header.getOrDefault("X-Amz-Date")
  valid_604837 = validateParameter(valid_604837, JString, required = false,
                                 default = nil)
  if valid_604837 != nil:
    section.add "X-Amz-Date", valid_604837
  var valid_604838 = header.getOrDefault("X-Amz-Security-Token")
  valid_604838 = validateParameter(valid_604838, JString, required = false,
                                 default = nil)
  if valid_604838 != nil:
    section.add "X-Amz-Security-Token", valid_604838
  var valid_604839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604839 = validateParameter(valid_604839, JString, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "X-Amz-Content-Sha256", valid_604839
  var valid_604840 = header.getOrDefault("X-Amz-Algorithm")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Algorithm", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Signature")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Signature", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-SignedHeaders", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Credential")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Credential", valid_604843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604844: Call_GetModifyEventSubscription_604827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604844.validator(path, query, header, formData, body)
  let scheme = call_604844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604844.url(scheme.get, call_604844.host, call_604844.base,
                         call_604844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604844, url, valid)

proc call*(call_604845: Call_GetModifyEventSubscription_604827;
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
  var query_604846 = newJObject()
  add(query_604846, "SourceType", newJString(SourceType))
  add(query_604846, "Enabled", newJBool(Enabled))
  add(query_604846, "Action", newJString(Action))
  add(query_604846, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604846.add "EventCategories", EventCategories
  add(query_604846, "SubscriptionName", newJString(SubscriptionName))
  add(query_604846, "Version", newJString(Version))
  result = call_604845.call(nil, query_604846, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604827(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604828, base: "/",
    url: url_GetModifyEventSubscription_604829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604887 = ref object of OpenApiRestCall_602450
proc url_PostModifyOptionGroup_604889(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_604888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("ModifyOptionGroup"))
  if valid_604890 != nil:
    section.add "Action", valid_604890
  var valid_604891 = query.getOrDefault("Version")
  valid_604891 = validateParameter(valid_604891, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604899 = formData.getOrDefault("OptionsToRemove")
  valid_604899 = validateParameter(valid_604899, JArray, required = false,
                                 default = nil)
  if valid_604899 != nil:
    section.add "OptionsToRemove", valid_604899
  var valid_604900 = formData.getOrDefault("ApplyImmediately")
  valid_604900 = validateParameter(valid_604900, JBool, required = false, default = nil)
  if valid_604900 != nil:
    section.add "ApplyImmediately", valid_604900
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604901 = formData.getOrDefault("OptionGroupName")
  valid_604901 = validateParameter(valid_604901, JString, required = true,
                                 default = nil)
  if valid_604901 != nil:
    section.add "OptionGroupName", valid_604901
  var valid_604902 = formData.getOrDefault("OptionsToInclude")
  valid_604902 = validateParameter(valid_604902, JArray, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "OptionsToInclude", valid_604902
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604903: Call_PostModifyOptionGroup_604887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604903.validator(path, query, header, formData, body)
  let scheme = call_604903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604903.url(scheme.get, call_604903.host, call_604903.base,
                         call_604903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604903, url, valid)

proc call*(call_604904: Call_PostModifyOptionGroup_604887; OptionGroupName: string;
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
  var query_604905 = newJObject()
  var formData_604906 = newJObject()
  if OptionsToRemove != nil:
    formData_604906.add "OptionsToRemove", OptionsToRemove
  add(formData_604906, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604906, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604906.add "OptionsToInclude", OptionsToInclude
  add(query_604905, "Action", newJString(Action))
  add(query_604905, "Version", newJString(Version))
  result = call_604904.call(nil, query_604905, nil, formData_604906, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604887(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604888, base: "/",
    url: url_PostModifyOptionGroup_604889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604868 = ref object of OpenApiRestCall_602450
proc url_GetModifyOptionGroup_604870(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_604869(path: JsonNode; query: JsonNode;
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
  var valid_604871 = query.getOrDefault("OptionGroupName")
  valid_604871 = validateParameter(valid_604871, JString, required = true,
                                 default = nil)
  if valid_604871 != nil:
    section.add "OptionGroupName", valid_604871
  var valid_604872 = query.getOrDefault("OptionsToRemove")
  valid_604872 = validateParameter(valid_604872, JArray, required = false,
                                 default = nil)
  if valid_604872 != nil:
    section.add "OptionsToRemove", valid_604872
  var valid_604873 = query.getOrDefault("Action")
  valid_604873 = validateParameter(valid_604873, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604873 != nil:
    section.add "Action", valid_604873
  var valid_604874 = query.getOrDefault("Version")
  valid_604874 = validateParameter(valid_604874, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604874 != nil:
    section.add "Version", valid_604874
  var valid_604875 = query.getOrDefault("ApplyImmediately")
  valid_604875 = validateParameter(valid_604875, JBool, required = false, default = nil)
  if valid_604875 != nil:
    section.add "ApplyImmediately", valid_604875
  var valid_604876 = query.getOrDefault("OptionsToInclude")
  valid_604876 = validateParameter(valid_604876, JArray, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "OptionsToInclude", valid_604876
  result.add "query", section
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

proc call*(call_604884: Call_GetModifyOptionGroup_604868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604884.validator(path, query, header, formData, body)
  let scheme = call_604884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604884.url(scheme.get, call_604884.host, call_604884.base,
                         call_604884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604884, url, valid)

proc call*(call_604885: Call_GetModifyOptionGroup_604868; OptionGroupName: string;
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
  var query_604886 = newJObject()
  add(query_604886, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604886.add "OptionsToRemove", OptionsToRemove
  add(query_604886, "Action", newJString(Action))
  add(query_604886, "Version", newJString(Version))
  add(query_604886, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604886.add "OptionsToInclude", OptionsToInclude
  result = call_604885.call(nil, query_604886, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604868(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604869, base: "/",
    url: url_GetModifyOptionGroup_604870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604925 = ref object of OpenApiRestCall_602450
proc url_PostPromoteReadReplica_604927(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_604926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604928 = query.getOrDefault("Action")
  valid_604928 = validateParameter(valid_604928, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604928 != nil:
    section.add "Action", valid_604928
  var valid_604929 = query.getOrDefault("Version")
  valid_604929 = validateParameter(valid_604929, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604929 != nil:
    section.add "Version", valid_604929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604930 = header.getOrDefault("X-Amz-Date")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Date", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Security-Token")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Security-Token", valid_604931
  var valid_604932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604932 = validateParameter(valid_604932, JString, required = false,
                                 default = nil)
  if valid_604932 != nil:
    section.add "X-Amz-Content-Sha256", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-Algorithm")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Algorithm", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Signature")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Signature", valid_604934
  var valid_604935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-SignedHeaders", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-Credential")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-Credential", valid_604936
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604937 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604937 = validateParameter(valid_604937, JString, required = true,
                                 default = nil)
  if valid_604937 != nil:
    section.add "DBInstanceIdentifier", valid_604937
  var valid_604938 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604938 = validateParameter(valid_604938, JInt, required = false, default = nil)
  if valid_604938 != nil:
    section.add "BackupRetentionPeriod", valid_604938
  var valid_604939 = formData.getOrDefault("PreferredBackupWindow")
  valid_604939 = validateParameter(valid_604939, JString, required = false,
                                 default = nil)
  if valid_604939 != nil:
    section.add "PreferredBackupWindow", valid_604939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604940: Call_PostPromoteReadReplica_604925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604940.validator(path, query, header, formData, body)
  let scheme = call_604940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604940.url(scheme.get, call_604940.host, call_604940.base,
                         call_604940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604940, url, valid)

proc call*(call_604941: Call_PostPromoteReadReplica_604925;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604942 = newJObject()
  var formData_604943 = newJObject()
  add(formData_604943, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604943, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604942, "Action", newJString(Action))
  add(formData_604943, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604942, "Version", newJString(Version))
  result = call_604941.call(nil, query_604942, nil, formData_604943, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604925(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604926, base: "/",
    url: url_PostPromoteReadReplica_604927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604907 = ref object of OpenApiRestCall_602450
proc url_GetPromoteReadReplica_604909(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_604908(path: JsonNode; query: JsonNode;
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
  var valid_604910 = query.getOrDefault("BackupRetentionPeriod")
  valid_604910 = validateParameter(valid_604910, JInt, required = false, default = nil)
  if valid_604910 != nil:
    section.add "BackupRetentionPeriod", valid_604910
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604911 = query.getOrDefault("Action")
  valid_604911 = validateParameter(valid_604911, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604911 != nil:
    section.add "Action", valid_604911
  var valid_604912 = query.getOrDefault("PreferredBackupWindow")
  valid_604912 = validateParameter(valid_604912, JString, required = false,
                                 default = nil)
  if valid_604912 != nil:
    section.add "PreferredBackupWindow", valid_604912
  var valid_604913 = query.getOrDefault("Version")
  valid_604913 = validateParameter(valid_604913, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604913 != nil:
    section.add "Version", valid_604913
  var valid_604914 = query.getOrDefault("DBInstanceIdentifier")
  valid_604914 = validateParameter(valid_604914, JString, required = true,
                                 default = nil)
  if valid_604914 != nil:
    section.add "DBInstanceIdentifier", valid_604914
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604922: Call_GetPromoteReadReplica_604907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604922.validator(path, query, header, formData, body)
  let scheme = call_604922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604922.url(scheme.get, call_604922.host, call_604922.base,
                         call_604922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604922, url, valid)

proc call*(call_604923: Call_GetPromoteReadReplica_604907;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604924 = newJObject()
  add(query_604924, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604924, "Action", newJString(Action))
  add(query_604924, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604924, "Version", newJString(Version))
  add(query_604924, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604923.call(nil, query_604924, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604907(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604908, base: "/",
    url: url_GetPromoteReadReplica_604909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604963 = ref object of OpenApiRestCall_602450
proc url_PostPurchaseReservedDBInstancesOffering_604965(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604964(path: JsonNode;
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
  var valid_604966 = query.getOrDefault("Action")
  valid_604966 = validateParameter(valid_604966, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604966 != nil:
    section.add "Action", valid_604966
  var valid_604967 = query.getOrDefault("Version")
  valid_604967 = validateParameter(valid_604967, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604967 != nil:
    section.add "Version", valid_604967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604968 = header.getOrDefault("X-Amz-Date")
  valid_604968 = validateParameter(valid_604968, JString, required = false,
                                 default = nil)
  if valid_604968 != nil:
    section.add "X-Amz-Date", valid_604968
  var valid_604969 = header.getOrDefault("X-Amz-Security-Token")
  valid_604969 = validateParameter(valid_604969, JString, required = false,
                                 default = nil)
  if valid_604969 != nil:
    section.add "X-Amz-Security-Token", valid_604969
  var valid_604970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604970 = validateParameter(valid_604970, JString, required = false,
                                 default = nil)
  if valid_604970 != nil:
    section.add "X-Amz-Content-Sha256", valid_604970
  var valid_604971 = header.getOrDefault("X-Amz-Algorithm")
  valid_604971 = validateParameter(valid_604971, JString, required = false,
                                 default = nil)
  if valid_604971 != nil:
    section.add "X-Amz-Algorithm", valid_604971
  var valid_604972 = header.getOrDefault("X-Amz-Signature")
  valid_604972 = validateParameter(valid_604972, JString, required = false,
                                 default = nil)
  if valid_604972 != nil:
    section.add "X-Amz-Signature", valid_604972
  var valid_604973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604973 = validateParameter(valid_604973, JString, required = false,
                                 default = nil)
  if valid_604973 != nil:
    section.add "X-Amz-SignedHeaders", valid_604973
  var valid_604974 = header.getOrDefault("X-Amz-Credential")
  valid_604974 = validateParameter(valid_604974, JString, required = false,
                                 default = nil)
  if valid_604974 != nil:
    section.add "X-Amz-Credential", valid_604974
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604975 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "ReservedDBInstanceId", valid_604975
  var valid_604976 = formData.getOrDefault("Tags")
  valid_604976 = validateParameter(valid_604976, JArray, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "Tags", valid_604976
  var valid_604977 = formData.getOrDefault("DBInstanceCount")
  valid_604977 = validateParameter(valid_604977, JInt, required = false, default = nil)
  if valid_604977 != nil:
    section.add "DBInstanceCount", valid_604977
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604978 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604978 = validateParameter(valid_604978, JString, required = true,
                                 default = nil)
  if valid_604978 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604979: Call_PostPurchaseReservedDBInstancesOffering_604963;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604979.validator(path, query, header, formData, body)
  let scheme = call_604979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604979.url(scheme.get, call_604979.host, call_604979.base,
                         call_604979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604979, url, valid)

proc call*(call_604980: Call_PostPurchaseReservedDBInstancesOffering_604963;
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
  var query_604981 = newJObject()
  var formData_604982 = newJObject()
  add(formData_604982, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_604982.add "Tags", Tags
  add(formData_604982, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604981, "Action", newJString(Action))
  add(formData_604982, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604981, "Version", newJString(Version))
  result = call_604980.call(nil, query_604981, nil, formData_604982, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604963(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604964, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604944 = ref object of OpenApiRestCall_602450
proc url_GetPurchaseReservedDBInstancesOffering_604946(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604945(path: JsonNode;
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
  var valid_604947 = query.getOrDefault("DBInstanceCount")
  valid_604947 = validateParameter(valid_604947, JInt, required = false, default = nil)
  if valid_604947 != nil:
    section.add "DBInstanceCount", valid_604947
  var valid_604948 = query.getOrDefault("Tags")
  valid_604948 = validateParameter(valid_604948, JArray, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "Tags", valid_604948
  var valid_604949 = query.getOrDefault("ReservedDBInstanceId")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "ReservedDBInstanceId", valid_604949
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604950 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604950 = validateParameter(valid_604950, JString, required = true,
                                 default = nil)
  if valid_604950 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604950
  var valid_604951 = query.getOrDefault("Action")
  valid_604951 = validateParameter(valid_604951, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604951 != nil:
    section.add "Action", valid_604951
  var valid_604952 = query.getOrDefault("Version")
  valid_604952 = validateParameter(valid_604952, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604952 != nil:
    section.add "Version", valid_604952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604953 = header.getOrDefault("X-Amz-Date")
  valid_604953 = validateParameter(valid_604953, JString, required = false,
                                 default = nil)
  if valid_604953 != nil:
    section.add "X-Amz-Date", valid_604953
  var valid_604954 = header.getOrDefault("X-Amz-Security-Token")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "X-Amz-Security-Token", valid_604954
  var valid_604955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604955 = validateParameter(valid_604955, JString, required = false,
                                 default = nil)
  if valid_604955 != nil:
    section.add "X-Amz-Content-Sha256", valid_604955
  var valid_604956 = header.getOrDefault("X-Amz-Algorithm")
  valid_604956 = validateParameter(valid_604956, JString, required = false,
                                 default = nil)
  if valid_604956 != nil:
    section.add "X-Amz-Algorithm", valid_604956
  var valid_604957 = header.getOrDefault("X-Amz-Signature")
  valid_604957 = validateParameter(valid_604957, JString, required = false,
                                 default = nil)
  if valid_604957 != nil:
    section.add "X-Amz-Signature", valid_604957
  var valid_604958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604958 = validateParameter(valid_604958, JString, required = false,
                                 default = nil)
  if valid_604958 != nil:
    section.add "X-Amz-SignedHeaders", valid_604958
  var valid_604959 = header.getOrDefault("X-Amz-Credential")
  valid_604959 = validateParameter(valid_604959, JString, required = false,
                                 default = nil)
  if valid_604959 != nil:
    section.add "X-Amz-Credential", valid_604959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604960: Call_GetPurchaseReservedDBInstancesOffering_604944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604960.validator(path, query, header, formData, body)
  let scheme = call_604960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604960.url(scheme.get, call_604960.host, call_604960.base,
                         call_604960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604960, url, valid)

proc call*(call_604961: Call_GetPurchaseReservedDBInstancesOffering_604944;
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
  var query_604962 = newJObject()
  add(query_604962, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_604962.add "Tags", Tags
  add(query_604962, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604962, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604962, "Action", newJString(Action))
  add(query_604962, "Version", newJString(Version))
  result = call_604961.call(nil, query_604962, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604944(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604945, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_605000 = ref object of OpenApiRestCall_602450
proc url_PostRebootDBInstance_605002(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_605001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605003 = query.getOrDefault("Action")
  valid_605003 = validateParameter(valid_605003, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_605003 != nil:
    section.add "Action", valid_605003
  var valid_605004 = query.getOrDefault("Version")
  valid_605004 = validateParameter(valid_605004, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605004 != nil:
    section.add "Version", valid_605004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605005 = header.getOrDefault("X-Amz-Date")
  valid_605005 = validateParameter(valid_605005, JString, required = false,
                                 default = nil)
  if valid_605005 != nil:
    section.add "X-Amz-Date", valid_605005
  var valid_605006 = header.getOrDefault("X-Amz-Security-Token")
  valid_605006 = validateParameter(valid_605006, JString, required = false,
                                 default = nil)
  if valid_605006 != nil:
    section.add "X-Amz-Security-Token", valid_605006
  var valid_605007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "X-Amz-Content-Sha256", valid_605007
  var valid_605008 = header.getOrDefault("X-Amz-Algorithm")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "X-Amz-Algorithm", valid_605008
  var valid_605009 = header.getOrDefault("X-Amz-Signature")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-Signature", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-SignedHeaders", valid_605010
  var valid_605011 = header.getOrDefault("X-Amz-Credential")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "X-Amz-Credential", valid_605011
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605012 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605012 = validateParameter(valid_605012, JString, required = true,
                                 default = nil)
  if valid_605012 != nil:
    section.add "DBInstanceIdentifier", valid_605012
  var valid_605013 = formData.getOrDefault("ForceFailover")
  valid_605013 = validateParameter(valid_605013, JBool, required = false, default = nil)
  if valid_605013 != nil:
    section.add "ForceFailover", valid_605013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605014: Call_PostRebootDBInstance_605000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605014.validator(path, query, header, formData, body)
  let scheme = call_605014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605014.url(scheme.get, call_605014.host, call_605014.base,
                         call_605014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605014, url, valid)

proc call*(call_605015: Call_PostRebootDBInstance_605000;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_605016 = newJObject()
  var formData_605017 = newJObject()
  add(formData_605017, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605016, "Action", newJString(Action))
  add(formData_605017, "ForceFailover", newJBool(ForceFailover))
  add(query_605016, "Version", newJString(Version))
  result = call_605015.call(nil, query_605016, nil, formData_605017, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_605000(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_605001, base: "/",
    url: url_PostRebootDBInstance_605002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604983 = ref object of OpenApiRestCall_602450
proc url_GetRebootDBInstance_604985(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_604984(path: JsonNode; query: JsonNode;
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
  var valid_604986 = query.getOrDefault("Action")
  valid_604986 = validateParameter(valid_604986, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604986 != nil:
    section.add "Action", valid_604986
  var valid_604987 = query.getOrDefault("ForceFailover")
  valid_604987 = validateParameter(valid_604987, JBool, required = false, default = nil)
  if valid_604987 != nil:
    section.add "ForceFailover", valid_604987
  var valid_604988 = query.getOrDefault("Version")
  valid_604988 = validateParameter(valid_604988, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604988 != nil:
    section.add "Version", valid_604988
  var valid_604989 = query.getOrDefault("DBInstanceIdentifier")
  valid_604989 = validateParameter(valid_604989, JString, required = true,
                                 default = nil)
  if valid_604989 != nil:
    section.add "DBInstanceIdentifier", valid_604989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604990 = header.getOrDefault("X-Amz-Date")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Date", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-Security-Token")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-Security-Token", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Content-Sha256", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-Algorithm")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-Algorithm", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Signature")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Signature", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-SignedHeaders", valid_604995
  var valid_604996 = header.getOrDefault("X-Amz-Credential")
  valid_604996 = validateParameter(valid_604996, JString, required = false,
                                 default = nil)
  if valid_604996 != nil:
    section.add "X-Amz-Credential", valid_604996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604997: Call_GetRebootDBInstance_604983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604997.validator(path, query, header, formData, body)
  let scheme = call_604997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604997.url(scheme.get, call_604997.host, call_604997.base,
                         call_604997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604997, url, valid)

proc call*(call_604998: Call_GetRebootDBInstance_604983;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604999 = newJObject()
  add(query_604999, "Action", newJString(Action))
  add(query_604999, "ForceFailover", newJBool(ForceFailover))
  add(query_604999, "Version", newJString(Version))
  add(query_604999, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604998.call(nil, query_604999, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604983(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604984, base: "/",
    url: url_GetRebootDBInstance_604985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_605035 = ref object of OpenApiRestCall_602450
proc url_PostRemoveSourceIdentifierFromSubscription_605037(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_605036(path: JsonNode;
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
      "RemoveSourceIdentifierFromSubscription"))
  if valid_605038 != nil:
    section.add "Action", valid_605038
  var valid_605039 = query.getOrDefault("Version")
  valid_605039 = validateParameter(valid_605039, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_605047 = formData.getOrDefault("SourceIdentifier")
  valid_605047 = validateParameter(valid_605047, JString, required = true,
                                 default = nil)
  if valid_605047 != nil:
    section.add "SourceIdentifier", valid_605047
  var valid_605048 = formData.getOrDefault("SubscriptionName")
  valid_605048 = validateParameter(valid_605048, JString, required = true,
                                 default = nil)
  if valid_605048 != nil:
    section.add "SubscriptionName", valid_605048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605049: Call_PostRemoveSourceIdentifierFromSubscription_605035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605049.validator(path, query, header, formData, body)
  let scheme = call_605049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605049.url(scheme.get, call_605049.host, call_605049.base,
                         call_605049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605049, url, valid)

proc call*(call_605050: Call_PostRemoveSourceIdentifierFromSubscription_605035;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_605051 = newJObject()
  var formData_605052 = newJObject()
  add(formData_605052, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_605052, "SubscriptionName", newJString(SubscriptionName))
  add(query_605051, "Action", newJString(Action))
  add(query_605051, "Version", newJString(Version))
  result = call_605050.call(nil, query_605051, nil, formData_605052, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_605035(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_605036,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_605037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_605018 = ref object of OpenApiRestCall_602450
proc url_GetRemoveSourceIdentifierFromSubscription_605020(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_605019(path: JsonNode;
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
  var valid_605021 = query.getOrDefault("Action")
  valid_605021 = validateParameter(valid_605021, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_605021 != nil:
    section.add "Action", valid_605021
  var valid_605022 = query.getOrDefault("SourceIdentifier")
  valid_605022 = validateParameter(valid_605022, JString, required = true,
                                 default = nil)
  if valid_605022 != nil:
    section.add "SourceIdentifier", valid_605022
  var valid_605023 = query.getOrDefault("SubscriptionName")
  valid_605023 = validateParameter(valid_605023, JString, required = true,
                                 default = nil)
  if valid_605023 != nil:
    section.add "SubscriptionName", valid_605023
  var valid_605024 = query.getOrDefault("Version")
  valid_605024 = validateParameter(valid_605024, JString, required = true,
                                 default = newJString("2014-09-01"))
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

proc call*(call_605032: Call_GetRemoveSourceIdentifierFromSubscription_605018;
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

proc call*(call_605033: Call_GetRemoveSourceIdentifierFromSubscription_605018;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_605034 = newJObject()
  add(query_605034, "Action", newJString(Action))
  add(query_605034, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_605034, "SubscriptionName", newJString(SubscriptionName))
  add(query_605034, "Version", newJString(Version))
  result = call_605033.call(nil, query_605034, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_605018(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_605019,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_605020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_605070 = ref object of OpenApiRestCall_602450
proc url_PostRemoveTagsFromResource_605072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_605071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605073 = query.getOrDefault("Action")
  valid_605073 = validateParameter(valid_605073, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_605073 != nil:
    section.add "Action", valid_605073
  var valid_605074 = query.getOrDefault("Version")
  valid_605074 = validateParameter(valid_605074, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605074 != nil:
    section.add "Version", valid_605074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605075 = header.getOrDefault("X-Amz-Date")
  valid_605075 = validateParameter(valid_605075, JString, required = false,
                                 default = nil)
  if valid_605075 != nil:
    section.add "X-Amz-Date", valid_605075
  var valid_605076 = header.getOrDefault("X-Amz-Security-Token")
  valid_605076 = validateParameter(valid_605076, JString, required = false,
                                 default = nil)
  if valid_605076 != nil:
    section.add "X-Amz-Security-Token", valid_605076
  var valid_605077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605077 = validateParameter(valid_605077, JString, required = false,
                                 default = nil)
  if valid_605077 != nil:
    section.add "X-Amz-Content-Sha256", valid_605077
  var valid_605078 = header.getOrDefault("X-Amz-Algorithm")
  valid_605078 = validateParameter(valid_605078, JString, required = false,
                                 default = nil)
  if valid_605078 != nil:
    section.add "X-Amz-Algorithm", valid_605078
  var valid_605079 = header.getOrDefault("X-Amz-Signature")
  valid_605079 = validateParameter(valid_605079, JString, required = false,
                                 default = nil)
  if valid_605079 != nil:
    section.add "X-Amz-Signature", valid_605079
  var valid_605080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605080 = validateParameter(valid_605080, JString, required = false,
                                 default = nil)
  if valid_605080 != nil:
    section.add "X-Amz-SignedHeaders", valid_605080
  var valid_605081 = header.getOrDefault("X-Amz-Credential")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "X-Amz-Credential", valid_605081
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_605082 = formData.getOrDefault("TagKeys")
  valid_605082 = validateParameter(valid_605082, JArray, required = true, default = nil)
  if valid_605082 != nil:
    section.add "TagKeys", valid_605082
  var valid_605083 = formData.getOrDefault("ResourceName")
  valid_605083 = validateParameter(valid_605083, JString, required = true,
                                 default = nil)
  if valid_605083 != nil:
    section.add "ResourceName", valid_605083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605084: Call_PostRemoveTagsFromResource_605070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605084.validator(path, query, header, formData, body)
  let scheme = call_605084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605084.url(scheme.get, call_605084.host, call_605084.base,
                         call_605084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605084, url, valid)

proc call*(call_605085: Call_PostRemoveTagsFromResource_605070; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_605086 = newJObject()
  var formData_605087 = newJObject()
  add(query_605086, "Action", newJString(Action))
  if TagKeys != nil:
    formData_605087.add "TagKeys", TagKeys
  add(formData_605087, "ResourceName", newJString(ResourceName))
  add(query_605086, "Version", newJString(Version))
  result = call_605085.call(nil, query_605086, nil, formData_605087, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_605070(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_605071, base: "/",
    url: url_PostRemoveTagsFromResource_605072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_605053 = ref object of OpenApiRestCall_602450
proc url_GetRemoveTagsFromResource_605055(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_605054(path: JsonNode; query: JsonNode;
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
  var valid_605056 = query.getOrDefault("ResourceName")
  valid_605056 = validateParameter(valid_605056, JString, required = true,
                                 default = nil)
  if valid_605056 != nil:
    section.add "ResourceName", valid_605056
  var valid_605057 = query.getOrDefault("Action")
  valid_605057 = validateParameter(valid_605057, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_605057 != nil:
    section.add "Action", valid_605057
  var valid_605058 = query.getOrDefault("TagKeys")
  valid_605058 = validateParameter(valid_605058, JArray, required = true, default = nil)
  if valid_605058 != nil:
    section.add "TagKeys", valid_605058
  var valid_605059 = query.getOrDefault("Version")
  valid_605059 = validateParameter(valid_605059, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605059 != nil:
    section.add "Version", valid_605059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605060 = header.getOrDefault("X-Amz-Date")
  valid_605060 = validateParameter(valid_605060, JString, required = false,
                                 default = nil)
  if valid_605060 != nil:
    section.add "X-Amz-Date", valid_605060
  var valid_605061 = header.getOrDefault("X-Amz-Security-Token")
  valid_605061 = validateParameter(valid_605061, JString, required = false,
                                 default = nil)
  if valid_605061 != nil:
    section.add "X-Amz-Security-Token", valid_605061
  var valid_605062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605062 = validateParameter(valid_605062, JString, required = false,
                                 default = nil)
  if valid_605062 != nil:
    section.add "X-Amz-Content-Sha256", valid_605062
  var valid_605063 = header.getOrDefault("X-Amz-Algorithm")
  valid_605063 = validateParameter(valid_605063, JString, required = false,
                                 default = nil)
  if valid_605063 != nil:
    section.add "X-Amz-Algorithm", valid_605063
  var valid_605064 = header.getOrDefault("X-Amz-Signature")
  valid_605064 = validateParameter(valid_605064, JString, required = false,
                                 default = nil)
  if valid_605064 != nil:
    section.add "X-Amz-Signature", valid_605064
  var valid_605065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605065 = validateParameter(valid_605065, JString, required = false,
                                 default = nil)
  if valid_605065 != nil:
    section.add "X-Amz-SignedHeaders", valid_605065
  var valid_605066 = header.getOrDefault("X-Amz-Credential")
  valid_605066 = validateParameter(valid_605066, JString, required = false,
                                 default = nil)
  if valid_605066 != nil:
    section.add "X-Amz-Credential", valid_605066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605067: Call_GetRemoveTagsFromResource_605053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605067.validator(path, query, header, formData, body)
  let scheme = call_605067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605067.url(scheme.get, call_605067.host, call_605067.base,
                         call_605067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605067, url, valid)

proc call*(call_605068: Call_GetRemoveTagsFromResource_605053;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_605069 = newJObject()
  add(query_605069, "ResourceName", newJString(ResourceName))
  add(query_605069, "Action", newJString(Action))
  if TagKeys != nil:
    query_605069.add "TagKeys", TagKeys
  add(query_605069, "Version", newJString(Version))
  result = call_605068.call(nil, query_605069, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_605053(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_605054, base: "/",
    url: url_GetRemoveTagsFromResource_605055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_605106 = ref object of OpenApiRestCall_602450
proc url_PostResetDBParameterGroup_605108(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_605107(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605109 = query.getOrDefault("Action")
  valid_605109 = validateParameter(valid_605109, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605109 != nil:
    section.add "Action", valid_605109
  var valid_605110 = query.getOrDefault("Version")
  valid_605110 = validateParameter(valid_605110, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605110 != nil:
    section.add "Version", valid_605110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605111 = header.getOrDefault("X-Amz-Date")
  valid_605111 = validateParameter(valid_605111, JString, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "X-Amz-Date", valid_605111
  var valid_605112 = header.getOrDefault("X-Amz-Security-Token")
  valid_605112 = validateParameter(valid_605112, JString, required = false,
                                 default = nil)
  if valid_605112 != nil:
    section.add "X-Amz-Security-Token", valid_605112
  var valid_605113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "X-Amz-Content-Sha256", valid_605113
  var valid_605114 = header.getOrDefault("X-Amz-Algorithm")
  valid_605114 = validateParameter(valid_605114, JString, required = false,
                                 default = nil)
  if valid_605114 != nil:
    section.add "X-Amz-Algorithm", valid_605114
  var valid_605115 = header.getOrDefault("X-Amz-Signature")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Signature", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-SignedHeaders", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Credential")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Credential", valid_605117
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_605118 = formData.getOrDefault("DBParameterGroupName")
  valid_605118 = validateParameter(valid_605118, JString, required = true,
                                 default = nil)
  if valid_605118 != nil:
    section.add "DBParameterGroupName", valid_605118
  var valid_605119 = formData.getOrDefault("Parameters")
  valid_605119 = validateParameter(valid_605119, JArray, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "Parameters", valid_605119
  var valid_605120 = formData.getOrDefault("ResetAllParameters")
  valid_605120 = validateParameter(valid_605120, JBool, required = false, default = nil)
  if valid_605120 != nil:
    section.add "ResetAllParameters", valid_605120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605121: Call_PostResetDBParameterGroup_605106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605121.validator(path, query, header, formData, body)
  let scheme = call_605121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605121.url(scheme.get, call_605121.host, call_605121.base,
                         call_605121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605121, url, valid)

proc call*(call_605122: Call_PostResetDBParameterGroup_605106;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605123 = newJObject()
  var formData_605124 = newJObject()
  add(formData_605124, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_605124.add "Parameters", Parameters
  add(query_605123, "Action", newJString(Action))
  add(formData_605124, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605123, "Version", newJString(Version))
  result = call_605122.call(nil, query_605123, nil, formData_605124, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_605106(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_605107, base: "/",
    url: url_PostResetDBParameterGroup_605108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_605088 = ref object of OpenApiRestCall_602450
proc url_GetResetDBParameterGroup_605090(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_605089(path: JsonNode; query: JsonNode;
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
  var valid_605091 = query.getOrDefault("DBParameterGroupName")
  valid_605091 = validateParameter(valid_605091, JString, required = true,
                                 default = nil)
  if valid_605091 != nil:
    section.add "DBParameterGroupName", valid_605091
  var valid_605092 = query.getOrDefault("Parameters")
  valid_605092 = validateParameter(valid_605092, JArray, required = false,
                                 default = nil)
  if valid_605092 != nil:
    section.add "Parameters", valid_605092
  var valid_605093 = query.getOrDefault("Action")
  valid_605093 = validateParameter(valid_605093, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605093 != nil:
    section.add "Action", valid_605093
  var valid_605094 = query.getOrDefault("ResetAllParameters")
  valid_605094 = validateParameter(valid_605094, JBool, required = false, default = nil)
  if valid_605094 != nil:
    section.add "ResetAllParameters", valid_605094
  var valid_605095 = query.getOrDefault("Version")
  valid_605095 = validateParameter(valid_605095, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605095 != nil:
    section.add "Version", valid_605095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605096 = header.getOrDefault("X-Amz-Date")
  valid_605096 = validateParameter(valid_605096, JString, required = false,
                                 default = nil)
  if valid_605096 != nil:
    section.add "X-Amz-Date", valid_605096
  var valid_605097 = header.getOrDefault("X-Amz-Security-Token")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "X-Amz-Security-Token", valid_605097
  var valid_605098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "X-Amz-Content-Sha256", valid_605098
  var valid_605099 = header.getOrDefault("X-Amz-Algorithm")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Algorithm", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Signature")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Signature", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-SignedHeaders", valid_605101
  var valid_605102 = header.getOrDefault("X-Amz-Credential")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "X-Amz-Credential", valid_605102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605103: Call_GetResetDBParameterGroup_605088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605103.validator(path, query, header, formData, body)
  let scheme = call_605103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605103.url(scheme.get, call_605103.host, call_605103.base,
                         call_605103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605103, url, valid)

proc call*(call_605104: Call_GetResetDBParameterGroup_605088;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605105 = newJObject()
  add(query_605105, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_605105.add "Parameters", Parameters
  add(query_605105, "Action", newJString(Action))
  add(query_605105, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605105, "Version", newJString(Version))
  result = call_605104.call(nil, query_605105, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_605088(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_605089, base: "/",
    url: url_GetResetDBParameterGroup_605090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_605158 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceFromDBSnapshot_605160(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_605159(path: JsonNode;
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
  var valid_605161 = query.getOrDefault("Action")
  valid_605161 = validateParameter(valid_605161, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605161 != nil:
    section.add "Action", valid_605161
  var valid_605162 = query.getOrDefault("Version")
  valid_605162 = validateParameter(valid_605162, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605162 != nil:
    section.add "Version", valid_605162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605163 = header.getOrDefault("X-Amz-Date")
  valid_605163 = validateParameter(valid_605163, JString, required = false,
                                 default = nil)
  if valid_605163 != nil:
    section.add "X-Amz-Date", valid_605163
  var valid_605164 = header.getOrDefault("X-Amz-Security-Token")
  valid_605164 = validateParameter(valid_605164, JString, required = false,
                                 default = nil)
  if valid_605164 != nil:
    section.add "X-Amz-Security-Token", valid_605164
  var valid_605165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605165 = validateParameter(valid_605165, JString, required = false,
                                 default = nil)
  if valid_605165 != nil:
    section.add "X-Amz-Content-Sha256", valid_605165
  var valid_605166 = header.getOrDefault("X-Amz-Algorithm")
  valid_605166 = validateParameter(valid_605166, JString, required = false,
                                 default = nil)
  if valid_605166 != nil:
    section.add "X-Amz-Algorithm", valid_605166
  var valid_605167 = header.getOrDefault("X-Amz-Signature")
  valid_605167 = validateParameter(valid_605167, JString, required = false,
                                 default = nil)
  if valid_605167 != nil:
    section.add "X-Amz-Signature", valid_605167
  var valid_605168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605168 = validateParameter(valid_605168, JString, required = false,
                                 default = nil)
  if valid_605168 != nil:
    section.add "X-Amz-SignedHeaders", valid_605168
  var valid_605169 = header.getOrDefault("X-Amz-Credential")
  valid_605169 = validateParameter(valid_605169, JString, required = false,
                                 default = nil)
  if valid_605169 != nil:
    section.add "X-Amz-Credential", valid_605169
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
  var valid_605170 = formData.getOrDefault("Port")
  valid_605170 = validateParameter(valid_605170, JInt, required = false, default = nil)
  if valid_605170 != nil:
    section.add "Port", valid_605170
  var valid_605171 = formData.getOrDefault("Engine")
  valid_605171 = validateParameter(valid_605171, JString, required = false,
                                 default = nil)
  if valid_605171 != nil:
    section.add "Engine", valid_605171
  var valid_605172 = formData.getOrDefault("Iops")
  valid_605172 = validateParameter(valid_605172, JInt, required = false, default = nil)
  if valid_605172 != nil:
    section.add "Iops", valid_605172
  var valid_605173 = formData.getOrDefault("DBName")
  valid_605173 = validateParameter(valid_605173, JString, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "DBName", valid_605173
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605174 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605174 = validateParameter(valid_605174, JString, required = true,
                                 default = nil)
  if valid_605174 != nil:
    section.add "DBInstanceIdentifier", valid_605174
  var valid_605175 = formData.getOrDefault("OptionGroupName")
  valid_605175 = validateParameter(valid_605175, JString, required = false,
                                 default = nil)
  if valid_605175 != nil:
    section.add "OptionGroupName", valid_605175
  var valid_605176 = formData.getOrDefault("Tags")
  valid_605176 = validateParameter(valid_605176, JArray, required = false,
                                 default = nil)
  if valid_605176 != nil:
    section.add "Tags", valid_605176
  var valid_605177 = formData.getOrDefault("TdeCredentialArn")
  valid_605177 = validateParameter(valid_605177, JString, required = false,
                                 default = nil)
  if valid_605177 != nil:
    section.add "TdeCredentialArn", valid_605177
  var valid_605178 = formData.getOrDefault("DBSubnetGroupName")
  valid_605178 = validateParameter(valid_605178, JString, required = false,
                                 default = nil)
  if valid_605178 != nil:
    section.add "DBSubnetGroupName", valid_605178
  var valid_605179 = formData.getOrDefault("TdeCredentialPassword")
  valid_605179 = validateParameter(valid_605179, JString, required = false,
                                 default = nil)
  if valid_605179 != nil:
    section.add "TdeCredentialPassword", valid_605179
  var valid_605180 = formData.getOrDefault("AvailabilityZone")
  valid_605180 = validateParameter(valid_605180, JString, required = false,
                                 default = nil)
  if valid_605180 != nil:
    section.add "AvailabilityZone", valid_605180
  var valid_605181 = formData.getOrDefault("MultiAZ")
  valid_605181 = validateParameter(valid_605181, JBool, required = false, default = nil)
  if valid_605181 != nil:
    section.add "MultiAZ", valid_605181
  var valid_605182 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_605182 = validateParameter(valid_605182, JString, required = true,
                                 default = nil)
  if valid_605182 != nil:
    section.add "DBSnapshotIdentifier", valid_605182
  var valid_605183 = formData.getOrDefault("PubliclyAccessible")
  valid_605183 = validateParameter(valid_605183, JBool, required = false, default = nil)
  if valid_605183 != nil:
    section.add "PubliclyAccessible", valid_605183
  var valid_605184 = formData.getOrDefault("StorageType")
  valid_605184 = validateParameter(valid_605184, JString, required = false,
                                 default = nil)
  if valid_605184 != nil:
    section.add "StorageType", valid_605184
  var valid_605185 = formData.getOrDefault("DBInstanceClass")
  valid_605185 = validateParameter(valid_605185, JString, required = false,
                                 default = nil)
  if valid_605185 != nil:
    section.add "DBInstanceClass", valid_605185
  var valid_605186 = formData.getOrDefault("LicenseModel")
  valid_605186 = validateParameter(valid_605186, JString, required = false,
                                 default = nil)
  if valid_605186 != nil:
    section.add "LicenseModel", valid_605186
  var valid_605187 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605187 = validateParameter(valid_605187, JBool, required = false, default = nil)
  if valid_605187 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605187
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605188: Call_PostRestoreDBInstanceFromDBSnapshot_605158;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605188.validator(path, query, header, formData, body)
  let scheme = call_605188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605188.url(scheme.get, call_605188.host, call_605188.base,
                         call_605188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605188, url, valid)

proc call*(call_605189: Call_PostRestoreDBInstanceFromDBSnapshot_605158;
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
  var query_605190 = newJObject()
  var formData_605191 = newJObject()
  add(formData_605191, "Port", newJInt(Port))
  add(formData_605191, "Engine", newJString(Engine))
  add(formData_605191, "Iops", newJInt(Iops))
  add(formData_605191, "DBName", newJString(DBName))
  add(formData_605191, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605191, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605191.add "Tags", Tags
  add(formData_605191, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_605191, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605191, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_605191, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605191, "MultiAZ", newJBool(MultiAZ))
  add(formData_605191, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_605190, "Action", newJString(Action))
  add(formData_605191, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605191, "StorageType", newJString(StorageType))
  add(formData_605191, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605191, "LicenseModel", newJString(LicenseModel))
  add(formData_605191, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605190, "Version", newJString(Version))
  result = call_605189.call(nil, query_605190, nil, formData_605191, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_605158(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_605159, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_605160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_605125 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceFromDBSnapshot_605127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_605126(path: JsonNode;
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
  var valid_605128 = query.getOrDefault("Engine")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "Engine", valid_605128
  var valid_605129 = query.getOrDefault("StorageType")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "StorageType", valid_605129
  var valid_605130 = query.getOrDefault("OptionGroupName")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "OptionGroupName", valid_605130
  var valid_605131 = query.getOrDefault("AvailabilityZone")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "AvailabilityZone", valid_605131
  var valid_605132 = query.getOrDefault("Iops")
  valid_605132 = validateParameter(valid_605132, JInt, required = false, default = nil)
  if valid_605132 != nil:
    section.add "Iops", valid_605132
  var valid_605133 = query.getOrDefault("MultiAZ")
  valid_605133 = validateParameter(valid_605133, JBool, required = false, default = nil)
  if valid_605133 != nil:
    section.add "MultiAZ", valid_605133
  var valid_605134 = query.getOrDefault("TdeCredentialPassword")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "TdeCredentialPassword", valid_605134
  var valid_605135 = query.getOrDefault("LicenseModel")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "LicenseModel", valid_605135
  var valid_605136 = query.getOrDefault("Tags")
  valid_605136 = validateParameter(valid_605136, JArray, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "Tags", valid_605136
  var valid_605137 = query.getOrDefault("DBName")
  valid_605137 = validateParameter(valid_605137, JString, required = false,
                                 default = nil)
  if valid_605137 != nil:
    section.add "DBName", valid_605137
  var valid_605138 = query.getOrDefault("DBInstanceClass")
  valid_605138 = validateParameter(valid_605138, JString, required = false,
                                 default = nil)
  if valid_605138 != nil:
    section.add "DBInstanceClass", valid_605138
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605139 = query.getOrDefault("Action")
  valid_605139 = validateParameter(valid_605139, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605139 != nil:
    section.add "Action", valid_605139
  var valid_605140 = query.getOrDefault("DBSubnetGroupName")
  valid_605140 = validateParameter(valid_605140, JString, required = false,
                                 default = nil)
  if valid_605140 != nil:
    section.add "DBSubnetGroupName", valid_605140
  var valid_605141 = query.getOrDefault("TdeCredentialArn")
  valid_605141 = validateParameter(valid_605141, JString, required = false,
                                 default = nil)
  if valid_605141 != nil:
    section.add "TdeCredentialArn", valid_605141
  var valid_605142 = query.getOrDefault("PubliclyAccessible")
  valid_605142 = validateParameter(valid_605142, JBool, required = false, default = nil)
  if valid_605142 != nil:
    section.add "PubliclyAccessible", valid_605142
  var valid_605143 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605143 = validateParameter(valid_605143, JBool, required = false, default = nil)
  if valid_605143 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605143
  var valid_605144 = query.getOrDefault("Port")
  valid_605144 = validateParameter(valid_605144, JInt, required = false, default = nil)
  if valid_605144 != nil:
    section.add "Port", valid_605144
  var valid_605145 = query.getOrDefault("Version")
  valid_605145 = validateParameter(valid_605145, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605145 != nil:
    section.add "Version", valid_605145
  var valid_605146 = query.getOrDefault("DBInstanceIdentifier")
  valid_605146 = validateParameter(valid_605146, JString, required = true,
                                 default = nil)
  if valid_605146 != nil:
    section.add "DBInstanceIdentifier", valid_605146
  var valid_605147 = query.getOrDefault("DBSnapshotIdentifier")
  valid_605147 = validateParameter(valid_605147, JString, required = true,
                                 default = nil)
  if valid_605147 != nil:
    section.add "DBSnapshotIdentifier", valid_605147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605148 = header.getOrDefault("X-Amz-Date")
  valid_605148 = validateParameter(valid_605148, JString, required = false,
                                 default = nil)
  if valid_605148 != nil:
    section.add "X-Amz-Date", valid_605148
  var valid_605149 = header.getOrDefault("X-Amz-Security-Token")
  valid_605149 = validateParameter(valid_605149, JString, required = false,
                                 default = nil)
  if valid_605149 != nil:
    section.add "X-Amz-Security-Token", valid_605149
  var valid_605150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605150 = validateParameter(valid_605150, JString, required = false,
                                 default = nil)
  if valid_605150 != nil:
    section.add "X-Amz-Content-Sha256", valid_605150
  var valid_605151 = header.getOrDefault("X-Amz-Algorithm")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "X-Amz-Algorithm", valid_605151
  var valid_605152 = header.getOrDefault("X-Amz-Signature")
  valid_605152 = validateParameter(valid_605152, JString, required = false,
                                 default = nil)
  if valid_605152 != nil:
    section.add "X-Amz-Signature", valid_605152
  var valid_605153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605153 = validateParameter(valid_605153, JString, required = false,
                                 default = nil)
  if valid_605153 != nil:
    section.add "X-Amz-SignedHeaders", valid_605153
  var valid_605154 = header.getOrDefault("X-Amz-Credential")
  valid_605154 = validateParameter(valid_605154, JString, required = false,
                                 default = nil)
  if valid_605154 != nil:
    section.add "X-Amz-Credential", valid_605154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605155: Call_GetRestoreDBInstanceFromDBSnapshot_605125;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605155.validator(path, query, header, formData, body)
  let scheme = call_605155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605155.url(scheme.get, call_605155.host, call_605155.base,
                         call_605155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605155, url, valid)

proc call*(call_605156: Call_GetRestoreDBInstanceFromDBSnapshot_605125;
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
  var query_605157 = newJObject()
  add(query_605157, "Engine", newJString(Engine))
  add(query_605157, "StorageType", newJString(StorageType))
  add(query_605157, "OptionGroupName", newJString(OptionGroupName))
  add(query_605157, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605157, "Iops", newJInt(Iops))
  add(query_605157, "MultiAZ", newJBool(MultiAZ))
  add(query_605157, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_605157, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605157.add "Tags", Tags
  add(query_605157, "DBName", newJString(DBName))
  add(query_605157, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605157, "Action", newJString(Action))
  add(query_605157, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605157, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_605157, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605157, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605157, "Port", newJInt(Port))
  add(query_605157, "Version", newJString(Version))
  add(query_605157, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605157, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_605156.call(nil, query_605157, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_605125(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_605126, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_605127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605227 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceToPointInTime_605229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_605228(path: JsonNode;
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
  var valid_605230 = query.getOrDefault("Action")
  valid_605230 = validateParameter(valid_605230, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605230 != nil:
    section.add "Action", valid_605230
  var valid_605231 = query.getOrDefault("Version")
  valid_605231 = validateParameter(valid_605231, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605231 != nil:
    section.add "Version", valid_605231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605232 = header.getOrDefault("X-Amz-Date")
  valid_605232 = validateParameter(valid_605232, JString, required = false,
                                 default = nil)
  if valid_605232 != nil:
    section.add "X-Amz-Date", valid_605232
  var valid_605233 = header.getOrDefault("X-Amz-Security-Token")
  valid_605233 = validateParameter(valid_605233, JString, required = false,
                                 default = nil)
  if valid_605233 != nil:
    section.add "X-Amz-Security-Token", valid_605233
  var valid_605234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605234 = validateParameter(valid_605234, JString, required = false,
                                 default = nil)
  if valid_605234 != nil:
    section.add "X-Amz-Content-Sha256", valid_605234
  var valid_605235 = header.getOrDefault("X-Amz-Algorithm")
  valid_605235 = validateParameter(valid_605235, JString, required = false,
                                 default = nil)
  if valid_605235 != nil:
    section.add "X-Amz-Algorithm", valid_605235
  var valid_605236 = header.getOrDefault("X-Amz-Signature")
  valid_605236 = validateParameter(valid_605236, JString, required = false,
                                 default = nil)
  if valid_605236 != nil:
    section.add "X-Amz-Signature", valid_605236
  var valid_605237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605237 = validateParameter(valid_605237, JString, required = false,
                                 default = nil)
  if valid_605237 != nil:
    section.add "X-Amz-SignedHeaders", valid_605237
  var valid_605238 = header.getOrDefault("X-Amz-Credential")
  valid_605238 = validateParameter(valid_605238, JString, required = false,
                                 default = nil)
  if valid_605238 != nil:
    section.add "X-Amz-Credential", valid_605238
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
  var valid_605239 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605239 = validateParameter(valid_605239, JBool, required = false, default = nil)
  if valid_605239 != nil:
    section.add "UseLatestRestorableTime", valid_605239
  var valid_605240 = formData.getOrDefault("Port")
  valid_605240 = validateParameter(valid_605240, JInt, required = false, default = nil)
  if valid_605240 != nil:
    section.add "Port", valid_605240
  var valid_605241 = formData.getOrDefault("Engine")
  valid_605241 = validateParameter(valid_605241, JString, required = false,
                                 default = nil)
  if valid_605241 != nil:
    section.add "Engine", valid_605241
  var valid_605242 = formData.getOrDefault("Iops")
  valid_605242 = validateParameter(valid_605242, JInt, required = false, default = nil)
  if valid_605242 != nil:
    section.add "Iops", valid_605242
  var valid_605243 = formData.getOrDefault("DBName")
  valid_605243 = validateParameter(valid_605243, JString, required = false,
                                 default = nil)
  if valid_605243 != nil:
    section.add "DBName", valid_605243
  var valid_605244 = formData.getOrDefault("OptionGroupName")
  valid_605244 = validateParameter(valid_605244, JString, required = false,
                                 default = nil)
  if valid_605244 != nil:
    section.add "OptionGroupName", valid_605244
  var valid_605245 = formData.getOrDefault("Tags")
  valid_605245 = validateParameter(valid_605245, JArray, required = false,
                                 default = nil)
  if valid_605245 != nil:
    section.add "Tags", valid_605245
  var valid_605246 = formData.getOrDefault("TdeCredentialArn")
  valid_605246 = validateParameter(valid_605246, JString, required = false,
                                 default = nil)
  if valid_605246 != nil:
    section.add "TdeCredentialArn", valid_605246
  var valid_605247 = formData.getOrDefault("DBSubnetGroupName")
  valid_605247 = validateParameter(valid_605247, JString, required = false,
                                 default = nil)
  if valid_605247 != nil:
    section.add "DBSubnetGroupName", valid_605247
  var valid_605248 = formData.getOrDefault("TdeCredentialPassword")
  valid_605248 = validateParameter(valid_605248, JString, required = false,
                                 default = nil)
  if valid_605248 != nil:
    section.add "TdeCredentialPassword", valid_605248
  var valid_605249 = formData.getOrDefault("AvailabilityZone")
  valid_605249 = validateParameter(valid_605249, JString, required = false,
                                 default = nil)
  if valid_605249 != nil:
    section.add "AvailabilityZone", valid_605249
  var valid_605250 = formData.getOrDefault("MultiAZ")
  valid_605250 = validateParameter(valid_605250, JBool, required = false, default = nil)
  if valid_605250 != nil:
    section.add "MultiAZ", valid_605250
  var valid_605251 = formData.getOrDefault("RestoreTime")
  valid_605251 = validateParameter(valid_605251, JString, required = false,
                                 default = nil)
  if valid_605251 != nil:
    section.add "RestoreTime", valid_605251
  var valid_605252 = formData.getOrDefault("PubliclyAccessible")
  valid_605252 = validateParameter(valid_605252, JBool, required = false, default = nil)
  if valid_605252 != nil:
    section.add "PubliclyAccessible", valid_605252
  var valid_605253 = formData.getOrDefault("StorageType")
  valid_605253 = validateParameter(valid_605253, JString, required = false,
                                 default = nil)
  if valid_605253 != nil:
    section.add "StorageType", valid_605253
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605254 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605254 = validateParameter(valid_605254, JString, required = true,
                                 default = nil)
  if valid_605254 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605254
  var valid_605255 = formData.getOrDefault("DBInstanceClass")
  valid_605255 = validateParameter(valid_605255, JString, required = false,
                                 default = nil)
  if valid_605255 != nil:
    section.add "DBInstanceClass", valid_605255
  var valid_605256 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605256 = validateParameter(valid_605256, JString, required = true,
                                 default = nil)
  if valid_605256 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605256
  var valid_605257 = formData.getOrDefault("LicenseModel")
  valid_605257 = validateParameter(valid_605257, JString, required = false,
                                 default = nil)
  if valid_605257 != nil:
    section.add "LicenseModel", valid_605257
  var valid_605258 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605258 = validateParameter(valid_605258, JBool, required = false, default = nil)
  if valid_605258 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605259: Call_PostRestoreDBInstanceToPointInTime_605227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605259.validator(path, query, header, formData, body)
  let scheme = call_605259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605259.url(scheme.get, call_605259.host, call_605259.base,
                         call_605259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605259, url, valid)

proc call*(call_605260: Call_PostRestoreDBInstanceToPointInTime_605227;
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
  var query_605261 = newJObject()
  var formData_605262 = newJObject()
  add(formData_605262, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605262, "Port", newJInt(Port))
  add(formData_605262, "Engine", newJString(Engine))
  add(formData_605262, "Iops", newJInt(Iops))
  add(formData_605262, "DBName", newJString(DBName))
  add(formData_605262, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605262.add "Tags", Tags
  add(formData_605262, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_605262, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605262, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_605262, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605262, "MultiAZ", newJBool(MultiAZ))
  add(query_605261, "Action", newJString(Action))
  add(formData_605262, "RestoreTime", newJString(RestoreTime))
  add(formData_605262, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605262, "StorageType", newJString(StorageType))
  add(formData_605262, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605262, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605262, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605262, "LicenseModel", newJString(LicenseModel))
  add(formData_605262, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605261, "Version", newJString(Version))
  result = call_605260.call(nil, query_605261, nil, formData_605262, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605227(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605228, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605192 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceToPointInTime_605194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_605193(path: JsonNode;
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
  var valid_605195 = query.getOrDefault("Engine")
  valid_605195 = validateParameter(valid_605195, JString, required = false,
                                 default = nil)
  if valid_605195 != nil:
    section.add "Engine", valid_605195
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605196 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605196 = validateParameter(valid_605196, JString, required = true,
                                 default = nil)
  if valid_605196 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605196
  var valid_605197 = query.getOrDefault("StorageType")
  valid_605197 = validateParameter(valid_605197, JString, required = false,
                                 default = nil)
  if valid_605197 != nil:
    section.add "StorageType", valid_605197
  var valid_605198 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605198 = validateParameter(valid_605198, JString, required = true,
                                 default = nil)
  if valid_605198 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605198
  var valid_605199 = query.getOrDefault("AvailabilityZone")
  valid_605199 = validateParameter(valid_605199, JString, required = false,
                                 default = nil)
  if valid_605199 != nil:
    section.add "AvailabilityZone", valid_605199
  var valid_605200 = query.getOrDefault("Iops")
  valid_605200 = validateParameter(valid_605200, JInt, required = false, default = nil)
  if valid_605200 != nil:
    section.add "Iops", valid_605200
  var valid_605201 = query.getOrDefault("OptionGroupName")
  valid_605201 = validateParameter(valid_605201, JString, required = false,
                                 default = nil)
  if valid_605201 != nil:
    section.add "OptionGroupName", valid_605201
  var valid_605202 = query.getOrDefault("RestoreTime")
  valid_605202 = validateParameter(valid_605202, JString, required = false,
                                 default = nil)
  if valid_605202 != nil:
    section.add "RestoreTime", valid_605202
  var valid_605203 = query.getOrDefault("MultiAZ")
  valid_605203 = validateParameter(valid_605203, JBool, required = false, default = nil)
  if valid_605203 != nil:
    section.add "MultiAZ", valid_605203
  var valid_605204 = query.getOrDefault("TdeCredentialPassword")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "TdeCredentialPassword", valid_605204
  var valid_605205 = query.getOrDefault("LicenseModel")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "LicenseModel", valid_605205
  var valid_605206 = query.getOrDefault("Tags")
  valid_605206 = validateParameter(valid_605206, JArray, required = false,
                                 default = nil)
  if valid_605206 != nil:
    section.add "Tags", valid_605206
  var valid_605207 = query.getOrDefault("DBName")
  valid_605207 = validateParameter(valid_605207, JString, required = false,
                                 default = nil)
  if valid_605207 != nil:
    section.add "DBName", valid_605207
  var valid_605208 = query.getOrDefault("DBInstanceClass")
  valid_605208 = validateParameter(valid_605208, JString, required = false,
                                 default = nil)
  if valid_605208 != nil:
    section.add "DBInstanceClass", valid_605208
  var valid_605209 = query.getOrDefault("Action")
  valid_605209 = validateParameter(valid_605209, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605209 != nil:
    section.add "Action", valid_605209
  var valid_605210 = query.getOrDefault("UseLatestRestorableTime")
  valid_605210 = validateParameter(valid_605210, JBool, required = false, default = nil)
  if valid_605210 != nil:
    section.add "UseLatestRestorableTime", valid_605210
  var valid_605211 = query.getOrDefault("DBSubnetGroupName")
  valid_605211 = validateParameter(valid_605211, JString, required = false,
                                 default = nil)
  if valid_605211 != nil:
    section.add "DBSubnetGroupName", valid_605211
  var valid_605212 = query.getOrDefault("TdeCredentialArn")
  valid_605212 = validateParameter(valid_605212, JString, required = false,
                                 default = nil)
  if valid_605212 != nil:
    section.add "TdeCredentialArn", valid_605212
  var valid_605213 = query.getOrDefault("PubliclyAccessible")
  valid_605213 = validateParameter(valid_605213, JBool, required = false, default = nil)
  if valid_605213 != nil:
    section.add "PubliclyAccessible", valid_605213
  var valid_605214 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605214 = validateParameter(valid_605214, JBool, required = false, default = nil)
  if valid_605214 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605214
  var valid_605215 = query.getOrDefault("Port")
  valid_605215 = validateParameter(valid_605215, JInt, required = false, default = nil)
  if valid_605215 != nil:
    section.add "Port", valid_605215
  var valid_605216 = query.getOrDefault("Version")
  valid_605216 = validateParameter(valid_605216, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605216 != nil:
    section.add "Version", valid_605216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605217 = header.getOrDefault("X-Amz-Date")
  valid_605217 = validateParameter(valid_605217, JString, required = false,
                                 default = nil)
  if valid_605217 != nil:
    section.add "X-Amz-Date", valid_605217
  var valid_605218 = header.getOrDefault("X-Amz-Security-Token")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "X-Amz-Security-Token", valid_605218
  var valid_605219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605219 = validateParameter(valid_605219, JString, required = false,
                                 default = nil)
  if valid_605219 != nil:
    section.add "X-Amz-Content-Sha256", valid_605219
  var valid_605220 = header.getOrDefault("X-Amz-Algorithm")
  valid_605220 = validateParameter(valid_605220, JString, required = false,
                                 default = nil)
  if valid_605220 != nil:
    section.add "X-Amz-Algorithm", valid_605220
  var valid_605221 = header.getOrDefault("X-Amz-Signature")
  valid_605221 = validateParameter(valid_605221, JString, required = false,
                                 default = nil)
  if valid_605221 != nil:
    section.add "X-Amz-Signature", valid_605221
  var valid_605222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605222 = validateParameter(valid_605222, JString, required = false,
                                 default = nil)
  if valid_605222 != nil:
    section.add "X-Amz-SignedHeaders", valid_605222
  var valid_605223 = header.getOrDefault("X-Amz-Credential")
  valid_605223 = validateParameter(valid_605223, JString, required = false,
                                 default = nil)
  if valid_605223 != nil:
    section.add "X-Amz-Credential", valid_605223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605224: Call_GetRestoreDBInstanceToPointInTime_605192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605224.validator(path, query, header, formData, body)
  let scheme = call_605224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605224.url(scheme.get, call_605224.host, call_605224.base,
                         call_605224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605224, url, valid)

proc call*(call_605225: Call_GetRestoreDBInstanceToPointInTime_605192;
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
  var query_605226 = newJObject()
  add(query_605226, "Engine", newJString(Engine))
  add(query_605226, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605226, "StorageType", newJString(StorageType))
  add(query_605226, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605226, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605226, "Iops", newJInt(Iops))
  add(query_605226, "OptionGroupName", newJString(OptionGroupName))
  add(query_605226, "RestoreTime", newJString(RestoreTime))
  add(query_605226, "MultiAZ", newJBool(MultiAZ))
  add(query_605226, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_605226, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605226.add "Tags", Tags
  add(query_605226, "DBName", newJString(DBName))
  add(query_605226, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605226, "Action", newJString(Action))
  add(query_605226, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605226, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605226, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_605226, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605226, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605226, "Port", newJInt(Port))
  add(query_605226, "Version", newJString(Version))
  result = call_605225.call(nil, query_605226, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605192(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605193, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605283 = ref object of OpenApiRestCall_602450
proc url_PostRevokeDBSecurityGroupIngress_605285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_605284(path: JsonNode;
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
  var valid_605286 = query.getOrDefault("Action")
  valid_605286 = validateParameter(valid_605286, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605286 != nil:
    section.add "Action", valid_605286
  var valid_605287 = query.getOrDefault("Version")
  valid_605287 = validateParameter(valid_605287, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605287 != nil:
    section.add "Version", valid_605287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605288 = header.getOrDefault("X-Amz-Date")
  valid_605288 = validateParameter(valid_605288, JString, required = false,
                                 default = nil)
  if valid_605288 != nil:
    section.add "X-Amz-Date", valid_605288
  var valid_605289 = header.getOrDefault("X-Amz-Security-Token")
  valid_605289 = validateParameter(valid_605289, JString, required = false,
                                 default = nil)
  if valid_605289 != nil:
    section.add "X-Amz-Security-Token", valid_605289
  var valid_605290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "X-Amz-Content-Sha256", valid_605290
  var valid_605291 = header.getOrDefault("X-Amz-Algorithm")
  valid_605291 = validateParameter(valid_605291, JString, required = false,
                                 default = nil)
  if valid_605291 != nil:
    section.add "X-Amz-Algorithm", valid_605291
  var valid_605292 = header.getOrDefault("X-Amz-Signature")
  valid_605292 = validateParameter(valid_605292, JString, required = false,
                                 default = nil)
  if valid_605292 != nil:
    section.add "X-Amz-Signature", valid_605292
  var valid_605293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "X-Amz-SignedHeaders", valid_605293
  var valid_605294 = header.getOrDefault("X-Amz-Credential")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-Credential", valid_605294
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605295 = formData.getOrDefault("DBSecurityGroupName")
  valid_605295 = validateParameter(valid_605295, JString, required = true,
                                 default = nil)
  if valid_605295 != nil:
    section.add "DBSecurityGroupName", valid_605295
  var valid_605296 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605296 = validateParameter(valid_605296, JString, required = false,
                                 default = nil)
  if valid_605296 != nil:
    section.add "EC2SecurityGroupName", valid_605296
  var valid_605297 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605297 = validateParameter(valid_605297, JString, required = false,
                                 default = nil)
  if valid_605297 != nil:
    section.add "EC2SecurityGroupId", valid_605297
  var valid_605298 = formData.getOrDefault("CIDRIP")
  valid_605298 = validateParameter(valid_605298, JString, required = false,
                                 default = nil)
  if valid_605298 != nil:
    section.add "CIDRIP", valid_605298
  var valid_605299 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605299
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605300: Call_PostRevokeDBSecurityGroupIngress_605283;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605300.validator(path, query, header, formData, body)
  let scheme = call_605300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605300.url(scheme.get, call_605300.host, call_605300.base,
                         call_605300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605300, url, valid)

proc call*(call_605301: Call_PostRevokeDBSecurityGroupIngress_605283;
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
  var query_605302 = newJObject()
  var formData_605303 = newJObject()
  add(formData_605303, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605302, "Action", newJString(Action))
  add(formData_605303, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605303, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605303, "CIDRIP", newJString(CIDRIP))
  add(query_605302, "Version", newJString(Version))
  add(formData_605303, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605301.call(nil, query_605302, nil, formData_605303, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605283(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605284, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605263 = ref object of OpenApiRestCall_602450
proc url_GetRevokeDBSecurityGroupIngress_605265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_605264(path: JsonNode;
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
  var valid_605266 = query.getOrDefault("EC2SecurityGroupId")
  valid_605266 = validateParameter(valid_605266, JString, required = false,
                                 default = nil)
  if valid_605266 != nil:
    section.add "EC2SecurityGroupId", valid_605266
  var valid_605267 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605267 = validateParameter(valid_605267, JString, required = false,
                                 default = nil)
  if valid_605267 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605267
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605268 = query.getOrDefault("DBSecurityGroupName")
  valid_605268 = validateParameter(valid_605268, JString, required = true,
                                 default = nil)
  if valid_605268 != nil:
    section.add "DBSecurityGroupName", valid_605268
  var valid_605269 = query.getOrDefault("Action")
  valid_605269 = validateParameter(valid_605269, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605269 != nil:
    section.add "Action", valid_605269
  var valid_605270 = query.getOrDefault("CIDRIP")
  valid_605270 = validateParameter(valid_605270, JString, required = false,
                                 default = nil)
  if valid_605270 != nil:
    section.add "CIDRIP", valid_605270
  var valid_605271 = query.getOrDefault("EC2SecurityGroupName")
  valid_605271 = validateParameter(valid_605271, JString, required = false,
                                 default = nil)
  if valid_605271 != nil:
    section.add "EC2SecurityGroupName", valid_605271
  var valid_605272 = query.getOrDefault("Version")
  valid_605272 = validateParameter(valid_605272, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605272 != nil:
    section.add "Version", valid_605272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605273 = header.getOrDefault("X-Amz-Date")
  valid_605273 = validateParameter(valid_605273, JString, required = false,
                                 default = nil)
  if valid_605273 != nil:
    section.add "X-Amz-Date", valid_605273
  var valid_605274 = header.getOrDefault("X-Amz-Security-Token")
  valid_605274 = validateParameter(valid_605274, JString, required = false,
                                 default = nil)
  if valid_605274 != nil:
    section.add "X-Amz-Security-Token", valid_605274
  var valid_605275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "X-Amz-Content-Sha256", valid_605275
  var valid_605276 = header.getOrDefault("X-Amz-Algorithm")
  valid_605276 = validateParameter(valid_605276, JString, required = false,
                                 default = nil)
  if valid_605276 != nil:
    section.add "X-Amz-Algorithm", valid_605276
  var valid_605277 = header.getOrDefault("X-Amz-Signature")
  valid_605277 = validateParameter(valid_605277, JString, required = false,
                                 default = nil)
  if valid_605277 != nil:
    section.add "X-Amz-Signature", valid_605277
  var valid_605278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605278 = validateParameter(valid_605278, JString, required = false,
                                 default = nil)
  if valid_605278 != nil:
    section.add "X-Amz-SignedHeaders", valid_605278
  var valid_605279 = header.getOrDefault("X-Amz-Credential")
  valid_605279 = validateParameter(valid_605279, JString, required = false,
                                 default = nil)
  if valid_605279 != nil:
    section.add "X-Amz-Credential", valid_605279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605280: Call_GetRevokeDBSecurityGroupIngress_605263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605280.validator(path, query, header, formData, body)
  let scheme = call_605280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605280.url(scheme.get, call_605280.host, call_605280.base,
                         call_605280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605280, url, valid)

proc call*(call_605281: Call_GetRevokeDBSecurityGroupIngress_605263;
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
  var query_605282 = newJObject()
  add(query_605282, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605282, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605282, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605282, "Action", newJString(Action))
  add(query_605282, "CIDRIP", newJString(CIDRIP))
  add(query_605282, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605282, "Version", newJString(Version))
  result = call_605281.call(nil, query_605282, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605263(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605264, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605265,
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

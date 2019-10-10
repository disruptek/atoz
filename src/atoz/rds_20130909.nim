
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_603171 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBSnapshot_603173(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_603172(path: JsonNode; query: JsonNode;
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
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("Version")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603175 != nil:
    section.add "Version", valid_603175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603176 = header.getOrDefault("X-Amz-Date")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Date", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Security-Token")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Security-Token", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Content-Sha256", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Algorithm")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Algorithm", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Signature")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Signature", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-SignedHeaders", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Credential")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Credential", valid_603182
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603183 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603183
  var valid_603184 = formData.getOrDefault("Tags")
  valid_603184 = validateParameter(valid_603184, JArray, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "Tags", valid_603184
  var valid_603185 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_PostCopyDBSnapshot_603171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_PostCopyDBSnapshot_603171;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603188 = newJObject()
  var formData_603189 = newJObject()
  add(formData_603189, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_603189.add "Tags", Tags
  add(query_603188, "Action", newJString(Action))
  add(formData_603189, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603188, "Version", newJString(Version))
  result = call_603187.call(nil, query_603188, nil, formData_603189, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603171(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603172, base: "/",
    url: url_PostCopyDBSnapshot_603173, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_603156 = query.getOrDefault("Tags")
  valid_603156 = validateParameter(valid_603156, JArray, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "Tags", valid_603156
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603157 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603157
  var valid_603158 = query.getOrDefault("Action")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603158 != nil:
    section.add "Action", valid_603158
  var valid_603159 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603159
  var valid_603160 = query.getOrDefault("Version")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603160 != nil:
    section.add "Version", valid_603160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603161 = header.getOrDefault("X-Amz-Date")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Date", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Security-Token")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Security-Token", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Content-Sha256", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Algorithm")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Algorithm", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Signature")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Signature", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-SignedHeaders", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Credential")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Credential", valid_603167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603168: Call_GetCopyDBSnapshot_603153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603168.validator(path, query, header, formData, body)
  let scheme = call_603168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603168.url(scheme.get, call_603168.host, call_603168.base,
                         call_603168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603168, url, valid)

proc call*(call_603169: Call_GetCopyDBSnapshot_603153;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603170 = newJObject()
  if Tags != nil:
    query_603170.add "Tags", Tags
  add(query_603170, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603170, "Action", newJString(Action))
  add(query_603170, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603170, "Version", newJString(Version))
  result = call_603169.call(nil, query_603170, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603153(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603154,
    base: "/", url: url_GetCopyDBSnapshot_603155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603230 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstance_603232(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_603231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603233 = query.getOrDefault("Action")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603233 != nil:
    section.add "Action", valid_603233
  var valid_603234 = query.getOrDefault("Version")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603234 != nil:
    section.add "Version", valid_603234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Content-Sha256", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Algorithm")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Algorithm", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Signature")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Signature", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-SignedHeaders", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Credential")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Credential", valid_603241
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
  var valid_603242 = formData.getOrDefault("DBSecurityGroups")
  valid_603242 = validateParameter(valid_603242, JArray, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "DBSecurityGroups", valid_603242
  var valid_603243 = formData.getOrDefault("Port")
  valid_603243 = validateParameter(valid_603243, JInt, required = false, default = nil)
  if valid_603243 != nil:
    section.add "Port", valid_603243
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603244 = formData.getOrDefault("Engine")
  valid_603244 = validateParameter(valid_603244, JString, required = true,
                                 default = nil)
  if valid_603244 != nil:
    section.add "Engine", valid_603244
  var valid_603245 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603245 = validateParameter(valid_603245, JArray, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "VpcSecurityGroupIds", valid_603245
  var valid_603246 = formData.getOrDefault("Iops")
  valid_603246 = validateParameter(valid_603246, JInt, required = false, default = nil)
  if valid_603246 != nil:
    section.add "Iops", valid_603246
  var valid_603247 = formData.getOrDefault("DBName")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "DBName", valid_603247
  var valid_603248 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = nil)
  if valid_603248 != nil:
    section.add "DBInstanceIdentifier", valid_603248
  var valid_603249 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603249 = validateParameter(valid_603249, JInt, required = false, default = nil)
  if valid_603249 != nil:
    section.add "BackupRetentionPeriod", valid_603249
  var valid_603250 = formData.getOrDefault("DBParameterGroupName")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "DBParameterGroupName", valid_603250
  var valid_603251 = formData.getOrDefault("OptionGroupName")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "OptionGroupName", valid_603251
  var valid_603252 = formData.getOrDefault("Tags")
  valid_603252 = validateParameter(valid_603252, JArray, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "Tags", valid_603252
  var valid_603253 = formData.getOrDefault("MasterUserPassword")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "MasterUserPassword", valid_603253
  var valid_603254 = formData.getOrDefault("DBSubnetGroupName")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "DBSubnetGroupName", valid_603254
  var valid_603255 = formData.getOrDefault("AvailabilityZone")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "AvailabilityZone", valid_603255
  var valid_603256 = formData.getOrDefault("MultiAZ")
  valid_603256 = validateParameter(valid_603256, JBool, required = false, default = nil)
  if valid_603256 != nil:
    section.add "MultiAZ", valid_603256
  var valid_603257 = formData.getOrDefault("AllocatedStorage")
  valid_603257 = validateParameter(valid_603257, JInt, required = true, default = nil)
  if valid_603257 != nil:
    section.add "AllocatedStorage", valid_603257
  var valid_603258 = formData.getOrDefault("PubliclyAccessible")
  valid_603258 = validateParameter(valid_603258, JBool, required = false, default = nil)
  if valid_603258 != nil:
    section.add "PubliclyAccessible", valid_603258
  var valid_603259 = formData.getOrDefault("MasterUsername")
  valid_603259 = validateParameter(valid_603259, JString, required = true,
                                 default = nil)
  if valid_603259 != nil:
    section.add "MasterUsername", valid_603259
  var valid_603260 = formData.getOrDefault("DBInstanceClass")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "DBInstanceClass", valid_603260
  var valid_603261 = formData.getOrDefault("CharacterSetName")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "CharacterSetName", valid_603261
  var valid_603262 = formData.getOrDefault("PreferredBackupWindow")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "PreferredBackupWindow", valid_603262
  var valid_603263 = formData.getOrDefault("LicenseModel")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "LicenseModel", valid_603263
  var valid_603264 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603264 = validateParameter(valid_603264, JBool, required = false, default = nil)
  if valid_603264 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603264
  var valid_603265 = formData.getOrDefault("EngineVersion")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "EngineVersion", valid_603265
  var valid_603266 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "PreferredMaintenanceWindow", valid_603266
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603267: Call_PostCreateDBInstance_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603267.validator(path, query, header, formData, body)
  let scheme = call_603267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603267.url(scheme.get, call_603267.host, call_603267.base,
                         call_603267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603267, url, valid)

proc call*(call_603268: Call_PostCreateDBInstance_603230; Engine: string;
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
  var query_603269 = newJObject()
  var formData_603270 = newJObject()
  if DBSecurityGroups != nil:
    formData_603270.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603270, "Port", newJInt(Port))
  add(formData_603270, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603270.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603270, "Iops", newJInt(Iops))
  add(formData_603270, "DBName", newJString(DBName))
  add(formData_603270, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603270, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603270, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603270, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603270.add "Tags", Tags
  add(formData_603270, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603270, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603270, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603270, "MultiAZ", newJBool(MultiAZ))
  add(query_603269, "Action", newJString(Action))
  add(formData_603270, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603270, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603270, "MasterUsername", newJString(MasterUsername))
  add(formData_603270, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603270, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603270, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603270, "LicenseModel", newJString(LicenseModel))
  add(formData_603270, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603270, "EngineVersion", newJString(EngineVersion))
  add(query_603269, "Version", newJString(Version))
  add(formData_603270, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603268.call(nil, query_603269, nil, formData_603270, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603230(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603231, base: "/",
    url: url_PostCreateDBInstance_603232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603190 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstance_603192(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_603191(path: JsonNode; query: JsonNode;
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
  var valid_603193 = query.getOrDefault("Engine")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = nil)
  if valid_603193 != nil:
    section.add "Engine", valid_603193
  var valid_603194 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "PreferredMaintenanceWindow", valid_603194
  var valid_603195 = query.getOrDefault("AllocatedStorage")
  valid_603195 = validateParameter(valid_603195, JInt, required = true, default = nil)
  if valid_603195 != nil:
    section.add "AllocatedStorage", valid_603195
  var valid_603196 = query.getOrDefault("OptionGroupName")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "OptionGroupName", valid_603196
  var valid_603197 = query.getOrDefault("DBSecurityGroups")
  valid_603197 = validateParameter(valid_603197, JArray, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "DBSecurityGroups", valid_603197
  var valid_603198 = query.getOrDefault("MasterUserPassword")
  valid_603198 = validateParameter(valid_603198, JString, required = true,
                                 default = nil)
  if valid_603198 != nil:
    section.add "MasterUserPassword", valid_603198
  var valid_603199 = query.getOrDefault("AvailabilityZone")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "AvailabilityZone", valid_603199
  var valid_603200 = query.getOrDefault("Iops")
  valid_603200 = validateParameter(valid_603200, JInt, required = false, default = nil)
  if valid_603200 != nil:
    section.add "Iops", valid_603200
  var valid_603201 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603201 = validateParameter(valid_603201, JArray, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "VpcSecurityGroupIds", valid_603201
  var valid_603202 = query.getOrDefault("MultiAZ")
  valid_603202 = validateParameter(valid_603202, JBool, required = false, default = nil)
  if valid_603202 != nil:
    section.add "MultiAZ", valid_603202
  var valid_603203 = query.getOrDefault("LicenseModel")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "LicenseModel", valid_603203
  var valid_603204 = query.getOrDefault("BackupRetentionPeriod")
  valid_603204 = validateParameter(valid_603204, JInt, required = false, default = nil)
  if valid_603204 != nil:
    section.add "BackupRetentionPeriod", valid_603204
  var valid_603205 = query.getOrDefault("DBName")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "DBName", valid_603205
  var valid_603206 = query.getOrDefault("DBParameterGroupName")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "DBParameterGroupName", valid_603206
  var valid_603207 = query.getOrDefault("Tags")
  valid_603207 = validateParameter(valid_603207, JArray, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "Tags", valid_603207
  var valid_603208 = query.getOrDefault("DBInstanceClass")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = nil)
  if valid_603208 != nil:
    section.add "DBInstanceClass", valid_603208
  var valid_603209 = query.getOrDefault("Action")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603209 != nil:
    section.add "Action", valid_603209
  var valid_603210 = query.getOrDefault("DBSubnetGroupName")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "DBSubnetGroupName", valid_603210
  var valid_603211 = query.getOrDefault("CharacterSetName")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "CharacterSetName", valid_603211
  var valid_603212 = query.getOrDefault("PubliclyAccessible")
  valid_603212 = validateParameter(valid_603212, JBool, required = false, default = nil)
  if valid_603212 != nil:
    section.add "PubliclyAccessible", valid_603212
  var valid_603213 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603213 = validateParameter(valid_603213, JBool, required = false, default = nil)
  if valid_603213 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603213
  var valid_603214 = query.getOrDefault("EngineVersion")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "EngineVersion", valid_603214
  var valid_603215 = query.getOrDefault("Port")
  valid_603215 = validateParameter(valid_603215, JInt, required = false, default = nil)
  if valid_603215 != nil:
    section.add "Port", valid_603215
  var valid_603216 = query.getOrDefault("PreferredBackupWindow")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "PreferredBackupWindow", valid_603216
  var valid_603217 = query.getOrDefault("Version")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603217 != nil:
    section.add "Version", valid_603217
  var valid_603218 = query.getOrDefault("DBInstanceIdentifier")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = nil)
  if valid_603218 != nil:
    section.add "DBInstanceIdentifier", valid_603218
  var valid_603219 = query.getOrDefault("MasterUsername")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "MasterUsername", valid_603219
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603227: Call_GetCreateDBInstance_603190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603227.validator(path, query, header, formData, body)
  let scheme = call_603227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603227.url(scheme.get, call_603227.host, call_603227.base,
                         call_603227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603227, url, valid)

proc call*(call_603228: Call_GetCreateDBInstance_603190; Engine: string;
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
  var query_603229 = newJObject()
  add(query_603229, "Engine", newJString(Engine))
  add(query_603229, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603229, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603229, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603229.add "DBSecurityGroups", DBSecurityGroups
  add(query_603229, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603229, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603229, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603229.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603229, "MultiAZ", newJBool(MultiAZ))
  add(query_603229, "LicenseModel", newJString(LicenseModel))
  add(query_603229, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603229, "DBName", newJString(DBName))
  add(query_603229, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_603229.add "Tags", Tags
  add(query_603229, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603229, "Action", newJString(Action))
  add(query_603229, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603229, "CharacterSetName", newJString(CharacterSetName))
  add(query_603229, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603229, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603229, "EngineVersion", newJString(EngineVersion))
  add(query_603229, "Port", newJInt(Port))
  add(query_603229, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603229, "Version", newJString(Version))
  add(query_603229, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603229, "MasterUsername", newJString(MasterUsername))
  result = call_603228.call(nil, query_603229, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603190(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603191, base: "/",
    url: url_GetCreateDBInstance_603192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603297 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstanceReadReplica_603299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_603298(path: JsonNode;
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
  var valid_603300 = query.getOrDefault("Action")
  valid_603300 = validateParameter(valid_603300, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603300 != nil:
    section.add "Action", valid_603300
  var valid_603301 = query.getOrDefault("Version")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603301 != nil:
    section.add "Version", valid_603301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603302 = header.getOrDefault("X-Amz-Date")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Date", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Security-Token")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Security-Token", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
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
  var valid_603309 = formData.getOrDefault("Port")
  valid_603309 = validateParameter(valid_603309, JInt, required = false, default = nil)
  if valid_603309 != nil:
    section.add "Port", valid_603309
  var valid_603310 = formData.getOrDefault("Iops")
  valid_603310 = validateParameter(valid_603310, JInt, required = false, default = nil)
  if valid_603310 != nil:
    section.add "Iops", valid_603310
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603311 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603311 = validateParameter(valid_603311, JString, required = true,
                                 default = nil)
  if valid_603311 != nil:
    section.add "DBInstanceIdentifier", valid_603311
  var valid_603312 = formData.getOrDefault("OptionGroupName")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "OptionGroupName", valid_603312
  var valid_603313 = formData.getOrDefault("Tags")
  valid_603313 = validateParameter(valid_603313, JArray, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "Tags", valid_603313
  var valid_603314 = formData.getOrDefault("DBSubnetGroupName")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "DBSubnetGroupName", valid_603314
  var valid_603315 = formData.getOrDefault("AvailabilityZone")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "AvailabilityZone", valid_603315
  var valid_603316 = formData.getOrDefault("PubliclyAccessible")
  valid_603316 = validateParameter(valid_603316, JBool, required = false, default = nil)
  if valid_603316 != nil:
    section.add "PubliclyAccessible", valid_603316
  var valid_603317 = formData.getOrDefault("DBInstanceClass")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "DBInstanceClass", valid_603317
  var valid_603318 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = nil)
  if valid_603318 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603318
  var valid_603319 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603319 = validateParameter(valid_603319, JBool, required = false, default = nil)
  if valid_603319 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603320: Call_PostCreateDBInstanceReadReplica_603297;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603320.validator(path, query, header, formData, body)
  let scheme = call_603320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603320.url(scheme.get, call_603320.host, call_603320.base,
                         call_603320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603320, url, valid)

proc call*(call_603321: Call_PostCreateDBInstanceReadReplica_603297;
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
  var query_603322 = newJObject()
  var formData_603323 = newJObject()
  add(formData_603323, "Port", newJInt(Port))
  add(formData_603323, "Iops", newJInt(Iops))
  add(formData_603323, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603323, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603323.add "Tags", Tags
  add(formData_603323, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603323, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603322, "Action", newJString(Action))
  add(formData_603323, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603323, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603323, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603323, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603322, "Version", newJString(Version))
  result = call_603321.call(nil, query_603322, nil, formData_603323, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603297(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603298, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603271 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstanceReadReplica_603273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_603272(path: JsonNode;
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
  var valid_603274 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = nil)
  if valid_603274 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603274
  var valid_603275 = query.getOrDefault("OptionGroupName")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "OptionGroupName", valid_603275
  var valid_603276 = query.getOrDefault("AvailabilityZone")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "AvailabilityZone", valid_603276
  var valid_603277 = query.getOrDefault("Iops")
  valid_603277 = validateParameter(valid_603277, JInt, required = false, default = nil)
  if valid_603277 != nil:
    section.add "Iops", valid_603277
  var valid_603278 = query.getOrDefault("Tags")
  valid_603278 = validateParameter(valid_603278, JArray, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "Tags", valid_603278
  var valid_603279 = query.getOrDefault("DBInstanceClass")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "DBInstanceClass", valid_603279
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("DBSubnetGroupName")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "DBSubnetGroupName", valid_603281
  var valid_603282 = query.getOrDefault("PubliclyAccessible")
  valid_603282 = validateParameter(valid_603282, JBool, required = false, default = nil)
  if valid_603282 != nil:
    section.add "PubliclyAccessible", valid_603282
  var valid_603283 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603283 = validateParameter(valid_603283, JBool, required = false, default = nil)
  if valid_603283 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603283
  var valid_603284 = query.getOrDefault("Port")
  valid_603284 = validateParameter(valid_603284, JInt, required = false, default = nil)
  if valid_603284 != nil:
    section.add "Port", valid_603284
  var valid_603285 = query.getOrDefault("Version")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603285 != nil:
    section.add "Version", valid_603285
  var valid_603286 = query.getOrDefault("DBInstanceIdentifier")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "DBInstanceIdentifier", valid_603286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_GetCreateDBInstanceReadReplica_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_GetCreateDBInstanceReadReplica_603271;
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
  var query_603296 = newJObject()
  add(query_603296, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603296, "OptionGroupName", newJString(OptionGroupName))
  add(query_603296, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603296, "Iops", newJInt(Iops))
  if Tags != nil:
    query_603296.add "Tags", Tags
  add(query_603296, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603296, "Action", newJString(Action))
  add(query_603296, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603296, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603296, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603296, "Port", newJInt(Port))
  add(query_603296, "Version", newJString(Version))
  add(query_603296, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603295.call(nil, query_603296, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603271(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603272, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603343 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBParameterGroup_603345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_603344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603346 = query.getOrDefault("Action")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603346 != nil:
    section.add "Action", valid_603346
  var valid_603347 = query.getOrDefault("Version")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603347 != nil:
    section.add "Version", valid_603347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603348 = header.getOrDefault("X-Amz-Date")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Date", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Security-Token")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Security-Token", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Content-Sha256", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Algorithm")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Algorithm", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Signature")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Signature", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-SignedHeaders", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Credential")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Credential", valid_603354
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603355 = formData.getOrDefault("DBParameterGroupName")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = nil)
  if valid_603355 != nil:
    section.add "DBParameterGroupName", valid_603355
  var valid_603356 = formData.getOrDefault("Tags")
  valid_603356 = validateParameter(valid_603356, JArray, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "Tags", valid_603356
  var valid_603357 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = nil)
  if valid_603357 != nil:
    section.add "DBParameterGroupFamily", valid_603357
  var valid_603358 = formData.getOrDefault("Description")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = nil)
  if valid_603358 != nil:
    section.add "Description", valid_603358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603359: Call_PostCreateDBParameterGroup_603343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603359.validator(path, query, header, formData, body)
  let scheme = call_603359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603359.url(scheme.get, call_603359.host, call_603359.base,
                         call_603359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603359, url, valid)

proc call*(call_603360: Call_PostCreateDBParameterGroup_603343;
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
  var query_603361 = newJObject()
  var formData_603362 = newJObject()
  add(formData_603362, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_603362.add "Tags", Tags
  add(query_603361, "Action", newJString(Action))
  add(formData_603362, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603361, "Version", newJString(Version))
  add(formData_603362, "Description", newJString(Description))
  result = call_603360.call(nil, query_603361, nil, formData_603362, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603343(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603344, base: "/",
    url: url_PostCreateDBParameterGroup_603345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603324 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBParameterGroup_603326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_603325(path: JsonNode; query: JsonNode;
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
  var valid_603327 = query.getOrDefault("Description")
  valid_603327 = validateParameter(valid_603327, JString, required = true,
                                 default = nil)
  if valid_603327 != nil:
    section.add "Description", valid_603327
  var valid_603328 = query.getOrDefault("DBParameterGroupFamily")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = nil)
  if valid_603328 != nil:
    section.add "DBParameterGroupFamily", valid_603328
  var valid_603329 = query.getOrDefault("Tags")
  valid_603329 = validateParameter(valid_603329, JArray, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "Tags", valid_603329
  var valid_603330 = query.getOrDefault("DBParameterGroupName")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = nil)
  if valid_603330 != nil:
    section.add "DBParameterGroupName", valid_603330
  var valid_603331 = query.getOrDefault("Action")
  valid_603331 = validateParameter(valid_603331, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603331 != nil:
    section.add "Action", valid_603331
  var valid_603332 = query.getOrDefault("Version")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603332 != nil:
    section.add "Version", valid_603332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603333 = header.getOrDefault("X-Amz-Date")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Date", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Security-Token")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Security-Token", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Content-Sha256", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Algorithm")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Algorithm", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Signature")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Signature", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-SignedHeaders", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Credential")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Credential", valid_603339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603340: Call_GetCreateDBParameterGroup_603324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603340.validator(path, query, header, formData, body)
  let scheme = call_603340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603340.url(scheme.get, call_603340.host, call_603340.base,
                         call_603340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603340, url, valid)

proc call*(call_603341: Call_GetCreateDBParameterGroup_603324; Description: string;
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
  var query_603342 = newJObject()
  add(query_603342, "Description", newJString(Description))
  add(query_603342, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603342.add "Tags", Tags
  add(query_603342, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603342, "Action", newJString(Action))
  add(query_603342, "Version", newJString(Version))
  result = call_603341.call(nil, query_603342, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603324(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603325, base: "/",
    url: url_GetCreateDBParameterGroup_603326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603381 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSecurityGroup_603383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_603382(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603384 = query.getOrDefault("Action")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603384 != nil:
    section.add "Action", valid_603384
  var valid_603385 = query.getOrDefault("Version")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603393 = formData.getOrDefault("DBSecurityGroupName")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = nil)
  if valid_603393 != nil:
    section.add "DBSecurityGroupName", valid_603393
  var valid_603394 = formData.getOrDefault("Tags")
  valid_603394 = validateParameter(valid_603394, JArray, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "Tags", valid_603394
  var valid_603395 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "DBSecurityGroupDescription", valid_603395
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603396: Call_PostCreateDBSecurityGroup_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603396.validator(path, query, header, formData, body)
  let scheme = call_603396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603396.url(scheme.get, call_603396.host, call_603396.base,
                         call_603396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603396, url, valid)

proc call*(call_603397: Call_PostCreateDBSecurityGroup_603381;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603398 = newJObject()
  var formData_603399 = newJObject()
  add(formData_603399, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_603399.add "Tags", Tags
  add(query_603398, "Action", newJString(Action))
  add(formData_603399, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603398, "Version", newJString(Version))
  result = call_603397.call(nil, query_603398, nil, formData_603399, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603381(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603382, base: "/",
    url: url_PostCreateDBSecurityGroup_603383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603363 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSecurityGroup_603365(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_603364(path: JsonNode; query: JsonNode;
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
  var valid_603366 = query.getOrDefault("DBSecurityGroupName")
  valid_603366 = validateParameter(valid_603366, JString, required = true,
                                 default = nil)
  if valid_603366 != nil:
    section.add "DBSecurityGroupName", valid_603366
  var valid_603367 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = nil)
  if valid_603367 != nil:
    section.add "DBSecurityGroupDescription", valid_603367
  var valid_603368 = query.getOrDefault("Tags")
  valid_603368 = validateParameter(valid_603368, JArray, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "Tags", valid_603368
  var valid_603369 = query.getOrDefault("Action")
  valid_603369 = validateParameter(valid_603369, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603369 != nil:
    section.add "Action", valid_603369
  var valid_603370 = query.getOrDefault("Version")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603370 != nil:
    section.add "Version", valid_603370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603371 = header.getOrDefault("X-Amz-Date")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Date", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Security-Token")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Security-Token", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Content-Sha256", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Algorithm")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Algorithm", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Signature")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Signature", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-SignedHeaders", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Credential")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Credential", valid_603377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_GetCreateDBSecurityGroup_603363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_GetCreateDBSecurityGroup_603363;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603380 = newJObject()
  add(query_603380, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603380, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_603380.add "Tags", Tags
  add(query_603380, "Action", newJString(Action))
  add(query_603380, "Version", newJString(Version))
  result = call_603379.call(nil, query_603380, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603363(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603364, base: "/",
    url: url_GetCreateDBSecurityGroup_603365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603418 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSnapshot_603420(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_603419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603421 = query.getOrDefault("Action")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603421 != nil:
    section.add "Action", valid_603421
  var valid_603422 = query.getOrDefault("Version")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603422 != nil:
    section.add "Version", valid_603422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603423 = header.getOrDefault("X-Amz-Date")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Date", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Security-Token")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Security-Token", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Algorithm")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Algorithm", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Signature")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Signature", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-SignedHeaders", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603430 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603430 = validateParameter(valid_603430, JString, required = true,
                                 default = nil)
  if valid_603430 != nil:
    section.add "DBInstanceIdentifier", valid_603430
  var valid_603431 = formData.getOrDefault("Tags")
  valid_603431 = validateParameter(valid_603431, JArray, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "Tags", valid_603431
  var valid_603432 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = nil)
  if valid_603432 != nil:
    section.add "DBSnapshotIdentifier", valid_603432
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_PostCreateDBSnapshot_603418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603433, url, valid)

proc call*(call_603434: Call_PostCreateDBSnapshot_603418;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603435 = newJObject()
  var formData_603436 = newJObject()
  add(formData_603436, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603436.add "Tags", Tags
  add(formData_603436, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603435, "Action", newJString(Action))
  add(query_603435, "Version", newJString(Version))
  result = call_603434.call(nil, query_603435, nil, formData_603436, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603418(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603419, base: "/",
    url: url_PostCreateDBSnapshot_603420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603400 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSnapshot_603402(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_603401(path: JsonNode; query: JsonNode;
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
  var valid_603403 = query.getOrDefault("Tags")
  valid_603403 = validateParameter(valid_603403, JArray, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "Tags", valid_603403
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603404 = query.getOrDefault("Action")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603404 != nil:
    section.add "Action", valid_603404
  var valid_603405 = query.getOrDefault("Version")
  valid_603405 = validateParameter(valid_603405, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603405 != nil:
    section.add "Version", valid_603405
  var valid_603406 = query.getOrDefault("DBInstanceIdentifier")
  valid_603406 = validateParameter(valid_603406, JString, required = true,
                                 default = nil)
  if valid_603406 != nil:
    section.add "DBInstanceIdentifier", valid_603406
  var valid_603407 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = nil)
  if valid_603407 != nil:
    section.add "DBSnapshotIdentifier", valid_603407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603408 = header.getOrDefault("X-Amz-Date")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Date", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Security-Token")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Security-Token", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Algorithm")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Algorithm", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Signature")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Signature", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-SignedHeaders", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_GetCreateDBSnapshot_603400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_GetCreateDBSnapshot_603400;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603417 = newJObject()
  if Tags != nil:
    query_603417.add "Tags", Tags
  add(query_603417, "Action", newJString(Action))
  add(query_603417, "Version", newJString(Version))
  add(query_603417, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603417, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603416.call(nil, query_603417, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603400(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603401, base: "/",
    url: url_GetCreateDBSnapshot_603402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603456 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSubnetGroup_603458(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_603457(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603459 = query.getOrDefault("Action")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603459 != nil:
    section.add "Action", valid_603459
  var valid_603460 = query.getOrDefault("Version")
  valid_603460 = validateParameter(valid_603460, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603460 != nil:
    section.add "Version", valid_603460
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_603468 = formData.getOrDefault("Tags")
  valid_603468 = validateParameter(valid_603468, JArray, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "Tags", valid_603468
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603469 = formData.getOrDefault("DBSubnetGroupName")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "DBSubnetGroupName", valid_603469
  var valid_603470 = formData.getOrDefault("SubnetIds")
  valid_603470 = validateParameter(valid_603470, JArray, required = true, default = nil)
  if valid_603470 != nil:
    section.add "SubnetIds", valid_603470
  var valid_603471 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603471 = validateParameter(valid_603471, JString, required = true,
                                 default = nil)
  if valid_603471 != nil:
    section.add "DBSubnetGroupDescription", valid_603471
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603472: Call_PostCreateDBSubnetGroup_603456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603472.validator(path, query, header, formData, body)
  let scheme = call_603472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603472.url(scheme.get, call_603472.host, call_603472.base,
                         call_603472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603472, url, valid)

proc call*(call_603473: Call_PostCreateDBSubnetGroup_603456;
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
  var query_603474 = newJObject()
  var formData_603475 = newJObject()
  if Tags != nil:
    formData_603475.add "Tags", Tags
  add(formData_603475, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603475.add "SubnetIds", SubnetIds
  add(query_603474, "Action", newJString(Action))
  add(formData_603475, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603474, "Version", newJString(Version))
  result = call_603473.call(nil, query_603474, nil, formData_603475, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603456(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603457, base: "/",
    url: url_PostCreateDBSubnetGroup_603458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603437 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSubnetGroup_603439(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_603438(path: JsonNode; query: JsonNode;
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
  var valid_603440 = query.getOrDefault("Tags")
  valid_603440 = validateParameter(valid_603440, JArray, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "Tags", valid_603440
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603441 = query.getOrDefault("Action")
  valid_603441 = validateParameter(valid_603441, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603441 != nil:
    section.add "Action", valid_603441
  var valid_603442 = query.getOrDefault("DBSubnetGroupName")
  valid_603442 = validateParameter(valid_603442, JString, required = true,
                                 default = nil)
  if valid_603442 != nil:
    section.add "DBSubnetGroupName", valid_603442
  var valid_603443 = query.getOrDefault("SubnetIds")
  valid_603443 = validateParameter(valid_603443, JArray, required = true, default = nil)
  if valid_603443 != nil:
    section.add "SubnetIds", valid_603443
  var valid_603444 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603444 = validateParameter(valid_603444, JString, required = true,
                                 default = nil)
  if valid_603444 != nil:
    section.add "DBSubnetGroupDescription", valid_603444
  var valid_603445 = query.getOrDefault("Version")
  valid_603445 = validateParameter(valid_603445, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603453: Call_GetCreateDBSubnetGroup_603437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603453.validator(path, query, header, formData, body)
  let scheme = call_603453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603453.url(scheme.get, call_603453.host, call_603453.base,
                         call_603453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603453, url, valid)

proc call*(call_603454: Call_GetCreateDBSubnetGroup_603437;
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
  var query_603455 = newJObject()
  if Tags != nil:
    query_603455.add "Tags", Tags
  add(query_603455, "Action", newJString(Action))
  add(query_603455, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603455.add "SubnetIds", SubnetIds
  add(query_603455, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603455, "Version", newJString(Version))
  result = call_603454.call(nil, query_603455, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603437(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603438, base: "/",
    url: url_GetCreateDBSubnetGroup_603439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603498 = ref object of OpenApiRestCall_602450
proc url_PostCreateEventSubscription_603500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_603499(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603501 = query.getOrDefault("Action")
  valid_603501 = validateParameter(valid_603501, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603501 != nil:
    section.add "Action", valid_603501
  var valid_603502 = query.getOrDefault("Version")
  valid_603502 = validateParameter(valid_603502, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603502 != nil:
    section.add "Version", valid_603502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603503 = header.getOrDefault("X-Amz-Date")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Date", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Security-Token")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Security-Token", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Content-Sha256", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Algorithm")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Algorithm", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Signature")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Signature", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-SignedHeaders", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Credential")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Credential", valid_603509
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
  var valid_603510 = formData.getOrDefault("Enabled")
  valid_603510 = validateParameter(valid_603510, JBool, required = false, default = nil)
  if valid_603510 != nil:
    section.add "Enabled", valid_603510
  var valid_603511 = formData.getOrDefault("EventCategories")
  valid_603511 = validateParameter(valid_603511, JArray, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "EventCategories", valid_603511
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603512 = formData.getOrDefault("SnsTopicArn")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = nil)
  if valid_603512 != nil:
    section.add "SnsTopicArn", valid_603512
  var valid_603513 = formData.getOrDefault("SourceIds")
  valid_603513 = validateParameter(valid_603513, JArray, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "SourceIds", valid_603513
  var valid_603514 = formData.getOrDefault("Tags")
  valid_603514 = validateParameter(valid_603514, JArray, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "Tags", valid_603514
  var valid_603515 = formData.getOrDefault("SubscriptionName")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "SubscriptionName", valid_603515
  var valid_603516 = formData.getOrDefault("SourceType")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "SourceType", valid_603516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_PostCreateEventSubscription_603498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603517, url, valid)

proc call*(call_603518: Call_PostCreateEventSubscription_603498;
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
  var query_603519 = newJObject()
  var formData_603520 = newJObject()
  add(formData_603520, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603520.add "EventCategories", EventCategories
  add(formData_603520, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603520.add "SourceIds", SourceIds
  if Tags != nil:
    formData_603520.add "Tags", Tags
  add(formData_603520, "SubscriptionName", newJString(SubscriptionName))
  add(query_603519, "Action", newJString(Action))
  add(query_603519, "Version", newJString(Version))
  add(formData_603520, "SourceType", newJString(SourceType))
  result = call_603518.call(nil, query_603519, nil, formData_603520, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603498(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603499, base: "/",
    url: url_PostCreateEventSubscription_603500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603476 = ref object of OpenApiRestCall_602450
proc url_GetCreateEventSubscription_603478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_603477(path: JsonNode; query: JsonNode;
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
  var valid_603479 = query.getOrDefault("SourceType")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "SourceType", valid_603479
  var valid_603480 = query.getOrDefault("SourceIds")
  valid_603480 = validateParameter(valid_603480, JArray, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "SourceIds", valid_603480
  var valid_603481 = query.getOrDefault("Enabled")
  valid_603481 = validateParameter(valid_603481, JBool, required = false, default = nil)
  if valid_603481 != nil:
    section.add "Enabled", valid_603481
  var valid_603482 = query.getOrDefault("Tags")
  valid_603482 = validateParameter(valid_603482, JArray, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "Tags", valid_603482
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603483 = query.getOrDefault("Action")
  valid_603483 = validateParameter(valid_603483, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603483 != nil:
    section.add "Action", valid_603483
  var valid_603484 = query.getOrDefault("SnsTopicArn")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = nil)
  if valid_603484 != nil:
    section.add "SnsTopicArn", valid_603484
  var valid_603485 = query.getOrDefault("EventCategories")
  valid_603485 = validateParameter(valid_603485, JArray, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "EventCategories", valid_603485
  var valid_603486 = query.getOrDefault("SubscriptionName")
  valid_603486 = validateParameter(valid_603486, JString, required = true,
                                 default = nil)
  if valid_603486 != nil:
    section.add "SubscriptionName", valid_603486
  var valid_603487 = query.getOrDefault("Version")
  valid_603487 = validateParameter(valid_603487, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603487 != nil:
    section.add "Version", valid_603487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603488 = header.getOrDefault("X-Amz-Date")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Date", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Security-Token")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Security-Token", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Content-Sha256", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Algorithm")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Algorithm", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Signature")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Signature", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-SignedHeaders", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Credential")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Credential", valid_603494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603495: Call_GetCreateEventSubscription_603476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603495.validator(path, query, header, formData, body)
  let scheme = call_603495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603495.url(scheme.get, call_603495.host, call_603495.base,
                         call_603495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603495, url, valid)

proc call*(call_603496: Call_GetCreateEventSubscription_603476;
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
  var query_603497 = newJObject()
  add(query_603497, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603497.add "SourceIds", SourceIds
  add(query_603497, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_603497.add "Tags", Tags
  add(query_603497, "Action", newJString(Action))
  add(query_603497, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603497.add "EventCategories", EventCategories
  add(query_603497, "SubscriptionName", newJString(SubscriptionName))
  add(query_603497, "Version", newJString(Version))
  result = call_603496.call(nil, query_603497, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603476(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603477, base: "/",
    url: url_GetCreateEventSubscription_603478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603541 = ref object of OpenApiRestCall_602450
proc url_PostCreateOptionGroup_603543(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_603542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603544 = query.getOrDefault("Action")
  valid_603544 = validateParameter(valid_603544, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603544 != nil:
    section.add "Action", valid_603544
  var valid_603545 = query.getOrDefault("Version")
  valid_603545 = validateParameter(valid_603545, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603545 != nil:
    section.add "Version", valid_603545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603546 = header.getOrDefault("X-Amz-Date")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Date", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Security-Token")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Security-Token", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Content-Sha256", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-Algorithm")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-Algorithm", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Signature")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Signature", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-SignedHeaders", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Credential")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Credential", valid_603552
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603553 = formData.getOrDefault("MajorEngineVersion")
  valid_603553 = validateParameter(valid_603553, JString, required = true,
                                 default = nil)
  if valid_603553 != nil:
    section.add "MajorEngineVersion", valid_603553
  var valid_603554 = formData.getOrDefault("OptionGroupName")
  valid_603554 = validateParameter(valid_603554, JString, required = true,
                                 default = nil)
  if valid_603554 != nil:
    section.add "OptionGroupName", valid_603554
  var valid_603555 = formData.getOrDefault("Tags")
  valid_603555 = validateParameter(valid_603555, JArray, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "Tags", valid_603555
  var valid_603556 = formData.getOrDefault("EngineName")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = nil)
  if valid_603556 != nil:
    section.add "EngineName", valid_603556
  var valid_603557 = formData.getOrDefault("OptionGroupDescription")
  valid_603557 = validateParameter(valid_603557, JString, required = true,
                                 default = nil)
  if valid_603557 != nil:
    section.add "OptionGroupDescription", valid_603557
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603558: Call_PostCreateOptionGroup_603541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603558.validator(path, query, header, formData, body)
  let scheme = call_603558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603558.url(scheme.get, call_603558.host, call_603558.base,
                         call_603558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603558, url, valid)

proc call*(call_603559: Call_PostCreateOptionGroup_603541;
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
  var query_603560 = newJObject()
  var formData_603561 = newJObject()
  add(formData_603561, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603561, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603561.add "Tags", Tags
  add(query_603560, "Action", newJString(Action))
  add(formData_603561, "EngineName", newJString(EngineName))
  add(formData_603561, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603560, "Version", newJString(Version))
  result = call_603559.call(nil, query_603560, nil, formData_603561, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603541(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603542, base: "/",
    url: url_PostCreateOptionGroup_603543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603521 = ref object of OpenApiRestCall_602450
proc url_GetCreateOptionGroup_603523(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_603522(path: JsonNode; query: JsonNode;
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
  var valid_603524 = query.getOrDefault("OptionGroupName")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "OptionGroupName", valid_603524
  var valid_603525 = query.getOrDefault("Tags")
  valid_603525 = validateParameter(valid_603525, JArray, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "Tags", valid_603525
  var valid_603526 = query.getOrDefault("OptionGroupDescription")
  valid_603526 = validateParameter(valid_603526, JString, required = true,
                                 default = nil)
  if valid_603526 != nil:
    section.add "OptionGroupDescription", valid_603526
  var valid_603527 = query.getOrDefault("Action")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603527 != nil:
    section.add "Action", valid_603527
  var valid_603528 = query.getOrDefault("Version")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603528 != nil:
    section.add "Version", valid_603528
  var valid_603529 = query.getOrDefault("EngineName")
  valid_603529 = validateParameter(valid_603529, JString, required = true,
                                 default = nil)
  if valid_603529 != nil:
    section.add "EngineName", valid_603529
  var valid_603530 = query.getOrDefault("MajorEngineVersion")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = nil)
  if valid_603530 != nil:
    section.add "MajorEngineVersion", valid_603530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603531 = header.getOrDefault("X-Amz-Date")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Date", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Security-Token")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Security-Token", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Content-Sha256", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Algorithm")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Algorithm", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Signature")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Signature", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-SignedHeaders", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Credential")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Credential", valid_603537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_GetCreateOptionGroup_603521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603538, url, valid)

proc call*(call_603539: Call_GetCreateOptionGroup_603521; OptionGroupName: string;
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
  var query_603540 = newJObject()
  add(query_603540, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_603540.add "Tags", Tags
  add(query_603540, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603540, "Action", newJString(Action))
  add(query_603540, "Version", newJString(Version))
  add(query_603540, "EngineName", newJString(EngineName))
  add(query_603540, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603539.call(nil, query_603540, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603521(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603522, base: "/",
    url: url_GetCreateOptionGroup_603523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603580 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBInstance_603582(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_603581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603583 = query.getOrDefault("Action")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603583 != nil:
    section.add "Action", valid_603583
  var valid_603584 = query.getOrDefault("Version")
  valid_603584 = validateParameter(valid_603584, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603592 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = nil)
  if valid_603592 != nil:
    section.add "DBInstanceIdentifier", valid_603592
  var valid_603593 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603593
  var valid_603594 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603594 = validateParameter(valid_603594, JBool, required = false, default = nil)
  if valid_603594 != nil:
    section.add "SkipFinalSnapshot", valid_603594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603595: Call_PostDeleteDBInstance_603580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603595.validator(path, query, header, formData, body)
  let scheme = call_603595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603595.url(scheme.get, call_603595.host, call_603595.base,
                         call_603595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603595, url, valid)

proc call*(call_603596: Call_PostDeleteDBInstance_603580;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603597 = newJObject()
  var formData_603598 = newJObject()
  add(formData_603598, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603598, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603597, "Action", newJString(Action))
  add(query_603597, "Version", newJString(Version))
  add(formData_603598, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603596.call(nil, query_603597, nil, formData_603598, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603580(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603581, base: "/",
    url: url_PostDeleteDBInstance_603582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603562 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBInstance_603564(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_603563(path: JsonNode; query: JsonNode;
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
  var valid_603565 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603565
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603566 = query.getOrDefault("Action")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603566 != nil:
    section.add "Action", valid_603566
  var valid_603567 = query.getOrDefault("SkipFinalSnapshot")
  valid_603567 = validateParameter(valid_603567, JBool, required = false, default = nil)
  if valid_603567 != nil:
    section.add "SkipFinalSnapshot", valid_603567
  var valid_603568 = query.getOrDefault("Version")
  valid_603568 = validateParameter(valid_603568, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603568 != nil:
    section.add "Version", valid_603568
  var valid_603569 = query.getOrDefault("DBInstanceIdentifier")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "DBInstanceIdentifier", valid_603569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Content-Sha256", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Algorithm")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Algorithm", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Signature")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Signature", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-SignedHeaders", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Credential")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Credential", valid_603576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603577: Call_GetDeleteDBInstance_603562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603577.validator(path, query, header, formData, body)
  let scheme = call_603577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603577.url(scheme.get, call_603577.host, call_603577.base,
                         call_603577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603577, url, valid)

proc call*(call_603578: Call_GetDeleteDBInstance_603562;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603579 = newJObject()
  add(query_603579, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603579, "Action", newJString(Action))
  add(query_603579, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603579, "Version", newJString(Version))
  add(query_603579, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603578.call(nil, query_603579, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603562(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603563, base: "/",
    url: url_GetDeleteDBInstance_603564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603615 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBParameterGroup_603617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_603616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBParameterGroup"))
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
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603627 = formData.getOrDefault("DBParameterGroupName")
  valid_603627 = validateParameter(valid_603627, JString, required = true,
                                 default = nil)
  if valid_603627 != nil:
    section.add "DBParameterGroupName", valid_603627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603628: Call_PostDeleteDBParameterGroup_603615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603628.validator(path, query, header, formData, body)
  let scheme = call_603628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603628.url(scheme.get, call_603628.host, call_603628.base,
                         call_603628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603628, url, valid)

proc call*(call_603629: Call_PostDeleteDBParameterGroup_603615;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603630 = newJObject()
  var formData_603631 = newJObject()
  add(formData_603631, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603630, "Action", newJString(Action))
  add(query_603630, "Version", newJString(Version))
  result = call_603629.call(nil, query_603630, nil, formData_603631, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603615(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603616, base: "/",
    url: url_PostDeleteDBParameterGroup_603617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603599 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBParameterGroup_603601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_603600(path: JsonNode; query: JsonNode;
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
  var valid_603602 = query.getOrDefault("DBParameterGroupName")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = nil)
  if valid_603602 != nil:
    section.add "DBParameterGroupName", valid_603602
  var valid_603603 = query.getOrDefault("Action")
  valid_603603 = validateParameter(valid_603603, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
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

proc call*(call_603612: Call_GetDeleteDBParameterGroup_603599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_GetDeleteDBParameterGroup_603599;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603614 = newJObject()
  add(query_603614, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603614, "Action", newJString(Action))
  add(query_603614, "Version", newJString(Version))
  result = call_603613.call(nil, query_603614, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603599(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603600, base: "/",
    url: url_GetDeleteDBParameterGroup_603601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603648 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSecurityGroup_603650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_603649(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSecurityGroup"))
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
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603660 = formData.getOrDefault("DBSecurityGroupName")
  valid_603660 = validateParameter(valid_603660, JString, required = true,
                                 default = nil)
  if valid_603660 != nil:
    section.add "DBSecurityGroupName", valid_603660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_PostDeleteDBSecurityGroup_603648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_PostDeleteDBSecurityGroup_603648;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603663 = newJObject()
  var formData_603664 = newJObject()
  add(formData_603664, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603663, "Action", newJString(Action))
  add(query_603663, "Version", newJString(Version))
  result = call_603662.call(nil, query_603663, nil, formData_603664, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603648(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603649, base: "/",
    url: url_PostDeleteDBSecurityGroup_603650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603632 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSecurityGroup_603634(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_603633(path: JsonNode; query: JsonNode;
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
  var valid_603635 = query.getOrDefault("DBSecurityGroupName")
  valid_603635 = validateParameter(valid_603635, JString, required = true,
                                 default = nil)
  if valid_603635 != nil:
    section.add "DBSecurityGroupName", valid_603635
  var valid_603636 = query.getOrDefault("Action")
  valid_603636 = validateParameter(valid_603636, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603636 != nil:
    section.add "Action", valid_603636
  var valid_603637 = query.getOrDefault("Version")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603645: Call_GetDeleteDBSecurityGroup_603632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603645.validator(path, query, header, formData, body)
  let scheme = call_603645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603645.url(scheme.get, call_603645.host, call_603645.base,
                         call_603645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603645, url, valid)

proc call*(call_603646: Call_GetDeleteDBSecurityGroup_603632;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603647 = newJObject()
  add(query_603647, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603647, "Action", newJString(Action))
  add(query_603647, "Version", newJString(Version))
  result = call_603646.call(nil, query_603647, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603632(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603633, base: "/",
    url: url_GetDeleteDBSecurityGroup_603634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603681 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSnapshot_603683(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_603682(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSnapshot"))
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
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603693 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = nil)
  if valid_603693 != nil:
    section.add "DBSnapshotIdentifier", valid_603693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603694: Call_PostDeleteDBSnapshot_603681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603694.validator(path, query, header, formData, body)
  let scheme = call_603694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603694.url(scheme.get, call_603694.host, call_603694.base,
                         call_603694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603694, url, valid)

proc call*(call_603695: Call_PostDeleteDBSnapshot_603681;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603696 = newJObject()
  var formData_603697 = newJObject()
  add(formData_603697, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603696, "Action", newJString(Action))
  add(query_603696, "Version", newJString(Version))
  result = call_603695.call(nil, query_603696, nil, formData_603697, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603681(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603682, base: "/",
    url: url_PostDeleteDBSnapshot_603683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603665 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSnapshot_603667(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_603666(path: JsonNode; query: JsonNode;
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
  var valid_603668 = query.getOrDefault("Action")
  valid_603668 = validateParameter(valid_603668, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603668 != nil:
    section.add "Action", valid_603668
  var valid_603669 = query.getOrDefault("Version")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603669 != nil:
    section.add "Version", valid_603669
  var valid_603670 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = nil)
  if valid_603670 != nil:
    section.add "DBSnapshotIdentifier", valid_603670
  result.add "query", section
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

proc call*(call_603678: Call_GetDeleteDBSnapshot_603665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603678.validator(path, query, header, formData, body)
  let scheme = call_603678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603678.url(scheme.get, call_603678.host, call_603678.base,
                         call_603678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603678, url, valid)

proc call*(call_603679: Call_GetDeleteDBSnapshot_603665;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603680 = newJObject()
  add(query_603680, "Action", newJString(Action))
  add(query_603680, "Version", newJString(Version))
  add(query_603680, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603679.call(nil, query_603680, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603665(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603666, base: "/",
    url: url_GetDeleteDBSnapshot_603667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603714 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSubnetGroup_603716(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_603715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603717 = validateParameter(valid_603717, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
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
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603726 = formData.getOrDefault("DBSubnetGroupName")
  valid_603726 = validateParameter(valid_603726, JString, required = true,
                                 default = nil)
  if valid_603726 != nil:
    section.add "DBSubnetGroupName", valid_603726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603727: Call_PostDeleteDBSubnetGroup_603714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603727.validator(path, query, header, formData, body)
  let scheme = call_603727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603727.url(scheme.get, call_603727.host, call_603727.base,
                         call_603727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603727, url, valid)

proc call*(call_603728: Call_PostDeleteDBSubnetGroup_603714;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603729 = newJObject()
  var formData_603730 = newJObject()
  add(formData_603730, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603729, "Action", newJString(Action))
  add(query_603729, "Version", newJString(Version))
  result = call_603728.call(nil, query_603729, nil, formData_603730, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603714(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603715, base: "/",
    url: url_PostDeleteDBSubnetGroup_603716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603698 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSubnetGroup_603700(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_603699(path: JsonNode; query: JsonNode;
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
  var valid_603701 = query.getOrDefault("Action")
  valid_603701 = validateParameter(valid_603701, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603701 != nil:
    section.add "Action", valid_603701
  var valid_603702 = query.getOrDefault("DBSubnetGroupName")
  valid_603702 = validateParameter(valid_603702, JString, required = true,
                                 default = nil)
  if valid_603702 != nil:
    section.add "DBSubnetGroupName", valid_603702
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

proc call*(call_603711: Call_GetDeleteDBSubnetGroup_603698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603711.validator(path, query, header, formData, body)
  let scheme = call_603711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603711.url(scheme.get, call_603711.host, call_603711.base,
                         call_603711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603711, url, valid)

proc call*(call_603712: Call_GetDeleteDBSubnetGroup_603698;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603713 = newJObject()
  add(query_603713, "Action", newJString(Action))
  add(query_603713, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603713, "Version", newJString(Version))
  result = call_603712.call(nil, query_603713, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603698(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603699, base: "/",
    url: url_GetDeleteDBSubnetGroup_603700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603747 = ref object of OpenApiRestCall_602450
proc url_PostDeleteEventSubscription_603749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_603748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603750 = validateParameter(valid_603750, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
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
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603759 = formData.getOrDefault("SubscriptionName")
  valid_603759 = validateParameter(valid_603759, JString, required = true,
                                 default = nil)
  if valid_603759 != nil:
    section.add "SubscriptionName", valid_603759
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603760: Call_PostDeleteEventSubscription_603747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603760.validator(path, query, header, formData, body)
  let scheme = call_603760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603760.url(scheme.get, call_603760.host, call_603760.base,
                         call_603760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603760, url, valid)

proc call*(call_603761: Call_PostDeleteEventSubscription_603747;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603762 = newJObject()
  var formData_603763 = newJObject()
  add(formData_603763, "SubscriptionName", newJString(SubscriptionName))
  add(query_603762, "Action", newJString(Action))
  add(query_603762, "Version", newJString(Version))
  result = call_603761.call(nil, query_603762, nil, formData_603763, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603747(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603748, base: "/",
    url: url_PostDeleteEventSubscription_603749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603731 = ref object of OpenApiRestCall_602450
proc url_GetDeleteEventSubscription_603733(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_603732(path: JsonNode; query: JsonNode;
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
  var valid_603734 = query.getOrDefault("Action")
  valid_603734 = validateParameter(valid_603734, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603734 != nil:
    section.add "Action", valid_603734
  var valid_603735 = query.getOrDefault("SubscriptionName")
  valid_603735 = validateParameter(valid_603735, JString, required = true,
                                 default = nil)
  if valid_603735 != nil:
    section.add "SubscriptionName", valid_603735
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

proc call*(call_603744: Call_GetDeleteEventSubscription_603731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603744.validator(path, query, header, formData, body)
  let scheme = call_603744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603744.url(scheme.get, call_603744.host, call_603744.base,
                         call_603744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603744, url, valid)

proc call*(call_603745: Call_GetDeleteEventSubscription_603731;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603746 = newJObject()
  add(query_603746, "Action", newJString(Action))
  add(query_603746, "SubscriptionName", newJString(SubscriptionName))
  add(query_603746, "Version", newJString(Version))
  result = call_603745.call(nil, query_603746, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603731(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603732, base: "/",
    url: url_GetDeleteEventSubscription_603733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603780 = ref object of OpenApiRestCall_602450
proc url_PostDeleteOptionGroup_603782(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_603781(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603783 = query.getOrDefault("Action")
  valid_603783 = validateParameter(valid_603783, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603783 != nil:
    section.add "Action", valid_603783
  var valid_603784 = query.getOrDefault("Version")
  valid_603784 = validateParameter(valid_603784, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603784 != nil:
    section.add "Version", valid_603784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603785 = header.getOrDefault("X-Amz-Date")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Date", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Security-Token")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Security-Token", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Content-Sha256", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Algorithm")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Algorithm", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Signature")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Signature", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-SignedHeaders", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Credential")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Credential", valid_603791
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603792 = formData.getOrDefault("OptionGroupName")
  valid_603792 = validateParameter(valid_603792, JString, required = true,
                                 default = nil)
  if valid_603792 != nil:
    section.add "OptionGroupName", valid_603792
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603793: Call_PostDeleteOptionGroup_603780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603793.validator(path, query, header, formData, body)
  let scheme = call_603793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603793.url(scheme.get, call_603793.host, call_603793.base,
                         call_603793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603793, url, valid)

proc call*(call_603794: Call_PostDeleteOptionGroup_603780; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603795 = newJObject()
  var formData_603796 = newJObject()
  add(formData_603796, "OptionGroupName", newJString(OptionGroupName))
  add(query_603795, "Action", newJString(Action))
  add(query_603795, "Version", newJString(Version))
  result = call_603794.call(nil, query_603795, nil, formData_603796, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603780(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603781, base: "/",
    url: url_PostDeleteOptionGroup_603782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603764 = ref object of OpenApiRestCall_602450
proc url_GetDeleteOptionGroup_603766(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_603765(path: JsonNode; query: JsonNode;
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
  var valid_603767 = query.getOrDefault("OptionGroupName")
  valid_603767 = validateParameter(valid_603767, JString, required = true,
                                 default = nil)
  if valid_603767 != nil:
    section.add "OptionGroupName", valid_603767
  var valid_603768 = query.getOrDefault("Action")
  valid_603768 = validateParameter(valid_603768, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603768 != nil:
    section.add "Action", valid_603768
  var valid_603769 = query.getOrDefault("Version")
  valid_603769 = validateParameter(valid_603769, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603769 != nil:
    section.add "Version", valid_603769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603770 = header.getOrDefault("X-Amz-Date")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Date", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Security-Token")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Security-Token", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Content-Sha256", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Algorithm")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Algorithm", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Signature")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Signature", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-SignedHeaders", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Credential")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Credential", valid_603776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603777: Call_GetDeleteOptionGroup_603764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603777.validator(path, query, header, formData, body)
  let scheme = call_603777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603777.url(scheme.get, call_603777.host, call_603777.base,
                         call_603777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603777, url, valid)

proc call*(call_603778: Call_GetDeleteOptionGroup_603764; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603779 = newJObject()
  add(query_603779, "OptionGroupName", newJString(OptionGroupName))
  add(query_603779, "Action", newJString(Action))
  add(query_603779, "Version", newJString(Version))
  result = call_603778.call(nil, query_603779, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603764(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603765, base: "/",
    url: url_GetDeleteOptionGroup_603766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603820 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBEngineVersions_603822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_603821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603823 = query.getOrDefault("Action")
  valid_603823 = validateParameter(valid_603823, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603823 != nil:
    section.add "Action", valid_603823
  var valid_603824 = query.getOrDefault("Version")
  valid_603824 = validateParameter(valid_603824, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603824 != nil:
    section.add "Version", valid_603824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603825 = header.getOrDefault("X-Amz-Date")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Date", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Security-Token")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Security-Token", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Content-Sha256", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Algorithm")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Algorithm", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Signature")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Signature", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-SignedHeaders", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Credential")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Credential", valid_603831
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
  var valid_603832 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603832 = validateParameter(valid_603832, JBool, required = false, default = nil)
  if valid_603832 != nil:
    section.add "ListSupportedCharacterSets", valid_603832
  var valid_603833 = formData.getOrDefault("Engine")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "Engine", valid_603833
  var valid_603834 = formData.getOrDefault("Marker")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "Marker", valid_603834
  var valid_603835 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "DBParameterGroupFamily", valid_603835
  var valid_603836 = formData.getOrDefault("Filters")
  valid_603836 = validateParameter(valid_603836, JArray, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "Filters", valid_603836
  var valid_603837 = formData.getOrDefault("MaxRecords")
  valid_603837 = validateParameter(valid_603837, JInt, required = false, default = nil)
  if valid_603837 != nil:
    section.add "MaxRecords", valid_603837
  var valid_603838 = formData.getOrDefault("EngineVersion")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "EngineVersion", valid_603838
  var valid_603839 = formData.getOrDefault("DefaultOnly")
  valid_603839 = validateParameter(valid_603839, JBool, required = false, default = nil)
  if valid_603839 != nil:
    section.add "DefaultOnly", valid_603839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603840: Call_PostDescribeDBEngineVersions_603820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603840.validator(path, query, header, formData, body)
  let scheme = call_603840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603840.url(scheme.get, call_603840.host, call_603840.base,
                         call_603840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603840, url, valid)

proc call*(call_603841: Call_PostDescribeDBEngineVersions_603820;
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
  var query_603842 = newJObject()
  var formData_603843 = newJObject()
  add(formData_603843, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603843, "Engine", newJString(Engine))
  add(formData_603843, "Marker", newJString(Marker))
  add(query_603842, "Action", newJString(Action))
  add(formData_603843, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603843.add "Filters", Filters
  add(formData_603843, "MaxRecords", newJInt(MaxRecords))
  add(formData_603843, "EngineVersion", newJString(EngineVersion))
  add(query_603842, "Version", newJString(Version))
  add(formData_603843, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603841.call(nil, query_603842, nil, formData_603843, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603820(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603821, base: "/",
    url: url_PostDescribeDBEngineVersions_603822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603797 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBEngineVersions_603799(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_603798(path: JsonNode; query: JsonNode;
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
  var valid_603800 = query.getOrDefault("Engine")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Engine", valid_603800
  var valid_603801 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603801 = validateParameter(valid_603801, JBool, required = false, default = nil)
  if valid_603801 != nil:
    section.add "ListSupportedCharacterSets", valid_603801
  var valid_603802 = query.getOrDefault("MaxRecords")
  valid_603802 = validateParameter(valid_603802, JInt, required = false, default = nil)
  if valid_603802 != nil:
    section.add "MaxRecords", valid_603802
  var valid_603803 = query.getOrDefault("DBParameterGroupFamily")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "DBParameterGroupFamily", valid_603803
  var valid_603804 = query.getOrDefault("Filters")
  valid_603804 = validateParameter(valid_603804, JArray, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "Filters", valid_603804
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603805 = query.getOrDefault("Action")
  valid_603805 = validateParameter(valid_603805, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603805 != nil:
    section.add "Action", valid_603805
  var valid_603806 = query.getOrDefault("Marker")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "Marker", valid_603806
  var valid_603807 = query.getOrDefault("EngineVersion")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "EngineVersion", valid_603807
  var valid_603808 = query.getOrDefault("DefaultOnly")
  valid_603808 = validateParameter(valid_603808, JBool, required = false, default = nil)
  if valid_603808 != nil:
    section.add "DefaultOnly", valid_603808
  var valid_603809 = query.getOrDefault("Version")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603809 != nil:
    section.add "Version", valid_603809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603810 = header.getOrDefault("X-Amz-Date")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Date", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Security-Token")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Security-Token", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Content-Sha256", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Algorithm")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Algorithm", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Signature")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Signature", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-SignedHeaders", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Credential")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Credential", valid_603816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603817: Call_GetDescribeDBEngineVersions_603797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603817.validator(path, query, header, formData, body)
  let scheme = call_603817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603817.url(scheme.get, call_603817.host, call_603817.base,
                         call_603817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603817, url, valid)

proc call*(call_603818: Call_GetDescribeDBEngineVersions_603797;
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
  var query_603819 = newJObject()
  add(query_603819, "Engine", newJString(Engine))
  add(query_603819, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603819, "MaxRecords", newJInt(MaxRecords))
  add(query_603819, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603819.add "Filters", Filters
  add(query_603819, "Action", newJString(Action))
  add(query_603819, "Marker", newJString(Marker))
  add(query_603819, "EngineVersion", newJString(EngineVersion))
  add(query_603819, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603819, "Version", newJString(Version))
  result = call_603818.call(nil, query_603819, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603797(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603798, base: "/",
    url: url_GetDescribeDBEngineVersions_603799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603863 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBInstances_603865(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_603864(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603866 = query.getOrDefault("Action")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603866 != nil:
    section.add "Action", valid_603866
  var valid_603867 = query.getOrDefault("Version")
  valid_603867 = validateParameter(valid_603867, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603867 != nil:
    section.add "Version", valid_603867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603868 = header.getOrDefault("X-Amz-Date")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Date", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Security-Token")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Security-Token", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Content-Sha256", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Algorithm")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Algorithm", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Signature")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Signature", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-SignedHeaders", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Credential")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Credential", valid_603874
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603875 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "DBInstanceIdentifier", valid_603875
  var valid_603876 = formData.getOrDefault("Marker")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "Marker", valid_603876
  var valid_603877 = formData.getOrDefault("Filters")
  valid_603877 = validateParameter(valid_603877, JArray, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "Filters", valid_603877
  var valid_603878 = formData.getOrDefault("MaxRecords")
  valid_603878 = validateParameter(valid_603878, JInt, required = false, default = nil)
  if valid_603878 != nil:
    section.add "MaxRecords", valid_603878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603879: Call_PostDescribeDBInstances_603863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603879.validator(path, query, header, formData, body)
  let scheme = call_603879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603879.url(scheme.get, call_603879.host, call_603879.base,
                         call_603879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603879, url, valid)

proc call*(call_603880: Call_PostDescribeDBInstances_603863;
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
  var query_603881 = newJObject()
  var formData_603882 = newJObject()
  add(formData_603882, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603882, "Marker", newJString(Marker))
  add(query_603881, "Action", newJString(Action))
  if Filters != nil:
    formData_603882.add "Filters", Filters
  add(formData_603882, "MaxRecords", newJInt(MaxRecords))
  add(query_603881, "Version", newJString(Version))
  result = call_603880.call(nil, query_603881, nil, formData_603882, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603863(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603864, base: "/",
    url: url_PostDescribeDBInstances_603865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603844 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBInstances_603846(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_603845(path: JsonNode; query: JsonNode;
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
  var valid_603847 = query.getOrDefault("MaxRecords")
  valid_603847 = validateParameter(valid_603847, JInt, required = false, default = nil)
  if valid_603847 != nil:
    section.add "MaxRecords", valid_603847
  var valid_603848 = query.getOrDefault("Filters")
  valid_603848 = validateParameter(valid_603848, JArray, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "Filters", valid_603848
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603849 = query.getOrDefault("Action")
  valid_603849 = validateParameter(valid_603849, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603849 != nil:
    section.add "Action", valid_603849
  var valid_603850 = query.getOrDefault("Marker")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "Marker", valid_603850
  var valid_603851 = query.getOrDefault("Version")
  valid_603851 = validateParameter(valid_603851, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603851 != nil:
    section.add "Version", valid_603851
  var valid_603852 = query.getOrDefault("DBInstanceIdentifier")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "DBInstanceIdentifier", valid_603852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603853 = header.getOrDefault("X-Amz-Date")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Date", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Security-Token")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Security-Token", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Content-Sha256", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Algorithm")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Algorithm", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Signature")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Signature", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-SignedHeaders", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Credential")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Credential", valid_603859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603860: Call_GetDescribeDBInstances_603844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603860.validator(path, query, header, formData, body)
  let scheme = call_603860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603860.url(scheme.get, call_603860.host, call_603860.base,
                         call_603860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603860, url, valid)

proc call*(call_603861: Call_GetDescribeDBInstances_603844; MaxRecords: int = 0;
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
  var query_603862 = newJObject()
  add(query_603862, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603862.add "Filters", Filters
  add(query_603862, "Action", newJString(Action))
  add(query_603862, "Marker", newJString(Marker))
  add(query_603862, "Version", newJString(Version))
  add(query_603862, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603861.call(nil, query_603862, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603844(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603845, base: "/",
    url: url_GetDescribeDBInstances_603846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_603905 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBLogFiles_603907(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_603906(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603908 = query.getOrDefault("Action")
  valid_603908 = validateParameter(valid_603908, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603908 != nil:
    section.add "Action", valid_603908
  var valid_603909 = query.getOrDefault("Version")
  valid_603909 = validateParameter(valid_603909, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_603917 = formData.getOrDefault("FilenameContains")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "FilenameContains", valid_603917
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603918 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = nil)
  if valid_603918 != nil:
    section.add "DBInstanceIdentifier", valid_603918
  var valid_603919 = formData.getOrDefault("FileSize")
  valid_603919 = validateParameter(valid_603919, JInt, required = false, default = nil)
  if valid_603919 != nil:
    section.add "FileSize", valid_603919
  var valid_603920 = formData.getOrDefault("Marker")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "Marker", valid_603920
  var valid_603921 = formData.getOrDefault("Filters")
  valid_603921 = validateParameter(valid_603921, JArray, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "Filters", valid_603921
  var valid_603922 = formData.getOrDefault("MaxRecords")
  valid_603922 = validateParameter(valid_603922, JInt, required = false, default = nil)
  if valid_603922 != nil:
    section.add "MaxRecords", valid_603922
  var valid_603923 = formData.getOrDefault("FileLastWritten")
  valid_603923 = validateParameter(valid_603923, JInt, required = false, default = nil)
  if valid_603923 != nil:
    section.add "FileLastWritten", valid_603923
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603924: Call_PostDescribeDBLogFiles_603905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603924.validator(path, query, header, formData, body)
  let scheme = call_603924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603924.url(scheme.get, call_603924.host, call_603924.base,
                         call_603924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603924, url, valid)

proc call*(call_603925: Call_PostDescribeDBLogFiles_603905;
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
  var query_603926 = newJObject()
  var formData_603927 = newJObject()
  add(formData_603927, "FilenameContains", newJString(FilenameContains))
  add(formData_603927, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603927, "FileSize", newJInt(FileSize))
  add(formData_603927, "Marker", newJString(Marker))
  add(query_603926, "Action", newJString(Action))
  if Filters != nil:
    formData_603927.add "Filters", Filters
  add(formData_603927, "MaxRecords", newJInt(MaxRecords))
  add(formData_603927, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603926, "Version", newJString(Version))
  result = call_603925.call(nil, query_603926, nil, formData_603927, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603905(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603906, base: "/",
    url: url_PostDescribeDBLogFiles_603907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603883 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBLogFiles_603885(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_603884(path: JsonNode; query: JsonNode;
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
  var valid_603886 = query.getOrDefault("FileLastWritten")
  valid_603886 = validateParameter(valid_603886, JInt, required = false, default = nil)
  if valid_603886 != nil:
    section.add "FileLastWritten", valid_603886
  var valid_603887 = query.getOrDefault("MaxRecords")
  valid_603887 = validateParameter(valid_603887, JInt, required = false, default = nil)
  if valid_603887 != nil:
    section.add "MaxRecords", valid_603887
  var valid_603888 = query.getOrDefault("FilenameContains")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "FilenameContains", valid_603888
  var valid_603889 = query.getOrDefault("FileSize")
  valid_603889 = validateParameter(valid_603889, JInt, required = false, default = nil)
  if valid_603889 != nil:
    section.add "FileSize", valid_603889
  var valid_603890 = query.getOrDefault("Filters")
  valid_603890 = validateParameter(valid_603890, JArray, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "Filters", valid_603890
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603891 = query.getOrDefault("Action")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603891 != nil:
    section.add "Action", valid_603891
  var valid_603892 = query.getOrDefault("Marker")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "Marker", valid_603892
  var valid_603893 = query.getOrDefault("Version")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603893 != nil:
    section.add "Version", valid_603893
  var valid_603894 = query.getOrDefault("DBInstanceIdentifier")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = nil)
  if valid_603894 != nil:
    section.add "DBInstanceIdentifier", valid_603894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603895 = header.getOrDefault("X-Amz-Date")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Date", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Content-Sha256", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Algorithm")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Algorithm", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Signature")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Signature", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-SignedHeaders", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Credential")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Credential", valid_603901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_GetDescribeDBLogFiles_603883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_GetDescribeDBLogFiles_603883;
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
  var query_603904 = newJObject()
  add(query_603904, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603904, "MaxRecords", newJInt(MaxRecords))
  add(query_603904, "FilenameContains", newJString(FilenameContains))
  add(query_603904, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_603904.add "Filters", Filters
  add(query_603904, "Action", newJString(Action))
  add(query_603904, "Marker", newJString(Marker))
  add(query_603904, "Version", newJString(Version))
  add(query_603904, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603903.call(nil, query_603904, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603883(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603884, base: "/",
    url: url_GetDescribeDBLogFiles_603885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_603947 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameterGroups_603949(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_603948(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603950 = query.getOrDefault("Action")
  valid_603950 = validateParameter(valid_603950, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603950 != nil:
    section.add "Action", valid_603950
  var valid_603951 = query.getOrDefault("Version")
  valid_603951 = validateParameter(valid_603951, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603951 != nil:
    section.add "Version", valid_603951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603952 = header.getOrDefault("X-Amz-Date")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Date", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Security-Token")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Security-Token", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Content-Sha256", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Algorithm")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Algorithm", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Signature")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Signature", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-SignedHeaders", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Credential")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Credential", valid_603958
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603959 = formData.getOrDefault("DBParameterGroupName")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "DBParameterGroupName", valid_603959
  var valid_603960 = formData.getOrDefault("Marker")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "Marker", valid_603960
  var valid_603961 = formData.getOrDefault("Filters")
  valid_603961 = validateParameter(valid_603961, JArray, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "Filters", valid_603961
  var valid_603962 = formData.getOrDefault("MaxRecords")
  valid_603962 = validateParameter(valid_603962, JInt, required = false, default = nil)
  if valid_603962 != nil:
    section.add "MaxRecords", valid_603962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603963: Call_PostDescribeDBParameterGroups_603947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603963.validator(path, query, header, formData, body)
  let scheme = call_603963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603963.url(scheme.get, call_603963.host, call_603963.base,
                         call_603963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603963, url, valid)

proc call*(call_603964: Call_PostDescribeDBParameterGroups_603947;
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
  var query_603965 = newJObject()
  var formData_603966 = newJObject()
  add(formData_603966, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603966, "Marker", newJString(Marker))
  add(query_603965, "Action", newJString(Action))
  if Filters != nil:
    formData_603966.add "Filters", Filters
  add(formData_603966, "MaxRecords", newJInt(MaxRecords))
  add(query_603965, "Version", newJString(Version))
  result = call_603964.call(nil, query_603965, nil, formData_603966, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_603947(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_603948, base: "/",
    url: url_PostDescribeDBParameterGroups_603949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603928 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameterGroups_603930(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_603929(path: JsonNode; query: JsonNode;
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
  var valid_603931 = query.getOrDefault("MaxRecords")
  valid_603931 = validateParameter(valid_603931, JInt, required = false, default = nil)
  if valid_603931 != nil:
    section.add "MaxRecords", valid_603931
  var valid_603932 = query.getOrDefault("Filters")
  valid_603932 = validateParameter(valid_603932, JArray, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "Filters", valid_603932
  var valid_603933 = query.getOrDefault("DBParameterGroupName")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "DBParameterGroupName", valid_603933
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603934 = query.getOrDefault("Action")
  valid_603934 = validateParameter(valid_603934, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603934 != nil:
    section.add "Action", valid_603934
  var valid_603935 = query.getOrDefault("Marker")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "Marker", valid_603935
  var valid_603936 = query.getOrDefault("Version")
  valid_603936 = validateParameter(valid_603936, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603936 != nil:
    section.add "Version", valid_603936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603937 = header.getOrDefault("X-Amz-Date")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Date", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Security-Token")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Security-Token", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Content-Sha256", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Algorithm")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Algorithm", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Signature")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Signature", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-SignedHeaders", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Credential")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Credential", valid_603943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603944: Call_GetDescribeDBParameterGroups_603928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603944.validator(path, query, header, formData, body)
  let scheme = call_603944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603944.url(scheme.get, call_603944.host, call_603944.base,
                         call_603944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603944, url, valid)

proc call*(call_603945: Call_GetDescribeDBParameterGroups_603928;
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
  var query_603946 = newJObject()
  add(query_603946, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603946.add "Filters", Filters
  add(query_603946, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603946, "Action", newJString(Action))
  add(query_603946, "Marker", newJString(Marker))
  add(query_603946, "Version", newJString(Version))
  result = call_603945.call(nil, query_603946, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603928(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603929, base: "/",
    url: url_GetDescribeDBParameterGroups_603930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_603987 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameters_603989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_603988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603990 = query.getOrDefault("Action")
  valid_603990 = validateParameter(valid_603990, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603990 != nil:
    section.add "Action", valid_603990
  var valid_603991 = query.getOrDefault("Version")
  valid_603991 = validateParameter(valid_603991, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603991 != nil:
    section.add "Version", valid_603991
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603999 = formData.getOrDefault("DBParameterGroupName")
  valid_603999 = validateParameter(valid_603999, JString, required = true,
                                 default = nil)
  if valid_603999 != nil:
    section.add "DBParameterGroupName", valid_603999
  var valid_604000 = formData.getOrDefault("Marker")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "Marker", valid_604000
  var valid_604001 = formData.getOrDefault("Filters")
  valid_604001 = validateParameter(valid_604001, JArray, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "Filters", valid_604001
  var valid_604002 = formData.getOrDefault("MaxRecords")
  valid_604002 = validateParameter(valid_604002, JInt, required = false, default = nil)
  if valid_604002 != nil:
    section.add "MaxRecords", valid_604002
  var valid_604003 = formData.getOrDefault("Source")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "Source", valid_604003
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604004: Call_PostDescribeDBParameters_603987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604004.validator(path, query, header, formData, body)
  let scheme = call_604004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604004.url(scheme.get, call_604004.host, call_604004.base,
                         call_604004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604004, url, valid)

proc call*(call_604005: Call_PostDescribeDBParameters_603987;
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
  var query_604006 = newJObject()
  var formData_604007 = newJObject()
  add(formData_604007, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604007, "Marker", newJString(Marker))
  add(query_604006, "Action", newJString(Action))
  if Filters != nil:
    formData_604007.add "Filters", Filters
  add(formData_604007, "MaxRecords", newJInt(MaxRecords))
  add(query_604006, "Version", newJString(Version))
  add(formData_604007, "Source", newJString(Source))
  result = call_604005.call(nil, query_604006, nil, formData_604007, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_603987(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_603988, base: "/",
    url: url_PostDescribeDBParameters_603989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_603967 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameters_603969(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_603968(path: JsonNode; query: JsonNode;
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
  var valid_603970 = query.getOrDefault("MaxRecords")
  valid_603970 = validateParameter(valid_603970, JInt, required = false, default = nil)
  if valid_603970 != nil:
    section.add "MaxRecords", valid_603970
  var valid_603971 = query.getOrDefault("Filters")
  valid_603971 = validateParameter(valid_603971, JArray, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "Filters", valid_603971
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603972 = query.getOrDefault("DBParameterGroupName")
  valid_603972 = validateParameter(valid_603972, JString, required = true,
                                 default = nil)
  if valid_603972 != nil:
    section.add "DBParameterGroupName", valid_603972
  var valid_603973 = query.getOrDefault("Action")
  valid_603973 = validateParameter(valid_603973, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603973 != nil:
    section.add "Action", valid_603973
  var valid_603974 = query.getOrDefault("Marker")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "Marker", valid_603974
  var valid_603975 = query.getOrDefault("Source")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "Source", valid_603975
  var valid_603976 = query.getOrDefault("Version")
  valid_603976 = validateParameter(valid_603976, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603976 != nil:
    section.add "Version", valid_603976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603977 = header.getOrDefault("X-Amz-Date")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Date", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Security-Token")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Security-Token", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Content-Sha256", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Algorithm")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Algorithm", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Signature")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Signature", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-SignedHeaders", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Credential")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Credential", valid_603983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_GetDescribeDBParameters_603967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603984, url, valid)

proc call*(call_603985: Call_GetDescribeDBParameters_603967;
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
  var query_603986 = newJObject()
  add(query_603986, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603986.add "Filters", Filters
  add(query_603986, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603986, "Action", newJString(Action))
  add(query_603986, "Marker", newJString(Marker))
  add(query_603986, "Source", newJString(Source))
  add(query_603986, "Version", newJString(Version))
  result = call_603985.call(nil, query_603986, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_603967(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_603968, base: "/",
    url: url_GetDescribeDBParameters_603969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_604027 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSecurityGroups_604029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_604028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604030 = query.getOrDefault("Action")
  valid_604030 = validateParameter(valid_604030, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_604030 != nil:
    section.add "Action", valid_604030
  var valid_604031 = query.getOrDefault("Version")
  valid_604031 = validateParameter(valid_604031, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604031 != nil:
    section.add "Version", valid_604031
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604032 = header.getOrDefault("X-Amz-Date")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Date", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Security-Token")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Security-Token", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Content-Sha256", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Algorithm")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Algorithm", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Signature")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Signature", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-SignedHeaders", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Credential")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Credential", valid_604038
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604039 = formData.getOrDefault("DBSecurityGroupName")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "DBSecurityGroupName", valid_604039
  var valid_604040 = formData.getOrDefault("Marker")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "Marker", valid_604040
  var valid_604041 = formData.getOrDefault("Filters")
  valid_604041 = validateParameter(valid_604041, JArray, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "Filters", valid_604041
  var valid_604042 = formData.getOrDefault("MaxRecords")
  valid_604042 = validateParameter(valid_604042, JInt, required = false, default = nil)
  if valid_604042 != nil:
    section.add "MaxRecords", valid_604042
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604043: Call_PostDescribeDBSecurityGroups_604027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604043.validator(path, query, header, formData, body)
  let scheme = call_604043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604043.url(scheme.get, call_604043.host, call_604043.base,
                         call_604043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604043, url, valid)

proc call*(call_604044: Call_PostDescribeDBSecurityGroups_604027;
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
  var query_604045 = newJObject()
  var formData_604046 = newJObject()
  add(formData_604046, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604046, "Marker", newJString(Marker))
  add(query_604045, "Action", newJString(Action))
  if Filters != nil:
    formData_604046.add "Filters", Filters
  add(formData_604046, "MaxRecords", newJInt(MaxRecords))
  add(query_604045, "Version", newJString(Version))
  result = call_604044.call(nil, query_604045, nil, formData_604046, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_604027(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_604028, base: "/",
    url: url_PostDescribeDBSecurityGroups_604029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_604008 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSecurityGroups_604010(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_604009(path: JsonNode; query: JsonNode;
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
  var valid_604011 = query.getOrDefault("MaxRecords")
  valid_604011 = validateParameter(valid_604011, JInt, required = false, default = nil)
  if valid_604011 != nil:
    section.add "MaxRecords", valid_604011
  var valid_604012 = query.getOrDefault("DBSecurityGroupName")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "DBSecurityGroupName", valid_604012
  var valid_604013 = query.getOrDefault("Filters")
  valid_604013 = validateParameter(valid_604013, JArray, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "Filters", valid_604013
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604014 = query.getOrDefault("Action")
  valid_604014 = validateParameter(valid_604014, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_604014 != nil:
    section.add "Action", valid_604014
  var valid_604015 = query.getOrDefault("Marker")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "Marker", valid_604015
  var valid_604016 = query.getOrDefault("Version")
  valid_604016 = validateParameter(valid_604016, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604016 != nil:
    section.add "Version", valid_604016
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604017 = header.getOrDefault("X-Amz-Date")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Date", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Security-Token")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Security-Token", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Content-Sha256", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Algorithm")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Algorithm", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Signature")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Signature", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-SignedHeaders", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Credential")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Credential", valid_604023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604024: Call_GetDescribeDBSecurityGroups_604008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604024.validator(path, query, header, formData, body)
  let scheme = call_604024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604024.url(scheme.get, call_604024.host, call_604024.base,
                         call_604024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604024, url, valid)

proc call*(call_604025: Call_GetDescribeDBSecurityGroups_604008;
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
  var query_604026 = newJObject()
  add(query_604026, "MaxRecords", newJInt(MaxRecords))
  add(query_604026, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_604026.add "Filters", Filters
  add(query_604026, "Action", newJString(Action))
  add(query_604026, "Marker", newJString(Marker))
  add(query_604026, "Version", newJString(Version))
  result = call_604025.call(nil, query_604026, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_604008(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_604009, base: "/",
    url: url_GetDescribeDBSecurityGroups_604010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604068 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSnapshots_604070(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_604069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_604071 = validateParameter(valid_604071, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604071 != nil:
    section.add "Action", valid_604071
  var valid_604072 = query.getOrDefault("Version")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604080 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "DBInstanceIdentifier", valid_604080
  var valid_604081 = formData.getOrDefault("SnapshotType")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "SnapshotType", valid_604081
  var valid_604082 = formData.getOrDefault("Marker")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "Marker", valid_604082
  var valid_604083 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "DBSnapshotIdentifier", valid_604083
  var valid_604084 = formData.getOrDefault("Filters")
  valid_604084 = validateParameter(valid_604084, JArray, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "Filters", valid_604084
  var valid_604085 = formData.getOrDefault("MaxRecords")
  valid_604085 = validateParameter(valid_604085, JInt, required = false, default = nil)
  if valid_604085 != nil:
    section.add "MaxRecords", valid_604085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604086: Call_PostDescribeDBSnapshots_604068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604086.validator(path, query, header, formData, body)
  let scheme = call_604086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604086.url(scheme.get, call_604086.host, call_604086.base,
                         call_604086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604086, url, valid)

proc call*(call_604087: Call_PostDescribeDBSnapshots_604068;
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
  var query_604088 = newJObject()
  var formData_604089 = newJObject()
  add(formData_604089, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604089, "SnapshotType", newJString(SnapshotType))
  add(formData_604089, "Marker", newJString(Marker))
  add(formData_604089, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604088, "Action", newJString(Action))
  if Filters != nil:
    formData_604089.add "Filters", Filters
  add(formData_604089, "MaxRecords", newJInt(MaxRecords))
  add(query_604088, "Version", newJString(Version))
  result = call_604087.call(nil, query_604088, nil, formData_604089, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604068(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604069, base: "/",
    url: url_PostDescribeDBSnapshots_604070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_604047 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSnapshots_604049(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_604048(path: JsonNode; query: JsonNode;
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
  var valid_604050 = query.getOrDefault("MaxRecords")
  valid_604050 = validateParameter(valid_604050, JInt, required = false, default = nil)
  if valid_604050 != nil:
    section.add "MaxRecords", valid_604050
  var valid_604051 = query.getOrDefault("Filters")
  valid_604051 = validateParameter(valid_604051, JArray, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "Filters", valid_604051
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604052 = query.getOrDefault("Action")
  valid_604052 = validateParameter(valid_604052, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604052 != nil:
    section.add "Action", valid_604052
  var valid_604053 = query.getOrDefault("Marker")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "Marker", valid_604053
  var valid_604054 = query.getOrDefault("SnapshotType")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "SnapshotType", valid_604054
  var valid_604055 = query.getOrDefault("Version")
  valid_604055 = validateParameter(valid_604055, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604055 != nil:
    section.add "Version", valid_604055
  var valid_604056 = query.getOrDefault("DBInstanceIdentifier")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "DBInstanceIdentifier", valid_604056
  var valid_604057 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "DBSnapshotIdentifier", valid_604057
  result.add "query", section
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

proc call*(call_604065: Call_GetDescribeDBSnapshots_604047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604065.validator(path, query, header, formData, body)
  let scheme = call_604065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604065.url(scheme.get, call_604065.host, call_604065.base,
                         call_604065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604065, url, valid)

proc call*(call_604066: Call_GetDescribeDBSnapshots_604047; MaxRecords: int = 0;
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
  var query_604067 = newJObject()
  add(query_604067, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604067.add "Filters", Filters
  add(query_604067, "Action", newJString(Action))
  add(query_604067, "Marker", newJString(Marker))
  add(query_604067, "SnapshotType", newJString(SnapshotType))
  add(query_604067, "Version", newJString(Version))
  add(query_604067, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604067, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604066.call(nil, query_604067, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_604047(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_604048, base: "/",
    url: url_GetDescribeDBSnapshots_604049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604109 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSubnetGroups_604111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_604110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604112 = query.getOrDefault("Action")
  valid_604112 = validateParameter(valid_604112, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604112 != nil:
    section.add "Action", valid_604112
  var valid_604113 = query.getOrDefault("Version")
  valid_604113 = validateParameter(valid_604113, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604113 != nil:
    section.add "Version", valid_604113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604114 = header.getOrDefault("X-Amz-Date")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Date", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Security-Token")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Security-Token", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Content-Sha256", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Algorithm")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Algorithm", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Signature")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Signature", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-SignedHeaders", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Credential")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Credential", valid_604120
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604121 = formData.getOrDefault("DBSubnetGroupName")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "DBSubnetGroupName", valid_604121
  var valid_604122 = formData.getOrDefault("Marker")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "Marker", valid_604122
  var valid_604123 = formData.getOrDefault("Filters")
  valid_604123 = validateParameter(valid_604123, JArray, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "Filters", valid_604123
  var valid_604124 = formData.getOrDefault("MaxRecords")
  valid_604124 = validateParameter(valid_604124, JInt, required = false, default = nil)
  if valid_604124 != nil:
    section.add "MaxRecords", valid_604124
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604125: Call_PostDescribeDBSubnetGroups_604109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604125.validator(path, query, header, formData, body)
  let scheme = call_604125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604125.url(scheme.get, call_604125.host, call_604125.base,
                         call_604125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604125, url, valid)

proc call*(call_604126: Call_PostDescribeDBSubnetGroups_604109;
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
  var query_604127 = newJObject()
  var formData_604128 = newJObject()
  add(formData_604128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604128, "Marker", newJString(Marker))
  add(query_604127, "Action", newJString(Action))
  if Filters != nil:
    formData_604128.add "Filters", Filters
  add(formData_604128, "MaxRecords", newJInt(MaxRecords))
  add(query_604127, "Version", newJString(Version))
  result = call_604126.call(nil, query_604127, nil, formData_604128, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604109(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604110, base: "/",
    url: url_PostDescribeDBSubnetGroups_604111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604090 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSubnetGroups_604092(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_604091(path: JsonNode; query: JsonNode;
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
  var valid_604093 = query.getOrDefault("MaxRecords")
  valid_604093 = validateParameter(valid_604093, JInt, required = false, default = nil)
  if valid_604093 != nil:
    section.add "MaxRecords", valid_604093
  var valid_604094 = query.getOrDefault("Filters")
  valid_604094 = validateParameter(valid_604094, JArray, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "Filters", valid_604094
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604095 = query.getOrDefault("Action")
  valid_604095 = validateParameter(valid_604095, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604095 != nil:
    section.add "Action", valid_604095
  var valid_604096 = query.getOrDefault("Marker")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "Marker", valid_604096
  var valid_604097 = query.getOrDefault("DBSubnetGroupName")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "DBSubnetGroupName", valid_604097
  var valid_604098 = query.getOrDefault("Version")
  valid_604098 = validateParameter(valid_604098, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604098 != nil:
    section.add "Version", valid_604098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604099 = header.getOrDefault("X-Amz-Date")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Date", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Security-Token")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Security-Token", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Content-Sha256", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Algorithm")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Algorithm", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Signature")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Signature", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-SignedHeaders", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Credential")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Credential", valid_604105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604106: Call_GetDescribeDBSubnetGroups_604090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604106.validator(path, query, header, formData, body)
  let scheme = call_604106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604106.url(scheme.get, call_604106.host, call_604106.base,
                         call_604106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604106, url, valid)

proc call*(call_604107: Call_GetDescribeDBSubnetGroups_604090; MaxRecords: int = 0;
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
  var query_604108 = newJObject()
  add(query_604108, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604108.add "Filters", Filters
  add(query_604108, "Action", newJString(Action))
  add(query_604108, "Marker", newJString(Marker))
  add(query_604108, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604108, "Version", newJString(Version))
  result = call_604107.call(nil, query_604108, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604090(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604091, base: "/",
    url: url_GetDescribeDBSubnetGroups_604092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604148 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEngineDefaultParameters_604150(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_604149(path: JsonNode;
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
      "DescribeEngineDefaultParameters"))
  if valid_604151 != nil:
    section.add "Action", valid_604151
  var valid_604152 = query.getOrDefault("Version")
  valid_604152 = validateParameter(valid_604152, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604160 = formData.getOrDefault("Marker")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "Marker", valid_604160
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604161 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604161 = validateParameter(valid_604161, JString, required = true,
                                 default = nil)
  if valid_604161 != nil:
    section.add "DBParameterGroupFamily", valid_604161
  var valid_604162 = formData.getOrDefault("Filters")
  valid_604162 = validateParameter(valid_604162, JArray, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "Filters", valid_604162
  var valid_604163 = formData.getOrDefault("MaxRecords")
  valid_604163 = validateParameter(valid_604163, JInt, required = false, default = nil)
  if valid_604163 != nil:
    section.add "MaxRecords", valid_604163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604164: Call_PostDescribeEngineDefaultParameters_604148;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604164.validator(path, query, header, formData, body)
  let scheme = call_604164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604164.url(scheme.get, call_604164.host, call_604164.base,
                         call_604164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604164, url, valid)

proc call*(call_604165: Call_PostDescribeEngineDefaultParameters_604148;
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
  var query_604166 = newJObject()
  var formData_604167 = newJObject()
  add(formData_604167, "Marker", newJString(Marker))
  add(query_604166, "Action", newJString(Action))
  add(formData_604167, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_604167.add "Filters", Filters
  add(formData_604167, "MaxRecords", newJInt(MaxRecords))
  add(query_604166, "Version", newJString(Version))
  result = call_604165.call(nil, query_604166, nil, formData_604167, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604148(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604149, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604129 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEngineDefaultParameters_604131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_604130(path: JsonNode;
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
  var valid_604132 = query.getOrDefault("MaxRecords")
  valid_604132 = validateParameter(valid_604132, JInt, required = false, default = nil)
  if valid_604132 != nil:
    section.add "MaxRecords", valid_604132
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604133 = query.getOrDefault("DBParameterGroupFamily")
  valid_604133 = validateParameter(valid_604133, JString, required = true,
                                 default = nil)
  if valid_604133 != nil:
    section.add "DBParameterGroupFamily", valid_604133
  var valid_604134 = query.getOrDefault("Filters")
  valid_604134 = validateParameter(valid_604134, JArray, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "Filters", valid_604134
  var valid_604135 = query.getOrDefault("Action")
  valid_604135 = validateParameter(valid_604135, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604135 != nil:
    section.add "Action", valid_604135
  var valid_604136 = query.getOrDefault("Marker")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "Marker", valid_604136
  var valid_604137 = query.getOrDefault("Version")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_604145: Call_GetDescribeEngineDefaultParameters_604129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604145.validator(path, query, header, formData, body)
  let scheme = call_604145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604145.url(scheme.get, call_604145.host, call_604145.base,
                         call_604145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604145, url, valid)

proc call*(call_604146: Call_GetDescribeEngineDefaultParameters_604129;
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
  var query_604147 = newJObject()
  add(query_604147, "MaxRecords", newJInt(MaxRecords))
  add(query_604147, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_604147.add "Filters", Filters
  add(query_604147, "Action", newJString(Action))
  add(query_604147, "Marker", newJString(Marker))
  add(query_604147, "Version", newJString(Version))
  result = call_604146.call(nil, query_604147, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604129(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604130, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604185 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventCategories_604187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_604186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604188 = query.getOrDefault("Action")
  valid_604188 = validateParameter(valid_604188, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604188 != nil:
    section.add "Action", valid_604188
  var valid_604189 = query.getOrDefault("Version")
  valid_604189 = validateParameter(valid_604189, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604189 != nil:
    section.add "Version", valid_604189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604190 = header.getOrDefault("X-Amz-Date")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Date", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-Security-Token")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Security-Token", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Content-Sha256", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Algorithm")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Algorithm", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Signature")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Signature", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-SignedHeaders", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Credential")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Credential", valid_604196
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_604197 = formData.getOrDefault("Filters")
  valid_604197 = validateParameter(valid_604197, JArray, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "Filters", valid_604197
  var valid_604198 = formData.getOrDefault("SourceType")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "SourceType", valid_604198
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604199: Call_PostDescribeEventCategories_604185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604199.validator(path, query, header, formData, body)
  let scheme = call_604199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604199.url(scheme.get, call_604199.host, call_604199.base,
                         call_604199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604199, url, valid)

proc call*(call_604200: Call_PostDescribeEventCategories_604185;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_604201 = newJObject()
  var formData_604202 = newJObject()
  add(query_604201, "Action", newJString(Action))
  if Filters != nil:
    formData_604202.add "Filters", Filters
  add(query_604201, "Version", newJString(Version))
  add(formData_604202, "SourceType", newJString(SourceType))
  result = call_604200.call(nil, query_604201, nil, formData_604202, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604185(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604186, base: "/",
    url: url_PostDescribeEventCategories_604187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604168 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventCategories_604170(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_604169(path: JsonNode; query: JsonNode;
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
  var valid_604171 = query.getOrDefault("SourceType")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "SourceType", valid_604171
  var valid_604172 = query.getOrDefault("Filters")
  valid_604172 = validateParameter(valid_604172, JArray, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "Filters", valid_604172
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604173 = query.getOrDefault("Action")
  valid_604173 = validateParameter(valid_604173, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604173 != nil:
    section.add "Action", valid_604173
  var valid_604174 = query.getOrDefault("Version")
  valid_604174 = validateParameter(valid_604174, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604174 != nil:
    section.add "Version", valid_604174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604175 = header.getOrDefault("X-Amz-Date")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Date", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Security-Token")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Security-Token", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Content-Sha256", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Algorithm")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Algorithm", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Signature")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Signature", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-SignedHeaders", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Credential")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Credential", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604182: Call_GetDescribeEventCategories_604168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604182.validator(path, query, header, formData, body)
  let scheme = call_604182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604182.url(scheme.get, call_604182.host, call_604182.base,
                         call_604182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604182, url, valid)

proc call*(call_604183: Call_GetDescribeEventCategories_604168;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604184 = newJObject()
  add(query_604184, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_604184.add "Filters", Filters
  add(query_604184, "Action", newJString(Action))
  add(query_604184, "Version", newJString(Version))
  result = call_604183.call(nil, query_604184, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604168(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604169, base: "/",
    url: url_GetDescribeEventCategories_604170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604222 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventSubscriptions_604224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_604223(path: JsonNode;
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
  var valid_604225 = query.getOrDefault("Action")
  valid_604225 = validateParameter(valid_604225, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604225 != nil:
    section.add "Action", valid_604225
  var valid_604226 = query.getOrDefault("Version")
  valid_604226 = validateParameter(valid_604226, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604226 != nil:
    section.add "Version", valid_604226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604227 = header.getOrDefault("X-Amz-Date")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Date", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Security-Token")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Security-Token", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Content-Sha256", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Algorithm")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Algorithm", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Signature")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Signature", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-SignedHeaders", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-Credential")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-Credential", valid_604233
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604234 = formData.getOrDefault("Marker")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "Marker", valid_604234
  var valid_604235 = formData.getOrDefault("SubscriptionName")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "SubscriptionName", valid_604235
  var valid_604236 = formData.getOrDefault("Filters")
  valid_604236 = validateParameter(valid_604236, JArray, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "Filters", valid_604236
  var valid_604237 = formData.getOrDefault("MaxRecords")
  valid_604237 = validateParameter(valid_604237, JInt, required = false, default = nil)
  if valid_604237 != nil:
    section.add "MaxRecords", valid_604237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604238: Call_PostDescribeEventSubscriptions_604222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604238.validator(path, query, header, formData, body)
  let scheme = call_604238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604238.url(scheme.get, call_604238.host, call_604238.base,
                         call_604238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604238, url, valid)

proc call*(call_604239: Call_PostDescribeEventSubscriptions_604222;
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
  var query_604240 = newJObject()
  var formData_604241 = newJObject()
  add(formData_604241, "Marker", newJString(Marker))
  add(formData_604241, "SubscriptionName", newJString(SubscriptionName))
  add(query_604240, "Action", newJString(Action))
  if Filters != nil:
    formData_604241.add "Filters", Filters
  add(formData_604241, "MaxRecords", newJInt(MaxRecords))
  add(query_604240, "Version", newJString(Version))
  result = call_604239.call(nil, query_604240, nil, formData_604241, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604222(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604223, base: "/",
    url: url_PostDescribeEventSubscriptions_604224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604203 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventSubscriptions_604205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_604204(path: JsonNode; query: JsonNode;
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
  var valid_604206 = query.getOrDefault("MaxRecords")
  valid_604206 = validateParameter(valid_604206, JInt, required = false, default = nil)
  if valid_604206 != nil:
    section.add "MaxRecords", valid_604206
  var valid_604207 = query.getOrDefault("Filters")
  valid_604207 = validateParameter(valid_604207, JArray, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "Filters", valid_604207
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604208 = query.getOrDefault("Action")
  valid_604208 = validateParameter(valid_604208, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604208 != nil:
    section.add "Action", valid_604208
  var valid_604209 = query.getOrDefault("Marker")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "Marker", valid_604209
  var valid_604210 = query.getOrDefault("SubscriptionName")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "SubscriptionName", valid_604210
  var valid_604211 = query.getOrDefault("Version")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604211 != nil:
    section.add "Version", valid_604211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604212 = header.getOrDefault("X-Amz-Date")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Date", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Security-Token")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Security-Token", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Content-Sha256", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Algorithm", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Signature")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Signature", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-SignedHeaders", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-Credential")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-Credential", valid_604218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604219: Call_GetDescribeEventSubscriptions_604203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604219.validator(path, query, header, formData, body)
  let scheme = call_604219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604219.url(scheme.get, call_604219.host, call_604219.base,
                         call_604219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604219, url, valid)

proc call*(call_604220: Call_GetDescribeEventSubscriptions_604203;
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
  var query_604221 = newJObject()
  add(query_604221, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604221.add "Filters", Filters
  add(query_604221, "Action", newJString(Action))
  add(query_604221, "Marker", newJString(Marker))
  add(query_604221, "SubscriptionName", newJString(SubscriptionName))
  add(query_604221, "Version", newJString(Version))
  result = call_604220.call(nil, query_604221, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604203(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604204, base: "/",
    url: url_GetDescribeEventSubscriptions_604205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604266 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEvents_604268(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604267(path: JsonNode; query: JsonNode;
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
  var valid_604269 = query.getOrDefault("Action")
  valid_604269 = validateParameter(valid_604269, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604269 != nil:
    section.add "Action", valid_604269
  var valid_604270 = query.getOrDefault("Version")
  valid_604270 = validateParameter(valid_604270, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_604278 = formData.getOrDefault("SourceIdentifier")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "SourceIdentifier", valid_604278
  var valid_604279 = formData.getOrDefault("EventCategories")
  valid_604279 = validateParameter(valid_604279, JArray, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "EventCategories", valid_604279
  var valid_604280 = formData.getOrDefault("Marker")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "Marker", valid_604280
  var valid_604281 = formData.getOrDefault("StartTime")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "StartTime", valid_604281
  var valid_604282 = formData.getOrDefault("Duration")
  valid_604282 = validateParameter(valid_604282, JInt, required = false, default = nil)
  if valid_604282 != nil:
    section.add "Duration", valid_604282
  var valid_604283 = formData.getOrDefault("Filters")
  valid_604283 = validateParameter(valid_604283, JArray, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "Filters", valid_604283
  var valid_604284 = formData.getOrDefault("EndTime")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "EndTime", valid_604284
  var valid_604285 = formData.getOrDefault("MaxRecords")
  valid_604285 = validateParameter(valid_604285, JInt, required = false, default = nil)
  if valid_604285 != nil:
    section.add "MaxRecords", valid_604285
  var valid_604286 = formData.getOrDefault("SourceType")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604286 != nil:
    section.add "SourceType", valid_604286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604287: Call_PostDescribeEvents_604266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604287.validator(path, query, header, formData, body)
  let scheme = call_604287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604287.url(scheme.get, call_604287.host, call_604287.base,
                         call_604287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604287, url, valid)

proc call*(call_604288: Call_PostDescribeEvents_604266;
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
  var query_604289 = newJObject()
  var formData_604290 = newJObject()
  add(formData_604290, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604290.add "EventCategories", EventCategories
  add(formData_604290, "Marker", newJString(Marker))
  add(formData_604290, "StartTime", newJString(StartTime))
  add(query_604289, "Action", newJString(Action))
  add(formData_604290, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604290.add "Filters", Filters
  add(formData_604290, "EndTime", newJString(EndTime))
  add(formData_604290, "MaxRecords", newJInt(MaxRecords))
  add(query_604289, "Version", newJString(Version))
  add(formData_604290, "SourceType", newJString(SourceType))
  result = call_604288.call(nil, query_604289, nil, formData_604290, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604266(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604267, base: "/",
    url: url_PostDescribeEvents_604268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604242 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEvents_604244(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604243(path: JsonNode; query: JsonNode;
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
  var valid_604245 = query.getOrDefault("SourceType")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604245 != nil:
    section.add "SourceType", valid_604245
  var valid_604246 = query.getOrDefault("MaxRecords")
  valid_604246 = validateParameter(valid_604246, JInt, required = false, default = nil)
  if valid_604246 != nil:
    section.add "MaxRecords", valid_604246
  var valid_604247 = query.getOrDefault("StartTime")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "StartTime", valid_604247
  var valid_604248 = query.getOrDefault("Filters")
  valid_604248 = validateParameter(valid_604248, JArray, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "Filters", valid_604248
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604249 = query.getOrDefault("Action")
  valid_604249 = validateParameter(valid_604249, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604249 != nil:
    section.add "Action", valid_604249
  var valid_604250 = query.getOrDefault("SourceIdentifier")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "SourceIdentifier", valid_604250
  var valid_604251 = query.getOrDefault("Marker")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "Marker", valid_604251
  var valid_604252 = query.getOrDefault("EventCategories")
  valid_604252 = validateParameter(valid_604252, JArray, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "EventCategories", valid_604252
  var valid_604253 = query.getOrDefault("Duration")
  valid_604253 = validateParameter(valid_604253, JInt, required = false, default = nil)
  if valid_604253 != nil:
    section.add "Duration", valid_604253
  var valid_604254 = query.getOrDefault("EndTime")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "EndTime", valid_604254
  var valid_604255 = query.getOrDefault("Version")
  valid_604255 = validateParameter(valid_604255, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604255 != nil:
    section.add "Version", valid_604255
  result.add "query", section
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

proc call*(call_604263: Call_GetDescribeEvents_604242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604263.validator(path, query, header, formData, body)
  let scheme = call_604263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604263.url(scheme.get, call_604263.host, call_604263.base,
                         call_604263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604263, url, valid)

proc call*(call_604264: Call_GetDescribeEvents_604242;
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
  var query_604265 = newJObject()
  add(query_604265, "SourceType", newJString(SourceType))
  add(query_604265, "MaxRecords", newJInt(MaxRecords))
  add(query_604265, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_604265.add "Filters", Filters
  add(query_604265, "Action", newJString(Action))
  add(query_604265, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604265, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604265.add "EventCategories", EventCategories
  add(query_604265, "Duration", newJInt(Duration))
  add(query_604265, "EndTime", newJString(EndTime))
  add(query_604265, "Version", newJString(Version))
  result = call_604264.call(nil, query_604265, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604242(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604243,
    base: "/", url: url_GetDescribeEvents_604244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604311 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroupOptions_604313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_604312(path: JsonNode;
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
  var valid_604314 = query.getOrDefault("Action")
  valid_604314 = validateParameter(valid_604314, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604314 != nil:
    section.add "Action", valid_604314
  var valid_604315 = query.getOrDefault("Version")
  valid_604315 = validateParameter(valid_604315, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604315 != nil:
    section.add "Version", valid_604315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604316 = header.getOrDefault("X-Amz-Date")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Date", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Security-Token")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Security-Token", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Content-Sha256", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Algorithm")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Algorithm", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Signature")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Signature", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-SignedHeaders", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Credential")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Credential", valid_604322
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604323 = formData.getOrDefault("MajorEngineVersion")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "MajorEngineVersion", valid_604323
  var valid_604324 = formData.getOrDefault("Marker")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "Marker", valid_604324
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604325 = formData.getOrDefault("EngineName")
  valid_604325 = validateParameter(valid_604325, JString, required = true,
                                 default = nil)
  if valid_604325 != nil:
    section.add "EngineName", valid_604325
  var valid_604326 = formData.getOrDefault("Filters")
  valid_604326 = validateParameter(valid_604326, JArray, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "Filters", valid_604326
  var valid_604327 = formData.getOrDefault("MaxRecords")
  valid_604327 = validateParameter(valid_604327, JInt, required = false, default = nil)
  if valid_604327 != nil:
    section.add "MaxRecords", valid_604327
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604328: Call_PostDescribeOptionGroupOptions_604311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604328.validator(path, query, header, formData, body)
  let scheme = call_604328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604328.url(scheme.get, call_604328.host, call_604328.base,
                         call_604328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604328, url, valid)

proc call*(call_604329: Call_PostDescribeOptionGroupOptions_604311;
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
  var query_604330 = newJObject()
  var formData_604331 = newJObject()
  add(formData_604331, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604331, "Marker", newJString(Marker))
  add(query_604330, "Action", newJString(Action))
  add(formData_604331, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604331.add "Filters", Filters
  add(formData_604331, "MaxRecords", newJInt(MaxRecords))
  add(query_604330, "Version", newJString(Version))
  result = call_604329.call(nil, query_604330, nil, formData_604331, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604311(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604312, base: "/",
    url: url_PostDescribeOptionGroupOptions_604313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604291 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroupOptions_604293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_604292(path: JsonNode; query: JsonNode;
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
  var valid_604294 = query.getOrDefault("MaxRecords")
  valid_604294 = validateParameter(valid_604294, JInt, required = false, default = nil)
  if valid_604294 != nil:
    section.add "MaxRecords", valid_604294
  var valid_604295 = query.getOrDefault("Filters")
  valid_604295 = validateParameter(valid_604295, JArray, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "Filters", valid_604295
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604296 = query.getOrDefault("Action")
  valid_604296 = validateParameter(valid_604296, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604296 != nil:
    section.add "Action", valid_604296
  var valid_604297 = query.getOrDefault("Marker")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "Marker", valid_604297
  var valid_604298 = query.getOrDefault("Version")
  valid_604298 = validateParameter(valid_604298, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604298 != nil:
    section.add "Version", valid_604298
  var valid_604299 = query.getOrDefault("EngineName")
  valid_604299 = validateParameter(valid_604299, JString, required = true,
                                 default = nil)
  if valid_604299 != nil:
    section.add "EngineName", valid_604299
  var valid_604300 = query.getOrDefault("MajorEngineVersion")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "MajorEngineVersion", valid_604300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604301 = header.getOrDefault("X-Amz-Date")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Date", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Security-Token")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Security-Token", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Content-Sha256", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Algorithm")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Algorithm", valid_604304
  var valid_604305 = header.getOrDefault("X-Amz-Signature")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Signature", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-SignedHeaders", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Credential")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Credential", valid_604307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604308: Call_GetDescribeOptionGroupOptions_604291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604308.validator(path, query, header, formData, body)
  let scheme = call_604308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604308.url(scheme.get, call_604308.host, call_604308.base,
                         call_604308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604308, url, valid)

proc call*(call_604309: Call_GetDescribeOptionGroupOptions_604291;
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
  var query_604310 = newJObject()
  add(query_604310, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604310.add "Filters", Filters
  add(query_604310, "Action", newJString(Action))
  add(query_604310, "Marker", newJString(Marker))
  add(query_604310, "Version", newJString(Version))
  add(query_604310, "EngineName", newJString(EngineName))
  add(query_604310, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604309.call(nil, query_604310, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604291(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604292, base: "/",
    url: url_GetDescribeOptionGroupOptions_604293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604353 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroups_604355(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_604354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_604356 = validateParameter(valid_604356, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604356 != nil:
    section.add "Action", valid_604356
  var valid_604357 = query.getOrDefault("Version")
  valid_604357 = validateParameter(valid_604357, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604365 = formData.getOrDefault("MajorEngineVersion")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "MajorEngineVersion", valid_604365
  var valid_604366 = formData.getOrDefault("OptionGroupName")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "OptionGroupName", valid_604366
  var valid_604367 = formData.getOrDefault("Marker")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "Marker", valid_604367
  var valid_604368 = formData.getOrDefault("EngineName")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "EngineName", valid_604368
  var valid_604369 = formData.getOrDefault("Filters")
  valid_604369 = validateParameter(valid_604369, JArray, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "Filters", valid_604369
  var valid_604370 = formData.getOrDefault("MaxRecords")
  valid_604370 = validateParameter(valid_604370, JInt, required = false, default = nil)
  if valid_604370 != nil:
    section.add "MaxRecords", valid_604370
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604371: Call_PostDescribeOptionGroups_604353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604371.validator(path, query, header, formData, body)
  let scheme = call_604371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604371.url(scheme.get, call_604371.host, call_604371.base,
                         call_604371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604371, url, valid)

proc call*(call_604372: Call_PostDescribeOptionGroups_604353;
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
  var query_604373 = newJObject()
  var formData_604374 = newJObject()
  add(formData_604374, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604374, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604374, "Marker", newJString(Marker))
  add(query_604373, "Action", newJString(Action))
  add(formData_604374, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604374.add "Filters", Filters
  add(formData_604374, "MaxRecords", newJInt(MaxRecords))
  add(query_604373, "Version", newJString(Version))
  result = call_604372.call(nil, query_604373, nil, formData_604374, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604353(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604354, base: "/",
    url: url_PostDescribeOptionGroups_604355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604332 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroups_604334(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_604333(path: JsonNode; query: JsonNode;
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
  var valid_604335 = query.getOrDefault("MaxRecords")
  valid_604335 = validateParameter(valid_604335, JInt, required = false, default = nil)
  if valid_604335 != nil:
    section.add "MaxRecords", valid_604335
  var valid_604336 = query.getOrDefault("OptionGroupName")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "OptionGroupName", valid_604336
  var valid_604337 = query.getOrDefault("Filters")
  valid_604337 = validateParameter(valid_604337, JArray, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "Filters", valid_604337
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604338 = query.getOrDefault("Action")
  valid_604338 = validateParameter(valid_604338, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604338 != nil:
    section.add "Action", valid_604338
  var valid_604339 = query.getOrDefault("Marker")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "Marker", valid_604339
  var valid_604340 = query.getOrDefault("Version")
  valid_604340 = validateParameter(valid_604340, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604340 != nil:
    section.add "Version", valid_604340
  var valid_604341 = query.getOrDefault("EngineName")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "EngineName", valid_604341
  var valid_604342 = query.getOrDefault("MajorEngineVersion")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "MajorEngineVersion", valid_604342
  result.add "query", section
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

proc call*(call_604350: Call_GetDescribeOptionGroups_604332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604350.validator(path, query, header, formData, body)
  let scheme = call_604350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604350.url(scheme.get, call_604350.host, call_604350.base,
                         call_604350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604350, url, valid)

proc call*(call_604351: Call_GetDescribeOptionGroups_604332; MaxRecords: int = 0;
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
  var query_604352 = newJObject()
  add(query_604352, "MaxRecords", newJInt(MaxRecords))
  add(query_604352, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_604352.add "Filters", Filters
  add(query_604352, "Action", newJString(Action))
  add(query_604352, "Marker", newJString(Marker))
  add(query_604352, "Version", newJString(Version))
  add(query_604352, "EngineName", newJString(EngineName))
  add(query_604352, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604351.call(nil, query_604352, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604332(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604333, base: "/",
    url: url_GetDescribeOptionGroups_604334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604398 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOrderableDBInstanceOptions_604400(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604399(path: JsonNode;
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
  var valid_604401 = query.getOrDefault("Action")
  valid_604401 = validateParameter(valid_604401, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604401 != nil:
    section.add "Action", valid_604401
  var valid_604402 = query.getOrDefault("Version")
  valid_604402 = validateParameter(valid_604402, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604402 != nil:
    section.add "Version", valid_604402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604403 = header.getOrDefault("X-Amz-Date")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Date", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Security-Token")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Security-Token", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Content-Sha256", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Algorithm")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Algorithm", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Signature")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Signature", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-SignedHeaders", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Credential")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Credential", valid_604409
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
  var valid_604410 = formData.getOrDefault("Engine")
  valid_604410 = validateParameter(valid_604410, JString, required = true,
                                 default = nil)
  if valid_604410 != nil:
    section.add "Engine", valid_604410
  var valid_604411 = formData.getOrDefault("Marker")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "Marker", valid_604411
  var valid_604412 = formData.getOrDefault("Vpc")
  valid_604412 = validateParameter(valid_604412, JBool, required = false, default = nil)
  if valid_604412 != nil:
    section.add "Vpc", valid_604412
  var valid_604413 = formData.getOrDefault("DBInstanceClass")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "DBInstanceClass", valid_604413
  var valid_604414 = formData.getOrDefault("Filters")
  valid_604414 = validateParameter(valid_604414, JArray, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "Filters", valid_604414
  var valid_604415 = formData.getOrDefault("LicenseModel")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "LicenseModel", valid_604415
  var valid_604416 = formData.getOrDefault("MaxRecords")
  valid_604416 = validateParameter(valid_604416, JInt, required = false, default = nil)
  if valid_604416 != nil:
    section.add "MaxRecords", valid_604416
  var valid_604417 = formData.getOrDefault("EngineVersion")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "EngineVersion", valid_604417
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604418: Call_PostDescribeOrderableDBInstanceOptions_604398;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604418.validator(path, query, header, formData, body)
  let scheme = call_604418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604418.url(scheme.get, call_604418.host, call_604418.base,
                         call_604418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604418, url, valid)

proc call*(call_604419: Call_PostDescribeOrderableDBInstanceOptions_604398;
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
  var query_604420 = newJObject()
  var formData_604421 = newJObject()
  add(formData_604421, "Engine", newJString(Engine))
  add(formData_604421, "Marker", newJString(Marker))
  add(query_604420, "Action", newJString(Action))
  add(formData_604421, "Vpc", newJBool(Vpc))
  add(formData_604421, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604421.add "Filters", Filters
  add(formData_604421, "LicenseModel", newJString(LicenseModel))
  add(formData_604421, "MaxRecords", newJInt(MaxRecords))
  add(formData_604421, "EngineVersion", newJString(EngineVersion))
  add(query_604420, "Version", newJString(Version))
  result = call_604419.call(nil, query_604420, nil, formData_604421, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604398(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604399, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604375 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOrderableDBInstanceOptions_604377(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604376(path: JsonNode;
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
  var valid_604378 = query.getOrDefault("Engine")
  valid_604378 = validateParameter(valid_604378, JString, required = true,
                                 default = nil)
  if valid_604378 != nil:
    section.add "Engine", valid_604378
  var valid_604379 = query.getOrDefault("MaxRecords")
  valid_604379 = validateParameter(valid_604379, JInt, required = false, default = nil)
  if valid_604379 != nil:
    section.add "MaxRecords", valid_604379
  var valid_604380 = query.getOrDefault("Filters")
  valid_604380 = validateParameter(valid_604380, JArray, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "Filters", valid_604380
  var valid_604381 = query.getOrDefault("LicenseModel")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "LicenseModel", valid_604381
  var valid_604382 = query.getOrDefault("Vpc")
  valid_604382 = validateParameter(valid_604382, JBool, required = false, default = nil)
  if valid_604382 != nil:
    section.add "Vpc", valid_604382
  var valid_604383 = query.getOrDefault("DBInstanceClass")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "DBInstanceClass", valid_604383
  var valid_604384 = query.getOrDefault("Action")
  valid_604384 = validateParameter(valid_604384, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604384 != nil:
    section.add "Action", valid_604384
  var valid_604385 = query.getOrDefault("Marker")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "Marker", valid_604385
  var valid_604386 = query.getOrDefault("EngineVersion")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "EngineVersion", valid_604386
  var valid_604387 = query.getOrDefault("Version")
  valid_604387 = validateParameter(valid_604387, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604387 != nil:
    section.add "Version", valid_604387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604388 = header.getOrDefault("X-Amz-Date")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Date", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Security-Token")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Security-Token", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Content-Sha256", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Algorithm")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Algorithm", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Signature")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Signature", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-SignedHeaders", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Credential")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Credential", valid_604394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604395: Call_GetDescribeOrderableDBInstanceOptions_604375;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604395.validator(path, query, header, formData, body)
  let scheme = call_604395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604395.url(scheme.get, call_604395.host, call_604395.base,
                         call_604395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604395, url, valid)

proc call*(call_604396: Call_GetDescribeOrderableDBInstanceOptions_604375;
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
  var query_604397 = newJObject()
  add(query_604397, "Engine", newJString(Engine))
  add(query_604397, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604397.add "Filters", Filters
  add(query_604397, "LicenseModel", newJString(LicenseModel))
  add(query_604397, "Vpc", newJBool(Vpc))
  add(query_604397, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604397, "Action", newJString(Action))
  add(query_604397, "Marker", newJString(Marker))
  add(query_604397, "EngineVersion", newJString(EngineVersion))
  add(query_604397, "Version", newJString(Version))
  result = call_604396.call(nil, query_604397, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604375(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604376, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604447 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstances_604449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_604448(path: JsonNode;
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
  var valid_604450 = query.getOrDefault("Action")
  valid_604450 = validateParameter(valid_604450, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604450 != nil:
    section.add "Action", valid_604450
  var valid_604451 = query.getOrDefault("Version")
  valid_604451 = validateParameter(valid_604451, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604451 != nil:
    section.add "Version", valid_604451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604452 = header.getOrDefault("X-Amz-Date")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-Date", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Security-Token")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Security-Token", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Content-Sha256", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Algorithm")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Algorithm", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-Signature")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Signature", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-SignedHeaders", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Credential")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Credential", valid_604458
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
  var valid_604459 = formData.getOrDefault("OfferingType")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "OfferingType", valid_604459
  var valid_604460 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "ReservedDBInstanceId", valid_604460
  var valid_604461 = formData.getOrDefault("Marker")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "Marker", valid_604461
  var valid_604462 = formData.getOrDefault("MultiAZ")
  valid_604462 = validateParameter(valid_604462, JBool, required = false, default = nil)
  if valid_604462 != nil:
    section.add "MultiAZ", valid_604462
  var valid_604463 = formData.getOrDefault("Duration")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "Duration", valid_604463
  var valid_604464 = formData.getOrDefault("DBInstanceClass")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "DBInstanceClass", valid_604464
  var valid_604465 = formData.getOrDefault("Filters")
  valid_604465 = validateParameter(valid_604465, JArray, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "Filters", valid_604465
  var valid_604466 = formData.getOrDefault("ProductDescription")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "ProductDescription", valid_604466
  var valid_604467 = formData.getOrDefault("MaxRecords")
  valid_604467 = validateParameter(valid_604467, JInt, required = false, default = nil)
  if valid_604467 != nil:
    section.add "MaxRecords", valid_604467
  var valid_604468 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604469: Call_PostDescribeReservedDBInstances_604447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604469.validator(path, query, header, formData, body)
  let scheme = call_604469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604469.url(scheme.get, call_604469.host, call_604469.base,
                         call_604469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604469, url, valid)

proc call*(call_604470: Call_PostDescribeReservedDBInstances_604447;
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
  var query_604471 = newJObject()
  var formData_604472 = newJObject()
  add(formData_604472, "OfferingType", newJString(OfferingType))
  add(formData_604472, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604472, "Marker", newJString(Marker))
  add(formData_604472, "MultiAZ", newJBool(MultiAZ))
  add(query_604471, "Action", newJString(Action))
  add(formData_604472, "Duration", newJString(Duration))
  add(formData_604472, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604472.add "Filters", Filters
  add(formData_604472, "ProductDescription", newJString(ProductDescription))
  add(formData_604472, "MaxRecords", newJInt(MaxRecords))
  add(formData_604472, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604471, "Version", newJString(Version))
  result = call_604470.call(nil, query_604471, nil, formData_604472, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604447(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604448, base: "/",
    url: url_PostDescribeReservedDBInstances_604449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604422 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstances_604424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_604423(path: JsonNode;
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
  var valid_604425 = query.getOrDefault("ProductDescription")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "ProductDescription", valid_604425
  var valid_604426 = query.getOrDefault("MaxRecords")
  valid_604426 = validateParameter(valid_604426, JInt, required = false, default = nil)
  if valid_604426 != nil:
    section.add "MaxRecords", valid_604426
  var valid_604427 = query.getOrDefault("OfferingType")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "OfferingType", valid_604427
  var valid_604428 = query.getOrDefault("Filters")
  valid_604428 = validateParameter(valid_604428, JArray, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "Filters", valid_604428
  var valid_604429 = query.getOrDefault("MultiAZ")
  valid_604429 = validateParameter(valid_604429, JBool, required = false, default = nil)
  if valid_604429 != nil:
    section.add "MultiAZ", valid_604429
  var valid_604430 = query.getOrDefault("ReservedDBInstanceId")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "ReservedDBInstanceId", valid_604430
  var valid_604431 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604431
  var valid_604432 = query.getOrDefault("DBInstanceClass")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "DBInstanceClass", valid_604432
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604433 = query.getOrDefault("Action")
  valid_604433 = validateParameter(valid_604433, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604433 != nil:
    section.add "Action", valid_604433
  var valid_604434 = query.getOrDefault("Marker")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "Marker", valid_604434
  var valid_604435 = query.getOrDefault("Duration")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "Duration", valid_604435
  var valid_604436 = query.getOrDefault("Version")
  valid_604436 = validateParameter(valid_604436, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604436 != nil:
    section.add "Version", valid_604436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604437 = header.getOrDefault("X-Amz-Date")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Date", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Security-Token")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Security-Token", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Content-Sha256", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Algorithm")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Algorithm", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Signature")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Signature", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-SignedHeaders", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Credential")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Credential", valid_604443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604444: Call_GetDescribeReservedDBInstances_604422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604444.validator(path, query, header, formData, body)
  let scheme = call_604444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604444.url(scheme.get, call_604444.host, call_604444.base,
                         call_604444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604444, url, valid)

proc call*(call_604445: Call_GetDescribeReservedDBInstances_604422;
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
  var query_604446 = newJObject()
  add(query_604446, "ProductDescription", newJString(ProductDescription))
  add(query_604446, "MaxRecords", newJInt(MaxRecords))
  add(query_604446, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604446.add "Filters", Filters
  add(query_604446, "MultiAZ", newJBool(MultiAZ))
  add(query_604446, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604446, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604446, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604446, "Action", newJString(Action))
  add(query_604446, "Marker", newJString(Marker))
  add(query_604446, "Duration", newJString(Duration))
  add(query_604446, "Version", newJString(Version))
  result = call_604445.call(nil, query_604446, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604422(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604423, base: "/",
    url: url_GetDescribeReservedDBInstances_604424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604497 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstancesOfferings_604499(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604498(path: JsonNode;
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
  var valid_604500 = query.getOrDefault("Action")
  valid_604500 = validateParameter(valid_604500, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604500 != nil:
    section.add "Action", valid_604500
  var valid_604501 = query.getOrDefault("Version")
  valid_604501 = validateParameter(valid_604501, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604501 != nil:
    section.add "Version", valid_604501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604502 = header.getOrDefault("X-Amz-Date")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Date", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Security-Token")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Security-Token", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Content-Sha256", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Algorithm")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Algorithm", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Signature")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Signature", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-SignedHeaders", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Credential")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Credential", valid_604508
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
  var valid_604509 = formData.getOrDefault("OfferingType")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "OfferingType", valid_604509
  var valid_604510 = formData.getOrDefault("Marker")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "Marker", valid_604510
  var valid_604511 = formData.getOrDefault("MultiAZ")
  valid_604511 = validateParameter(valid_604511, JBool, required = false, default = nil)
  if valid_604511 != nil:
    section.add "MultiAZ", valid_604511
  var valid_604512 = formData.getOrDefault("Duration")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "Duration", valid_604512
  var valid_604513 = formData.getOrDefault("DBInstanceClass")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "DBInstanceClass", valid_604513
  var valid_604514 = formData.getOrDefault("Filters")
  valid_604514 = validateParameter(valid_604514, JArray, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "Filters", valid_604514
  var valid_604515 = formData.getOrDefault("ProductDescription")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "ProductDescription", valid_604515
  var valid_604516 = formData.getOrDefault("MaxRecords")
  valid_604516 = validateParameter(valid_604516, JInt, required = false, default = nil)
  if valid_604516 != nil:
    section.add "MaxRecords", valid_604516
  var valid_604517 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604517
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604518: Call_PostDescribeReservedDBInstancesOfferings_604497;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604518.validator(path, query, header, formData, body)
  let scheme = call_604518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604518.url(scheme.get, call_604518.host, call_604518.base,
                         call_604518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604518, url, valid)

proc call*(call_604519: Call_PostDescribeReservedDBInstancesOfferings_604497;
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
  var query_604520 = newJObject()
  var formData_604521 = newJObject()
  add(formData_604521, "OfferingType", newJString(OfferingType))
  add(formData_604521, "Marker", newJString(Marker))
  add(formData_604521, "MultiAZ", newJBool(MultiAZ))
  add(query_604520, "Action", newJString(Action))
  add(formData_604521, "Duration", newJString(Duration))
  add(formData_604521, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604521.add "Filters", Filters
  add(formData_604521, "ProductDescription", newJString(ProductDescription))
  add(formData_604521, "MaxRecords", newJInt(MaxRecords))
  add(formData_604521, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604520, "Version", newJString(Version))
  result = call_604519.call(nil, query_604520, nil, formData_604521, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604497(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604498,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604473 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstancesOfferings_604475(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604474(path: JsonNode;
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
  var valid_604476 = query.getOrDefault("ProductDescription")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "ProductDescription", valid_604476
  var valid_604477 = query.getOrDefault("MaxRecords")
  valid_604477 = validateParameter(valid_604477, JInt, required = false, default = nil)
  if valid_604477 != nil:
    section.add "MaxRecords", valid_604477
  var valid_604478 = query.getOrDefault("OfferingType")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "OfferingType", valid_604478
  var valid_604479 = query.getOrDefault("Filters")
  valid_604479 = validateParameter(valid_604479, JArray, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "Filters", valid_604479
  var valid_604480 = query.getOrDefault("MultiAZ")
  valid_604480 = validateParameter(valid_604480, JBool, required = false, default = nil)
  if valid_604480 != nil:
    section.add "MultiAZ", valid_604480
  var valid_604481 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604481
  var valid_604482 = query.getOrDefault("DBInstanceClass")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "DBInstanceClass", valid_604482
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604483 = query.getOrDefault("Action")
  valid_604483 = validateParameter(valid_604483, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604483 != nil:
    section.add "Action", valid_604483
  var valid_604484 = query.getOrDefault("Marker")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "Marker", valid_604484
  var valid_604485 = query.getOrDefault("Duration")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "Duration", valid_604485
  var valid_604486 = query.getOrDefault("Version")
  valid_604486 = validateParameter(valid_604486, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604486 != nil:
    section.add "Version", valid_604486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604487 = header.getOrDefault("X-Amz-Date")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Date", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Security-Token")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Security-Token", valid_604488
  var valid_604489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604489 = validateParameter(valid_604489, JString, required = false,
                                 default = nil)
  if valid_604489 != nil:
    section.add "X-Amz-Content-Sha256", valid_604489
  var valid_604490 = header.getOrDefault("X-Amz-Algorithm")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Algorithm", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-Signature")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-Signature", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-SignedHeaders", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Credential")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Credential", valid_604493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604494: Call_GetDescribeReservedDBInstancesOfferings_604473;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604494.validator(path, query, header, formData, body)
  let scheme = call_604494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604494.url(scheme.get, call_604494.host, call_604494.base,
                         call_604494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604494, url, valid)

proc call*(call_604495: Call_GetDescribeReservedDBInstancesOfferings_604473;
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
  var query_604496 = newJObject()
  add(query_604496, "ProductDescription", newJString(ProductDescription))
  add(query_604496, "MaxRecords", newJInt(MaxRecords))
  add(query_604496, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604496.add "Filters", Filters
  add(query_604496, "MultiAZ", newJBool(MultiAZ))
  add(query_604496, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604496, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604496, "Action", newJString(Action))
  add(query_604496, "Marker", newJString(Marker))
  add(query_604496, "Duration", newJString(Duration))
  add(query_604496, "Version", newJString(Version))
  result = call_604495.call(nil, query_604496, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604473(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604474, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604541 = ref object of OpenApiRestCall_602450
proc url_PostDownloadDBLogFilePortion_604543(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_604542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604544 = query.getOrDefault("Action")
  valid_604544 = validateParameter(valid_604544, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604544 != nil:
    section.add "Action", valid_604544
  var valid_604545 = query.getOrDefault("Version")
  valid_604545 = validateParameter(valid_604545, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604545 != nil:
    section.add "Version", valid_604545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604546 = header.getOrDefault("X-Amz-Date")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Date", valid_604546
  var valid_604547 = header.getOrDefault("X-Amz-Security-Token")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Security-Token", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Content-Sha256", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Algorithm")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Algorithm", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Signature")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Signature", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-SignedHeaders", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Credential")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Credential", valid_604552
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604553 = formData.getOrDefault("NumberOfLines")
  valid_604553 = validateParameter(valid_604553, JInt, required = false, default = nil)
  if valid_604553 != nil:
    section.add "NumberOfLines", valid_604553
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604554 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604554 = validateParameter(valid_604554, JString, required = true,
                                 default = nil)
  if valid_604554 != nil:
    section.add "DBInstanceIdentifier", valid_604554
  var valid_604555 = formData.getOrDefault("Marker")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "Marker", valid_604555
  var valid_604556 = formData.getOrDefault("LogFileName")
  valid_604556 = validateParameter(valid_604556, JString, required = true,
                                 default = nil)
  if valid_604556 != nil:
    section.add "LogFileName", valid_604556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604557: Call_PostDownloadDBLogFilePortion_604541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604557.validator(path, query, header, formData, body)
  let scheme = call_604557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604557.url(scheme.get, call_604557.host, call_604557.base,
                         call_604557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604557, url, valid)

proc call*(call_604558: Call_PostDownloadDBLogFilePortion_604541;
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
  var query_604559 = newJObject()
  var formData_604560 = newJObject()
  add(formData_604560, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604560, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604560, "Marker", newJString(Marker))
  add(query_604559, "Action", newJString(Action))
  add(formData_604560, "LogFileName", newJString(LogFileName))
  add(query_604559, "Version", newJString(Version))
  result = call_604558.call(nil, query_604559, nil, formData_604560, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604541(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604542, base: "/",
    url: url_PostDownloadDBLogFilePortion_604543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604522 = ref object of OpenApiRestCall_602450
proc url_GetDownloadDBLogFilePortion_604524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_604523(path: JsonNode; query: JsonNode;
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
  var valid_604525 = query.getOrDefault("NumberOfLines")
  valid_604525 = validateParameter(valid_604525, JInt, required = false, default = nil)
  if valid_604525 != nil:
    section.add "NumberOfLines", valid_604525
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604526 = query.getOrDefault("LogFileName")
  valid_604526 = validateParameter(valid_604526, JString, required = true,
                                 default = nil)
  if valid_604526 != nil:
    section.add "LogFileName", valid_604526
  var valid_604527 = query.getOrDefault("Action")
  valid_604527 = validateParameter(valid_604527, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604527 != nil:
    section.add "Action", valid_604527
  var valid_604528 = query.getOrDefault("Marker")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "Marker", valid_604528
  var valid_604529 = query.getOrDefault("Version")
  valid_604529 = validateParameter(valid_604529, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604529 != nil:
    section.add "Version", valid_604529
  var valid_604530 = query.getOrDefault("DBInstanceIdentifier")
  valid_604530 = validateParameter(valid_604530, JString, required = true,
                                 default = nil)
  if valid_604530 != nil:
    section.add "DBInstanceIdentifier", valid_604530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604531 = header.getOrDefault("X-Amz-Date")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-Date", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Security-Token")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Security-Token", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Content-Sha256", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Algorithm")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Algorithm", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Signature")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Signature", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-SignedHeaders", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Credential")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Credential", valid_604537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604538: Call_GetDownloadDBLogFilePortion_604522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604538.validator(path, query, header, formData, body)
  let scheme = call_604538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604538.url(scheme.get, call_604538.host, call_604538.base,
                         call_604538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604538, url, valid)

proc call*(call_604539: Call_GetDownloadDBLogFilePortion_604522;
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
  var query_604540 = newJObject()
  add(query_604540, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604540, "LogFileName", newJString(LogFileName))
  add(query_604540, "Action", newJString(Action))
  add(query_604540, "Marker", newJString(Marker))
  add(query_604540, "Version", newJString(Version))
  add(query_604540, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604539.call(nil, query_604540, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604522(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604523, base: "/",
    url: url_GetDownloadDBLogFilePortion_604524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604578 = ref object of OpenApiRestCall_602450
proc url_PostListTagsForResource_604580(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604579(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("ListTagsForResource"))
  if valid_604581 != nil:
    section.add "Action", valid_604581
  var valid_604582 = query.getOrDefault("Version")
  valid_604582 = validateParameter(valid_604582, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_604590 = formData.getOrDefault("Filters")
  valid_604590 = validateParameter(valid_604590, JArray, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "Filters", valid_604590
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604591 = formData.getOrDefault("ResourceName")
  valid_604591 = validateParameter(valid_604591, JString, required = true,
                                 default = nil)
  if valid_604591 != nil:
    section.add "ResourceName", valid_604591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604592: Call_PostListTagsForResource_604578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604592.validator(path, query, header, formData, body)
  let scheme = call_604592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604592.url(scheme.get, call_604592.host, call_604592.base,
                         call_604592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604592, url, valid)

proc call*(call_604593: Call_PostListTagsForResource_604578; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604594 = newJObject()
  var formData_604595 = newJObject()
  add(query_604594, "Action", newJString(Action))
  if Filters != nil:
    formData_604595.add "Filters", Filters
  add(formData_604595, "ResourceName", newJString(ResourceName))
  add(query_604594, "Version", newJString(Version))
  result = call_604593.call(nil, query_604594, nil, formData_604595, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604578(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604579, base: "/",
    url: url_PostListTagsForResource_604580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604561 = ref object of OpenApiRestCall_602450
proc url_GetListTagsForResource_604563(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604562(path: JsonNode; query: JsonNode;
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
  var valid_604564 = query.getOrDefault("Filters")
  valid_604564 = validateParameter(valid_604564, JArray, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "Filters", valid_604564
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604565 = query.getOrDefault("ResourceName")
  valid_604565 = validateParameter(valid_604565, JString, required = true,
                                 default = nil)
  if valid_604565 != nil:
    section.add "ResourceName", valid_604565
  var valid_604566 = query.getOrDefault("Action")
  valid_604566 = validateParameter(valid_604566, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604566 != nil:
    section.add "Action", valid_604566
  var valid_604567 = query.getOrDefault("Version")
  valid_604567 = validateParameter(valid_604567, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_604575: Call_GetListTagsForResource_604561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604575.validator(path, query, header, formData, body)
  let scheme = call_604575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604575.url(scheme.get, call_604575.host, call_604575.base,
                         call_604575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604575, url, valid)

proc call*(call_604576: Call_GetListTagsForResource_604561; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604577 = newJObject()
  if Filters != nil:
    query_604577.add "Filters", Filters
  add(query_604577, "ResourceName", newJString(ResourceName))
  add(query_604577, "Action", newJString(Action))
  add(query_604577, "Version", newJString(Version))
  result = call_604576.call(nil, query_604577, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604561(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604562, base: "/",
    url: url_GetListTagsForResource_604563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604629 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBInstance_604631(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_604630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604632 = query.getOrDefault("Action")
  valid_604632 = validateParameter(valid_604632, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604632 != nil:
    section.add "Action", valid_604632
  var valid_604633 = query.getOrDefault("Version")
  valid_604633 = validateParameter(valid_604633, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604633 != nil:
    section.add "Version", valid_604633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604634 = header.getOrDefault("X-Amz-Date")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Date", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Security-Token")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Security-Token", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-Content-Sha256", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Algorithm")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Algorithm", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Signature")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Signature", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-SignedHeaders", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-Credential")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Credential", valid_604640
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
  var valid_604641 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "PreferredMaintenanceWindow", valid_604641
  var valid_604642 = formData.getOrDefault("DBSecurityGroups")
  valid_604642 = validateParameter(valid_604642, JArray, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "DBSecurityGroups", valid_604642
  var valid_604643 = formData.getOrDefault("ApplyImmediately")
  valid_604643 = validateParameter(valid_604643, JBool, required = false, default = nil)
  if valid_604643 != nil:
    section.add "ApplyImmediately", valid_604643
  var valid_604644 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604644 = validateParameter(valid_604644, JArray, required = false,
                                 default = nil)
  if valid_604644 != nil:
    section.add "VpcSecurityGroupIds", valid_604644
  var valid_604645 = formData.getOrDefault("Iops")
  valid_604645 = validateParameter(valid_604645, JInt, required = false, default = nil)
  if valid_604645 != nil:
    section.add "Iops", valid_604645
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604646 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604646 = validateParameter(valid_604646, JString, required = true,
                                 default = nil)
  if valid_604646 != nil:
    section.add "DBInstanceIdentifier", valid_604646
  var valid_604647 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604647 = validateParameter(valid_604647, JInt, required = false, default = nil)
  if valid_604647 != nil:
    section.add "BackupRetentionPeriod", valid_604647
  var valid_604648 = formData.getOrDefault("DBParameterGroupName")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "DBParameterGroupName", valid_604648
  var valid_604649 = formData.getOrDefault("OptionGroupName")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "OptionGroupName", valid_604649
  var valid_604650 = formData.getOrDefault("MasterUserPassword")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "MasterUserPassword", valid_604650
  var valid_604651 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "NewDBInstanceIdentifier", valid_604651
  var valid_604652 = formData.getOrDefault("MultiAZ")
  valid_604652 = validateParameter(valid_604652, JBool, required = false, default = nil)
  if valid_604652 != nil:
    section.add "MultiAZ", valid_604652
  var valid_604653 = formData.getOrDefault("AllocatedStorage")
  valid_604653 = validateParameter(valid_604653, JInt, required = false, default = nil)
  if valid_604653 != nil:
    section.add "AllocatedStorage", valid_604653
  var valid_604654 = formData.getOrDefault("DBInstanceClass")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "DBInstanceClass", valid_604654
  var valid_604655 = formData.getOrDefault("PreferredBackupWindow")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "PreferredBackupWindow", valid_604655
  var valid_604656 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604656 = validateParameter(valid_604656, JBool, required = false, default = nil)
  if valid_604656 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604656
  var valid_604657 = formData.getOrDefault("EngineVersion")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "EngineVersion", valid_604657
  var valid_604658 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604658 = validateParameter(valid_604658, JBool, required = false, default = nil)
  if valid_604658 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604658
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604659: Call_PostModifyDBInstance_604629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604659.validator(path, query, header, formData, body)
  let scheme = call_604659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604659.url(scheme.get, call_604659.host, call_604659.base,
                         call_604659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604659, url, valid)

proc call*(call_604660: Call_PostModifyDBInstance_604629;
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
  var query_604661 = newJObject()
  var formData_604662 = newJObject()
  add(formData_604662, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604662.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604662, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604662.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604662, "Iops", newJInt(Iops))
  add(formData_604662, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604662, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604662, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604662, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604662, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604662, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604662, "MultiAZ", newJBool(MultiAZ))
  add(query_604661, "Action", newJString(Action))
  add(formData_604662, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604662, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604662, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604662, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604662, "EngineVersion", newJString(EngineVersion))
  add(query_604661, "Version", newJString(Version))
  add(formData_604662, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604660.call(nil, query_604661, nil, formData_604662, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604629(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604630, base: "/",
    url: url_PostModifyDBInstance_604631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604596 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBInstance_604598(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_604597(path: JsonNode; query: JsonNode;
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
  var valid_604599 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "PreferredMaintenanceWindow", valid_604599
  var valid_604600 = query.getOrDefault("AllocatedStorage")
  valid_604600 = validateParameter(valid_604600, JInt, required = false, default = nil)
  if valid_604600 != nil:
    section.add "AllocatedStorage", valid_604600
  var valid_604601 = query.getOrDefault("OptionGroupName")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "OptionGroupName", valid_604601
  var valid_604602 = query.getOrDefault("DBSecurityGroups")
  valid_604602 = validateParameter(valid_604602, JArray, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "DBSecurityGroups", valid_604602
  var valid_604603 = query.getOrDefault("MasterUserPassword")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "MasterUserPassword", valid_604603
  var valid_604604 = query.getOrDefault("Iops")
  valid_604604 = validateParameter(valid_604604, JInt, required = false, default = nil)
  if valid_604604 != nil:
    section.add "Iops", valid_604604
  var valid_604605 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604605 = validateParameter(valid_604605, JArray, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "VpcSecurityGroupIds", valid_604605
  var valid_604606 = query.getOrDefault("MultiAZ")
  valid_604606 = validateParameter(valid_604606, JBool, required = false, default = nil)
  if valid_604606 != nil:
    section.add "MultiAZ", valid_604606
  var valid_604607 = query.getOrDefault("BackupRetentionPeriod")
  valid_604607 = validateParameter(valid_604607, JInt, required = false, default = nil)
  if valid_604607 != nil:
    section.add "BackupRetentionPeriod", valid_604607
  var valid_604608 = query.getOrDefault("DBParameterGroupName")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "DBParameterGroupName", valid_604608
  var valid_604609 = query.getOrDefault("DBInstanceClass")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "DBInstanceClass", valid_604609
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604610 = query.getOrDefault("Action")
  valid_604610 = validateParameter(valid_604610, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604610 != nil:
    section.add "Action", valid_604610
  var valid_604611 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604611 = validateParameter(valid_604611, JBool, required = false, default = nil)
  if valid_604611 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604611
  var valid_604612 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "NewDBInstanceIdentifier", valid_604612
  var valid_604613 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604613 = validateParameter(valid_604613, JBool, required = false, default = nil)
  if valid_604613 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604613
  var valid_604614 = query.getOrDefault("EngineVersion")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "EngineVersion", valid_604614
  var valid_604615 = query.getOrDefault("PreferredBackupWindow")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "PreferredBackupWindow", valid_604615
  var valid_604616 = query.getOrDefault("Version")
  valid_604616 = validateParameter(valid_604616, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604616 != nil:
    section.add "Version", valid_604616
  var valid_604617 = query.getOrDefault("DBInstanceIdentifier")
  valid_604617 = validateParameter(valid_604617, JString, required = true,
                                 default = nil)
  if valid_604617 != nil:
    section.add "DBInstanceIdentifier", valid_604617
  var valid_604618 = query.getOrDefault("ApplyImmediately")
  valid_604618 = validateParameter(valid_604618, JBool, required = false, default = nil)
  if valid_604618 != nil:
    section.add "ApplyImmediately", valid_604618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604619 = header.getOrDefault("X-Amz-Date")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Date", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Security-Token")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Security-Token", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Content-Sha256", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Algorithm")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Algorithm", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Signature")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Signature", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-SignedHeaders", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Credential")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Credential", valid_604625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604626: Call_GetModifyDBInstance_604596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604626.validator(path, query, header, formData, body)
  let scheme = call_604626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604626.url(scheme.get, call_604626.host, call_604626.base,
                         call_604626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604626, url, valid)

proc call*(call_604627: Call_GetModifyDBInstance_604596;
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
  var query_604628 = newJObject()
  add(query_604628, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604628, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604628, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604628.add "DBSecurityGroups", DBSecurityGroups
  add(query_604628, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604628, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604628.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604628, "MultiAZ", newJBool(MultiAZ))
  add(query_604628, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604628, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604628, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604628, "Action", newJString(Action))
  add(query_604628, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604628, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604628, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604628, "EngineVersion", newJString(EngineVersion))
  add(query_604628, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604628, "Version", newJString(Version))
  add(query_604628, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604628, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604627.call(nil, query_604628, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604596(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604597, base: "/",
    url: url_GetModifyDBInstance_604598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604680 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBParameterGroup_604682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_604681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604683 = query.getOrDefault("Action")
  valid_604683 = validateParameter(valid_604683, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604683 != nil:
    section.add "Action", valid_604683
  var valid_604684 = query.getOrDefault("Version")
  valid_604684 = validateParameter(valid_604684, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604684 != nil:
    section.add "Version", valid_604684
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604692 = formData.getOrDefault("DBParameterGroupName")
  valid_604692 = validateParameter(valid_604692, JString, required = true,
                                 default = nil)
  if valid_604692 != nil:
    section.add "DBParameterGroupName", valid_604692
  var valid_604693 = formData.getOrDefault("Parameters")
  valid_604693 = validateParameter(valid_604693, JArray, required = true, default = nil)
  if valid_604693 != nil:
    section.add "Parameters", valid_604693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604694: Call_PostModifyDBParameterGroup_604680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604694.validator(path, query, header, formData, body)
  let scheme = call_604694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604694.url(scheme.get, call_604694.host, call_604694.base,
                         call_604694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604694, url, valid)

proc call*(call_604695: Call_PostModifyDBParameterGroup_604680;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604696 = newJObject()
  var formData_604697 = newJObject()
  add(formData_604697, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604697.add "Parameters", Parameters
  add(query_604696, "Action", newJString(Action))
  add(query_604696, "Version", newJString(Version))
  result = call_604695.call(nil, query_604696, nil, formData_604697, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604680(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604681, base: "/",
    url: url_PostModifyDBParameterGroup_604682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604663 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBParameterGroup_604665(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_604664(path: JsonNode; query: JsonNode;
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
  var valid_604666 = query.getOrDefault("DBParameterGroupName")
  valid_604666 = validateParameter(valid_604666, JString, required = true,
                                 default = nil)
  if valid_604666 != nil:
    section.add "DBParameterGroupName", valid_604666
  var valid_604667 = query.getOrDefault("Parameters")
  valid_604667 = validateParameter(valid_604667, JArray, required = true, default = nil)
  if valid_604667 != nil:
    section.add "Parameters", valid_604667
  var valid_604668 = query.getOrDefault("Action")
  valid_604668 = validateParameter(valid_604668, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604668 != nil:
    section.add "Action", valid_604668
  var valid_604669 = query.getOrDefault("Version")
  valid_604669 = validateParameter(valid_604669, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604669 != nil:
    section.add "Version", valid_604669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604670 = header.getOrDefault("X-Amz-Date")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "X-Amz-Date", valid_604670
  var valid_604671 = header.getOrDefault("X-Amz-Security-Token")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "X-Amz-Security-Token", valid_604671
  var valid_604672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604672 = validateParameter(valid_604672, JString, required = false,
                                 default = nil)
  if valid_604672 != nil:
    section.add "X-Amz-Content-Sha256", valid_604672
  var valid_604673 = header.getOrDefault("X-Amz-Algorithm")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Algorithm", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-Signature")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-Signature", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-SignedHeaders", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Credential")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Credential", valid_604676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604677: Call_GetModifyDBParameterGroup_604663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604677.validator(path, query, header, formData, body)
  let scheme = call_604677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604677.url(scheme.get, call_604677.host, call_604677.base,
                         call_604677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604677, url, valid)

proc call*(call_604678: Call_GetModifyDBParameterGroup_604663;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604679 = newJObject()
  add(query_604679, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604679.add "Parameters", Parameters
  add(query_604679, "Action", newJString(Action))
  add(query_604679, "Version", newJString(Version))
  result = call_604678.call(nil, query_604679, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604663(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604664, base: "/",
    url: url_GetModifyDBParameterGroup_604665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604716 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBSubnetGroup_604718(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_604717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604719 = query.getOrDefault("Action")
  valid_604719 = validateParameter(valid_604719, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604719 != nil:
    section.add "Action", valid_604719
  var valid_604720 = query.getOrDefault("Version")
  valid_604720 = validateParameter(valid_604720, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604720 != nil:
    section.add "Version", valid_604720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604721 = header.getOrDefault("X-Amz-Date")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Date", valid_604721
  var valid_604722 = header.getOrDefault("X-Amz-Security-Token")
  valid_604722 = validateParameter(valid_604722, JString, required = false,
                                 default = nil)
  if valid_604722 != nil:
    section.add "X-Amz-Security-Token", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Content-Sha256", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Algorithm")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Algorithm", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Signature")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Signature", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-SignedHeaders", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Credential")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Credential", valid_604727
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604728 = formData.getOrDefault("DBSubnetGroupName")
  valid_604728 = validateParameter(valid_604728, JString, required = true,
                                 default = nil)
  if valid_604728 != nil:
    section.add "DBSubnetGroupName", valid_604728
  var valid_604729 = formData.getOrDefault("SubnetIds")
  valid_604729 = validateParameter(valid_604729, JArray, required = true, default = nil)
  if valid_604729 != nil:
    section.add "SubnetIds", valid_604729
  var valid_604730 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "DBSubnetGroupDescription", valid_604730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604731: Call_PostModifyDBSubnetGroup_604716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604731.validator(path, query, header, formData, body)
  let scheme = call_604731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604731.url(scheme.get, call_604731.host, call_604731.base,
                         call_604731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604731, url, valid)

proc call*(call_604732: Call_PostModifyDBSubnetGroup_604716;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604733 = newJObject()
  var formData_604734 = newJObject()
  add(formData_604734, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604734.add "SubnetIds", SubnetIds
  add(query_604733, "Action", newJString(Action))
  add(formData_604734, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604733, "Version", newJString(Version))
  result = call_604732.call(nil, query_604733, nil, formData_604734, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604716(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604717, base: "/",
    url: url_PostModifyDBSubnetGroup_604718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604698 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBSubnetGroup_604700(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_604699(path: JsonNode; query: JsonNode;
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
  var valid_604701 = query.getOrDefault("Action")
  valid_604701 = validateParameter(valid_604701, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604701 != nil:
    section.add "Action", valid_604701
  var valid_604702 = query.getOrDefault("DBSubnetGroupName")
  valid_604702 = validateParameter(valid_604702, JString, required = true,
                                 default = nil)
  if valid_604702 != nil:
    section.add "DBSubnetGroupName", valid_604702
  var valid_604703 = query.getOrDefault("SubnetIds")
  valid_604703 = validateParameter(valid_604703, JArray, required = true, default = nil)
  if valid_604703 != nil:
    section.add "SubnetIds", valid_604703
  var valid_604704 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "DBSubnetGroupDescription", valid_604704
  var valid_604705 = query.getOrDefault("Version")
  valid_604705 = validateParameter(valid_604705, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604705 != nil:
    section.add "Version", valid_604705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604706 = header.getOrDefault("X-Amz-Date")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Date", valid_604706
  var valid_604707 = header.getOrDefault("X-Amz-Security-Token")
  valid_604707 = validateParameter(valid_604707, JString, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "X-Amz-Security-Token", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Content-Sha256", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Algorithm")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Algorithm", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Signature")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Signature", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-SignedHeaders", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Credential")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Credential", valid_604712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604713: Call_GetModifyDBSubnetGroup_604698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604713.validator(path, query, header, formData, body)
  let scheme = call_604713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604713.url(scheme.get, call_604713.host, call_604713.base,
                         call_604713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604713, url, valid)

proc call*(call_604714: Call_GetModifyDBSubnetGroup_604698;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604715 = newJObject()
  add(query_604715, "Action", newJString(Action))
  add(query_604715, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604715.add "SubnetIds", SubnetIds
  add(query_604715, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604715, "Version", newJString(Version))
  result = call_604714.call(nil, query_604715, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604698(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604699, base: "/",
    url: url_GetModifyDBSubnetGroup_604700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604755 = ref object of OpenApiRestCall_602450
proc url_PostModifyEventSubscription_604757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_604756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604758 = query.getOrDefault("Action")
  valid_604758 = validateParameter(valid_604758, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604758 != nil:
    section.add "Action", valid_604758
  var valid_604759 = query.getOrDefault("Version")
  valid_604759 = validateParameter(valid_604759, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604759 != nil:
    section.add "Version", valid_604759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604760 = header.getOrDefault("X-Amz-Date")
  valid_604760 = validateParameter(valid_604760, JString, required = false,
                                 default = nil)
  if valid_604760 != nil:
    section.add "X-Amz-Date", valid_604760
  var valid_604761 = header.getOrDefault("X-Amz-Security-Token")
  valid_604761 = validateParameter(valid_604761, JString, required = false,
                                 default = nil)
  if valid_604761 != nil:
    section.add "X-Amz-Security-Token", valid_604761
  var valid_604762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604762 = validateParameter(valid_604762, JString, required = false,
                                 default = nil)
  if valid_604762 != nil:
    section.add "X-Amz-Content-Sha256", valid_604762
  var valid_604763 = header.getOrDefault("X-Amz-Algorithm")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "X-Amz-Algorithm", valid_604763
  var valid_604764 = header.getOrDefault("X-Amz-Signature")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "X-Amz-Signature", valid_604764
  var valid_604765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-SignedHeaders", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Credential")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Credential", valid_604766
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604767 = formData.getOrDefault("Enabled")
  valid_604767 = validateParameter(valid_604767, JBool, required = false, default = nil)
  if valid_604767 != nil:
    section.add "Enabled", valid_604767
  var valid_604768 = formData.getOrDefault("EventCategories")
  valid_604768 = validateParameter(valid_604768, JArray, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "EventCategories", valid_604768
  var valid_604769 = formData.getOrDefault("SnsTopicArn")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "SnsTopicArn", valid_604769
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604770 = formData.getOrDefault("SubscriptionName")
  valid_604770 = validateParameter(valid_604770, JString, required = true,
                                 default = nil)
  if valid_604770 != nil:
    section.add "SubscriptionName", valid_604770
  var valid_604771 = formData.getOrDefault("SourceType")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "SourceType", valid_604771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604772: Call_PostModifyEventSubscription_604755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604772.validator(path, query, header, formData, body)
  let scheme = call_604772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604772.url(scheme.get, call_604772.host, call_604772.base,
                         call_604772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604772, url, valid)

proc call*(call_604773: Call_PostModifyEventSubscription_604755;
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
  var query_604774 = newJObject()
  var formData_604775 = newJObject()
  add(formData_604775, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604775.add "EventCategories", EventCategories
  add(formData_604775, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604775, "SubscriptionName", newJString(SubscriptionName))
  add(query_604774, "Action", newJString(Action))
  add(query_604774, "Version", newJString(Version))
  add(formData_604775, "SourceType", newJString(SourceType))
  result = call_604773.call(nil, query_604774, nil, formData_604775, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604755(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604756, base: "/",
    url: url_PostModifyEventSubscription_604757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604735 = ref object of OpenApiRestCall_602450
proc url_GetModifyEventSubscription_604737(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_604736(path: JsonNode; query: JsonNode;
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
  var valid_604738 = query.getOrDefault("SourceType")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "SourceType", valid_604738
  var valid_604739 = query.getOrDefault("Enabled")
  valid_604739 = validateParameter(valid_604739, JBool, required = false, default = nil)
  if valid_604739 != nil:
    section.add "Enabled", valid_604739
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604740 = query.getOrDefault("Action")
  valid_604740 = validateParameter(valid_604740, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604740 != nil:
    section.add "Action", valid_604740
  var valid_604741 = query.getOrDefault("SnsTopicArn")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "SnsTopicArn", valid_604741
  var valid_604742 = query.getOrDefault("EventCategories")
  valid_604742 = validateParameter(valid_604742, JArray, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "EventCategories", valid_604742
  var valid_604743 = query.getOrDefault("SubscriptionName")
  valid_604743 = validateParameter(valid_604743, JString, required = true,
                                 default = nil)
  if valid_604743 != nil:
    section.add "SubscriptionName", valid_604743
  var valid_604744 = query.getOrDefault("Version")
  valid_604744 = validateParameter(valid_604744, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604744 != nil:
    section.add "Version", valid_604744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604745 = header.getOrDefault("X-Amz-Date")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "X-Amz-Date", valid_604745
  var valid_604746 = header.getOrDefault("X-Amz-Security-Token")
  valid_604746 = validateParameter(valid_604746, JString, required = false,
                                 default = nil)
  if valid_604746 != nil:
    section.add "X-Amz-Security-Token", valid_604746
  var valid_604747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604747 = validateParameter(valid_604747, JString, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "X-Amz-Content-Sha256", valid_604747
  var valid_604748 = header.getOrDefault("X-Amz-Algorithm")
  valid_604748 = validateParameter(valid_604748, JString, required = false,
                                 default = nil)
  if valid_604748 != nil:
    section.add "X-Amz-Algorithm", valid_604748
  var valid_604749 = header.getOrDefault("X-Amz-Signature")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "X-Amz-Signature", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-SignedHeaders", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Credential")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Credential", valid_604751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604752: Call_GetModifyEventSubscription_604735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604752.validator(path, query, header, formData, body)
  let scheme = call_604752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604752.url(scheme.get, call_604752.host, call_604752.base,
                         call_604752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604752, url, valid)

proc call*(call_604753: Call_GetModifyEventSubscription_604735;
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
  var query_604754 = newJObject()
  add(query_604754, "SourceType", newJString(SourceType))
  add(query_604754, "Enabled", newJBool(Enabled))
  add(query_604754, "Action", newJString(Action))
  add(query_604754, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604754.add "EventCategories", EventCategories
  add(query_604754, "SubscriptionName", newJString(SubscriptionName))
  add(query_604754, "Version", newJString(Version))
  result = call_604753.call(nil, query_604754, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604735(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604736, base: "/",
    url: url_GetModifyEventSubscription_604737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604795 = ref object of OpenApiRestCall_602450
proc url_PostModifyOptionGroup_604797(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_604796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604798 = query.getOrDefault("Action")
  valid_604798 = validateParameter(valid_604798, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604798 != nil:
    section.add "Action", valid_604798
  var valid_604799 = query.getOrDefault("Version")
  valid_604799 = validateParameter(valid_604799, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604799 != nil:
    section.add "Version", valid_604799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604800 = header.getOrDefault("X-Amz-Date")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "X-Amz-Date", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-Security-Token")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-Security-Token", valid_604801
  var valid_604802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604802 = validateParameter(valid_604802, JString, required = false,
                                 default = nil)
  if valid_604802 != nil:
    section.add "X-Amz-Content-Sha256", valid_604802
  var valid_604803 = header.getOrDefault("X-Amz-Algorithm")
  valid_604803 = validateParameter(valid_604803, JString, required = false,
                                 default = nil)
  if valid_604803 != nil:
    section.add "X-Amz-Algorithm", valid_604803
  var valid_604804 = header.getOrDefault("X-Amz-Signature")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "X-Amz-Signature", valid_604804
  var valid_604805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "X-Amz-SignedHeaders", valid_604805
  var valid_604806 = header.getOrDefault("X-Amz-Credential")
  valid_604806 = validateParameter(valid_604806, JString, required = false,
                                 default = nil)
  if valid_604806 != nil:
    section.add "X-Amz-Credential", valid_604806
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604807 = formData.getOrDefault("OptionsToRemove")
  valid_604807 = validateParameter(valid_604807, JArray, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "OptionsToRemove", valid_604807
  var valid_604808 = formData.getOrDefault("ApplyImmediately")
  valid_604808 = validateParameter(valid_604808, JBool, required = false, default = nil)
  if valid_604808 != nil:
    section.add "ApplyImmediately", valid_604808
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604809 = formData.getOrDefault("OptionGroupName")
  valid_604809 = validateParameter(valid_604809, JString, required = true,
                                 default = nil)
  if valid_604809 != nil:
    section.add "OptionGroupName", valid_604809
  var valid_604810 = formData.getOrDefault("OptionsToInclude")
  valid_604810 = validateParameter(valid_604810, JArray, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "OptionsToInclude", valid_604810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604811: Call_PostModifyOptionGroup_604795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604811.validator(path, query, header, formData, body)
  let scheme = call_604811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604811.url(scheme.get, call_604811.host, call_604811.base,
                         call_604811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604811, url, valid)

proc call*(call_604812: Call_PostModifyOptionGroup_604795; OptionGroupName: string;
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
  var query_604813 = newJObject()
  var formData_604814 = newJObject()
  if OptionsToRemove != nil:
    formData_604814.add "OptionsToRemove", OptionsToRemove
  add(formData_604814, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604814, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604814.add "OptionsToInclude", OptionsToInclude
  add(query_604813, "Action", newJString(Action))
  add(query_604813, "Version", newJString(Version))
  result = call_604812.call(nil, query_604813, nil, formData_604814, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604795(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604796, base: "/",
    url: url_PostModifyOptionGroup_604797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604776 = ref object of OpenApiRestCall_602450
proc url_GetModifyOptionGroup_604778(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_604777(path: JsonNode; query: JsonNode;
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
  var valid_604779 = query.getOrDefault("OptionGroupName")
  valid_604779 = validateParameter(valid_604779, JString, required = true,
                                 default = nil)
  if valid_604779 != nil:
    section.add "OptionGroupName", valid_604779
  var valid_604780 = query.getOrDefault("OptionsToRemove")
  valid_604780 = validateParameter(valid_604780, JArray, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "OptionsToRemove", valid_604780
  var valid_604781 = query.getOrDefault("Action")
  valid_604781 = validateParameter(valid_604781, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604781 != nil:
    section.add "Action", valid_604781
  var valid_604782 = query.getOrDefault("Version")
  valid_604782 = validateParameter(valid_604782, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604782 != nil:
    section.add "Version", valid_604782
  var valid_604783 = query.getOrDefault("ApplyImmediately")
  valid_604783 = validateParameter(valid_604783, JBool, required = false, default = nil)
  if valid_604783 != nil:
    section.add "ApplyImmediately", valid_604783
  var valid_604784 = query.getOrDefault("OptionsToInclude")
  valid_604784 = validateParameter(valid_604784, JArray, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "OptionsToInclude", valid_604784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604785 = header.getOrDefault("X-Amz-Date")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-Date", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-Security-Token")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Security-Token", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Content-Sha256", valid_604787
  var valid_604788 = header.getOrDefault("X-Amz-Algorithm")
  valid_604788 = validateParameter(valid_604788, JString, required = false,
                                 default = nil)
  if valid_604788 != nil:
    section.add "X-Amz-Algorithm", valid_604788
  var valid_604789 = header.getOrDefault("X-Amz-Signature")
  valid_604789 = validateParameter(valid_604789, JString, required = false,
                                 default = nil)
  if valid_604789 != nil:
    section.add "X-Amz-Signature", valid_604789
  var valid_604790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604790 = validateParameter(valid_604790, JString, required = false,
                                 default = nil)
  if valid_604790 != nil:
    section.add "X-Amz-SignedHeaders", valid_604790
  var valid_604791 = header.getOrDefault("X-Amz-Credential")
  valid_604791 = validateParameter(valid_604791, JString, required = false,
                                 default = nil)
  if valid_604791 != nil:
    section.add "X-Amz-Credential", valid_604791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604792: Call_GetModifyOptionGroup_604776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604792.validator(path, query, header, formData, body)
  let scheme = call_604792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604792.url(scheme.get, call_604792.host, call_604792.base,
                         call_604792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604792, url, valid)

proc call*(call_604793: Call_GetModifyOptionGroup_604776; OptionGroupName: string;
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
  var query_604794 = newJObject()
  add(query_604794, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604794.add "OptionsToRemove", OptionsToRemove
  add(query_604794, "Action", newJString(Action))
  add(query_604794, "Version", newJString(Version))
  add(query_604794, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604794.add "OptionsToInclude", OptionsToInclude
  result = call_604793.call(nil, query_604794, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604776(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604777, base: "/",
    url: url_GetModifyOptionGroup_604778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604833 = ref object of OpenApiRestCall_602450
proc url_PostPromoteReadReplica_604835(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_604834(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604836 = query.getOrDefault("Action")
  valid_604836 = validateParameter(valid_604836, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604836 != nil:
    section.add "Action", valid_604836
  var valid_604837 = query.getOrDefault("Version")
  valid_604837 = validateParameter(valid_604837, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604837 != nil:
    section.add "Version", valid_604837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604838 = header.getOrDefault("X-Amz-Date")
  valid_604838 = validateParameter(valid_604838, JString, required = false,
                                 default = nil)
  if valid_604838 != nil:
    section.add "X-Amz-Date", valid_604838
  var valid_604839 = header.getOrDefault("X-Amz-Security-Token")
  valid_604839 = validateParameter(valid_604839, JString, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "X-Amz-Security-Token", valid_604839
  var valid_604840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Content-Sha256", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Algorithm")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Algorithm", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-Signature")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Signature", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-SignedHeaders", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Credential")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Credential", valid_604844
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604845 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604845 = validateParameter(valid_604845, JString, required = true,
                                 default = nil)
  if valid_604845 != nil:
    section.add "DBInstanceIdentifier", valid_604845
  var valid_604846 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604846 = validateParameter(valid_604846, JInt, required = false, default = nil)
  if valid_604846 != nil:
    section.add "BackupRetentionPeriod", valid_604846
  var valid_604847 = formData.getOrDefault("PreferredBackupWindow")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "PreferredBackupWindow", valid_604847
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604848: Call_PostPromoteReadReplica_604833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604848.validator(path, query, header, formData, body)
  let scheme = call_604848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604848.url(scheme.get, call_604848.host, call_604848.base,
                         call_604848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604848, url, valid)

proc call*(call_604849: Call_PostPromoteReadReplica_604833;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604850 = newJObject()
  var formData_604851 = newJObject()
  add(formData_604851, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604851, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604850, "Action", newJString(Action))
  add(formData_604851, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604850, "Version", newJString(Version))
  result = call_604849.call(nil, query_604850, nil, formData_604851, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604833(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604834, base: "/",
    url: url_PostPromoteReadReplica_604835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604815 = ref object of OpenApiRestCall_602450
proc url_GetPromoteReadReplica_604817(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_604816(path: JsonNode; query: JsonNode;
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
  var valid_604818 = query.getOrDefault("BackupRetentionPeriod")
  valid_604818 = validateParameter(valid_604818, JInt, required = false, default = nil)
  if valid_604818 != nil:
    section.add "BackupRetentionPeriod", valid_604818
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604819 = query.getOrDefault("Action")
  valid_604819 = validateParameter(valid_604819, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604819 != nil:
    section.add "Action", valid_604819
  var valid_604820 = query.getOrDefault("PreferredBackupWindow")
  valid_604820 = validateParameter(valid_604820, JString, required = false,
                                 default = nil)
  if valid_604820 != nil:
    section.add "PreferredBackupWindow", valid_604820
  var valid_604821 = query.getOrDefault("Version")
  valid_604821 = validateParameter(valid_604821, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604821 != nil:
    section.add "Version", valid_604821
  var valid_604822 = query.getOrDefault("DBInstanceIdentifier")
  valid_604822 = validateParameter(valid_604822, JString, required = true,
                                 default = nil)
  if valid_604822 != nil:
    section.add "DBInstanceIdentifier", valid_604822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604823 = header.getOrDefault("X-Amz-Date")
  valid_604823 = validateParameter(valid_604823, JString, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "X-Amz-Date", valid_604823
  var valid_604824 = header.getOrDefault("X-Amz-Security-Token")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-Security-Token", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Content-Sha256", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Algorithm")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Algorithm", valid_604826
  var valid_604827 = header.getOrDefault("X-Amz-Signature")
  valid_604827 = validateParameter(valid_604827, JString, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "X-Amz-Signature", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-SignedHeaders", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Credential")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Credential", valid_604829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604830: Call_GetPromoteReadReplica_604815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604830.validator(path, query, header, formData, body)
  let scheme = call_604830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604830.url(scheme.get, call_604830.host, call_604830.base,
                         call_604830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604830, url, valid)

proc call*(call_604831: Call_GetPromoteReadReplica_604815;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604832 = newJObject()
  add(query_604832, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604832, "Action", newJString(Action))
  add(query_604832, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604832, "Version", newJString(Version))
  add(query_604832, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604831.call(nil, query_604832, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604815(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604816, base: "/",
    url: url_GetPromoteReadReplica_604817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604871 = ref object of OpenApiRestCall_602450
proc url_PostPurchaseReservedDBInstancesOffering_604873(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604872(path: JsonNode;
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
  var valid_604874 = query.getOrDefault("Action")
  valid_604874 = validateParameter(valid_604874, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604874 != nil:
    section.add "Action", valid_604874
  var valid_604875 = query.getOrDefault("Version")
  valid_604875 = validateParameter(valid_604875, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604875 != nil:
    section.add "Version", valid_604875
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604876 = header.getOrDefault("X-Amz-Date")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-Date", valid_604876
  var valid_604877 = header.getOrDefault("X-Amz-Security-Token")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-Security-Token", valid_604877
  var valid_604878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604878 = validateParameter(valid_604878, JString, required = false,
                                 default = nil)
  if valid_604878 != nil:
    section.add "X-Amz-Content-Sha256", valid_604878
  var valid_604879 = header.getOrDefault("X-Amz-Algorithm")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "X-Amz-Algorithm", valid_604879
  var valid_604880 = header.getOrDefault("X-Amz-Signature")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-Signature", valid_604880
  var valid_604881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-SignedHeaders", valid_604881
  var valid_604882 = header.getOrDefault("X-Amz-Credential")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-Credential", valid_604882
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604883 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "ReservedDBInstanceId", valid_604883
  var valid_604884 = formData.getOrDefault("Tags")
  valid_604884 = validateParameter(valid_604884, JArray, required = false,
                                 default = nil)
  if valid_604884 != nil:
    section.add "Tags", valid_604884
  var valid_604885 = formData.getOrDefault("DBInstanceCount")
  valid_604885 = validateParameter(valid_604885, JInt, required = false, default = nil)
  if valid_604885 != nil:
    section.add "DBInstanceCount", valid_604885
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604886 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604886 = validateParameter(valid_604886, JString, required = true,
                                 default = nil)
  if valid_604886 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604887: Call_PostPurchaseReservedDBInstancesOffering_604871;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604887.validator(path, query, header, formData, body)
  let scheme = call_604887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604887.url(scheme.get, call_604887.host, call_604887.base,
                         call_604887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604887, url, valid)

proc call*(call_604888: Call_PostPurchaseReservedDBInstancesOffering_604871;
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
  var query_604889 = newJObject()
  var formData_604890 = newJObject()
  add(formData_604890, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_604890.add "Tags", Tags
  add(formData_604890, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604889, "Action", newJString(Action))
  add(formData_604890, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604889, "Version", newJString(Version))
  result = call_604888.call(nil, query_604889, nil, formData_604890, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604871(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604872, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604852 = ref object of OpenApiRestCall_602450
proc url_GetPurchaseReservedDBInstancesOffering_604854(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604853(path: JsonNode;
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
  var valid_604855 = query.getOrDefault("DBInstanceCount")
  valid_604855 = validateParameter(valid_604855, JInt, required = false, default = nil)
  if valid_604855 != nil:
    section.add "DBInstanceCount", valid_604855
  var valid_604856 = query.getOrDefault("Tags")
  valid_604856 = validateParameter(valid_604856, JArray, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "Tags", valid_604856
  var valid_604857 = query.getOrDefault("ReservedDBInstanceId")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "ReservedDBInstanceId", valid_604857
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604858 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604858 = validateParameter(valid_604858, JString, required = true,
                                 default = nil)
  if valid_604858 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604858
  var valid_604859 = query.getOrDefault("Action")
  valid_604859 = validateParameter(valid_604859, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604859 != nil:
    section.add "Action", valid_604859
  var valid_604860 = query.getOrDefault("Version")
  valid_604860 = validateParameter(valid_604860, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604860 != nil:
    section.add "Version", valid_604860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604861 = header.getOrDefault("X-Amz-Date")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Date", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-Security-Token")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-Security-Token", valid_604862
  var valid_604863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "X-Amz-Content-Sha256", valid_604863
  var valid_604864 = header.getOrDefault("X-Amz-Algorithm")
  valid_604864 = validateParameter(valid_604864, JString, required = false,
                                 default = nil)
  if valid_604864 != nil:
    section.add "X-Amz-Algorithm", valid_604864
  var valid_604865 = header.getOrDefault("X-Amz-Signature")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Signature", valid_604865
  var valid_604866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604866 = validateParameter(valid_604866, JString, required = false,
                                 default = nil)
  if valid_604866 != nil:
    section.add "X-Amz-SignedHeaders", valid_604866
  var valid_604867 = header.getOrDefault("X-Amz-Credential")
  valid_604867 = validateParameter(valid_604867, JString, required = false,
                                 default = nil)
  if valid_604867 != nil:
    section.add "X-Amz-Credential", valid_604867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604868: Call_GetPurchaseReservedDBInstancesOffering_604852;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604868.validator(path, query, header, formData, body)
  let scheme = call_604868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604868.url(scheme.get, call_604868.host, call_604868.base,
                         call_604868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604868, url, valid)

proc call*(call_604869: Call_GetPurchaseReservedDBInstancesOffering_604852;
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
  var query_604870 = newJObject()
  add(query_604870, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_604870.add "Tags", Tags
  add(query_604870, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604870, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604870, "Action", newJString(Action))
  add(query_604870, "Version", newJString(Version))
  result = call_604869.call(nil, query_604870, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604852(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604853, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604908 = ref object of OpenApiRestCall_602450
proc url_PostRebootDBInstance_604910(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_604909(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604911 = query.getOrDefault("Action")
  valid_604911 = validateParameter(valid_604911, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604911 != nil:
    section.add "Action", valid_604911
  var valid_604912 = query.getOrDefault("Version")
  valid_604912 = validateParameter(valid_604912, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604920 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604920 = validateParameter(valid_604920, JString, required = true,
                                 default = nil)
  if valid_604920 != nil:
    section.add "DBInstanceIdentifier", valid_604920
  var valid_604921 = formData.getOrDefault("ForceFailover")
  valid_604921 = validateParameter(valid_604921, JBool, required = false, default = nil)
  if valid_604921 != nil:
    section.add "ForceFailover", valid_604921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604922: Call_PostRebootDBInstance_604908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604922.validator(path, query, header, formData, body)
  let scheme = call_604922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604922.url(scheme.get, call_604922.host, call_604922.base,
                         call_604922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604922, url, valid)

proc call*(call_604923: Call_PostRebootDBInstance_604908;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604924 = newJObject()
  var formData_604925 = newJObject()
  add(formData_604925, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604924, "Action", newJString(Action))
  add(formData_604925, "ForceFailover", newJBool(ForceFailover))
  add(query_604924, "Version", newJString(Version))
  result = call_604923.call(nil, query_604924, nil, formData_604925, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604908(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604909, base: "/",
    url: url_PostRebootDBInstance_604910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604891 = ref object of OpenApiRestCall_602450
proc url_GetRebootDBInstance_604893(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_604892(path: JsonNode; query: JsonNode;
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
  var valid_604894 = query.getOrDefault("Action")
  valid_604894 = validateParameter(valid_604894, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604894 != nil:
    section.add "Action", valid_604894
  var valid_604895 = query.getOrDefault("ForceFailover")
  valid_604895 = validateParameter(valid_604895, JBool, required = false, default = nil)
  if valid_604895 != nil:
    section.add "ForceFailover", valid_604895
  var valid_604896 = query.getOrDefault("Version")
  valid_604896 = validateParameter(valid_604896, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604896 != nil:
    section.add "Version", valid_604896
  var valid_604897 = query.getOrDefault("DBInstanceIdentifier")
  valid_604897 = validateParameter(valid_604897, JString, required = true,
                                 default = nil)
  if valid_604897 != nil:
    section.add "DBInstanceIdentifier", valid_604897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604898 = header.getOrDefault("X-Amz-Date")
  valid_604898 = validateParameter(valid_604898, JString, required = false,
                                 default = nil)
  if valid_604898 != nil:
    section.add "X-Amz-Date", valid_604898
  var valid_604899 = header.getOrDefault("X-Amz-Security-Token")
  valid_604899 = validateParameter(valid_604899, JString, required = false,
                                 default = nil)
  if valid_604899 != nil:
    section.add "X-Amz-Security-Token", valid_604899
  var valid_604900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Content-Sha256", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-Algorithm")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-Algorithm", valid_604901
  var valid_604902 = header.getOrDefault("X-Amz-Signature")
  valid_604902 = validateParameter(valid_604902, JString, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "X-Amz-Signature", valid_604902
  var valid_604903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-SignedHeaders", valid_604903
  var valid_604904 = header.getOrDefault("X-Amz-Credential")
  valid_604904 = validateParameter(valid_604904, JString, required = false,
                                 default = nil)
  if valid_604904 != nil:
    section.add "X-Amz-Credential", valid_604904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604905: Call_GetRebootDBInstance_604891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604905.validator(path, query, header, formData, body)
  let scheme = call_604905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604905.url(scheme.get, call_604905.host, call_604905.base,
                         call_604905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604905, url, valid)

proc call*(call_604906: Call_GetRebootDBInstance_604891;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604907 = newJObject()
  add(query_604907, "Action", newJString(Action))
  add(query_604907, "ForceFailover", newJBool(ForceFailover))
  add(query_604907, "Version", newJString(Version))
  add(query_604907, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604906.call(nil, query_604907, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604891(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604892, base: "/",
    url: url_GetRebootDBInstance_604893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_604943 = ref object of OpenApiRestCall_602450
proc url_PostRemoveSourceIdentifierFromSubscription_604945(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_604944(path: JsonNode;
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
  var valid_604946 = query.getOrDefault("Action")
  valid_604946 = validateParameter(valid_604946, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604946 != nil:
    section.add "Action", valid_604946
  var valid_604947 = query.getOrDefault("Version")
  valid_604947 = validateParameter(valid_604947, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604947 != nil:
    section.add "Version", valid_604947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604948 = header.getOrDefault("X-Amz-Date")
  valid_604948 = validateParameter(valid_604948, JString, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "X-Amz-Date", valid_604948
  var valid_604949 = header.getOrDefault("X-Amz-Security-Token")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "X-Amz-Security-Token", valid_604949
  var valid_604950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Content-Sha256", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-Algorithm")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-Algorithm", valid_604951
  var valid_604952 = header.getOrDefault("X-Amz-Signature")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "X-Amz-Signature", valid_604952
  var valid_604953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604953 = validateParameter(valid_604953, JString, required = false,
                                 default = nil)
  if valid_604953 != nil:
    section.add "X-Amz-SignedHeaders", valid_604953
  var valid_604954 = header.getOrDefault("X-Amz-Credential")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "X-Amz-Credential", valid_604954
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_604955 = formData.getOrDefault("SourceIdentifier")
  valid_604955 = validateParameter(valid_604955, JString, required = true,
                                 default = nil)
  if valid_604955 != nil:
    section.add "SourceIdentifier", valid_604955
  var valid_604956 = formData.getOrDefault("SubscriptionName")
  valid_604956 = validateParameter(valid_604956, JString, required = true,
                                 default = nil)
  if valid_604956 != nil:
    section.add "SubscriptionName", valid_604956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604957: Call_PostRemoveSourceIdentifierFromSubscription_604943;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604957.validator(path, query, header, formData, body)
  let scheme = call_604957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604957.url(scheme.get, call_604957.host, call_604957.base,
                         call_604957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604957, url, valid)

proc call*(call_604958: Call_PostRemoveSourceIdentifierFromSubscription_604943;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604959 = newJObject()
  var formData_604960 = newJObject()
  add(formData_604960, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_604960, "SubscriptionName", newJString(SubscriptionName))
  add(query_604959, "Action", newJString(Action))
  add(query_604959, "Version", newJString(Version))
  result = call_604958.call(nil, query_604959, nil, formData_604960, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_604943(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_604944,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_604945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604926 = ref object of OpenApiRestCall_602450
proc url_GetRemoveSourceIdentifierFromSubscription_604928(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604927(path: JsonNode;
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
  var valid_604929 = query.getOrDefault("Action")
  valid_604929 = validateParameter(valid_604929, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604929 != nil:
    section.add "Action", valid_604929
  var valid_604930 = query.getOrDefault("SourceIdentifier")
  valid_604930 = validateParameter(valid_604930, JString, required = true,
                                 default = nil)
  if valid_604930 != nil:
    section.add "SourceIdentifier", valid_604930
  var valid_604931 = query.getOrDefault("SubscriptionName")
  valid_604931 = validateParameter(valid_604931, JString, required = true,
                                 default = nil)
  if valid_604931 != nil:
    section.add "SubscriptionName", valid_604931
  var valid_604932 = query.getOrDefault("Version")
  valid_604932 = validateParameter(valid_604932, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604932 != nil:
    section.add "Version", valid_604932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604933 = header.getOrDefault("X-Amz-Date")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Date", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Security-Token")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Security-Token", valid_604934
  var valid_604935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-Content-Sha256", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-Algorithm")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-Algorithm", valid_604936
  var valid_604937 = header.getOrDefault("X-Amz-Signature")
  valid_604937 = validateParameter(valid_604937, JString, required = false,
                                 default = nil)
  if valid_604937 != nil:
    section.add "X-Amz-Signature", valid_604937
  var valid_604938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604938 = validateParameter(valid_604938, JString, required = false,
                                 default = nil)
  if valid_604938 != nil:
    section.add "X-Amz-SignedHeaders", valid_604938
  var valid_604939 = header.getOrDefault("X-Amz-Credential")
  valid_604939 = validateParameter(valid_604939, JString, required = false,
                                 default = nil)
  if valid_604939 != nil:
    section.add "X-Amz-Credential", valid_604939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604940: Call_GetRemoveSourceIdentifierFromSubscription_604926;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604940.validator(path, query, header, formData, body)
  let scheme = call_604940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604940.url(scheme.get, call_604940.host, call_604940.base,
                         call_604940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604940, url, valid)

proc call*(call_604941: Call_GetRemoveSourceIdentifierFromSubscription_604926;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_604942 = newJObject()
  add(query_604942, "Action", newJString(Action))
  add(query_604942, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604942, "SubscriptionName", newJString(SubscriptionName))
  add(query_604942, "Version", newJString(Version))
  result = call_604941.call(nil, query_604942, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604926(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604927,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604978 = ref object of OpenApiRestCall_602450
proc url_PostRemoveTagsFromResource_604980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_604979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604981 = query.getOrDefault("Action")
  valid_604981 = validateParameter(valid_604981, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604981 != nil:
    section.add "Action", valid_604981
  var valid_604982 = query.getOrDefault("Version")
  valid_604982 = validateParameter(valid_604982, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604982 != nil:
    section.add "Version", valid_604982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604983 = header.getOrDefault("X-Amz-Date")
  valid_604983 = validateParameter(valid_604983, JString, required = false,
                                 default = nil)
  if valid_604983 != nil:
    section.add "X-Amz-Date", valid_604983
  var valid_604984 = header.getOrDefault("X-Amz-Security-Token")
  valid_604984 = validateParameter(valid_604984, JString, required = false,
                                 default = nil)
  if valid_604984 != nil:
    section.add "X-Amz-Security-Token", valid_604984
  var valid_604985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604985 = validateParameter(valid_604985, JString, required = false,
                                 default = nil)
  if valid_604985 != nil:
    section.add "X-Amz-Content-Sha256", valid_604985
  var valid_604986 = header.getOrDefault("X-Amz-Algorithm")
  valid_604986 = validateParameter(valid_604986, JString, required = false,
                                 default = nil)
  if valid_604986 != nil:
    section.add "X-Amz-Algorithm", valid_604986
  var valid_604987 = header.getOrDefault("X-Amz-Signature")
  valid_604987 = validateParameter(valid_604987, JString, required = false,
                                 default = nil)
  if valid_604987 != nil:
    section.add "X-Amz-Signature", valid_604987
  var valid_604988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604988 = validateParameter(valid_604988, JString, required = false,
                                 default = nil)
  if valid_604988 != nil:
    section.add "X-Amz-SignedHeaders", valid_604988
  var valid_604989 = header.getOrDefault("X-Amz-Credential")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "X-Amz-Credential", valid_604989
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604990 = formData.getOrDefault("TagKeys")
  valid_604990 = validateParameter(valid_604990, JArray, required = true, default = nil)
  if valid_604990 != nil:
    section.add "TagKeys", valid_604990
  var valid_604991 = formData.getOrDefault("ResourceName")
  valid_604991 = validateParameter(valid_604991, JString, required = true,
                                 default = nil)
  if valid_604991 != nil:
    section.add "ResourceName", valid_604991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604992: Call_PostRemoveTagsFromResource_604978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604992.validator(path, query, header, formData, body)
  let scheme = call_604992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604992.url(scheme.get, call_604992.host, call_604992.base,
                         call_604992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604992, url, valid)

proc call*(call_604993: Call_PostRemoveTagsFromResource_604978; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604994 = newJObject()
  var formData_604995 = newJObject()
  add(query_604994, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604995.add "TagKeys", TagKeys
  add(formData_604995, "ResourceName", newJString(ResourceName))
  add(query_604994, "Version", newJString(Version))
  result = call_604993.call(nil, query_604994, nil, formData_604995, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604978(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604979, base: "/",
    url: url_PostRemoveTagsFromResource_604980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604961 = ref object of OpenApiRestCall_602450
proc url_GetRemoveTagsFromResource_604963(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_604962(path: JsonNode; query: JsonNode;
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
  var valid_604964 = query.getOrDefault("ResourceName")
  valid_604964 = validateParameter(valid_604964, JString, required = true,
                                 default = nil)
  if valid_604964 != nil:
    section.add "ResourceName", valid_604964
  var valid_604965 = query.getOrDefault("Action")
  valid_604965 = validateParameter(valid_604965, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604965 != nil:
    section.add "Action", valid_604965
  var valid_604966 = query.getOrDefault("TagKeys")
  valid_604966 = validateParameter(valid_604966, JArray, required = true, default = nil)
  if valid_604966 != nil:
    section.add "TagKeys", valid_604966
  var valid_604967 = query.getOrDefault("Version")
  valid_604967 = validateParameter(valid_604967, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604975: Call_GetRemoveTagsFromResource_604961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604975.validator(path, query, header, formData, body)
  let scheme = call_604975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604975.url(scheme.get, call_604975.host, call_604975.base,
                         call_604975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604975, url, valid)

proc call*(call_604976: Call_GetRemoveTagsFromResource_604961;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_604977 = newJObject()
  add(query_604977, "ResourceName", newJString(ResourceName))
  add(query_604977, "Action", newJString(Action))
  if TagKeys != nil:
    query_604977.add "TagKeys", TagKeys
  add(query_604977, "Version", newJString(Version))
  result = call_604976.call(nil, query_604977, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604961(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604962, base: "/",
    url: url_GetRemoveTagsFromResource_604963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_605014 = ref object of OpenApiRestCall_602450
proc url_PostResetDBParameterGroup_605016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_605015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605017 = query.getOrDefault("Action")
  valid_605017 = validateParameter(valid_605017, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605017 != nil:
    section.add "Action", valid_605017
  var valid_605018 = query.getOrDefault("Version")
  valid_605018 = validateParameter(valid_605018, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605018 != nil:
    section.add "Version", valid_605018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605019 = header.getOrDefault("X-Amz-Date")
  valid_605019 = validateParameter(valid_605019, JString, required = false,
                                 default = nil)
  if valid_605019 != nil:
    section.add "X-Amz-Date", valid_605019
  var valid_605020 = header.getOrDefault("X-Amz-Security-Token")
  valid_605020 = validateParameter(valid_605020, JString, required = false,
                                 default = nil)
  if valid_605020 != nil:
    section.add "X-Amz-Security-Token", valid_605020
  var valid_605021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "X-Amz-Content-Sha256", valid_605021
  var valid_605022 = header.getOrDefault("X-Amz-Algorithm")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "X-Amz-Algorithm", valid_605022
  var valid_605023 = header.getOrDefault("X-Amz-Signature")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Signature", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-SignedHeaders", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-Credential")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Credential", valid_605025
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_605026 = formData.getOrDefault("DBParameterGroupName")
  valid_605026 = validateParameter(valid_605026, JString, required = true,
                                 default = nil)
  if valid_605026 != nil:
    section.add "DBParameterGroupName", valid_605026
  var valid_605027 = formData.getOrDefault("Parameters")
  valid_605027 = validateParameter(valid_605027, JArray, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "Parameters", valid_605027
  var valid_605028 = formData.getOrDefault("ResetAllParameters")
  valid_605028 = validateParameter(valid_605028, JBool, required = false, default = nil)
  if valid_605028 != nil:
    section.add "ResetAllParameters", valid_605028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605029: Call_PostResetDBParameterGroup_605014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605029.validator(path, query, header, formData, body)
  let scheme = call_605029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605029.url(scheme.get, call_605029.host, call_605029.base,
                         call_605029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605029, url, valid)

proc call*(call_605030: Call_PostResetDBParameterGroup_605014;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605031 = newJObject()
  var formData_605032 = newJObject()
  add(formData_605032, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_605032.add "Parameters", Parameters
  add(query_605031, "Action", newJString(Action))
  add(formData_605032, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605031, "Version", newJString(Version))
  result = call_605030.call(nil, query_605031, nil, formData_605032, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_605014(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_605015, base: "/",
    url: url_PostResetDBParameterGroup_605016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604996 = ref object of OpenApiRestCall_602450
proc url_GetResetDBParameterGroup_604998(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_604997(path: JsonNode; query: JsonNode;
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
  var valid_604999 = query.getOrDefault("DBParameterGroupName")
  valid_604999 = validateParameter(valid_604999, JString, required = true,
                                 default = nil)
  if valid_604999 != nil:
    section.add "DBParameterGroupName", valid_604999
  var valid_605000 = query.getOrDefault("Parameters")
  valid_605000 = validateParameter(valid_605000, JArray, required = false,
                                 default = nil)
  if valid_605000 != nil:
    section.add "Parameters", valid_605000
  var valid_605001 = query.getOrDefault("Action")
  valid_605001 = validateParameter(valid_605001, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605001 != nil:
    section.add "Action", valid_605001
  var valid_605002 = query.getOrDefault("ResetAllParameters")
  valid_605002 = validateParameter(valid_605002, JBool, required = false, default = nil)
  if valid_605002 != nil:
    section.add "ResetAllParameters", valid_605002
  var valid_605003 = query.getOrDefault("Version")
  valid_605003 = validateParameter(valid_605003, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605003 != nil:
    section.add "Version", valid_605003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605004 = header.getOrDefault("X-Amz-Date")
  valid_605004 = validateParameter(valid_605004, JString, required = false,
                                 default = nil)
  if valid_605004 != nil:
    section.add "X-Amz-Date", valid_605004
  var valid_605005 = header.getOrDefault("X-Amz-Security-Token")
  valid_605005 = validateParameter(valid_605005, JString, required = false,
                                 default = nil)
  if valid_605005 != nil:
    section.add "X-Amz-Security-Token", valid_605005
  var valid_605006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605006 = validateParameter(valid_605006, JString, required = false,
                                 default = nil)
  if valid_605006 != nil:
    section.add "X-Amz-Content-Sha256", valid_605006
  var valid_605007 = header.getOrDefault("X-Amz-Algorithm")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "X-Amz-Algorithm", valid_605007
  var valid_605008 = header.getOrDefault("X-Amz-Signature")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "X-Amz-Signature", valid_605008
  var valid_605009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-SignedHeaders", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-Credential")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-Credential", valid_605010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605011: Call_GetResetDBParameterGroup_604996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605011.validator(path, query, header, formData, body)
  let scheme = call_605011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605011.url(scheme.get, call_605011.host, call_605011.base,
                         call_605011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605011, url, valid)

proc call*(call_605012: Call_GetResetDBParameterGroup_604996;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605013 = newJObject()
  add(query_605013, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_605013.add "Parameters", Parameters
  add(query_605013, "Action", newJString(Action))
  add(query_605013, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605013, "Version", newJString(Version))
  result = call_605012.call(nil, query_605013, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604996(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604997, base: "/",
    url: url_GetResetDBParameterGroup_604998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_605063 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceFromDBSnapshot_605065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_605064(path: JsonNode;
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
  var valid_605066 = query.getOrDefault("Action")
  valid_605066 = validateParameter(valid_605066, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605066 != nil:
    section.add "Action", valid_605066
  var valid_605067 = query.getOrDefault("Version")
  valid_605067 = validateParameter(valid_605067, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605067 != nil:
    section.add "Version", valid_605067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605068 = header.getOrDefault("X-Amz-Date")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "X-Amz-Date", valid_605068
  var valid_605069 = header.getOrDefault("X-Amz-Security-Token")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "X-Amz-Security-Token", valid_605069
  var valid_605070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605070 = validateParameter(valid_605070, JString, required = false,
                                 default = nil)
  if valid_605070 != nil:
    section.add "X-Amz-Content-Sha256", valid_605070
  var valid_605071 = header.getOrDefault("X-Amz-Algorithm")
  valid_605071 = validateParameter(valid_605071, JString, required = false,
                                 default = nil)
  if valid_605071 != nil:
    section.add "X-Amz-Algorithm", valid_605071
  var valid_605072 = header.getOrDefault("X-Amz-Signature")
  valid_605072 = validateParameter(valid_605072, JString, required = false,
                                 default = nil)
  if valid_605072 != nil:
    section.add "X-Amz-Signature", valid_605072
  var valid_605073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605073 = validateParameter(valid_605073, JString, required = false,
                                 default = nil)
  if valid_605073 != nil:
    section.add "X-Amz-SignedHeaders", valid_605073
  var valid_605074 = header.getOrDefault("X-Amz-Credential")
  valid_605074 = validateParameter(valid_605074, JString, required = false,
                                 default = nil)
  if valid_605074 != nil:
    section.add "X-Amz-Credential", valid_605074
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
  var valid_605075 = formData.getOrDefault("Port")
  valid_605075 = validateParameter(valid_605075, JInt, required = false, default = nil)
  if valid_605075 != nil:
    section.add "Port", valid_605075
  var valid_605076 = formData.getOrDefault("Engine")
  valid_605076 = validateParameter(valid_605076, JString, required = false,
                                 default = nil)
  if valid_605076 != nil:
    section.add "Engine", valid_605076
  var valid_605077 = formData.getOrDefault("Iops")
  valid_605077 = validateParameter(valid_605077, JInt, required = false, default = nil)
  if valid_605077 != nil:
    section.add "Iops", valid_605077
  var valid_605078 = formData.getOrDefault("DBName")
  valid_605078 = validateParameter(valid_605078, JString, required = false,
                                 default = nil)
  if valid_605078 != nil:
    section.add "DBName", valid_605078
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605079 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605079 = validateParameter(valid_605079, JString, required = true,
                                 default = nil)
  if valid_605079 != nil:
    section.add "DBInstanceIdentifier", valid_605079
  var valid_605080 = formData.getOrDefault("OptionGroupName")
  valid_605080 = validateParameter(valid_605080, JString, required = false,
                                 default = nil)
  if valid_605080 != nil:
    section.add "OptionGroupName", valid_605080
  var valid_605081 = formData.getOrDefault("Tags")
  valid_605081 = validateParameter(valid_605081, JArray, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "Tags", valid_605081
  var valid_605082 = formData.getOrDefault("DBSubnetGroupName")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "DBSubnetGroupName", valid_605082
  var valid_605083 = formData.getOrDefault("AvailabilityZone")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "AvailabilityZone", valid_605083
  var valid_605084 = formData.getOrDefault("MultiAZ")
  valid_605084 = validateParameter(valid_605084, JBool, required = false, default = nil)
  if valid_605084 != nil:
    section.add "MultiAZ", valid_605084
  var valid_605085 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_605085 = validateParameter(valid_605085, JString, required = true,
                                 default = nil)
  if valid_605085 != nil:
    section.add "DBSnapshotIdentifier", valid_605085
  var valid_605086 = formData.getOrDefault("PubliclyAccessible")
  valid_605086 = validateParameter(valid_605086, JBool, required = false, default = nil)
  if valid_605086 != nil:
    section.add "PubliclyAccessible", valid_605086
  var valid_605087 = formData.getOrDefault("DBInstanceClass")
  valid_605087 = validateParameter(valid_605087, JString, required = false,
                                 default = nil)
  if valid_605087 != nil:
    section.add "DBInstanceClass", valid_605087
  var valid_605088 = formData.getOrDefault("LicenseModel")
  valid_605088 = validateParameter(valid_605088, JString, required = false,
                                 default = nil)
  if valid_605088 != nil:
    section.add "LicenseModel", valid_605088
  var valid_605089 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605089 = validateParameter(valid_605089, JBool, required = false, default = nil)
  if valid_605089 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605090: Call_PostRestoreDBInstanceFromDBSnapshot_605063;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605090.validator(path, query, header, formData, body)
  let scheme = call_605090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605090.url(scheme.get, call_605090.host, call_605090.base,
                         call_605090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605090, url, valid)

proc call*(call_605091: Call_PostRestoreDBInstanceFromDBSnapshot_605063;
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
  var query_605092 = newJObject()
  var formData_605093 = newJObject()
  add(formData_605093, "Port", newJInt(Port))
  add(formData_605093, "Engine", newJString(Engine))
  add(formData_605093, "Iops", newJInt(Iops))
  add(formData_605093, "DBName", newJString(DBName))
  add(formData_605093, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605093, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605093.add "Tags", Tags
  add(formData_605093, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605093, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605093, "MultiAZ", newJBool(MultiAZ))
  add(formData_605093, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_605092, "Action", newJString(Action))
  add(formData_605093, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605093, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605093, "LicenseModel", newJString(LicenseModel))
  add(formData_605093, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605092, "Version", newJString(Version))
  result = call_605091.call(nil, query_605092, nil, formData_605093, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_605063(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_605064, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_605065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_605033 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceFromDBSnapshot_605035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_605034(path: JsonNode;
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
  var valid_605036 = query.getOrDefault("Engine")
  valid_605036 = validateParameter(valid_605036, JString, required = false,
                                 default = nil)
  if valid_605036 != nil:
    section.add "Engine", valid_605036
  var valid_605037 = query.getOrDefault("OptionGroupName")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "OptionGroupName", valid_605037
  var valid_605038 = query.getOrDefault("AvailabilityZone")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "AvailabilityZone", valid_605038
  var valid_605039 = query.getOrDefault("Iops")
  valid_605039 = validateParameter(valid_605039, JInt, required = false, default = nil)
  if valid_605039 != nil:
    section.add "Iops", valid_605039
  var valid_605040 = query.getOrDefault("MultiAZ")
  valid_605040 = validateParameter(valid_605040, JBool, required = false, default = nil)
  if valid_605040 != nil:
    section.add "MultiAZ", valid_605040
  var valid_605041 = query.getOrDefault("LicenseModel")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "LicenseModel", valid_605041
  var valid_605042 = query.getOrDefault("Tags")
  valid_605042 = validateParameter(valid_605042, JArray, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "Tags", valid_605042
  var valid_605043 = query.getOrDefault("DBName")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "DBName", valid_605043
  var valid_605044 = query.getOrDefault("DBInstanceClass")
  valid_605044 = validateParameter(valid_605044, JString, required = false,
                                 default = nil)
  if valid_605044 != nil:
    section.add "DBInstanceClass", valid_605044
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605045 = query.getOrDefault("Action")
  valid_605045 = validateParameter(valid_605045, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605045 != nil:
    section.add "Action", valid_605045
  var valid_605046 = query.getOrDefault("DBSubnetGroupName")
  valid_605046 = validateParameter(valid_605046, JString, required = false,
                                 default = nil)
  if valid_605046 != nil:
    section.add "DBSubnetGroupName", valid_605046
  var valid_605047 = query.getOrDefault("PubliclyAccessible")
  valid_605047 = validateParameter(valid_605047, JBool, required = false, default = nil)
  if valid_605047 != nil:
    section.add "PubliclyAccessible", valid_605047
  var valid_605048 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605048 = validateParameter(valid_605048, JBool, required = false, default = nil)
  if valid_605048 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605048
  var valid_605049 = query.getOrDefault("Port")
  valid_605049 = validateParameter(valid_605049, JInt, required = false, default = nil)
  if valid_605049 != nil:
    section.add "Port", valid_605049
  var valid_605050 = query.getOrDefault("Version")
  valid_605050 = validateParameter(valid_605050, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605050 != nil:
    section.add "Version", valid_605050
  var valid_605051 = query.getOrDefault("DBInstanceIdentifier")
  valid_605051 = validateParameter(valid_605051, JString, required = true,
                                 default = nil)
  if valid_605051 != nil:
    section.add "DBInstanceIdentifier", valid_605051
  var valid_605052 = query.getOrDefault("DBSnapshotIdentifier")
  valid_605052 = validateParameter(valid_605052, JString, required = true,
                                 default = nil)
  if valid_605052 != nil:
    section.add "DBSnapshotIdentifier", valid_605052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605053 = header.getOrDefault("X-Amz-Date")
  valid_605053 = validateParameter(valid_605053, JString, required = false,
                                 default = nil)
  if valid_605053 != nil:
    section.add "X-Amz-Date", valid_605053
  var valid_605054 = header.getOrDefault("X-Amz-Security-Token")
  valid_605054 = validateParameter(valid_605054, JString, required = false,
                                 default = nil)
  if valid_605054 != nil:
    section.add "X-Amz-Security-Token", valid_605054
  var valid_605055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "X-Amz-Content-Sha256", valid_605055
  var valid_605056 = header.getOrDefault("X-Amz-Algorithm")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "X-Amz-Algorithm", valid_605056
  var valid_605057 = header.getOrDefault("X-Amz-Signature")
  valid_605057 = validateParameter(valid_605057, JString, required = false,
                                 default = nil)
  if valid_605057 != nil:
    section.add "X-Amz-Signature", valid_605057
  var valid_605058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605058 = validateParameter(valid_605058, JString, required = false,
                                 default = nil)
  if valid_605058 != nil:
    section.add "X-Amz-SignedHeaders", valid_605058
  var valid_605059 = header.getOrDefault("X-Amz-Credential")
  valid_605059 = validateParameter(valid_605059, JString, required = false,
                                 default = nil)
  if valid_605059 != nil:
    section.add "X-Amz-Credential", valid_605059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605060: Call_GetRestoreDBInstanceFromDBSnapshot_605033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605060.validator(path, query, header, formData, body)
  let scheme = call_605060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605060.url(scheme.get, call_605060.host, call_605060.base,
                         call_605060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605060, url, valid)

proc call*(call_605061: Call_GetRestoreDBInstanceFromDBSnapshot_605033;
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
  var query_605062 = newJObject()
  add(query_605062, "Engine", newJString(Engine))
  add(query_605062, "OptionGroupName", newJString(OptionGroupName))
  add(query_605062, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605062, "Iops", newJInt(Iops))
  add(query_605062, "MultiAZ", newJBool(MultiAZ))
  add(query_605062, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605062.add "Tags", Tags
  add(query_605062, "DBName", newJString(DBName))
  add(query_605062, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605062, "Action", newJString(Action))
  add(query_605062, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605062, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605062, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605062, "Port", newJInt(Port))
  add(query_605062, "Version", newJString(Version))
  add(query_605062, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605062, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_605061.call(nil, query_605062, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_605033(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_605034, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_605035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605126 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceToPointInTime_605128(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_605127(path: JsonNode;
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
  var valid_605129 = query.getOrDefault("Action")
  valid_605129 = validateParameter(valid_605129, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605129 != nil:
    section.add "Action", valid_605129
  var valid_605130 = query.getOrDefault("Version")
  valid_605130 = validateParameter(valid_605130, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605130 != nil:
    section.add "Version", valid_605130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605131 = header.getOrDefault("X-Amz-Date")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Date", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Security-Token")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Security-Token", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-Content-Sha256", valid_605133
  var valid_605134 = header.getOrDefault("X-Amz-Algorithm")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "X-Amz-Algorithm", valid_605134
  var valid_605135 = header.getOrDefault("X-Amz-Signature")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "X-Amz-Signature", valid_605135
  var valid_605136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605136 = validateParameter(valid_605136, JString, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "X-Amz-SignedHeaders", valid_605136
  var valid_605137 = header.getOrDefault("X-Amz-Credential")
  valid_605137 = validateParameter(valid_605137, JString, required = false,
                                 default = nil)
  if valid_605137 != nil:
    section.add "X-Amz-Credential", valid_605137
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
  var valid_605138 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605138 = validateParameter(valid_605138, JBool, required = false, default = nil)
  if valid_605138 != nil:
    section.add "UseLatestRestorableTime", valid_605138
  var valid_605139 = formData.getOrDefault("Port")
  valid_605139 = validateParameter(valid_605139, JInt, required = false, default = nil)
  if valid_605139 != nil:
    section.add "Port", valid_605139
  var valid_605140 = formData.getOrDefault("Engine")
  valid_605140 = validateParameter(valid_605140, JString, required = false,
                                 default = nil)
  if valid_605140 != nil:
    section.add "Engine", valid_605140
  var valid_605141 = formData.getOrDefault("Iops")
  valid_605141 = validateParameter(valid_605141, JInt, required = false, default = nil)
  if valid_605141 != nil:
    section.add "Iops", valid_605141
  var valid_605142 = formData.getOrDefault("DBName")
  valid_605142 = validateParameter(valid_605142, JString, required = false,
                                 default = nil)
  if valid_605142 != nil:
    section.add "DBName", valid_605142
  var valid_605143 = formData.getOrDefault("OptionGroupName")
  valid_605143 = validateParameter(valid_605143, JString, required = false,
                                 default = nil)
  if valid_605143 != nil:
    section.add "OptionGroupName", valid_605143
  var valid_605144 = formData.getOrDefault("Tags")
  valid_605144 = validateParameter(valid_605144, JArray, required = false,
                                 default = nil)
  if valid_605144 != nil:
    section.add "Tags", valid_605144
  var valid_605145 = formData.getOrDefault("DBSubnetGroupName")
  valid_605145 = validateParameter(valid_605145, JString, required = false,
                                 default = nil)
  if valid_605145 != nil:
    section.add "DBSubnetGroupName", valid_605145
  var valid_605146 = formData.getOrDefault("AvailabilityZone")
  valid_605146 = validateParameter(valid_605146, JString, required = false,
                                 default = nil)
  if valid_605146 != nil:
    section.add "AvailabilityZone", valid_605146
  var valid_605147 = formData.getOrDefault("MultiAZ")
  valid_605147 = validateParameter(valid_605147, JBool, required = false, default = nil)
  if valid_605147 != nil:
    section.add "MultiAZ", valid_605147
  var valid_605148 = formData.getOrDefault("RestoreTime")
  valid_605148 = validateParameter(valid_605148, JString, required = false,
                                 default = nil)
  if valid_605148 != nil:
    section.add "RestoreTime", valid_605148
  var valid_605149 = formData.getOrDefault("PubliclyAccessible")
  valid_605149 = validateParameter(valid_605149, JBool, required = false, default = nil)
  if valid_605149 != nil:
    section.add "PubliclyAccessible", valid_605149
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605150 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605150 = validateParameter(valid_605150, JString, required = true,
                                 default = nil)
  if valid_605150 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605150
  var valid_605151 = formData.getOrDefault("DBInstanceClass")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "DBInstanceClass", valid_605151
  var valid_605152 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605152 = validateParameter(valid_605152, JString, required = true,
                                 default = nil)
  if valid_605152 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605152
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

proc call*(call_605155: Call_PostRestoreDBInstanceToPointInTime_605126;
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

proc call*(call_605156: Call_PostRestoreDBInstanceToPointInTime_605126;
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
  var query_605157 = newJObject()
  var formData_605158 = newJObject()
  add(formData_605158, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605158, "Port", newJInt(Port))
  add(formData_605158, "Engine", newJString(Engine))
  add(formData_605158, "Iops", newJInt(Iops))
  add(formData_605158, "DBName", newJString(DBName))
  add(formData_605158, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605158.add "Tags", Tags
  add(formData_605158, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605158, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605158, "MultiAZ", newJBool(MultiAZ))
  add(query_605157, "Action", newJString(Action))
  add(formData_605158, "RestoreTime", newJString(RestoreTime))
  add(formData_605158, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605158, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605158, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605158, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605158, "LicenseModel", newJString(LicenseModel))
  add(formData_605158, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605157, "Version", newJString(Version))
  result = call_605156.call(nil, query_605157, nil, formData_605158, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605126(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605127, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605094 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceToPointInTime_605096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_605095(path: JsonNode;
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
  var valid_605097 = query.getOrDefault("Engine")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "Engine", valid_605097
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605098 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605098 = validateParameter(valid_605098, JString, required = true,
                                 default = nil)
  if valid_605098 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605098
  var valid_605099 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605099 = validateParameter(valid_605099, JString, required = true,
                                 default = nil)
  if valid_605099 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605099
  var valid_605100 = query.getOrDefault("AvailabilityZone")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "AvailabilityZone", valid_605100
  var valid_605101 = query.getOrDefault("Iops")
  valid_605101 = validateParameter(valid_605101, JInt, required = false, default = nil)
  if valid_605101 != nil:
    section.add "Iops", valid_605101
  var valid_605102 = query.getOrDefault("OptionGroupName")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "OptionGroupName", valid_605102
  var valid_605103 = query.getOrDefault("RestoreTime")
  valid_605103 = validateParameter(valid_605103, JString, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "RestoreTime", valid_605103
  var valid_605104 = query.getOrDefault("MultiAZ")
  valid_605104 = validateParameter(valid_605104, JBool, required = false, default = nil)
  if valid_605104 != nil:
    section.add "MultiAZ", valid_605104
  var valid_605105 = query.getOrDefault("LicenseModel")
  valid_605105 = validateParameter(valid_605105, JString, required = false,
                                 default = nil)
  if valid_605105 != nil:
    section.add "LicenseModel", valid_605105
  var valid_605106 = query.getOrDefault("Tags")
  valid_605106 = validateParameter(valid_605106, JArray, required = false,
                                 default = nil)
  if valid_605106 != nil:
    section.add "Tags", valid_605106
  var valid_605107 = query.getOrDefault("DBName")
  valid_605107 = validateParameter(valid_605107, JString, required = false,
                                 default = nil)
  if valid_605107 != nil:
    section.add "DBName", valid_605107
  var valid_605108 = query.getOrDefault("DBInstanceClass")
  valid_605108 = validateParameter(valid_605108, JString, required = false,
                                 default = nil)
  if valid_605108 != nil:
    section.add "DBInstanceClass", valid_605108
  var valid_605109 = query.getOrDefault("Action")
  valid_605109 = validateParameter(valid_605109, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605109 != nil:
    section.add "Action", valid_605109
  var valid_605110 = query.getOrDefault("UseLatestRestorableTime")
  valid_605110 = validateParameter(valid_605110, JBool, required = false, default = nil)
  if valid_605110 != nil:
    section.add "UseLatestRestorableTime", valid_605110
  var valid_605111 = query.getOrDefault("DBSubnetGroupName")
  valid_605111 = validateParameter(valid_605111, JString, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "DBSubnetGroupName", valid_605111
  var valid_605112 = query.getOrDefault("PubliclyAccessible")
  valid_605112 = validateParameter(valid_605112, JBool, required = false, default = nil)
  if valid_605112 != nil:
    section.add "PubliclyAccessible", valid_605112
  var valid_605113 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605113 = validateParameter(valid_605113, JBool, required = false, default = nil)
  if valid_605113 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605113
  var valid_605114 = query.getOrDefault("Port")
  valid_605114 = validateParameter(valid_605114, JInt, required = false, default = nil)
  if valid_605114 != nil:
    section.add "Port", valid_605114
  var valid_605115 = query.getOrDefault("Version")
  valid_605115 = validateParameter(valid_605115, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605115 != nil:
    section.add "Version", valid_605115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605116 = header.getOrDefault("X-Amz-Date")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Date", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Security-Token")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Security-Token", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-Content-Sha256", valid_605118
  var valid_605119 = header.getOrDefault("X-Amz-Algorithm")
  valid_605119 = validateParameter(valid_605119, JString, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "X-Amz-Algorithm", valid_605119
  var valid_605120 = header.getOrDefault("X-Amz-Signature")
  valid_605120 = validateParameter(valid_605120, JString, required = false,
                                 default = nil)
  if valid_605120 != nil:
    section.add "X-Amz-Signature", valid_605120
  var valid_605121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605121 = validateParameter(valid_605121, JString, required = false,
                                 default = nil)
  if valid_605121 != nil:
    section.add "X-Amz-SignedHeaders", valid_605121
  var valid_605122 = header.getOrDefault("X-Amz-Credential")
  valid_605122 = validateParameter(valid_605122, JString, required = false,
                                 default = nil)
  if valid_605122 != nil:
    section.add "X-Amz-Credential", valid_605122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605123: Call_GetRestoreDBInstanceToPointInTime_605094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605123.validator(path, query, header, formData, body)
  let scheme = call_605123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605123.url(scheme.get, call_605123.host, call_605123.base,
                         call_605123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605123, url, valid)

proc call*(call_605124: Call_GetRestoreDBInstanceToPointInTime_605094;
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
  var query_605125 = newJObject()
  add(query_605125, "Engine", newJString(Engine))
  add(query_605125, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605125, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605125, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605125, "Iops", newJInt(Iops))
  add(query_605125, "OptionGroupName", newJString(OptionGroupName))
  add(query_605125, "RestoreTime", newJString(RestoreTime))
  add(query_605125, "MultiAZ", newJBool(MultiAZ))
  add(query_605125, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605125.add "Tags", Tags
  add(query_605125, "DBName", newJString(DBName))
  add(query_605125, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605125, "Action", newJString(Action))
  add(query_605125, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605125, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605125, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605125, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605125, "Port", newJInt(Port))
  add(query_605125, "Version", newJString(Version))
  result = call_605124.call(nil, query_605125, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605094(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605095, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605179 = ref object of OpenApiRestCall_602450
proc url_PostRevokeDBSecurityGroupIngress_605181(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_605180(path: JsonNode;
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
  var valid_605182 = query.getOrDefault("Action")
  valid_605182 = validateParameter(valid_605182, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605182 != nil:
    section.add "Action", valid_605182
  var valid_605183 = query.getOrDefault("Version")
  valid_605183 = validateParameter(valid_605183, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605191 = formData.getOrDefault("DBSecurityGroupName")
  valid_605191 = validateParameter(valid_605191, JString, required = true,
                                 default = nil)
  if valid_605191 != nil:
    section.add "DBSecurityGroupName", valid_605191
  var valid_605192 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605192 = validateParameter(valid_605192, JString, required = false,
                                 default = nil)
  if valid_605192 != nil:
    section.add "EC2SecurityGroupName", valid_605192
  var valid_605193 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605193 = validateParameter(valid_605193, JString, required = false,
                                 default = nil)
  if valid_605193 != nil:
    section.add "EC2SecurityGroupId", valid_605193
  var valid_605194 = formData.getOrDefault("CIDRIP")
  valid_605194 = validateParameter(valid_605194, JString, required = false,
                                 default = nil)
  if valid_605194 != nil:
    section.add "CIDRIP", valid_605194
  var valid_605195 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605195 = validateParameter(valid_605195, JString, required = false,
                                 default = nil)
  if valid_605195 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605196: Call_PostRevokeDBSecurityGroupIngress_605179;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605196.validator(path, query, header, formData, body)
  let scheme = call_605196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605196.url(scheme.get, call_605196.host, call_605196.base,
                         call_605196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605196, url, valid)

proc call*(call_605197: Call_PostRevokeDBSecurityGroupIngress_605179;
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
  var query_605198 = newJObject()
  var formData_605199 = newJObject()
  add(formData_605199, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605198, "Action", newJString(Action))
  add(formData_605199, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605199, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605199, "CIDRIP", newJString(CIDRIP))
  add(query_605198, "Version", newJString(Version))
  add(formData_605199, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605197.call(nil, query_605198, nil, formData_605199, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605179(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605180, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605159 = ref object of OpenApiRestCall_602450
proc url_GetRevokeDBSecurityGroupIngress_605161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_605160(path: JsonNode;
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
  var valid_605162 = query.getOrDefault("EC2SecurityGroupId")
  valid_605162 = validateParameter(valid_605162, JString, required = false,
                                 default = nil)
  if valid_605162 != nil:
    section.add "EC2SecurityGroupId", valid_605162
  var valid_605163 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605163 = validateParameter(valid_605163, JString, required = false,
                                 default = nil)
  if valid_605163 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605163
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605164 = query.getOrDefault("DBSecurityGroupName")
  valid_605164 = validateParameter(valid_605164, JString, required = true,
                                 default = nil)
  if valid_605164 != nil:
    section.add "DBSecurityGroupName", valid_605164
  var valid_605165 = query.getOrDefault("Action")
  valid_605165 = validateParameter(valid_605165, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605165 != nil:
    section.add "Action", valid_605165
  var valid_605166 = query.getOrDefault("CIDRIP")
  valid_605166 = validateParameter(valid_605166, JString, required = false,
                                 default = nil)
  if valid_605166 != nil:
    section.add "CIDRIP", valid_605166
  var valid_605167 = query.getOrDefault("EC2SecurityGroupName")
  valid_605167 = validateParameter(valid_605167, JString, required = false,
                                 default = nil)
  if valid_605167 != nil:
    section.add "EC2SecurityGroupName", valid_605167
  var valid_605168 = query.getOrDefault("Version")
  valid_605168 = validateParameter(valid_605168, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605168 != nil:
    section.add "Version", valid_605168
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605169 = header.getOrDefault("X-Amz-Date")
  valid_605169 = validateParameter(valid_605169, JString, required = false,
                                 default = nil)
  if valid_605169 != nil:
    section.add "X-Amz-Date", valid_605169
  var valid_605170 = header.getOrDefault("X-Amz-Security-Token")
  valid_605170 = validateParameter(valid_605170, JString, required = false,
                                 default = nil)
  if valid_605170 != nil:
    section.add "X-Amz-Security-Token", valid_605170
  var valid_605171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605171 = validateParameter(valid_605171, JString, required = false,
                                 default = nil)
  if valid_605171 != nil:
    section.add "X-Amz-Content-Sha256", valid_605171
  var valid_605172 = header.getOrDefault("X-Amz-Algorithm")
  valid_605172 = validateParameter(valid_605172, JString, required = false,
                                 default = nil)
  if valid_605172 != nil:
    section.add "X-Amz-Algorithm", valid_605172
  var valid_605173 = header.getOrDefault("X-Amz-Signature")
  valid_605173 = validateParameter(valid_605173, JString, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "X-Amz-Signature", valid_605173
  var valid_605174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605174 = validateParameter(valid_605174, JString, required = false,
                                 default = nil)
  if valid_605174 != nil:
    section.add "X-Amz-SignedHeaders", valid_605174
  var valid_605175 = header.getOrDefault("X-Amz-Credential")
  valid_605175 = validateParameter(valid_605175, JString, required = false,
                                 default = nil)
  if valid_605175 != nil:
    section.add "X-Amz-Credential", valid_605175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605176: Call_GetRevokeDBSecurityGroupIngress_605159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605176.validator(path, query, header, formData, body)
  let scheme = call_605176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605176.url(scheme.get, call_605176.host, call_605176.base,
                         call_605176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605176, url, valid)

proc call*(call_605177: Call_GetRevokeDBSecurityGroupIngress_605159;
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
  var query_605178 = newJObject()
  add(query_605178, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605178, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605178, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605178, "Action", newJString(Action))
  add(query_605178, "CIDRIP", newJString(CIDRIP))
  add(query_605178, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605178, "Version", newJString(Version))
  result = call_605177.call(nil, query_605178, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605159(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605160, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605161,
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

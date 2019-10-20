
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
  Call_PostAddSourceIdentifierToSubscription_592959 = ref object of OpenApiRestCall_592348
proc url_PostAddSourceIdentifierToSubscription_592961(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_592960(path: JsonNode;
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
  var valid_592962 = query.getOrDefault("Action")
  valid_592962 = validateParameter(valid_592962, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_592962 != nil:
    section.add "Action", valid_592962
  var valid_592963 = query.getOrDefault("Version")
  valid_592963 = validateParameter(valid_592963, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_592963 != nil:
    section.add "Version", valid_592963
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592964 = header.getOrDefault("X-Amz-Signature")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Signature", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Content-Sha256", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Date")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Date", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Credential")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Credential", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Security-Token")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Security-Token", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Algorithm")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Algorithm", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-SignedHeaders", valid_592970
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_592971 = formData.getOrDefault("SubscriptionName")
  valid_592971 = validateParameter(valid_592971, JString, required = true,
                                 default = nil)
  if valid_592971 != nil:
    section.add "SubscriptionName", valid_592971
  var valid_592972 = formData.getOrDefault("SourceIdentifier")
  valid_592972 = validateParameter(valid_592972, JString, required = true,
                                 default = nil)
  if valid_592972 != nil:
    section.add "SourceIdentifier", valid_592972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592973: Call_PostAddSourceIdentifierToSubscription_592959;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_592973.validator(path, query, header, formData, body)
  let scheme = call_592973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592973.url(scheme.get, call_592973.host, call_592973.base,
                         call_592973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592973, url, valid)

proc call*(call_592974: Call_PostAddSourceIdentifierToSubscription_592959;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592975 = newJObject()
  var formData_592976 = newJObject()
  add(formData_592976, "SubscriptionName", newJString(SubscriptionName))
  add(formData_592976, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_592975, "Action", newJString(Action))
  add(query_592975, "Version", newJString(Version))
  result = call_592974.call(nil, query_592975, nil, formData_592976, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_592959(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_592960, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_592961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_592687 = ref object of OpenApiRestCall_592348
proc url_GetAddSourceIdentifierToSubscription_592689(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_592688(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_592801 = query.getOrDefault("SourceIdentifier")
  valid_592801 = validateParameter(valid_592801, JString, required = true,
                                 default = nil)
  if valid_592801 != nil:
    section.add "SourceIdentifier", valid_592801
  var valid_592802 = query.getOrDefault("SubscriptionName")
  valid_592802 = validateParameter(valid_592802, JString, required = true,
                                 default = nil)
  if valid_592802 != nil:
    section.add "SubscriptionName", valid_592802
  var valid_592816 = query.getOrDefault("Action")
  valid_592816 = validateParameter(valid_592816, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_592816 != nil:
    section.add "Action", valid_592816
  var valid_592817 = query.getOrDefault("Version")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_592817 != nil:
    section.add "Version", valid_592817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592818 = header.getOrDefault("X-Amz-Signature")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Signature", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Content-Sha256", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Date")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Date", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Credential")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Credential", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Security-Token")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Security-Token", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Algorithm")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Algorithm", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-SignedHeaders", valid_592824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_GetAddSourceIdentifierToSubscription_592687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_GetAddSourceIdentifierToSubscription_592687;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592919 = newJObject()
  add(query_592919, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_592919, "SubscriptionName", newJString(SubscriptionName))
  add(query_592919, "Action", newJString(Action))
  add(query_592919, "Version", newJString(Version))
  result = call_592918.call(nil, query_592919, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_592687(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_592688, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_592689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_592994 = ref object of OpenApiRestCall_592348
proc url_PostAddTagsToResource_592996(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_592995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_592997 = query.getOrDefault("Action")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592997 != nil:
    section.add "Action", valid_592997
  var valid_592998 = query.getOrDefault("Version")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_592998 != nil:
    section.add "Version", valid_592998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Security-Token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Security-Token", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Algorithm")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Algorithm", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-SignedHeaders", valid_593005
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_593006 = formData.getOrDefault("Tags")
  valid_593006 = validateParameter(valid_593006, JArray, required = true, default = nil)
  if valid_593006 != nil:
    section.add "Tags", valid_593006
  var valid_593007 = formData.getOrDefault("ResourceName")
  valid_593007 = validateParameter(valid_593007, JString, required = true,
                                 default = nil)
  if valid_593007 != nil:
    section.add "ResourceName", valid_593007
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593008: Call_PostAddTagsToResource_592994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593008.validator(path, query, header, formData, body)
  let scheme = call_593008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593008.url(scheme.get, call_593008.host, call_593008.base,
                         call_593008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593008, url, valid)

proc call*(call_593009: Call_PostAddTagsToResource_592994; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_593010 = newJObject()
  var formData_593011 = newJObject()
  add(query_593010, "Action", newJString(Action))
  if Tags != nil:
    formData_593011.add "Tags", Tags
  add(query_593010, "Version", newJString(Version))
  add(formData_593011, "ResourceName", newJString(ResourceName))
  result = call_593009.call(nil, query_593010, nil, formData_593011, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_592994(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_592995, base: "/",
    url: url_PostAddTagsToResource_592996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_592977 = ref object of OpenApiRestCall_592348
proc url_GetAddTagsToResource_592979(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_592978(path: JsonNode; query: JsonNode;
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
  var valid_592980 = query.getOrDefault("Tags")
  valid_592980 = validateParameter(valid_592980, JArray, required = true, default = nil)
  if valid_592980 != nil:
    section.add "Tags", valid_592980
  var valid_592981 = query.getOrDefault("ResourceName")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "ResourceName", valid_592981
  var valid_592982 = query.getOrDefault("Action")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_592982 != nil:
    section.add "Action", valid_592982
  var valid_592983 = query.getOrDefault("Version")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_592983 != nil:
    section.add "Version", valid_592983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592984 = header.getOrDefault("X-Amz-Signature")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Signature", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Content-Sha256", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Date")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Date", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Credential")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Credential", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Security-Token")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Security-Token", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Algorithm")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Algorithm", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-SignedHeaders", valid_592990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592991: Call_GetAddTagsToResource_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_592991.validator(path, query, header, formData, body)
  let scheme = call_592991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592991.url(scheme.get, call_592991.host, call_592991.base,
                         call_592991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592991, url, valid)

proc call*(call_592992: Call_GetAddTagsToResource_592977; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592993 = newJObject()
  if Tags != nil:
    query_592993.add "Tags", Tags
  add(query_592993, "ResourceName", newJString(ResourceName))
  add(query_592993, "Action", newJString(Action))
  add(query_592993, "Version", newJString(Version))
  result = call_592992.call(nil, query_592993, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_592977(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_592978, base: "/",
    url: url_GetAddTagsToResource_592979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_593032 = ref object of OpenApiRestCall_592348
proc url_PostAuthorizeDBSecurityGroupIngress_593034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_593033(path: JsonNode;
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
  var valid_593035 = query.getOrDefault("Action")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_593035 != nil:
    section.add "Action", valid_593035
  var valid_593036 = query.getOrDefault("Version")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593036 != nil:
    section.add "Version", valid_593036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593044 = formData.getOrDefault("DBSecurityGroupName")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "DBSecurityGroupName", valid_593044
  var valid_593045 = formData.getOrDefault("EC2SecurityGroupName")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "EC2SecurityGroupName", valid_593045
  var valid_593046 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_593046
  var valid_593047 = formData.getOrDefault("EC2SecurityGroupId")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "EC2SecurityGroupId", valid_593047
  var valid_593048 = formData.getOrDefault("CIDRIP")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "CIDRIP", valid_593048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593049: Call_PostAuthorizeDBSecurityGroupIngress_593032;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593049.validator(path, query, header, formData, body)
  let scheme = call_593049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593049.url(scheme.get, call_593049.host, call_593049.base,
                         call_593049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593049, url, valid)

proc call*(call_593050: Call_PostAuthorizeDBSecurityGroupIngress_593032;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2014-09-01"): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593051 = newJObject()
  var formData_593052 = newJObject()
  add(formData_593052, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_593052, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_593052, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_593052, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_593052, "CIDRIP", newJString(CIDRIP))
  add(query_593051, "Action", newJString(Action))
  add(query_593051, "Version", newJString(Version))
  result = call_593050.call(nil, query_593051, nil, formData_593052, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_593032(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_593033, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_593034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_593012 = ref object of OpenApiRestCall_592348
proc url_GetAuthorizeDBSecurityGroupIngress_593014(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_593013(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_593015 = query.getOrDefault("EC2SecurityGroupName")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "EC2SecurityGroupName", valid_593015
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593016 = query.getOrDefault("DBSecurityGroupName")
  valid_593016 = validateParameter(valid_593016, JString, required = true,
                                 default = nil)
  if valid_593016 != nil:
    section.add "DBSecurityGroupName", valid_593016
  var valid_593017 = query.getOrDefault("EC2SecurityGroupId")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "EC2SecurityGroupId", valid_593017
  var valid_593018 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_593018
  var valid_593019 = query.getOrDefault("Action")
  valid_593019 = validateParameter(valid_593019, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_593019 != nil:
    section.add "Action", valid_593019
  var valid_593020 = query.getOrDefault("Version")
  valid_593020 = validateParameter(valid_593020, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593020 != nil:
    section.add "Version", valid_593020
  var valid_593021 = query.getOrDefault("CIDRIP")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "CIDRIP", valid_593021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Algorithm")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Algorithm", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-SignedHeaders", valid_593028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_GetAuthorizeDBSecurityGroupIngress_593012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_GetAuthorizeDBSecurityGroupIngress_593012;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_593031 = newJObject()
  add(query_593031, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_593031, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593031, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_593031, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_593031, "Action", newJString(Action))
  add(query_593031, "Version", newJString(Version))
  add(query_593031, "CIDRIP", newJString(CIDRIP))
  result = call_593030.call(nil, query_593031, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_593012(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_593013, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_593014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_593072 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBParameterGroup_593074(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBParameterGroup_593073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593075 = query.getOrDefault("Action")
  valid_593075 = validateParameter(valid_593075, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_593075 != nil:
    section.add "Action", valid_593075
  var valid_593076 = query.getOrDefault("Version")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593076 != nil:
    section.add "Version", valid_593076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593077 = header.getOrDefault("X-Amz-Signature")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Signature", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Content-Sha256", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Date")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Date", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Credential")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Credential", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Security-Token")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Security-Token", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Algorithm")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Algorithm", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-SignedHeaders", valid_593083
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_593084 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_593084 = validateParameter(valid_593084, JString, required = true,
                                 default = nil)
  if valid_593084 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_593084
  var valid_593085 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = nil)
  if valid_593085 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_593085
  var valid_593086 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_593086 = validateParameter(valid_593086, JString, required = true,
                                 default = nil)
  if valid_593086 != nil:
    section.add "TargetDBParameterGroupDescription", valid_593086
  var valid_593087 = formData.getOrDefault("Tags")
  valid_593087 = validateParameter(valid_593087, JArray, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "Tags", valid_593087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593088: Call_PostCopyDBParameterGroup_593072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593088.validator(path, query, header, formData, body)
  let scheme = call_593088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593088.url(scheme.get, call_593088.host, call_593088.base,
                         call_593088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593088, url, valid)

proc call*(call_593089: Call_PostCopyDBParameterGroup_593072;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          Action: string = "CopyDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593090 = newJObject()
  var formData_593091 = newJObject()
  add(formData_593091, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(formData_593091, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_593091, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_593090, "Action", newJString(Action))
  if Tags != nil:
    formData_593091.add "Tags", Tags
  add(query_593090, "Version", newJString(Version))
  result = call_593089.call(nil, query_593090, nil, formData_593091, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_593072(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_593073, base: "/",
    url: url_PostCopyDBParameterGroup_593074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_593053 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBParameterGroup_593055(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBParameterGroup_593054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_593056 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_593056
  var valid_593057 = query.getOrDefault("Tags")
  valid_593057 = validateParameter(valid_593057, JArray, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "Tags", valid_593057
  var valid_593058 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "TargetDBParameterGroupDescription", valid_593058
  var valid_593059 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_593059
  var valid_593060 = query.getOrDefault("Action")
  valid_593060 = validateParameter(valid_593060, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_593060 != nil:
    section.add "Action", valid_593060
  var valid_593061 = query.getOrDefault("Version")
  valid_593061 = validateParameter(valid_593061, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593061 != nil:
    section.add "Version", valid_593061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593062 = header.getOrDefault("X-Amz-Signature")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Signature", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Content-Sha256", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Date")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Date", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Credential")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Credential", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Security-Token")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Security-Token", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Algorithm")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Algorithm", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-SignedHeaders", valid_593068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593069: Call_GetCopyDBParameterGroup_593053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593069.validator(path, query, header, formData, body)
  let scheme = call_593069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593069.url(scheme.get, call_593069.host, call_593069.base,
                         call_593069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593069, url, valid)

proc call*(call_593070: Call_GetCopyDBParameterGroup_593053;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          TargetDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593071 = newJObject()
  add(query_593071, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    query_593071.add "Tags", Tags
  add(query_593071, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_593071, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_593071, "Action", newJString(Action))
  add(query_593071, "Version", newJString(Version))
  result = call_593070.call(nil, query_593071, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_593053(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_593054, base: "/",
    url: url_GetCopyDBParameterGroup_593055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_593110 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBSnapshot_593112(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_593111(path: JsonNode; query: JsonNode;
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
  var valid_593113 = query.getOrDefault("Action")
  valid_593113 = validateParameter(valid_593113, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593113 != nil:
    section.add "Action", valid_593113
  var valid_593114 = query.getOrDefault("Version")
  valid_593114 = validateParameter(valid_593114, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593114 != nil:
    section.add "Version", valid_593114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593115 = header.getOrDefault("X-Amz-Signature")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Signature", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Content-Sha256", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Date")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Date", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Credential")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Credential", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Security-Token")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Security-Token", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Algorithm")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Algorithm", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-SignedHeaders", valid_593121
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593122 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593122
  var valid_593123 = formData.getOrDefault("Tags")
  valid_593123 = validateParameter(valid_593123, JArray, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "Tags", valid_593123
  var valid_593124 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = nil)
  if valid_593124 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593124
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_PostCopyDBSnapshot_593110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_PostCopyDBSnapshot_593110;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593127 = newJObject()
  var formData_593128 = newJObject()
  add(formData_593128, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593127, "Action", newJString(Action))
  if Tags != nil:
    formData_593128.add "Tags", Tags
  add(formData_593128, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593127, "Version", newJString(Version))
  result = call_593126.call(nil, query_593127, nil, formData_593128, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_593110(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_593111, base: "/",
    url: url_PostCopyDBSnapshot_593112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_593092 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBSnapshot_593094(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_593093(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593095 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593095 = validateParameter(valid_593095, JString, required = true,
                                 default = nil)
  if valid_593095 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593095
  var valid_593096 = query.getOrDefault("Tags")
  valid_593096 = validateParameter(valid_593096, JArray, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "Tags", valid_593096
  var valid_593097 = query.getOrDefault("Action")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593097 != nil:
    section.add "Action", valid_593097
  var valid_593098 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593098 = validateParameter(valid_593098, JString, required = true,
                                 default = nil)
  if valid_593098 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593098
  var valid_593099 = query.getOrDefault("Version")
  valid_593099 = validateParameter(valid_593099, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593099 != nil:
    section.add "Version", valid_593099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593100 = header.getOrDefault("X-Amz-Signature")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Signature", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Content-Sha256", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Date")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Date", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Credential")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Credential", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Security-Token")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Security-Token", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Algorithm")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Algorithm", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-SignedHeaders", valid_593106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593107: Call_GetCopyDBSnapshot_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593107.validator(path, query, header, formData, body)
  let scheme = call_593107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593107.url(scheme.get, call_593107.host, call_593107.base,
                         call_593107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593107, url, valid)

proc call*(call_593108: Call_GetCopyDBSnapshot_593092;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593109 = newJObject()
  add(query_593109, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_593109.add "Tags", Tags
  add(query_593109, "Action", newJString(Action))
  add(query_593109, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593109, "Version", newJString(Version))
  result = call_593108.call(nil, query_593109, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_593092(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_593093,
    base: "/", url: url_GetCopyDBSnapshot_593094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_593148 = ref object of OpenApiRestCall_592348
proc url_PostCopyOptionGroup_593150(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyOptionGroup_593149(path: JsonNode; query: JsonNode;
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
  var valid_593151 = query.getOrDefault("Action")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_593151 != nil:
    section.add "Action", valid_593151
  var valid_593152 = query.getOrDefault("Version")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593152 != nil:
    section.add "Version", valid_593152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_593160 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "TargetOptionGroupIdentifier", valid_593160
  var valid_593161 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_593161 = validateParameter(valid_593161, JString, required = true,
                                 default = nil)
  if valid_593161 != nil:
    section.add "TargetOptionGroupDescription", valid_593161
  var valid_593162 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = nil)
  if valid_593162 != nil:
    section.add "SourceOptionGroupIdentifier", valid_593162
  var valid_593163 = formData.getOrDefault("Tags")
  valid_593163 = validateParameter(valid_593163, JArray, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "Tags", valid_593163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_PostCopyOptionGroup_593148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_PostCopyOptionGroup_593148;
          TargetOptionGroupIdentifier: string;
          TargetOptionGroupDescription: string;
          SourceOptionGroupIdentifier: string; Action: string = "CopyOptionGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupIdentifier: string (required)
  ##   TargetOptionGroupDescription: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593166 = newJObject()
  var formData_593167 = newJObject()
  add(formData_593167, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(formData_593167, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(formData_593167, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_593166, "Action", newJString(Action))
  if Tags != nil:
    formData_593167.add "Tags", Tags
  add(query_593166, "Version", newJString(Version))
  result = call_593165.call(nil, query_593166, nil, formData_593167, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_593148(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_593149, base: "/",
    url: url_PostCopyOptionGroup_593150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_593129 = ref object of OpenApiRestCall_592348
proc url_GetCopyOptionGroup_593131(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyOptionGroup_593130(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  section = newJObject()
  var valid_593132 = query.getOrDefault("Tags")
  valid_593132 = validateParameter(valid_593132, JArray, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "Tags", valid_593132
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_593133 = query.getOrDefault("TargetOptionGroupDescription")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "TargetOptionGroupDescription", valid_593133
  var valid_593134 = query.getOrDefault("Action")
  valid_593134 = validateParameter(valid_593134, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_593134 != nil:
    section.add "Action", valid_593134
  var valid_593135 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_593135 = validateParameter(valid_593135, JString, required = true,
                                 default = nil)
  if valid_593135 != nil:
    section.add "TargetOptionGroupIdentifier", valid_593135
  var valid_593136 = query.getOrDefault("Version")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593136 != nil:
    section.add "Version", valid_593136
  var valid_593137 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_593137 = validateParameter(valid_593137, JString, required = true,
                                 default = nil)
  if valid_593137 != nil:
    section.add "SourceOptionGroupIdentifier", valid_593137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593138 = header.getOrDefault("X-Amz-Signature")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Signature", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Content-Sha256", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Date")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Date", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Credential")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Credential", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Security-Token")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Security-Token", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Algorithm")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Algorithm", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-SignedHeaders", valid_593144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593145: Call_GetCopyOptionGroup_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593145.validator(path, query, header, formData, body)
  let scheme = call_593145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593145.url(scheme.get, call_593145.host, call_593145.base,
                         call_593145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593145, url, valid)

proc call*(call_593146: Call_GetCopyOptionGroup_593129;
          TargetOptionGroupDescription: string;
          TargetOptionGroupIdentifier: string;
          SourceOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyOptionGroup
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  var query_593147 = newJObject()
  if Tags != nil:
    query_593147.add "Tags", Tags
  add(query_593147, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_593147, "Action", newJString(Action))
  add(query_593147, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_593147, "Version", newJString(Version))
  add(query_593147, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  result = call_593146.call(nil, query_593147, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_593129(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_593130,
    base: "/", url: url_GetCopyOptionGroup_593131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_593211 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstance_593213(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_593212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593214 = query.getOrDefault("Action")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593214 != nil:
    section.add "Action", valid_593214
  var valid_593215 = query.getOrDefault("Version")
  valid_593215 = validateParameter(valid_593215, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593215 != nil:
    section.add "Version", valid_593215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString (required)
  ##   Port: JInt
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString (required)
  ##   MultiAZ: JBool
  ##   MasterUsername: JString (required)
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: JString
  ##   BackupRetentionPeriod: JInt
  ##   Engine: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_593223 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "PreferredMaintenanceWindow", valid_593223
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_593224 = formData.getOrDefault("DBInstanceClass")
  valid_593224 = validateParameter(valid_593224, JString, required = true,
                                 default = nil)
  if valid_593224 != nil:
    section.add "DBInstanceClass", valid_593224
  var valid_593225 = formData.getOrDefault("Port")
  valid_593225 = validateParameter(valid_593225, JInt, required = false, default = nil)
  if valid_593225 != nil:
    section.add "Port", valid_593225
  var valid_593226 = formData.getOrDefault("PreferredBackupWindow")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "PreferredBackupWindow", valid_593226
  var valid_593227 = formData.getOrDefault("MasterUserPassword")
  valid_593227 = validateParameter(valid_593227, JString, required = true,
                                 default = nil)
  if valid_593227 != nil:
    section.add "MasterUserPassword", valid_593227
  var valid_593228 = formData.getOrDefault("MultiAZ")
  valid_593228 = validateParameter(valid_593228, JBool, required = false, default = nil)
  if valid_593228 != nil:
    section.add "MultiAZ", valid_593228
  var valid_593229 = formData.getOrDefault("MasterUsername")
  valid_593229 = validateParameter(valid_593229, JString, required = true,
                                 default = nil)
  if valid_593229 != nil:
    section.add "MasterUsername", valid_593229
  var valid_593230 = formData.getOrDefault("DBParameterGroupName")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "DBParameterGroupName", valid_593230
  var valid_593231 = formData.getOrDefault("EngineVersion")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "EngineVersion", valid_593231
  var valid_593232 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_593232 = validateParameter(valid_593232, JArray, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "VpcSecurityGroupIds", valid_593232
  var valid_593233 = formData.getOrDefault("AvailabilityZone")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "AvailabilityZone", valid_593233
  var valid_593234 = formData.getOrDefault("BackupRetentionPeriod")
  valid_593234 = validateParameter(valid_593234, JInt, required = false, default = nil)
  if valid_593234 != nil:
    section.add "BackupRetentionPeriod", valid_593234
  var valid_593235 = formData.getOrDefault("Engine")
  valid_593235 = validateParameter(valid_593235, JString, required = true,
                                 default = nil)
  if valid_593235 != nil:
    section.add "Engine", valid_593235
  var valid_593236 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593236 = validateParameter(valid_593236, JBool, required = false, default = nil)
  if valid_593236 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593236
  var valid_593237 = formData.getOrDefault("TdeCredentialPassword")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "TdeCredentialPassword", valid_593237
  var valid_593238 = formData.getOrDefault("DBName")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "DBName", valid_593238
  var valid_593239 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593239 = validateParameter(valid_593239, JString, required = true,
                                 default = nil)
  if valid_593239 != nil:
    section.add "DBInstanceIdentifier", valid_593239
  var valid_593240 = formData.getOrDefault("Iops")
  valid_593240 = validateParameter(valid_593240, JInt, required = false, default = nil)
  if valid_593240 != nil:
    section.add "Iops", valid_593240
  var valid_593241 = formData.getOrDefault("TdeCredentialArn")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "TdeCredentialArn", valid_593241
  var valid_593242 = formData.getOrDefault("PubliclyAccessible")
  valid_593242 = validateParameter(valid_593242, JBool, required = false, default = nil)
  if valid_593242 != nil:
    section.add "PubliclyAccessible", valid_593242
  var valid_593243 = formData.getOrDefault("LicenseModel")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "LicenseModel", valid_593243
  var valid_593244 = formData.getOrDefault("Tags")
  valid_593244 = validateParameter(valid_593244, JArray, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "Tags", valid_593244
  var valid_593245 = formData.getOrDefault("DBSubnetGroupName")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "DBSubnetGroupName", valid_593245
  var valid_593246 = formData.getOrDefault("OptionGroupName")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "OptionGroupName", valid_593246
  var valid_593247 = formData.getOrDefault("CharacterSetName")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "CharacterSetName", valid_593247
  var valid_593248 = formData.getOrDefault("DBSecurityGroups")
  valid_593248 = validateParameter(valid_593248, JArray, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "DBSecurityGroups", valid_593248
  var valid_593249 = formData.getOrDefault("StorageType")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "StorageType", valid_593249
  var valid_593250 = formData.getOrDefault("AllocatedStorage")
  valid_593250 = validateParameter(valid_593250, JInt, required = true, default = nil)
  if valid_593250 != nil:
    section.add "AllocatedStorage", valid_593250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593251: Call_PostCreateDBInstance_593211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593251.validator(path, query, header, formData, body)
  let scheme = call_593251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593251.url(scheme.get, call_593251.host, call_593251.base,
                         call_593251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593251, url, valid)

proc call*(call_593252: Call_PostCreateDBInstance_593211; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          TdeCredentialPassword: string = ""; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2014-09-01"; DBSecurityGroups: JsonNode = nil;
          StorageType: string = ""): Recallable =
  ## postCreateDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string (required)
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string (required)
  ##   MultiAZ: bool
  ##   MasterUsername: string (required)
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: string
  ##   BackupRetentionPeriod: int
  ##   Engine: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int (required)
  var query_593253 = newJObject()
  var formData_593254 = newJObject()
  add(formData_593254, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593254, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593254, "Port", newJInt(Port))
  add(formData_593254, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_593254, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_593254, "MultiAZ", newJBool(MultiAZ))
  add(formData_593254, "MasterUsername", newJString(MasterUsername))
  add(formData_593254, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593254, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_593254.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_593254, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593254, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_593254, "Engine", newJString(Engine))
  add(formData_593254, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593254, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_593254, "DBName", newJString(DBName))
  add(formData_593254, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593254, "Iops", newJInt(Iops))
  add(formData_593254, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_593254, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593253, "Action", newJString(Action))
  add(formData_593254, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_593254.add "Tags", Tags
  add(formData_593254, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593254, "OptionGroupName", newJString(OptionGroupName))
  add(formData_593254, "CharacterSetName", newJString(CharacterSetName))
  add(query_593253, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_593254.add "DBSecurityGroups", DBSecurityGroups
  add(formData_593254, "StorageType", newJString(StorageType))
  add(formData_593254, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_593252.call(nil, query_593253, nil, formData_593254, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_593211(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_593212, base: "/",
    url: url_PostCreateDBInstance_593213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_593168 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstance_593170(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_593169(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   Port: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   AllocatedStorage: JInt (required)
  ##   DBInstanceClass: JString (required)
  ##   PreferredMaintenanceWindow: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Version` field"
  var valid_593171 = query.getOrDefault("Version")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593171 != nil:
    section.add "Version", valid_593171
  var valid_593172 = query.getOrDefault("DBName")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "DBName", valid_593172
  var valid_593173 = query.getOrDefault("TdeCredentialPassword")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "TdeCredentialPassword", valid_593173
  var valid_593174 = query.getOrDefault("Engine")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = nil)
  if valid_593174 != nil:
    section.add "Engine", valid_593174
  var valid_593175 = query.getOrDefault("DBParameterGroupName")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "DBParameterGroupName", valid_593175
  var valid_593176 = query.getOrDefault("CharacterSetName")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "CharacterSetName", valid_593176
  var valid_593177 = query.getOrDefault("Tags")
  valid_593177 = validateParameter(valid_593177, JArray, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "Tags", valid_593177
  var valid_593178 = query.getOrDefault("LicenseModel")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "LicenseModel", valid_593178
  var valid_593179 = query.getOrDefault("DBInstanceIdentifier")
  valid_593179 = validateParameter(valid_593179, JString, required = true,
                                 default = nil)
  if valid_593179 != nil:
    section.add "DBInstanceIdentifier", valid_593179
  var valid_593180 = query.getOrDefault("TdeCredentialArn")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "TdeCredentialArn", valid_593180
  var valid_593181 = query.getOrDefault("MasterUsername")
  valid_593181 = validateParameter(valid_593181, JString, required = true,
                                 default = nil)
  if valid_593181 != nil:
    section.add "MasterUsername", valid_593181
  var valid_593182 = query.getOrDefault("BackupRetentionPeriod")
  valid_593182 = validateParameter(valid_593182, JInt, required = false, default = nil)
  if valid_593182 != nil:
    section.add "BackupRetentionPeriod", valid_593182
  var valid_593183 = query.getOrDefault("StorageType")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "StorageType", valid_593183
  var valid_593184 = query.getOrDefault("EngineVersion")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "EngineVersion", valid_593184
  var valid_593185 = query.getOrDefault("Action")
  valid_593185 = validateParameter(valid_593185, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593185 != nil:
    section.add "Action", valid_593185
  var valid_593186 = query.getOrDefault("MultiAZ")
  valid_593186 = validateParameter(valid_593186, JBool, required = false, default = nil)
  if valid_593186 != nil:
    section.add "MultiAZ", valid_593186
  var valid_593187 = query.getOrDefault("DBSecurityGroups")
  valid_593187 = validateParameter(valid_593187, JArray, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "DBSecurityGroups", valid_593187
  var valid_593188 = query.getOrDefault("Port")
  valid_593188 = validateParameter(valid_593188, JInt, required = false, default = nil)
  if valid_593188 != nil:
    section.add "Port", valid_593188
  var valid_593189 = query.getOrDefault("VpcSecurityGroupIds")
  valid_593189 = validateParameter(valid_593189, JArray, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "VpcSecurityGroupIds", valid_593189
  var valid_593190 = query.getOrDefault("MasterUserPassword")
  valid_593190 = validateParameter(valid_593190, JString, required = true,
                                 default = nil)
  if valid_593190 != nil:
    section.add "MasterUserPassword", valid_593190
  var valid_593191 = query.getOrDefault("AvailabilityZone")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "AvailabilityZone", valid_593191
  var valid_593192 = query.getOrDefault("OptionGroupName")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "OptionGroupName", valid_593192
  var valid_593193 = query.getOrDefault("DBSubnetGroupName")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "DBSubnetGroupName", valid_593193
  var valid_593194 = query.getOrDefault("AllocatedStorage")
  valid_593194 = validateParameter(valid_593194, JInt, required = true, default = nil)
  if valid_593194 != nil:
    section.add "AllocatedStorage", valid_593194
  var valid_593195 = query.getOrDefault("DBInstanceClass")
  valid_593195 = validateParameter(valid_593195, JString, required = true,
                                 default = nil)
  if valid_593195 != nil:
    section.add "DBInstanceClass", valid_593195
  var valid_593196 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "PreferredMaintenanceWindow", valid_593196
  var valid_593197 = query.getOrDefault("PreferredBackupWindow")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "PreferredBackupWindow", valid_593197
  var valid_593198 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593198 = validateParameter(valid_593198, JBool, required = false, default = nil)
  if valid_593198 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593198
  var valid_593199 = query.getOrDefault("Iops")
  valid_593199 = validateParameter(valid_593199, JInt, required = false, default = nil)
  if valid_593199 != nil:
    section.add "Iops", valid_593199
  var valid_593200 = query.getOrDefault("PubliclyAccessible")
  valid_593200 = validateParameter(valid_593200, JBool, required = false, default = nil)
  if valid_593200 != nil:
    section.add "PubliclyAccessible", valid_593200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593208: Call_GetCreateDBInstance_593168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593208.validator(path, query, header, formData, body)
  let scheme = call_593208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593208.url(scheme.get, call_593208.host, call_593208.base,
                         call_593208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593208, url, valid)

proc call*(call_593209: Call_GetCreateDBInstance_593168; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2014-09-01";
          DBName: string = ""; TdeCredentialPassword: string = "";
          DBParameterGroupName: string = ""; CharacterSetName: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
          Action: string = "CreateDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0; PubliclyAccessible: bool = false): Recallable =
  ## getCreateDBInstance
  ##   Version: string (required)
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   Port: int
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   AllocatedStorage: int (required)
  ##   DBInstanceClass: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  ##   PubliclyAccessible: bool
  var query_593210 = newJObject()
  add(query_593210, "Version", newJString(Version))
  add(query_593210, "DBName", newJString(DBName))
  add(query_593210, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_593210, "Engine", newJString(Engine))
  add(query_593210, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593210, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_593210.add "Tags", Tags
  add(query_593210, "LicenseModel", newJString(LicenseModel))
  add(query_593210, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593210, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_593210, "MasterUsername", newJString(MasterUsername))
  add(query_593210, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_593210, "StorageType", newJString(StorageType))
  add(query_593210, "EngineVersion", newJString(EngineVersion))
  add(query_593210, "Action", newJString(Action))
  add(query_593210, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_593210.add "DBSecurityGroups", DBSecurityGroups
  add(query_593210, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_593210.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_593210, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_593210, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593210, "OptionGroupName", newJString(OptionGroupName))
  add(query_593210, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593210, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_593210, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593210, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593210, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_593210, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593210, "Iops", newJInt(Iops))
  add(query_593210, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_593209.call(nil, query_593210, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_593168(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_593169, base: "/",
    url: url_GetCreateDBInstance_593170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_593282 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstanceReadReplica_593284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_593283(path: JsonNode;
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
  var valid_593285 = query.getOrDefault("Action")
  valid_593285 = validateParameter(valid_593285, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593285 != nil:
    section.add "Action", valid_593285
  var valid_593286 = query.getOrDefault("Version")
  valid_593286 = validateParameter(valid_593286, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593286 != nil:
    section.add "Version", valid_593286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593287 = header.getOrDefault("X-Amz-Signature")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Signature", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Content-Sha256", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Date")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Date", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Credential")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Credential", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Security-Token")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Security-Token", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Algorithm")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Algorithm", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-SignedHeaders", valid_593293
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   StorageType: JString
  section = newJObject()
  var valid_593294 = formData.getOrDefault("Port")
  valid_593294 = validateParameter(valid_593294, JInt, required = false, default = nil)
  if valid_593294 != nil:
    section.add "Port", valid_593294
  var valid_593295 = formData.getOrDefault("DBInstanceClass")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "DBInstanceClass", valid_593295
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_593296 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = nil)
  if valid_593296 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593296
  var valid_593297 = formData.getOrDefault("AvailabilityZone")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "AvailabilityZone", valid_593297
  var valid_593298 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593298 = validateParameter(valid_593298, JBool, required = false, default = nil)
  if valid_593298 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593298
  var valid_593299 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593299 = validateParameter(valid_593299, JString, required = true,
                                 default = nil)
  if valid_593299 != nil:
    section.add "DBInstanceIdentifier", valid_593299
  var valid_593300 = formData.getOrDefault("Iops")
  valid_593300 = validateParameter(valid_593300, JInt, required = false, default = nil)
  if valid_593300 != nil:
    section.add "Iops", valid_593300
  var valid_593301 = formData.getOrDefault("PubliclyAccessible")
  valid_593301 = validateParameter(valid_593301, JBool, required = false, default = nil)
  if valid_593301 != nil:
    section.add "PubliclyAccessible", valid_593301
  var valid_593302 = formData.getOrDefault("Tags")
  valid_593302 = validateParameter(valid_593302, JArray, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "Tags", valid_593302
  var valid_593303 = formData.getOrDefault("DBSubnetGroupName")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "DBSubnetGroupName", valid_593303
  var valid_593304 = formData.getOrDefault("OptionGroupName")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "OptionGroupName", valid_593304
  var valid_593305 = formData.getOrDefault("StorageType")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "StorageType", valid_593305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593306: Call_PostCreateDBInstanceReadReplica_593282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593306.validator(path, query, header, formData, body)
  let scheme = call_593306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593306.url(scheme.get, call_593306.host, call_593306.base,
                         call_593306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593306, url, valid)

proc call*(call_593307: Call_PostCreateDBInstanceReadReplica_593282;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   StorageType: string
  var query_593308 = newJObject()
  var formData_593309 = newJObject()
  add(formData_593309, "Port", newJInt(Port))
  add(formData_593309, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593309, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_593309, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593309, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593309, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593309, "Iops", newJInt(Iops))
  add(formData_593309, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593308, "Action", newJString(Action))
  if Tags != nil:
    formData_593309.add "Tags", Tags
  add(formData_593309, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593309, "OptionGroupName", newJString(OptionGroupName))
  add(query_593308, "Version", newJString(Version))
  add(formData_593309, "StorageType", newJString(StorageType))
  result = call_593307.call(nil, query_593308, nil, formData_593309, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_593282(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_593283, base: "/",
    url: url_PostCreateDBInstanceReadReplica_593284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_593255 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstanceReadReplica_593257(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_593256(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_593258 = query.getOrDefault("Tags")
  valid_593258 = validateParameter(valid_593258, JArray, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "Tags", valid_593258
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593259 = query.getOrDefault("DBInstanceIdentifier")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = nil)
  if valid_593259 != nil:
    section.add "DBInstanceIdentifier", valid_593259
  var valid_593260 = query.getOrDefault("StorageType")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "StorageType", valid_593260
  var valid_593261 = query.getOrDefault("Action")
  valid_593261 = validateParameter(valid_593261, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593261 != nil:
    section.add "Action", valid_593261
  var valid_593262 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = nil)
  if valid_593262 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593262
  var valid_593263 = query.getOrDefault("Port")
  valid_593263 = validateParameter(valid_593263, JInt, required = false, default = nil)
  if valid_593263 != nil:
    section.add "Port", valid_593263
  var valid_593264 = query.getOrDefault("AvailabilityZone")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "AvailabilityZone", valid_593264
  var valid_593265 = query.getOrDefault("OptionGroupName")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "OptionGroupName", valid_593265
  var valid_593266 = query.getOrDefault("DBSubnetGroupName")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "DBSubnetGroupName", valid_593266
  var valid_593267 = query.getOrDefault("Version")
  valid_593267 = validateParameter(valid_593267, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593267 != nil:
    section.add "Version", valid_593267
  var valid_593268 = query.getOrDefault("DBInstanceClass")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "DBInstanceClass", valid_593268
  var valid_593269 = query.getOrDefault("PubliclyAccessible")
  valid_593269 = validateParameter(valid_593269, JBool, required = false, default = nil)
  if valid_593269 != nil:
    section.add "PubliclyAccessible", valid_593269
  var valid_593270 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593270 = validateParameter(valid_593270, JBool, required = false, default = nil)
  if valid_593270 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593270
  var valid_593271 = query.getOrDefault("Iops")
  valid_593271 = validateParameter(valid_593271, JInt, required = false, default = nil)
  if valid_593271 != nil:
    section.add "Iops", valid_593271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593272 = header.getOrDefault("X-Amz-Signature")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Signature", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Content-Sha256", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Date")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Date", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Credential")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Credential", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Security-Token")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Security-Token", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Algorithm")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Algorithm", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-SignedHeaders", valid_593278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593279: Call_GetCreateDBInstanceReadReplica_593255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593279.validator(path, query, header, formData, body)
  let scheme = call_593279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593279.url(scheme.get, call_593279.host, call_593279.base,
                         call_593279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593279, url, valid)

proc call*(call_593280: Call_GetCreateDBInstanceReadReplica_593255;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; StorageType: string = "";
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   StorageType: string
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_593281 = newJObject()
  if Tags != nil:
    query_593281.add "Tags", Tags
  add(query_593281, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593281, "StorageType", newJString(StorageType))
  add(query_593281, "Action", newJString(Action))
  add(query_593281, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_593281, "Port", newJInt(Port))
  add(query_593281, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593281, "OptionGroupName", newJString(OptionGroupName))
  add(query_593281, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593281, "Version", newJString(Version))
  add(query_593281, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593281, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593281, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593281, "Iops", newJInt(Iops))
  result = call_593280.call(nil, query_593281, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_593255(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_593256, base: "/",
    url: url_GetCreateDBInstanceReadReplica_593257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_593329 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBParameterGroup_593331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_593330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593332 = query.getOrDefault("Action")
  valid_593332 = validateParameter(valid_593332, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593332 != nil:
    section.add "Action", valid_593332
  var valid_593333 = query.getOrDefault("Version")
  valid_593333 = validateParameter(valid_593333, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593333 != nil:
    section.add "Version", valid_593333
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593334 = header.getOrDefault("X-Amz-Signature")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Signature", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Content-Sha256", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Date")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Date", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Credential")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Credential", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Security-Token")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Security-Token", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Algorithm")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Algorithm", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-SignedHeaders", valid_593340
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_593341 = formData.getOrDefault("Description")
  valid_593341 = validateParameter(valid_593341, JString, required = true,
                                 default = nil)
  if valid_593341 != nil:
    section.add "Description", valid_593341
  var valid_593342 = formData.getOrDefault("DBParameterGroupName")
  valid_593342 = validateParameter(valid_593342, JString, required = true,
                                 default = nil)
  if valid_593342 != nil:
    section.add "DBParameterGroupName", valid_593342
  var valid_593343 = formData.getOrDefault("Tags")
  valid_593343 = validateParameter(valid_593343, JArray, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "Tags", valid_593343
  var valid_593344 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593344 = validateParameter(valid_593344, JString, required = true,
                                 default = nil)
  if valid_593344 != nil:
    section.add "DBParameterGroupFamily", valid_593344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593345: Call_PostCreateDBParameterGroup_593329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593345.validator(path, query, header, formData, body)
  let scheme = call_593345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593345.url(scheme.get, call_593345.host, call_593345.base,
                         call_593345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593345, url, valid)

proc call*(call_593346: Call_PostCreateDBParameterGroup_593329;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_593347 = newJObject()
  var formData_593348 = newJObject()
  add(formData_593348, "Description", newJString(Description))
  add(formData_593348, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593347, "Action", newJString(Action))
  if Tags != nil:
    formData_593348.add "Tags", Tags
  add(query_593347, "Version", newJString(Version))
  add(formData_593348, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593346.call(nil, query_593347, nil, formData_593348, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_593329(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_593330, base: "/",
    url: url_PostCreateDBParameterGroup_593331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_593310 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBParameterGroup_593312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_593311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593313 = query.getOrDefault("DBParameterGroupFamily")
  valid_593313 = validateParameter(valid_593313, JString, required = true,
                                 default = nil)
  if valid_593313 != nil:
    section.add "DBParameterGroupFamily", valid_593313
  var valid_593314 = query.getOrDefault("DBParameterGroupName")
  valid_593314 = validateParameter(valid_593314, JString, required = true,
                                 default = nil)
  if valid_593314 != nil:
    section.add "DBParameterGroupName", valid_593314
  var valid_593315 = query.getOrDefault("Tags")
  valid_593315 = validateParameter(valid_593315, JArray, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "Tags", valid_593315
  var valid_593316 = query.getOrDefault("Action")
  valid_593316 = validateParameter(valid_593316, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593316 != nil:
    section.add "Action", valid_593316
  var valid_593317 = query.getOrDefault("Description")
  valid_593317 = validateParameter(valid_593317, JString, required = true,
                                 default = nil)
  if valid_593317 != nil:
    section.add "Description", valid_593317
  var valid_593318 = query.getOrDefault("Version")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593318 != nil:
    section.add "Version", valid_593318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593319 = header.getOrDefault("X-Amz-Signature")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Signature", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Content-Sha256", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Date")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Date", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Credential")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Credential", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Security-Token")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Security-Token", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Algorithm")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Algorithm", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-SignedHeaders", valid_593325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593326: Call_GetCreateDBParameterGroup_593310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593326.validator(path, query, header, formData, body)
  let scheme = call_593326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593326.url(scheme.get, call_593326.host, call_593326.base,
                         call_593326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593326, url, valid)

proc call*(call_593327: Call_GetCreateDBParameterGroup_593310;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_593328 = newJObject()
  add(query_593328, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593328, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_593328.add "Tags", Tags
  add(query_593328, "Action", newJString(Action))
  add(query_593328, "Description", newJString(Description))
  add(query_593328, "Version", newJString(Version))
  result = call_593327.call(nil, query_593328, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_593310(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_593311, base: "/",
    url: url_GetCreateDBParameterGroup_593312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_593367 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSecurityGroup_593369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_593368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593370 = query.getOrDefault("Action")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593370 != nil:
    section.add "Action", valid_593370
  var valid_593371 = query.getOrDefault("Version")
  valid_593371 = validateParameter(valid_593371, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593371 != nil:
    section.add "Version", valid_593371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593372 = header.getOrDefault("X-Amz-Signature")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Signature", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Content-Sha256", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Date")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Date", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Credential")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Credential", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Security-Token")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Security-Token", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Algorithm")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Algorithm", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-SignedHeaders", valid_593378
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_593379 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_593379 = validateParameter(valid_593379, JString, required = true,
                                 default = nil)
  if valid_593379 != nil:
    section.add "DBSecurityGroupDescription", valid_593379
  var valid_593380 = formData.getOrDefault("DBSecurityGroupName")
  valid_593380 = validateParameter(valid_593380, JString, required = true,
                                 default = nil)
  if valid_593380 != nil:
    section.add "DBSecurityGroupName", valid_593380
  var valid_593381 = formData.getOrDefault("Tags")
  valid_593381 = validateParameter(valid_593381, JArray, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "Tags", valid_593381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593382: Call_PostCreateDBSecurityGroup_593367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593382.validator(path, query, header, formData, body)
  let scheme = call_593382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593382.url(scheme.get, call_593382.host, call_593382.base,
                         call_593382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593382, url, valid)

proc call*(call_593383: Call_PostCreateDBSecurityGroup_593367;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593384 = newJObject()
  var formData_593385 = newJObject()
  add(formData_593385, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_593385, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593384, "Action", newJString(Action))
  if Tags != nil:
    formData_593385.add "Tags", Tags
  add(query_593384, "Version", newJString(Version))
  result = call_593383.call(nil, query_593384, nil, formData_593385, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_593367(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_593368, base: "/",
    url: url_PostCreateDBSecurityGroup_593369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_593349 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSecurityGroup_593351(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_593350(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593352 = query.getOrDefault("DBSecurityGroupName")
  valid_593352 = validateParameter(valid_593352, JString, required = true,
                                 default = nil)
  if valid_593352 != nil:
    section.add "DBSecurityGroupName", valid_593352
  var valid_593353 = query.getOrDefault("Tags")
  valid_593353 = validateParameter(valid_593353, JArray, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "Tags", valid_593353
  var valid_593354 = query.getOrDefault("DBSecurityGroupDescription")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = nil)
  if valid_593354 != nil:
    section.add "DBSecurityGroupDescription", valid_593354
  var valid_593355 = query.getOrDefault("Action")
  valid_593355 = validateParameter(valid_593355, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593355 != nil:
    section.add "Action", valid_593355
  var valid_593356 = query.getOrDefault("Version")
  valid_593356 = validateParameter(valid_593356, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593356 != nil:
    section.add "Version", valid_593356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593357 = header.getOrDefault("X-Amz-Signature")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Signature", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Content-Sha256", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Date")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Date", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Credential")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Credential", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Security-Token")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Security-Token", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Algorithm")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Algorithm", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-SignedHeaders", valid_593363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593364: Call_GetCreateDBSecurityGroup_593349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593364.validator(path, query, header, formData, body)
  let scheme = call_593364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593364.url(scheme.get, call_593364.host, call_593364.base,
                         call_593364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593364, url, valid)

proc call*(call_593365: Call_GetCreateDBSecurityGroup_593349;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593366 = newJObject()
  add(query_593366, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_593366.add "Tags", Tags
  add(query_593366, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_593366, "Action", newJString(Action))
  add(query_593366, "Version", newJString(Version))
  result = call_593365.call(nil, query_593366, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_593349(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_593350, base: "/",
    url: url_GetCreateDBSecurityGroup_593351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_593404 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSnapshot_593406(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_593405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593407 = query.getOrDefault("Action")
  valid_593407 = validateParameter(valid_593407, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593407 != nil:
    section.add "Action", valid_593407
  var valid_593408 = query.getOrDefault("Version")
  valid_593408 = validateParameter(valid_593408, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593408 != nil:
    section.add "Version", valid_593408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593409 = header.getOrDefault("X-Amz-Signature")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Signature", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Content-Sha256", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Date")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Date", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Credential")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Credential", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Security-Token")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Security-Token", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Algorithm")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Algorithm", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-SignedHeaders", valid_593415
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593416 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593416 = validateParameter(valid_593416, JString, required = true,
                                 default = nil)
  if valid_593416 != nil:
    section.add "DBInstanceIdentifier", valid_593416
  var valid_593417 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593417 = validateParameter(valid_593417, JString, required = true,
                                 default = nil)
  if valid_593417 != nil:
    section.add "DBSnapshotIdentifier", valid_593417
  var valid_593418 = formData.getOrDefault("Tags")
  valid_593418 = validateParameter(valid_593418, JArray, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "Tags", valid_593418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_PostCreateDBSnapshot_593404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_PostCreateDBSnapshot_593404;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593421 = newJObject()
  var formData_593422 = newJObject()
  add(formData_593422, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593422, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593421, "Action", newJString(Action))
  if Tags != nil:
    formData_593422.add "Tags", Tags
  add(query_593421, "Version", newJString(Version))
  result = call_593420.call(nil, query_593421, nil, formData_593422, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_593404(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_593405, base: "/",
    url: url_PostCreateDBSnapshot_593406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_593386 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSnapshot_593388(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_593387(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593389 = query.getOrDefault("Tags")
  valid_593389 = validateParameter(valid_593389, JArray, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "Tags", valid_593389
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593390 = query.getOrDefault("DBInstanceIdentifier")
  valid_593390 = validateParameter(valid_593390, JString, required = true,
                                 default = nil)
  if valid_593390 != nil:
    section.add "DBInstanceIdentifier", valid_593390
  var valid_593391 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593391 = validateParameter(valid_593391, JString, required = true,
                                 default = nil)
  if valid_593391 != nil:
    section.add "DBSnapshotIdentifier", valid_593391
  var valid_593392 = query.getOrDefault("Action")
  valid_593392 = validateParameter(valid_593392, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593392 != nil:
    section.add "Action", valid_593392
  var valid_593393 = query.getOrDefault("Version")
  valid_593393 = validateParameter(valid_593393, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593393 != nil:
    section.add "Version", valid_593393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593394 = header.getOrDefault("X-Amz-Signature")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Signature", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-Content-Sha256", valid_593395
  var valid_593396 = header.getOrDefault("X-Amz-Date")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Date", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Credential")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Credential", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Security-Token")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Security-Token", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Algorithm")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Algorithm", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-SignedHeaders", valid_593400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593401: Call_GetCreateDBSnapshot_593386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593401.validator(path, query, header, formData, body)
  let scheme = call_593401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593401.url(scheme.get, call_593401.host, call_593401.base,
                         call_593401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593401, url, valid)

proc call*(call_593402: Call_GetCreateDBSnapshot_593386;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593403 = newJObject()
  if Tags != nil:
    query_593403.add "Tags", Tags
  add(query_593403, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593403, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593403, "Action", newJString(Action))
  add(query_593403, "Version", newJString(Version))
  result = call_593402.call(nil, query_593403, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_593386(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_593387, base: "/",
    url: url_GetCreateDBSnapshot_593388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_593442 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSubnetGroup_593444(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_593443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593445 = query.getOrDefault("Action")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593445 != nil:
    section.add "Action", valid_593445
  var valid_593446 = query.getOrDefault("Version")
  valid_593446 = validateParameter(valid_593446, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593446 != nil:
    section.add "Version", valid_593446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593447 = header.getOrDefault("X-Amz-Signature")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Signature", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Content-Sha256", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Date")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Date", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Credential")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Credential", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Security-Token")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Security-Token", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Algorithm")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Algorithm", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-SignedHeaders", valid_593453
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_593454 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_593454 = validateParameter(valid_593454, JString, required = true,
                                 default = nil)
  if valid_593454 != nil:
    section.add "DBSubnetGroupDescription", valid_593454
  var valid_593455 = formData.getOrDefault("Tags")
  valid_593455 = validateParameter(valid_593455, JArray, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "Tags", valid_593455
  var valid_593456 = formData.getOrDefault("DBSubnetGroupName")
  valid_593456 = validateParameter(valid_593456, JString, required = true,
                                 default = nil)
  if valid_593456 != nil:
    section.add "DBSubnetGroupName", valid_593456
  var valid_593457 = formData.getOrDefault("SubnetIds")
  valid_593457 = validateParameter(valid_593457, JArray, required = true, default = nil)
  if valid_593457 != nil:
    section.add "SubnetIds", valid_593457
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593458: Call_PostCreateDBSubnetGroup_593442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593458.validator(path, query, header, formData, body)
  let scheme = call_593458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593458.url(scheme.get, call_593458.host, call_593458.base,
                         call_593458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593458, url, valid)

proc call*(call_593459: Call_PostCreateDBSubnetGroup_593442;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_593460 = newJObject()
  var formData_593461 = newJObject()
  add(formData_593461, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593460, "Action", newJString(Action))
  if Tags != nil:
    formData_593461.add "Tags", Tags
  add(formData_593461, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593460, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_593461.add "SubnetIds", SubnetIds
  result = call_593459.call(nil, query_593460, nil, formData_593461, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_593442(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_593443, base: "/",
    url: url_PostCreateDBSubnetGroup_593444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_593423 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSubnetGroup_593425(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_593424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593426 = query.getOrDefault("Tags")
  valid_593426 = validateParameter(valid_593426, JArray, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "Tags", valid_593426
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_593427 = query.getOrDefault("SubnetIds")
  valid_593427 = validateParameter(valid_593427, JArray, required = true, default = nil)
  if valid_593427 != nil:
    section.add "SubnetIds", valid_593427
  var valid_593428 = query.getOrDefault("Action")
  valid_593428 = validateParameter(valid_593428, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593428 != nil:
    section.add "Action", valid_593428
  var valid_593429 = query.getOrDefault("DBSubnetGroupDescription")
  valid_593429 = validateParameter(valid_593429, JString, required = true,
                                 default = nil)
  if valid_593429 != nil:
    section.add "DBSubnetGroupDescription", valid_593429
  var valid_593430 = query.getOrDefault("DBSubnetGroupName")
  valid_593430 = validateParameter(valid_593430, JString, required = true,
                                 default = nil)
  if valid_593430 != nil:
    section.add "DBSubnetGroupName", valid_593430
  var valid_593431 = query.getOrDefault("Version")
  valid_593431 = validateParameter(valid_593431, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593431 != nil:
    section.add "Version", valid_593431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593432 = header.getOrDefault("X-Amz-Signature")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Signature", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Content-Sha256", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Date")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Date", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Credential")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Credential", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Security-Token")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Security-Token", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Algorithm")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Algorithm", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-SignedHeaders", valid_593438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593439: Call_GetCreateDBSubnetGroup_593423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593439.validator(path, query, header, formData, body)
  let scheme = call_593439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593439.url(scheme.get, call_593439.host, call_593439.base,
                         call_593439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593439, url, valid)

proc call*(call_593440: Call_GetCreateDBSubnetGroup_593423; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593441 = newJObject()
  if Tags != nil:
    query_593441.add "Tags", Tags
  if SubnetIds != nil:
    query_593441.add "SubnetIds", SubnetIds
  add(query_593441, "Action", newJString(Action))
  add(query_593441, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593441, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593441, "Version", newJString(Version))
  result = call_593440.call(nil, query_593441, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_593423(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_593424, base: "/",
    url: url_GetCreateDBSubnetGroup_593425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_593484 = ref object of OpenApiRestCall_592348
proc url_PostCreateEventSubscription_593486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_593485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593487 = query.getOrDefault("Action")
  valid_593487 = validateParameter(valid_593487, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593487 != nil:
    section.add "Action", valid_593487
  var valid_593488 = query.getOrDefault("Version")
  valid_593488 = validateParameter(valid_593488, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593488 != nil:
    section.add "Version", valid_593488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593489 = header.getOrDefault("X-Amz-Signature")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Signature", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Content-Sha256", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Date")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Date", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-Credential")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-Credential", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-Security-Token")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Security-Token", valid_593493
  var valid_593494 = header.getOrDefault("X-Amz-Algorithm")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Algorithm", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-SignedHeaders", valid_593495
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  ##   Tags: JArray
  section = newJObject()
  var valid_593496 = formData.getOrDefault("SourceIds")
  valid_593496 = validateParameter(valid_593496, JArray, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "SourceIds", valid_593496
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_593497 = formData.getOrDefault("SnsTopicArn")
  valid_593497 = validateParameter(valid_593497, JString, required = true,
                                 default = nil)
  if valid_593497 != nil:
    section.add "SnsTopicArn", valid_593497
  var valid_593498 = formData.getOrDefault("Enabled")
  valid_593498 = validateParameter(valid_593498, JBool, required = false, default = nil)
  if valid_593498 != nil:
    section.add "Enabled", valid_593498
  var valid_593499 = formData.getOrDefault("SubscriptionName")
  valid_593499 = validateParameter(valid_593499, JString, required = true,
                                 default = nil)
  if valid_593499 != nil:
    section.add "SubscriptionName", valid_593499
  var valid_593500 = formData.getOrDefault("SourceType")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "SourceType", valid_593500
  var valid_593501 = formData.getOrDefault("EventCategories")
  valid_593501 = validateParameter(valid_593501, JArray, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "EventCategories", valid_593501
  var valid_593502 = formData.getOrDefault("Tags")
  valid_593502 = validateParameter(valid_593502, JArray, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "Tags", valid_593502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593503: Call_PostCreateEventSubscription_593484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593503.validator(path, query, header, formData, body)
  let scheme = call_593503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593503.url(scheme.get, call_593503.host, call_593503.base,
                         call_593503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593503, url, valid)

proc call*(call_593504: Call_PostCreateEventSubscription_593484;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593505 = newJObject()
  var formData_593506 = newJObject()
  if SourceIds != nil:
    formData_593506.add "SourceIds", SourceIds
  add(formData_593506, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_593506, "Enabled", newJBool(Enabled))
  add(formData_593506, "SubscriptionName", newJString(SubscriptionName))
  add(formData_593506, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_593506.add "EventCategories", EventCategories
  add(query_593505, "Action", newJString(Action))
  if Tags != nil:
    formData_593506.add "Tags", Tags
  add(query_593505, "Version", newJString(Version))
  result = call_593504.call(nil, query_593505, nil, formData_593506, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_593484(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_593485, base: "/",
    url: url_PostCreateEventSubscription_593486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_593462 = ref object of OpenApiRestCall_592348
proc url_GetCreateEventSubscription_593464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_593463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593465 = query.getOrDefault("Tags")
  valid_593465 = validateParameter(valid_593465, JArray, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "Tags", valid_593465
  var valid_593466 = query.getOrDefault("SourceType")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "SourceType", valid_593466
  var valid_593467 = query.getOrDefault("Enabled")
  valid_593467 = validateParameter(valid_593467, JBool, required = false, default = nil)
  if valid_593467 != nil:
    section.add "Enabled", valid_593467
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_593468 = query.getOrDefault("SubscriptionName")
  valid_593468 = validateParameter(valid_593468, JString, required = true,
                                 default = nil)
  if valid_593468 != nil:
    section.add "SubscriptionName", valid_593468
  var valid_593469 = query.getOrDefault("EventCategories")
  valid_593469 = validateParameter(valid_593469, JArray, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "EventCategories", valid_593469
  var valid_593470 = query.getOrDefault("SourceIds")
  valid_593470 = validateParameter(valid_593470, JArray, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "SourceIds", valid_593470
  var valid_593471 = query.getOrDefault("Action")
  valid_593471 = validateParameter(valid_593471, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593471 != nil:
    section.add "Action", valid_593471
  var valid_593472 = query.getOrDefault("SnsTopicArn")
  valid_593472 = validateParameter(valid_593472, JString, required = true,
                                 default = nil)
  if valid_593472 != nil:
    section.add "SnsTopicArn", valid_593472
  var valid_593473 = query.getOrDefault("Version")
  valid_593473 = validateParameter(valid_593473, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593473 != nil:
    section.add "Version", valid_593473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593474 = header.getOrDefault("X-Amz-Signature")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Signature", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Content-Sha256", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Date")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Date", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Credential")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Credential", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Security-Token")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Security-Token", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Algorithm")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Algorithm", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-SignedHeaders", valid_593480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593481: Call_GetCreateEventSubscription_593462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593481.validator(path, query, header, formData, body)
  let scheme = call_593481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593481.url(scheme.get, call_593481.host, call_593481.base,
                         call_593481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593481, url, valid)

proc call*(call_593482: Call_GetCreateEventSubscription_593462;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2014-09-01"): Recallable =
  ## getCreateEventSubscription
  ##   Tags: JArray
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_593483 = newJObject()
  if Tags != nil:
    query_593483.add "Tags", Tags
  add(query_593483, "SourceType", newJString(SourceType))
  add(query_593483, "Enabled", newJBool(Enabled))
  add(query_593483, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_593483.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_593483.add "SourceIds", SourceIds
  add(query_593483, "Action", newJString(Action))
  add(query_593483, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_593483, "Version", newJString(Version))
  result = call_593482.call(nil, query_593483, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_593462(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_593463, base: "/",
    url: url_GetCreateEventSubscription_593464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_593527 = ref object of OpenApiRestCall_592348
proc url_PostCreateOptionGroup_593529(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_593528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593530 = query.getOrDefault("Action")
  valid_593530 = validateParameter(valid_593530, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593530 != nil:
    section.add "Action", valid_593530
  var valid_593531 = query.getOrDefault("Version")
  valid_593531 = validateParameter(valid_593531, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593531 != nil:
    section.add "Version", valid_593531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593532 = header.getOrDefault("X-Amz-Signature")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Signature", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Content-Sha256", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Date")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Date", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Credential")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Credential", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Security-Token")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Security-Token", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Algorithm")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Algorithm", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-SignedHeaders", valid_593538
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_593539 = formData.getOrDefault("OptionGroupDescription")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = nil)
  if valid_593539 != nil:
    section.add "OptionGroupDescription", valid_593539
  var valid_593540 = formData.getOrDefault("EngineName")
  valid_593540 = validateParameter(valid_593540, JString, required = true,
                                 default = nil)
  if valid_593540 != nil:
    section.add "EngineName", valid_593540
  var valid_593541 = formData.getOrDefault("MajorEngineVersion")
  valid_593541 = validateParameter(valid_593541, JString, required = true,
                                 default = nil)
  if valid_593541 != nil:
    section.add "MajorEngineVersion", valid_593541
  var valid_593542 = formData.getOrDefault("Tags")
  valid_593542 = validateParameter(valid_593542, JArray, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "Tags", valid_593542
  var valid_593543 = formData.getOrDefault("OptionGroupName")
  valid_593543 = validateParameter(valid_593543, JString, required = true,
                                 default = nil)
  if valid_593543 != nil:
    section.add "OptionGroupName", valid_593543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593544: Call_PostCreateOptionGroup_593527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593544.validator(path, query, header, formData, body)
  let scheme = call_593544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593544.url(scheme.get, call_593544.host, call_593544.base,
                         call_593544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593544, url, valid)

proc call*(call_593545: Call_PostCreateOptionGroup_593527;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593546 = newJObject()
  var formData_593547 = newJObject()
  add(formData_593547, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_593547, "EngineName", newJString(EngineName))
  add(formData_593547, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_593546, "Action", newJString(Action))
  if Tags != nil:
    formData_593547.add "Tags", Tags
  add(formData_593547, "OptionGroupName", newJString(OptionGroupName))
  add(query_593546, "Version", newJString(Version))
  result = call_593545.call(nil, query_593546, nil, formData_593547, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_593527(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_593528, base: "/",
    url: url_PostCreateOptionGroup_593529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_593507 = ref object of OpenApiRestCall_592348
proc url_GetCreateOptionGroup_593509(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_593508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_593510 = query.getOrDefault("EngineName")
  valid_593510 = validateParameter(valid_593510, JString, required = true,
                                 default = nil)
  if valid_593510 != nil:
    section.add "EngineName", valid_593510
  var valid_593511 = query.getOrDefault("OptionGroupDescription")
  valid_593511 = validateParameter(valid_593511, JString, required = true,
                                 default = nil)
  if valid_593511 != nil:
    section.add "OptionGroupDescription", valid_593511
  var valid_593512 = query.getOrDefault("Tags")
  valid_593512 = validateParameter(valid_593512, JArray, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "Tags", valid_593512
  var valid_593513 = query.getOrDefault("Action")
  valid_593513 = validateParameter(valid_593513, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593513 != nil:
    section.add "Action", valid_593513
  var valid_593514 = query.getOrDefault("OptionGroupName")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = nil)
  if valid_593514 != nil:
    section.add "OptionGroupName", valid_593514
  var valid_593515 = query.getOrDefault("Version")
  valid_593515 = validateParameter(valid_593515, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593515 != nil:
    section.add "Version", valid_593515
  var valid_593516 = query.getOrDefault("MajorEngineVersion")
  valid_593516 = validateParameter(valid_593516, JString, required = true,
                                 default = nil)
  if valid_593516 != nil:
    section.add "MajorEngineVersion", valid_593516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593517 = header.getOrDefault("X-Amz-Signature")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Signature", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Content-Sha256", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Date")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Date", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Credential")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Credential", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Security-Token")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Security-Token", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Algorithm")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Algorithm", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-SignedHeaders", valid_593523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593524: Call_GetCreateOptionGroup_593507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593524.validator(path, query, header, formData, body)
  let scheme = call_593524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593524.url(scheme.get, call_593524.host, call_593524.base,
                         call_593524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593524, url, valid)

proc call*(call_593525: Call_GetCreateOptionGroup_593507; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_593526 = newJObject()
  add(query_593526, "EngineName", newJString(EngineName))
  add(query_593526, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_593526.add "Tags", Tags
  add(query_593526, "Action", newJString(Action))
  add(query_593526, "OptionGroupName", newJString(OptionGroupName))
  add(query_593526, "Version", newJString(Version))
  add(query_593526, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_593525.call(nil, query_593526, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_593507(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_593508, base: "/",
    url: url_GetCreateOptionGroup_593509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_593566 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBInstance_593568(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_593567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593569 = query.getOrDefault("Action")
  valid_593569 = validateParameter(valid_593569, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593569 != nil:
    section.add "Action", valid_593569
  var valid_593570 = query.getOrDefault("Version")
  valid_593570 = validateParameter(valid_593570, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593570 != nil:
    section.add "Version", valid_593570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593571 = header.getOrDefault("X-Amz-Signature")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Signature", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Content-Sha256", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-Date")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-Date", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Credential")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Credential", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Security-Token")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Security-Token", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Algorithm")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Algorithm", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-SignedHeaders", valid_593577
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593578 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593578 = validateParameter(valid_593578, JString, required = true,
                                 default = nil)
  if valid_593578 != nil:
    section.add "DBInstanceIdentifier", valid_593578
  var valid_593579 = formData.getOrDefault("SkipFinalSnapshot")
  valid_593579 = validateParameter(valid_593579, JBool, required = false, default = nil)
  if valid_593579 != nil:
    section.add "SkipFinalSnapshot", valid_593579
  var valid_593580 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593580
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593581: Call_PostDeleteDBInstance_593566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593581.validator(path, query, header, formData, body)
  let scheme = call_593581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593581.url(scheme.get, call_593581.host, call_593581.base,
                         call_593581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593581, url, valid)

proc call*(call_593582: Call_PostDeleteDBInstance_593566;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_593583 = newJObject()
  var formData_593584 = newJObject()
  add(formData_593584, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593583, "Action", newJString(Action))
  add(formData_593584, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_593584, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_593583, "Version", newJString(Version))
  result = call_593582.call(nil, query_593583, nil, formData_593584, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_593566(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_593567, base: "/",
    url: url_PostDeleteDBInstance_593568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_593548 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBInstance_593550(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_593549(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593551 = query.getOrDefault("DBInstanceIdentifier")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = nil)
  if valid_593551 != nil:
    section.add "DBInstanceIdentifier", valid_593551
  var valid_593552 = query.getOrDefault("SkipFinalSnapshot")
  valid_593552 = validateParameter(valid_593552, JBool, required = false, default = nil)
  if valid_593552 != nil:
    section.add "SkipFinalSnapshot", valid_593552
  var valid_593553 = query.getOrDefault("Action")
  valid_593553 = validateParameter(valid_593553, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593553 != nil:
    section.add "Action", valid_593553
  var valid_593554 = query.getOrDefault("Version")
  valid_593554 = validateParameter(valid_593554, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593554 != nil:
    section.add "Version", valid_593554
  var valid_593555 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593556 = header.getOrDefault("X-Amz-Signature")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Signature", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Content-Sha256", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Date")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Date", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Credential")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Credential", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Security-Token")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Security-Token", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-Algorithm")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-Algorithm", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-SignedHeaders", valid_593562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593563: Call_GetDeleteDBInstance_593548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593563.validator(path, query, header, formData, body)
  let scheme = call_593563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593563.url(scheme.get, call_593563.host, call_593563.base,
                         call_593563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593563, url, valid)

proc call*(call_593564: Call_GetDeleteDBInstance_593548;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_593565 = newJObject()
  add(query_593565, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593565, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_593565, "Action", newJString(Action))
  add(query_593565, "Version", newJString(Version))
  add(query_593565, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_593564.call(nil, query_593565, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_593548(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_593549, base: "/",
    url: url_GetDeleteDBInstance_593550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_593601 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBParameterGroup_593603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_593602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593604 = query.getOrDefault("Action")
  valid_593604 = validateParameter(valid_593604, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593604 != nil:
    section.add "Action", valid_593604
  var valid_593605 = query.getOrDefault("Version")
  valid_593605 = validateParameter(valid_593605, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593605 != nil:
    section.add "Version", valid_593605
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593606 = header.getOrDefault("X-Amz-Signature")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Signature", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Content-Sha256", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Date")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Date", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Credential")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Credential", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Security-Token")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Security-Token", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Algorithm")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Algorithm", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-SignedHeaders", valid_593612
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593613 = formData.getOrDefault("DBParameterGroupName")
  valid_593613 = validateParameter(valid_593613, JString, required = true,
                                 default = nil)
  if valid_593613 != nil:
    section.add "DBParameterGroupName", valid_593613
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593614: Call_PostDeleteDBParameterGroup_593601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593614.validator(path, query, header, formData, body)
  let scheme = call_593614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593614.url(scheme.get, call_593614.host, call_593614.base,
                         call_593614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593614, url, valid)

proc call*(call_593615: Call_PostDeleteDBParameterGroup_593601;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593616 = newJObject()
  var formData_593617 = newJObject()
  add(formData_593617, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593616, "Action", newJString(Action))
  add(query_593616, "Version", newJString(Version))
  result = call_593615.call(nil, query_593616, nil, formData_593617, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_593601(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_593602, base: "/",
    url: url_PostDeleteDBParameterGroup_593603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_593585 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBParameterGroup_593587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_593586(path: JsonNode; query: JsonNode;
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
  var valid_593588 = query.getOrDefault("DBParameterGroupName")
  valid_593588 = validateParameter(valid_593588, JString, required = true,
                                 default = nil)
  if valid_593588 != nil:
    section.add "DBParameterGroupName", valid_593588
  var valid_593589 = query.getOrDefault("Action")
  valid_593589 = validateParameter(valid_593589, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593589 != nil:
    section.add "Action", valid_593589
  var valid_593590 = query.getOrDefault("Version")
  valid_593590 = validateParameter(valid_593590, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593590 != nil:
    section.add "Version", valid_593590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593591 = header.getOrDefault("X-Amz-Signature")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Signature", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Content-Sha256", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Date")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Date", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-Credential")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Credential", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Security-Token")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Security-Token", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Algorithm")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Algorithm", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-SignedHeaders", valid_593597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593598: Call_GetDeleteDBParameterGroup_593585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593598.validator(path, query, header, formData, body)
  let scheme = call_593598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593598.url(scheme.get, call_593598.host, call_593598.base,
                         call_593598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593598, url, valid)

proc call*(call_593599: Call_GetDeleteDBParameterGroup_593585;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593600 = newJObject()
  add(query_593600, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593600, "Action", newJString(Action))
  add(query_593600, "Version", newJString(Version))
  result = call_593599.call(nil, query_593600, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_593585(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_593586, base: "/",
    url: url_GetDeleteDBParameterGroup_593587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_593634 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSecurityGroup_593636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_593635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593637 = query.getOrDefault("Action")
  valid_593637 = validateParameter(valid_593637, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593637 != nil:
    section.add "Action", valid_593637
  var valid_593638 = query.getOrDefault("Version")
  valid_593638 = validateParameter(valid_593638, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593638 != nil:
    section.add "Version", valid_593638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593639 = header.getOrDefault("X-Amz-Signature")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Signature", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Content-Sha256", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Date")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Date", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Credential")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Credential", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Security-Token")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Security-Token", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Algorithm")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Algorithm", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-SignedHeaders", valid_593645
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593646 = formData.getOrDefault("DBSecurityGroupName")
  valid_593646 = validateParameter(valid_593646, JString, required = true,
                                 default = nil)
  if valid_593646 != nil:
    section.add "DBSecurityGroupName", valid_593646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593647: Call_PostDeleteDBSecurityGroup_593634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593647.validator(path, query, header, formData, body)
  let scheme = call_593647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593647.url(scheme.get, call_593647.host, call_593647.base,
                         call_593647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593647, url, valid)

proc call*(call_593648: Call_PostDeleteDBSecurityGroup_593634;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593649 = newJObject()
  var formData_593650 = newJObject()
  add(formData_593650, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593649, "Action", newJString(Action))
  add(query_593649, "Version", newJString(Version))
  result = call_593648.call(nil, query_593649, nil, formData_593650, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_593634(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_593635, base: "/",
    url: url_PostDeleteDBSecurityGroup_593636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_593618 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSecurityGroup_593620(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_593619(path: JsonNode; query: JsonNode;
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
  var valid_593621 = query.getOrDefault("DBSecurityGroupName")
  valid_593621 = validateParameter(valid_593621, JString, required = true,
                                 default = nil)
  if valid_593621 != nil:
    section.add "DBSecurityGroupName", valid_593621
  var valid_593622 = query.getOrDefault("Action")
  valid_593622 = validateParameter(valid_593622, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593622 != nil:
    section.add "Action", valid_593622
  var valid_593623 = query.getOrDefault("Version")
  valid_593623 = validateParameter(valid_593623, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593623 != nil:
    section.add "Version", valid_593623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593624 = header.getOrDefault("X-Amz-Signature")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Signature", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Content-Sha256", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Date")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Date", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Credential")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Credential", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Security-Token")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Security-Token", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Algorithm")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Algorithm", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-SignedHeaders", valid_593630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_GetDeleteDBSecurityGroup_593618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_GetDeleteDBSecurityGroup_593618;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593633 = newJObject()
  add(query_593633, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593633, "Action", newJString(Action))
  add(query_593633, "Version", newJString(Version))
  result = call_593632.call(nil, query_593633, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_593618(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_593619, base: "/",
    url: url_GetDeleteDBSecurityGroup_593620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_593667 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSnapshot_593669(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_593668(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593670 = query.getOrDefault("Action")
  valid_593670 = validateParameter(valid_593670, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593670 != nil:
    section.add "Action", valid_593670
  var valid_593671 = query.getOrDefault("Version")
  valid_593671 = validateParameter(valid_593671, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593671 != nil:
    section.add "Version", valid_593671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593672 = header.getOrDefault("X-Amz-Signature")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-Signature", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Content-Sha256", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Date")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Date", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Credential")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Credential", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Security-Token")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Security-Token", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Algorithm")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Algorithm", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-SignedHeaders", valid_593678
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_593679 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593679 = validateParameter(valid_593679, JString, required = true,
                                 default = nil)
  if valid_593679 != nil:
    section.add "DBSnapshotIdentifier", valid_593679
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593680: Call_PostDeleteDBSnapshot_593667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593680.validator(path, query, header, formData, body)
  let scheme = call_593680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593680.url(scheme.get, call_593680.host, call_593680.base,
                         call_593680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593680, url, valid)

proc call*(call_593681: Call_PostDeleteDBSnapshot_593667;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593682 = newJObject()
  var formData_593683 = newJObject()
  add(formData_593683, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593682, "Action", newJString(Action))
  add(query_593682, "Version", newJString(Version))
  result = call_593681.call(nil, query_593682, nil, formData_593683, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_593667(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_593668, base: "/",
    url: url_PostDeleteDBSnapshot_593669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_593651 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSnapshot_593653(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_593652(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_593654 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593654 = validateParameter(valid_593654, JString, required = true,
                                 default = nil)
  if valid_593654 != nil:
    section.add "DBSnapshotIdentifier", valid_593654
  var valid_593655 = query.getOrDefault("Action")
  valid_593655 = validateParameter(valid_593655, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593655 != nil:
    section.add "Action", valid_593655
  var valid_593656 = query.getOrDefault("Version")
  valid_593656 = validateParameter(valid_593656, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593656 != nil:
    section.add "Version", valid_593656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593657 = header.getOrDefault("X-Amz-Signature")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Signature", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Content-Sha256", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Date")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Date", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Credential")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Credential", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593664: Call_GetDeleteDBSnapshot_593651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593664.validator(path, query, header, formData, body)
  let scheme = call_593664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593664.url(scheme.get, call_593664.host, call_593664.base,
                         call_593664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593664, url, valid)

proc call*(call_593665: Call_GetDeleteDBSnapshot_593651;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593666 = newJObject()
  add(query_593666, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593666, "Action", newJString(Action))
  add(query_593666, "Version", newJString(Version))
  result = call_593665.call(nil, query_593666, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_593651(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_593652, base: "/",
    url: url_GetDeleteDBSnapshot_593653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_593700 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSubnetGroup_593702(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_593701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593703 = query.getOrDefault("Action")
  valid_593703 = validateParameter(valid_593703, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593703 != nil:
    section.add "Action", valid_593703
  var valid_593704 = query.getOrDefault("Version")
  valid_593704 = validateParameter(valid_593704, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593704 != nil:
    section.add "Version", valid_593704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593705 = header.getOrDefault("X-Amz-Signature")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Signature", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Content-Sha256", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Date")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Date", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Credential")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Credential", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Security-Token")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Security-Token", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Algorithm")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Algorithm", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-SignedHeaders", valid_593711
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_593712 = formData.getOrDefault("DBSubnetGroupName")
  valid_593712 = validateParameter(valid_593712, JString, required = true,
                                 default = nil)
  if valid_593712 != nil:
    section.add "DBSubnetGroupName", valid_593712
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593713: Call_PostDeleteDBSubnetGroup_593700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593713.validator(path, query, header, formData, body)
  let scheme = call_593713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593713.url(scheme.get, call_593713.host, call_593713.base,
                         call_593713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593713, url, valid)

proc call*(call_593714: Call_PostDeleteDBSubnetGroup_593700;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593715 = newJObject()
  var formData_593716 = newJObject()
  add(query_593715, "Action", newJString(Action))
  add(formData_593716, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593715, "Version", newJString(Version))
  result = call_593714.call(nil, query_593715, nil, formData_593716, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_593700(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_593701, base: "/",
    url: url_PostDeleteDBSubnetGroup_593702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_593684 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSubnetGroup_593686(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_593685(path: JsonNode; query: JsonNode;
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
  var valid_593687 = query.getOrDefault("Action")
  valid_593687 = validateParameter(valid_593687, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593687 != nil:
    section.add "Action", valid_593687
  var valid_593688 = query.getOrDefault("DBSubnetGroupName")
  valid_593688 = validateParameter(valid_593688, JString, required = true,
                                 default = nil)
  if valid_593688 != nil:
    section.add "DBSubnetGroupName", valid_593688
  var valid_593689 = query.getOrDefault("Version")
  valid_593689 = validateParameter(valid_593689, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593689 != nil:
    section.add "Version", valid_593689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593690 = header.getOrDefault("X-Amz-Signature")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Signature", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Content-Sha256", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Date")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Date", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Credential")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Credential", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Security-Token")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Security-Token", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Algorithm")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Algorithm", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-SignedHeaders", valid_593696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593697: Call_GetDeleteDBSubnetGroup_593684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593697.validator(path, query, header, formData, body)
  let scheme = call_593697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593697.url(scheme.get, call_593697.host, call_593697.base,
                         call_593697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593697, url, valid)

proc call*(call_593698: Call_GetDeleteDBSubnetGroup_593684;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593699 = newJObject()
  add(query_593699, "Action", newJString(Action))
  add(query_593699, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593699, "Version", newJString(Version))
  result = call_593698.call(nil, query_593699, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_593684(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_593685, base: "/",
    url: url_GetDeleteDBSubnetGroup_593686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_593733 = ref object of OpenApiRestCall_592348
proc url_PostDeleteEventSubscription_593735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_593734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593736 = query.getOrDefault("Action")
  valid_593736 = validateParameter(valid_593736, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593736 != nil:
    section.add "Action", valid_593736
  var valid_593737 = query.getOrDefault("Version")
  valid_593737 = validateParameter(valid_593737, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593737 != nil:
    section.add "Version", valid_593737
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593738 = header.getOrDefault("X-Amz-Signature")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Signature", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Content-Sha256", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Date")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Date", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-Credential")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Credential", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Security-Token")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Security-Token", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-Algorithm")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Algorithm", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-SignedHeaders", valid_593744
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_593745 = formData.getOrDefault("SubscriptionName")
  valid_593745 = validateParameter(valid_593745, JString, required = true,
                                 default = nil)
  if valid_593745 != nil:
    section.add "SubscriptionName", valid_593745
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593746: Call_PostDeleteEventSubscription_593733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593746.validator(path, query, header, formData, body)
  let scheme = call_593746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593746.url(scheme.get, call_593746.host, call_593746.base,
                         call_593746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593746, url, valid)

proc call*(call_593747: Call_PostDeleteEventSubscription_593733;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593748 = newJObject()
  var formData_593749 = newJObject()
  add(formData_593749, "SubscriptionName", newJString(SubscriptionName))
  add(query_593748, "Action", newJString(Action))
  add(query_593748, "Version", newJString(Version))
  result = call_593747.call(nil, query_593748, nil, formData_593749, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_593733(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_593734, base: "/",
    url: url_PostDeleteEventSubscription_593735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_593717 = ref object of OpenApiRestCall_592348
proc url_GetDeleteEventSubscription_593719(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_593718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_593720 = query.getOrDefault("SubscriptionName")
  valid_593720 = validateParameter(valid_593720, JString, required = true,
                                 default = nil)
  if valid_593720 != nil:
    section.add "SubscriptionName", valid_593720
  var valid_593721 = query.getOrDefault("Action")
  valid_593721 = validateParameter(valid_593721, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593721 != nil:
    section.add "Action", valid_593721
  var valid_593722 = query.getOrDefault("Version")
  valid_593722 = validateParameter(valid_593722, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593722 != nil:
    section.add "Version", valid_593722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593723 = header.getOrDefault("X-Amz-Signature")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Signature", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Content-Sha256", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Date")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Date", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Credential")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Credential", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Security-Token")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Security-Token", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Algorithm")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Algorithm", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-SignedHeaders", valid_593729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593730: Call_GetDeleteEventSubscription_593717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593730.validator(path, query, header, formData, body)
  let scheme = call_593730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593730.url(scheme.get, call_593730.host, call_593730.base,
                         call_593730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593730, url, valid)

proc call*(call_593731: Call_GetDeleteEventSubscription_593717;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593732 = newJObject()
  add(query_593732, "SubscriptionName", newJString(SubscriptionName))
  add(query_593732, "Action", newJString(Action))
  add(query_593732, "Version", newJString(Version))
  result = call_593731.call(nil, query_593732, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_593717(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_593718, base: "/",
    url: url_GetDeleteEventSubscription_593719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_593766 = ref object of OpenApiRestCall_592348
proc url_PostDeleteOptionGroup_593768(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_593767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593769 = query.getOrDefault("Action")
  valid_593769 = validateParameter(valid_593769, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593769 != nil:
    section.add "Action", valid_593769
  var valid_593770 = query.getOrDefault("Version")
  valid_593770 = validateParameter(valid_593770, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593770 != nil:
    section.add "Version", valid_593770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593771 = header.getOrDefault("X-Amz-Signature")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Signature", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Content-Sha256", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Date")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Date", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Credential")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Credential", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Security-Token")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Security-Token", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Algorithm")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Algorithm", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-SignedHeaders", valid_593777
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_593778 = formData.getOrDefault("OptionGroupName")
  valid_593778 = validateParameter(valid_593778, JString, required = true,
                                 default = nil)
  if valid_593778 != nil:
    section.add "OptionGroupName", valid_593778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593779: Call_PostDeleteOptionGroup_593766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593779.validator(path, query, header, formData, body)
  let scheme = call_593779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593779.url(scheme.get, call_593779.host, call_593779.base,
                         call_593779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593779, url, valid)

proc call*(call_593780: Call_PostDeleteOptionGroup_593766; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593781 = newJObject()
  var formData_593782 = newJObject()
  add(query_593781, "Action", newJString(Action))
  add(formData_593782, "OptionGroupName", newJString(OptionGroupName))
  add(query_593781, "Version", newJString(Version))
  result = call_593780.call(nil, query_593781, nil, formData_593782, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_593766(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_593767, base: "/",
    url: url_PostDeleteOptionGroup_593768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_593750 = ref object of OpenApiRestCall_592348
proc url_GetDeleteOptionGroup_593752(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_593751(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593753 = query.getOrDefault("Action")
  valid_593753 = validateParameter(valid_593753, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593753 != nil:
    section.add "Action", valid_593753
  var valid_593754 = query.getOrDefault("OptionGroupName")
  valid_593754 = validateParameter(valid_593754, JString, required = true,
                                 default = nil)
  if valid_593754 != nil:
    section.add "OptionGroupName", valid_593754
  var valid_593755 = query.getOrDefault("Version")
  valid_593755 = validateParameter(valid_593755, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593755 != nil:
    section.add "Version", valid_593755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593756 = header.getOrDefault("X-Amz-Signature")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Signature", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Content-Sha256", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Date")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Date", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Credential")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Credential", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Security-Token")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Security-Token", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Algorithm")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Algorithm", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-SignedHeaders", valid_593762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593763: Call_GetDeleteOptionGroup_593750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593763.validator(path, query, header, formData, body)
  let scheme = call_593763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593763.url(scheme.get, call_593763.host, call_593763.base,
                         call_593763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593763, url, valid)

proc call*(call_593764: Call_GetDeleteOptionGroup_593750; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593765 = newJObject()
  add(query_593765, "Action", newJString(Action))
  add(query_593765, "OptionGroupName", newJString(OptionGroupName))
  add(query_593765, "Version", newJString(Version))
  result = call_593764.call(nil, query_593765, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_593750(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_593751, base: "/",
    url: url_GetDeleteOptionGroup_593752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_593806 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBEngineVersions_593808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_593807(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593809 = query.getOrDefault("Action")
  valid_593809 = validateParameter(valid_593809, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593809 != nil:
    section.add "Action", valid_593809
  var valid_593810 = query.getOrDefault("Version")
  valid_593810 = validateParameter(valid_593810, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593810 != nil:
    section.add "Version", valid_593810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593811 = header.getOrDefault("X-Amz-Signature")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Signature", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Content-Sha256", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Date")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Date", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Credential")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Credential", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Security-Token")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Security-Token", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-Algorithm")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-Algorithm", valid_593816
  var valid_593817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-SignedHeaders", valid_593817
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_593818 = formData.getOrDefault("DefaultOnly")
  valid_593818 = validateParameter(valid_593818, JBool, required = false, default = nil)
  if valid_593818 != nil:
    section.add "DefaultOnly", valid_593818
  var valid_593819 = formData.getOrDefault("MaxRecords")
  valid_593819 = validateParameter(valid_593819, JInt, required = false, default = nil)
  if valid_593819 != nil:
    section.add "MaxRecords", valid_593819
  var valid_593820 = formData.getOrDefault("EngineVersion")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "EngineVersion", valid_593820
  var valid_593821 = formData.getOrDefault("Marker")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "Marker", valid_593821
  var valid_593822 = formData.getOrDefault("Engine")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "Engine", valid_593822
  var valid_593823 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_593823 = validateParameter(valid_593823, JBool, required = false, default = nil)
  if valid_593823 != nil:
    section.add "ListSupportedCharacterSets", valid_593823
  var valid_593824 = formData.getOrDefault("Filters")
  valid_593824 = validateParameter(valid_593824, JArray, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "Filters", valid_593824
  var valid_593825 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "DBParameterGroupFamily", valid_593825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593826: Call_PostDescribeDBEngineVersions_593806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593826.validator(path, query, header, formData, body)
  let scheme = call_593826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593826.url(scheme.get, call_593826.host, call_593826.base,
                         call_593826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593826, url, valid)

proc call*(call_593827: Call_PostDescribeDBEngineVersions_593806;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_593828 = newJObject()
  var formData_593829 = newJObject()
  add(formData_593829, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_593829, "MaxRecords", newJInt(MaxRecords))
  add(formData_593829, "EngineVersion", newJString(EngineVersion))
  add(formData_593829, "Marker", newJString(Marker))
  add(formData_593829, "Engine", newJString(Engine))
  add(formData_593829, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593828, "Action", newJString(Action))
  if Filters != nil:
    formData_593829.add "Filters", Filters
  add(query_593828, "Version", newJString(Version))
  add(formData_593829, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593827.call(nil, query_593828, nil, formData_593829, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_593806(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_593807, base: "/",
    url: url_PostDescribeDBEngineVersions_593808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_593783 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBEngineVersions_593785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_593784(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   Engine: JString
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   ListSupportedCharacterSets: JBool
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_593786 = query.getOrDefault("Marker")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "Marker", valid_593786
  var valid_593787 = query.getOrDefault("DBParameterGroupFamily")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "DBParameterGroupFamily", valid_593787
  var valid_593788 = query.getOrDefault("Engine")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "Engine", valid_593788
  var valid_593789 = query.getOrDefault("EngineVersion")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "EngineVersion", valid_593789
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593790 = query.getOrDefault("Action")
  valid_593790 = validateParameter(valid_593790, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593790 != nil:
    section.add "Action", valid_593790
  var valid_593791 = query.getOrDefault("ListSupportedCharacterSets")
  valid_593791 = validateParameter(valid_593791, JBool, required = false, default = nil)
  if valid_593791 != nil:
    section.add "ListSupportedCharacterSets", valid_593791
  var valid_593792 = query.getOrDefault("Version")
  valid_593792 = validateParameter(valid_593792, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593792 != nil:
    section.add "Version", valid_593792
  var valid_593793 = query.getOrDefault("Filters")
  valid_593793 = validateParameter(valid_593793, JArray, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "Filters", valid_593793
  var valid_593794 = query.getOrDefault("MaxRecords")
  valid_593794 = validateParameter(valid_593794, JInt, required = false, default = nil)
  if valid_593794 != nil:
    section.add "MaxRecords", valid_593794
  var valid_593795 = query.getOrDefault("DefaultOnly")
  valid_593795 = validateParameter(valid_593795, JBool, required = false, default = nil)
  if valid_593795 != nil:
    section.add "DefaultOnly", valid_593795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593796 = header.getOrDefault("X-Amz-Signature")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Signature", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Content-Sha256", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Date")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Date", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Credential")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Credential", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Security-Token")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Security-Token", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-Algorithm")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-Algorithm", valid_593801
  var valid_593802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593802 = validateParameter(valid_593802, JString, required = false,
                                 default = nil)
  if valid_593802 != nil:
    section.add "X-Amz-SignedHeaders", valid_593802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593803: Call_GetDescribeDBEngineVersions_593783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593803.validator(path, query, header, formData, body)
  let scheme = call_593803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593803.url(scheme.get, call_593803.host, call_593803.base,
                         call_593803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593803, url, valid)

proc call*(call_593804: Call_GetDescribeDBEngineVersions_593783;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2014-09-01";
          Filters: JsonNode = nil; MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_593805 = newJObject()
  add(query_593805, "Marker", newJString(Marker))
  add(query_593805, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593805, "Engine", newJString(Engine))
  add(query_593805, "EngineVersion", newJString(EngineVersion))
  add(query_593805, "Action", newJString(Action))
  add(query_593805, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593805, "Version", newJString(Version))
  if Filters != nil:
    query_593805.add "Filters", Filters
  add(query_593805, "MaxRecords", newJInt(MaxRecords))
  add(query_593805, "DefaultOnly", newJBool(DefaultOnly))
  result = call_593804.call(nil, query_593805, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_593783(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_593784, base: "/",
    url: url_GetDescribeDBEngineVersions_593785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_593849 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBInstances_593851(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_593850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593852 = query.getOrDefault("Action")
  valid_593852 = validateParameter(valid_593852, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593852 != nil:
    section.add "Action", valid_593852
  var valid_593853 = query.getOrDefault("Version")
  valid_593853 = validateParameter(valid_593853, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593853 != nil:
    section.add "Version", valid_593853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593854 = header.getOrDefault("X-Amz-Signature")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Signature", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Content-Sha256", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Date")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Date", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Credential")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Credential", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Security-Token")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Security-Token", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Algorithm")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Algorithm", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-SignedHeaders", valid_593860
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593861 = formData.getOrDefault("MaxRecords")
  valid_593861 = validateParameter(valid_593861, JInt, required = false, default = nil)
  if valid_593861 != nil:
    section.add "MaxRecords", valid_593861
  var valid_593862 = formData.getOrDefault("Marker")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "Marker", valid_593862
  var valid_593863 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "DBInstanceIdentifier", valid_593863
  var valid_593864 = formData.getOrDefault("Filters")
  valid_593864 = validateParameter(valid_593864, JArray, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "Filters", valid_593864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593865: Call_PostDescribeDBInstances_593849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593865.validator(path, query, header, formData, body)
  let scheme = call_593865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593865.url(scheme.get, call_593865.host, call_593865.base,
                         call_593865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593865, url, valid)

proc call*(call_593866: Call_PostDescribeDBInstances_593849; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593867 = newJObject()
  var formData_593868 = newJObject()
  add(formData_593868, "MaxRecords", newJInt(MaxRecords))
  add(formData_593868, "Marker", newJString(Marker))
  add(formData_593868, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593867, "Action", newJString(Action))
  if Filters != nil:
    formData_593868.add "Filters", Filters
  add(query_593867, "Version", newJString(Version))
  result = call_593866.call(nil, query_593867, nil, formData_593868, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_593849(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_593850, base: "/",
    url: url_PostDescribeDBInstances_593851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_593830 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBInstances_593832(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_593831(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593833 = query.getOrDefault("Marker")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "Marker", valid_593833
  var valid_593834 = query.getOrDefault("DBInstanceIdentifier")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "DBInstanceIdentifier", valid_593834
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593835 = query.getOrDefault("Action")
  valid_593835 = validateParameter(valid_593835, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593835 != nil:
    section.add "Action", valid_593835
  var valid_593836 = query.getOrDefault("Version")
  valid_593836 = validateParameter(valid_593836, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593836 != nil:
    section.add "Version", valid_593836
  var valid_593837 = query.getOrDefault("Filters")
  valid_593837 = validateParameter(valid_593837, JArray, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "Filters", valid_593837
  var valid_593838 = query.getOrDefault("MaxRecords")
  valid_593838 = validateParameter(valid_593838, JInt, required = false, default = nil)
  if valid_593838 != nil:
    section.add "MaxRecords", valid_593838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593839 = header.getOrDefault("X-Amz-Signature")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Signature", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Content-Sha256", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Date")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Date", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Credential")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Credential", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-Security-Token")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Security-Token", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Algorithm")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Algorithm", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-SignedHeaders", valid_593845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593846: Call_GetDescribeDBInstances_593830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593846.validator(path, query, header, formData, body)
  let scheme = call_593846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593846.url(scheme.get, call_593846.host, call_593846.base,
                         call_593846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593846, url, valid)

proc call*(call_593847: Call_GetDescribeDBInstances_593830; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593848 = newJObject()
  add(query_593848, "Marker", newJString(Marker))
  add(query_593848, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593848, "Action", newJString(Action))
  add(query_593848, "Version", newJString(Version))
  if Filters != nil:
    query_593848.add "Filters", Filters
  add(query_593848, "MaxRecords", newJInt(MaxRecords))
  result = call_593847.call(nil, query_593848, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_593830(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_593831, base: "/",
    url: url_GetDescribeDBInstances_593832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_593891 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBLogFiles_593893(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_593892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593894 = query.getOrDefault("Action")
  valid_593894 = validateParameter(valid_593894, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593894 != nil:
    section.add "Action", valid_593894
  var valid_593895 = query.getOrDefault("Version")
  valid_593895 = validateParameter(valid_593895, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593895 != nil:
    section.add "Version", valid_593895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593896 = header.getOrDefault("X-Amz-Signature")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Signature", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Content-Sha256", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-Date")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-Date", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Credential")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Credential", valid_593899
  var valid_593900 = header.getOrDefault("X-Amz-Security-Token")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "X-Amz-Security-Token", valid_593900
  var valid_593901 = header.getOrDefault("X-Amz-Algorithm")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Algorithm", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-SignedHeaders", valid_593902
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   Filters: JArray
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_593903 = formData.getOrDefault("FileSize")
  valid_593903 = validateParameter(valid_593903, JInt, required = false, default = nil)
  if valid_593903 != nil:
    section.add "FileSize", valid_593903
  var valid_593904 = formData.getOrDefault("MaxRecords")
  valid_593904 = validateParameter(valid_593904, JInt, required = false, default = nil)
  if valid_593904 != nil:
    section.add "MaxRecords", valid_593904
  var valid_593905 = formData.getOrDefault("Marker")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "Marker", valid_593905
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593906 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593906 = validateParameter(valid_593906, JString, required = true,
                                 default = nil)
  if valid_593906 != nil:
    section.add "DBInstanceIdentifier", valid_593906
  var valid_593907 = formData.getOrDefault("FilenameContains")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "FilenameContains", valid_593907
  var valid_593908 = formData.getOrDefault("Filters")
  valid_593908 = validateParameter(valid_593908, JArray, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "Filters", valid_593908
  var valid_593909 = formData.getOrDefault("FileLastWritten")
  valid_593909 = validateParameter(valid_593909, JInt, required = false, default = nil)
  if valid_593909 != nil:
    section.add "FileLastWritten", valid_593909
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593910: Call_PostDescribeDBLogFiles_593891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593910.validator(path, query, header, formData, body)
  let scheme = call_593910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593910.url(scheme.get, call_593910.host, call_593910.base,
                         call_593910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593910, url, valid)

proc call*(call_593911: Call_PostDescribeDBLogFiles_593891;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; FileLastWritten: int = 0): Recallable =
  ## postDescribeDBLogFiles
  ##   FileSize: int
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FilenameContains: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   FileLastWritten: int
  var query_593912 = newJObject()
  var formData_593913 = newJObject()
  add(formData_593913, "FileSize", newJInt(FileSize))
  add(formData_593913, "MaxRecords", newJInt(MaxRecords))
  add(formData_593913, "Marker", newJString(Marker))
  add(formData_593913, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593913, "FilenameContains", newJString(FilenameContains))
  add(query_593912, "Action", newJString(Action))
  if Filters != nil:
    formData_593913.add "Filters", Filters
  add(query_593912, "Version", newJString(Version))
  add(formData_593913, "FileLastWritten", newJInt(FileLastWritten))
  result = call_593911.call(nil, query_593912, nil, formData_593913, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_593891(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_593892, base: "/",
    url: url_PostDescribeDBLogFiles_593893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_593869 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBLogFiles_593871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_593870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileLastWritten: JInt
  ##   Action: JString (required)
  ##   FilenameContains: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_593872 = query.getOrDefault("Marker")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "Marker", valid_593872
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593873 = query.getOrDefault("DBInstanceIdentifier")
  valid_593873 = validateParameter(valid_593873, JString, required = true,
                                 default = nil)
  if valid_593873 != nil:
    section.add "DBInstanceIdentifier", valid_593873
  var valid_593874 = query.getOrDefault("FileLastWritten")
  valid_593874 = validateParameter(valid_593874, JInt, required = false, default = nil)
  if valid_593874 != nil:
    section.add "FileLastWritten", valid_593874
  var valid_593875 = query.getOrDefault("Action")
  valid_593875 = validateParameter(valid_593875, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593875 != nil:
    section.add "Action", valid_593875
  var valid_593876 = query.getOrDefault("FilenameContains")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "FilenameContains", valid_593876
  var valid_593877 = query.getOrDefault("Version")
  valid_593877 = validateParameter(valid_593877, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593877 != nil:
    section.add "Version", valid_593877
  var valid_593878 = query.getOrDefault("Filters")
  valid_593878 = validateParameter(valid_593878, JArray, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "Filters", valid_593878
  var valid_593879 = query.getOrDefault("MaxRecords")
  valid_593879 = validateParameter(valid_593879, JInt, required = false, default = nil)
  if valid_593879 != nil:
    section.add "MaxRecords", valid_593879
  var valid_593880 = query.getOrDefault("FileSize")
  valid_593880 = validateParameter(valid_593880, JInt, required = false, default = nil)
  if valid_593880 != nil:
    section.add "FileSize", valid_593880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593881 = header.getOrDefault("X-Amz-Signature")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Signature", valid_593881
  var valid_593882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-Content-Sha256", valid_593882
  var valid_593883 = header.getOrDefault("X-Amz-Date")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Date", valid_593883
  var valid_593884 = header.getOrDefault("X-Amz-Credential")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Credential", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Security-Token")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Security-Token", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Algorithm")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Algorithm", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-SignedHeaders", valid_593887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593888: Call_GetDescribeDBLogFiles_593869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593888.validator(path, query, header, formData, body)
  let scheme = call_593888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593888.url(scheme.get, call_593888.host, call_593888.base,
                         call_593888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593888, url, valid)

proc call*(call_593889: Call_GetDescribeDBLogFiles_593869;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
          FileSize: int = 0): Recallable =
  ## getDescribeDBLogFiles
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileLastWritten: int
  ##   Action: string (required)
  ##   FilenameContains: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   FileSize: int
  var query_593890 = newJObject()
  add(query_593890, "Marker", newJString(Marker))
  add(query_593890, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593890, "FileLastWritten", newJInt(FileLastWritten))
  add(query_593890, "Action", newJString(Action))
  add(query_593890, "FilenameContains", newJString(FilenameContains))
  add(query_593890, "Version", newJString(Version))
  if Filters != nil:
    query_593890.add "Filters", Filters
  add(query_593890, "MaxRecords", newJInt(MaxRecords))
  add(query_593890, "FileSize", newJInt(FileSize))
  result = call_593889.call(nil, query_593890, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_593869(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_593870, base: "/",
    url: url_GetDescribeDBLogFiles_593871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_593933 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameterGroups_593935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_593934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593936 = query.getOrDefault("Action")
  valid_593936 = validateParameter(valid_593936, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593936 != nil:
    section.add "Action", valid_593936
  var valid_593937 = query.getOrDefault("Version")
  valid_593937 = validateParameter(valid_593937, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593937 != nil:
    section.add "Version", valid_593937
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593938 = header.getOrDefault("X-Amz-Signature")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Signature", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Content-Sha256", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-Date")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Date", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-Credential")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Credential", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-Security-Token")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-Security-Token", valid_593942
  var valid_593943 = header.getOrDefault("X-Amz-Algorithm")
  valid_593943 = validateParameter(valid_593943, JString, required = false,
                                 default = nil)
  if valid_593943 != nil:
    section.add "X-Amz-Algorithm", valid_593943
  var valid_593944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "X-Amz-SignedHeaders", valid_593944
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593945 = formData.getOrDefault("MaxRecords")
  valid_593945 = validateParameter(valid_593945, JInt, required = false, default = nil)
  if valid_593945 != nil:
    section.add "MaxRecords", valid_593945
  var valid_593946 = formData.getOrDefault("DBParameterGroupName")
  valid_593946 = validateParameter(valid_593946, JString, required = false,
                                 default = nil)
  if valid_593946 != nil:
    section.add "DBParameterGroupName", valid_593946
  var valid_593947 = formData.getOrDefault("Marker")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "Marker", valid_593947
  var valid_593948 = formData.getOrDefault("Filters")
  valid_593948 = validateParameter(valid_593948, JArray, required = false,
                                 default = nil)
  if valid_593948 != nil:
    section.add "Filters", valid_593948
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593949: Call_PostDescribeDBParameterGroups_593933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593949.validator(path, query, header, formData, body)
  let scheme = call_593949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593949.url(scheme.get, call_593949.host, call_593949.base,
                         call_593949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593949, url, valid)

proc call*(call_593950: Call_PostDescribeDBParameterGroups_593933;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593951 = newJObject()
  var formData_593952 = newJObject()
  add(formData_593952, "MaxRecords", newJInt(MaxRecords))
  add(formData_593952, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593952, "Marker", newJString(Marker))
  add(query_593951, "Action", newJString(Action))
  if Filters != nil:
    formData_593952.add "Filters", Filters
  add(query_593951, "Version", newJString(Version))
  result = call_593950.call(nil, query_593951, nil, formData_593952, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_593933(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_593934, base: "/",
    url: url_PostDescribeDBParameterGroups_593935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_593914 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameterGroups_593916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_593915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593917 = query.getOrDefault("Marker")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "Marker", valid_593917
  var valid_593918 = query.getOrDefault("DBParameterGroupName")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "DBParameterGroupName", valid_593918
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593919 = query.getOrDefault("Action")
  valid_593919 = validateParameter(valid_593919, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593919 != nil:
    section.add "Action", valid_593919
  var valid_593920 = query.getOrDefault("Version")
  valid_593920 = validateParameter(valid_593920, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593920 != nil:
    section.add "Version", valid_593920
  var valid_593921 = query.getOrDefault("Filters")
  valid_593921 = validateParameter(valid_593921, JArray, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "Filters", valid_593921
  var valid_593922 = query.getOrDefault("MaxRecords")
  valid_593922 = validateParameter(valid_593922, JInt, required = false, default = nil)
  if valid_593922 != nil:
    section.add "MaxRecords", valid_593922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593923 = header.getOrDefault("X-Amz-Signature")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Signature", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Content-Sha256", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Date")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Date", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Credential")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Credential", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-Security-Token")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Security-Token", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-Algorithm")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-Algorithm", valid_593928
  var valid_593929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-SignedHeaders", valid_593929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593930: Call_GetDescribeDBParameterGroups_593914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593930.validator(path, query, header, formData, body)
  let scheme = call_593930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593930.url(scheme.get, call_593930.host, call_593930.base,
                         call_593930.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593930, url, valid)

proc call*(call_593931: Call_GetDescribeDBParameterGroups_593914;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593932 = newJObject()
  add(query_593932, "Marker", newJString(Marker))
  add(query_593932, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593932, "Action", newJString(Action))
  add(query_593932, "Version", newJString(Version))
  if Filters != nil:
    query_593932.add "Filters", Filters
  add(query_593932, "MaxRecords", newJInt(MaxRecords))
  result = call_593931.call(nil, query_593932, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_593914(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_593915, base: "/",
    url: url_GetDescribeDBParameterGroups_593916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_593973 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameters_593975(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_593974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593976 = query.getOrDefault("Action")
  valid_593976 = validateParameter(valid_593976, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593976 != nil:
    section.add "Action", valid_593976
  var valid_593977 = query.getOrDefault("Version")
  valid_593977 = validateParameter(valid_593977, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593977 != nil:
    section.add "Version", valid_593977
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593978 = header.getOrDefault("X-Amz-Signature")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-Signature", valid_593978
  var valid_593979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-Content-Sha256", valid_593979
  var valid_593980 = header.getOrDefault("X-Amz-Date")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "X-Amz-Date", valid_593980
  var valid_593981 = header.getOrDefault("X-Amz-Credential")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "X-Amz-Credential", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-Security-Token")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-Security-Token", valid_593982
  var valid_593983 = header.getOrDefault("X-Amz-Algorithm")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "X-Amz-Algorithm", valid_593983
  var valid_593984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-SignedHeaders", valid_593984
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593985 = formData.getOrDefault("Source")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "Source", valid_593985
  var valid_593986 = formData.getOrDefault("MaxRecords")
  valid_593986 = validateParameter(valid_593986, JInt, required = false, default = nil)
  if valid_593986 != nil:
    section.add "MaxRecords", valid_593986
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593987 = formData.getOrDefault("DBParameterGroupName")
  valid_593987 = validateParameter(valid_593987, JString, required = true,
                                 default = nil)
  if valid_593987 != nil:
    section.add "DBParameterGroupName", valid_593987
  var valid_593988 = formData.getOrDefault("Marker")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "Marker", valid_593988
  var valid_593989 = formData.getOrDefault("Filters")
  valid_593989 = validateParameter(valid_593989, JArray, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "Filters", valid_593989
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593990: Call_PostDescribeDBParameters_593973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593990.validator(path, query, header, formData, body)
  let scheme = call_593990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593990.url(scheme.get, call_593990.host, call_593990.base,
                         call_593990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593990, url, valid)

proc call*(call_593991: Call_PostDescribeDBParameters_593973;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593992 = newJObject()
  var formData_593993 = newJObject()
  add(formData_593993, "Source", newJString(Source))
  add(formData_593993, "MaxRecords", newJInt(MaxRecords))
  add(formData_593993, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593993, "Marker", newJString(Marker))
  add(query_593992, "Action", newJString(Action))
  if Filters != nil:
    formData_593993.add "Filters", Filters
  add(query_593992, "Version", newJString(Version))
  result = call_593991.call(nil, query_593992, nil, formData_593993, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_593973(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_593974, base: "/",
    url: url_PostDescribeDBParameters_593975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_593953 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameters_593955(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_593954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   Source: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593956 = query.getOrDefault("Marker")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "Marker", valid_593956
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_593957 = query.getOrDefault("DBParameterGroupName")
  valid_593957 = validateParameter(valid_593957, JString, required = true,
                                 default = nil)
  if valid_593957 != nil:
    section.add "DBParameterGroupName", valid_593957
  var valid_593958 = query.getOrDefault("Source")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "Source", valid_593958
  var valid_593959 = query.getOrDefault("Action")
  valid_593959 = validateParameter(valid_593959, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593959 != nil:
    section.add "Action", valid_593959
  var valid_593960 = query.getOrDefault("Version")
  valid_593960 = validateParameter(valid_593960, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_593960 != nil:
    section.add "Version", valid_593960
  var valid_593961 = query.getOrDefault("Filters")
  valid_593961 = validateParameter(valid_593961, JArray, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "Filters", valid_593961
  var valid_593962 = query.getOrDefault("MaxRecords")
  valid_593962 = validateParameter(valid_593962, JInt, required = false, default = nil)
  if valid_593962 != nil:
    section.add "MaxRecords", valid_593962
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593963 = header.getOrDefault("X-Amz-Signature")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-Signature", valid_593963
  var valid_593964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-Content-Sha256", valid_593964
  var valid_593965 = header.getOrDefault("X-Amz-Date")
  valid_593965 = validateParameter(valid_593965, JString, required = false,
                                 default = nil)
  if valid_593965 != nil:
    section.add "X-Amz-Date", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Credential")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Credential", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Security-Token")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Security-Token", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Algorithm")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Algorithm", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-SignedHeaders", valid_593969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593970: Call_GetDescribeDBParameters_593953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593970.validator(path, query, header, formData, body)
  let scheme = call_593970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593970.url(scheme.get, call_593970.host, call_593970.base,
                         call_593970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593970, url, valid)

proc call*(call_593971: Call_GetDescribeDBParameters_593953;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2014-09-01";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593972 = newJObject()
  add(query_593972, "Marker", newJString(Marker))
  add(query_593972, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593972, "Source", newJString(Source))
  add(query_593972, "Action", newJString(Action))
  add(query_593972, "Version", newJString(Version))
  if Filters != nil:
    query_593972.add "Filters", Filters
  add(query_593972, "MaxRecords", newJInt(MaxRecords))
  result = call_593971.call(nil, query_593972, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_593953(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_593954, base: "/",
    url: url_GetDescribeDBParameters_593955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_594013 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSecurityGroups_594015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_594014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594016 = query.getOrDefault("Action")
  valid_594016 = validateParameter(valid_594016, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594016 != nil:
    section.add "Action", valid_594016
  var valid_594017 = query.getOrDefault("Version")
  valid_594017 = validateParameter(valid_594017, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594017 != nil:
    section.add "Version", valid_594017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594018 = header.getOrDefault("X-Amz-Signature")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Signature", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Content-Sha256", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Date")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Date", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Credential")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Credential", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Security-Token")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Security-Token", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Algorithm")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Algorithm", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-SignedHeaders", valid_594024
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594025 = formData.getOrDefault("DBSecurityGroupName")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "DBSecurityGroupName", valid_594025
  var valid_594026 = formData.getOrDefault("MaxRecords")
  valid_594026 = validateParameter(valid_594026, JInt, required = false, default = nil)
  if valid_594026 != nil:
    section.add "MaxRecords", valid_594026
  var valid_594027 = formData.getOrDefault("Marker")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "Marker", valid_594027
  var valid_594028 = formData.getOrDefault("Filters")
  valid_594028 = validateParameter(valid_594028, JArray, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "Filters", valid_594028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594029: Call_PostDescribeDBSecurityGroups_594013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594029.validator(path, query, header, formData, body)
  let scheme = call_594029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594029.url(scheme.get, call_594029.host, call_594029.base,
                         call_594029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594029, url, valid)

proc call*(call_594030: Call_PostDescribeDBSecurityGroups_594013;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594031 = newJObject()
  var formData_594032 = newJObject()
  add(formData_594032, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_594032, "MaxRecords", newJInt(MaxRecords))
  add(formData_594032, "Marker", newJString(Marker))
  add(query_594031, "Action", newJString(Action))
  if Filters != nil:
    formData_594032.add "Filters", Filters
  add(query_594031, "Version", newJString(Version))
  result = call_594030.call(nil, query_594031, nil, formData_594032, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_594013(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_594014, base: "/",
    url: url_PostDescribeDBSecurityGroups_594015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_593994 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSecurityGroups_593996(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_593995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593997 = query.getOrDefault("Marker")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "Marker", valid_593997
  var valid_593998 = query.getOrDefault("DBSecurityGroupName")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "DBSecurityGroupName", valid_593998
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593999 = query.getOrDefault("Action")
  valid_593999 = validateParameter(valid_593999, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593999 != nil:
    section.add "Action", valid_593999
  var valid_594000 = query.getOrDefault("Version")
  valid_594000 = validateParameter(valid_594000, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594000 != nil:
    section.add "Version", valid_594000
  var valid_594001 = query.getOrDefault("Filters")
  valid_594001 = validateParameter(valid_594001, JArray, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "Filters", valid_594001
  var valid_594002 = query.getOrDefault("MaxRecords")
  valid_594002 = validateParameter(valid_594002, JInt, required = false, default = nil)
  if valid_594002 != nil:
    section.add "MaxRecords", valid_594002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594003 = header.getOrDefault("X-Amz-Signature")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Signature", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Content-Sha256", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Date")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Date", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Credential")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Credential", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Security-Token")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Security-Token", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Algorithm")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Algorithm", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-SignedHeaders", valid_594009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594010: Call_GetDescribeDBSecurityGroups_593994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594010.validator(path, query, header, formData, body)
  let scheme = call_594010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594010.url(scheme.get, call_594010.host, call_594010.base,
                         call_594010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594010, url, valid)

proc call*(call_594011: Call_GetDescribeDBSecurityGroups_593994;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594012 = newJObject()
  add(query_594012, "Marker", newJString(Marker))
  add(query_594012, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594012, "Action", newJString(Action))
  add(query_594012, "Version", newJString(Version))
  if Filters != nil:
    query_594012.add "Filters", Filters
  add(query_594012, "MaxRecords", newJInt(MaxRecords))
  result = call_594011.call(nil, query_594012, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_593994(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_593995, base: "/",
    url: url_GetDescribeDBSecurityGroups_593996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_594054 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSnapshots_594056(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_594055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594057 = query.getOrDefault("Action")
  valid_594057 = validateParameter(valid_594057, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_594057 != nil:
    section.add "Action", valid_594057
  var valid_594058 = query.getOrDefault("Version")
  valid_594058 = validateParameter(valid_594058, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594058 != nil:
    section.add "Version", valid_594058
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Content-Sha256", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Credential")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Credential", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Security-Token")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Security-Token", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Algorithm")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Algorithm", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-SignedHeaders", valid_594065
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594066 = formData.getOrDefault("SnapshotType")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "SnapshotType", valid_594066
  var valid_594067 = formData.getOrDefault("MaxRecords")
  valid_594067 = validateParameter(valid_594067, JInt, required = false, default = nil)
  if valid_594067 != nil:
    section.add "MaxRecords", valid_594067
  var valid_594068 = formData.getOrDefault("Marker")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "Marker", valid_594068
  var valid_594069 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "DBInstanceIdentifier", valid_594069
  var valid_594070 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "DBSnapshotIdentifier", valid_594070
  var valid_594071 = formData.getOrDefault("Filters")
  valid_594071 = validateParameter(valid_594071, JArray, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "Filters", valid_594071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594072: Call_PostDescribeDBSnapshots_594054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594072.validator(path, query, header, formData, body)
  let scheme = call_594072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594072.url(scheme.get, call_594072.host, call_594072.base,
                         call_594072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594072, url, valid)

proc call*(call_594073: Call_PostDescribeDBSnapshots_594054;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594074 = newJObject()
  var formData_594075 = newJObject()
  add(formData_594075, "SnapshotType", newJString(SnapshotType))
  add(formData_594075, "MaxRecords", newJInt(MaxRecords))
  add(formData_594075, "Marker", newJString(Marker))
  add(formData_594075, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594075, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594074, "Action", newJString(Action))
  if Filters != nil:
    formData_594075.add "Filters", Filters
  add(query_594074, "Version", newJString(Version))
  result = call_594073.call(nil, query_594074, nil, formData_594075, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_594054(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_594055, base: "/",
    url: url_PostDescribeDBSnapshots_594056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_594033 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSnapshots_594035(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_594034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594036 = query.getOrDefault("Marker")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "Marker", valid_594036
  var valid_594037 = query.getOrDefault("DBInstanceIdentifier")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "DBInstanceIdentifier", valid_594037
  var valid_594038 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "DBSnapshotIdentifier", valid_594038
  var valid_594039 = query.getOrDefault("SnapshotType")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "SnapshotType", valid_594039
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594040 = query.getOrDefault("Action")
  valid_594040 = validateParameter(valid_594040, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_594040 != nil:
    section.add "Action", valid_594040
  var valid_594041 = query.getOrDefault("Version")
  valid_594041 = validateParameter(valid_594041, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594041 != nil:
    section.add "Version", valid_594041
  var valid_594042 = query.getOrDefault("Filters")
  valid_594042 = validateParameter(valid_594042, JArray, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "Filters", valid_594042
  var valid_594043 = query.getOrDefault("MaxRecords")
  valid_594043 = validateParameter(valid_594043, JInt, required = false, default = nil)
  if valid_594043 != nil:
    section.add "MaxRecords", valid_594043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594044 = header.getOrDefault("X-Amz-Signature")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Signature", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Content-Sha256", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Credential")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Credential", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Security-Token")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Security-Token", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Algorithm")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Algorithm", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-SignedHeaders", valid_594050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594051: Call_GetDescribeDBSnapshots_594033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594051.validator(path, query, header, formData, body)
  let scheme = call_594051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594051.url(scheme.get, call_594051.host, call_594051.base,
                         call_594051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594051, url, valid)

proc call*(call_594052: Call_GetDescribeDBSnapshots_594033; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594053 = newJObject()
  add(query_594053, "Marker", newJString(Marker))
  add(query_594053, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594053, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594053, "SnapshotType", newJString(SnapshotType))
  add(query_594053, "Action", newJString(Action))
  add(query_594053, "Version", newJString(Version))
  if Filters != nil:
    query_594053.add "Filters", Filters
  add(query_594053, "MaxRecords", newJInt(MaxRecords))
  result = call_594052.call(nil, query_594053, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_594033(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_594034, base: "/",
    url: url_GetDescribeDBSnapshots_594035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_594095 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSubnetGroups_594097(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_594096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594098 = query.getOrDefault("Action")
  valid_594098 = validateParameter(valid_594098, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594098 != nil:
    section.add "Action", valid_594098
  var valid_594099 = query.getOrDefault("Version")
  valid_594099 = validateParameter(valid_594099, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594099 != nil:
    section.add "Version", valid_594099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594100 = header.getOrDefault("X-Amz-Signature")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Signature", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Content-Sha256", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Date")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Date", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Credential")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Credential", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Security-Token")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Security-Token", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Algorithm")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Algorithm", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-SignedHeaders", valid_594106
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594107 = formData.getOrDefault("MaxRecords")
  valid_594107 = validateParameter(valid_594107, JInt, required = false, default = nil)
  if valid_594107 != nil:
    section.add "MaxRecords", valid_594107
  var valid_594108 = formData.getOrDefault("Marker")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "Marker", valid_594108
  var valid_594109 = formData.getOrDefault("DBSubnetGroupName")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "DBSubnetGroupName", valid_594109
  var valid_594110 = formData.getOrDefault("Filters")
  valid_594110 = validateParameter(valid_594110, JArray, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "Filters", valid_594110
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594111: Call_PostDescribeDBSubnetGroups_594095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594111.validator(path, query, header, formData, body)
  let scheme = call_594111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594111.url(scheme.get, call_594111.host, call_594111.base,
                         call_594111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594111, url, valid)

proc call*(call_594112: Call_PostDescribeDBSubnetGroups_594095;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594113 = newJObject()
  var formData_594114 = newJObject()
  add(formData_594114, "MaxRecords", newJInt(MaxRecords))
  add(formData_594114, "Marker", newJString(Marker))
  add(query_594113, "Action", newJString(Action))
  add(formData_594114, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_594114.add "Filters", Filters
  add(query_594113, "Version", newJString(Version))
  result = call_594112.call(nil, query_594113, nil, formData_594114, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_594095(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_594096, base: "/",
    url: url_PostDescribeDBSubnetGroups_594097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_594076 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSubnetGroups_594078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_594077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594079 = query.getOrDefault("Marker")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "Marker", valid_594079
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594080 = query.getOrDefault("Action")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594080 != nil:
    section.add "Action", valid_594080
  var valid_594081 = query.getOrDefault("DBSubnetGroupName")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "DBSubnetGroupName", valid_594081
  var valid_594082 = query.getOrDefault("Version")
  valid_594082 = validateParameter(valid_594082, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594082 != nil:
    section.add "Version", valid_594082
  var valid_594083 = query.getOrDefault("Filters")
  valid_594083 = validateParameter(valid_594083, JArray, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "Filters", valid_594083
  var valid_594084 = query.getOrDefault("MaxRecords")
  valid_594084 = validateParameter(valid_594084, JInt, required = false, default = nil)
  if valid_594084 != nil:
    section.add "MaxRecords", valid_594084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594085 = header.getOrDefault("X-Amz-Signature")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Signature", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Content-Sha256", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Date")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Date", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Credential")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Credential", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Security-Token")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Security-Token", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Algorithm")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Algorithm", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-SignedHeaders", valid_594091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594092: Call_GetDescribeDBSubnetGroups_594076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594092.validator(path, query, header, formData, body)
  let scheme = call_594092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594092.url(scheme.get, call_594092.host, call_594092.base,
                         call_594092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594092, url, valid)

proc call*(call_594093: Call_GetDescribeDBSubnetGroups_594076; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594094 = newJObject()
  add(query_594094, "Marker", newJString(Marker))
  add(query_594094, "Action", newJString(Action))
  add(query_594094, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594094, "Version", newJString(Version))
  if Filters != nil:
    query_594094.add "Filters", Filters
  add(query_594094, "MaxRecords", newJInt(MaxRecords))
  result = call_594093.call(nil, query_594094, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_594076(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_594077, base: "/",
    url: url_GetDescribeDBSubnetGroups_594078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_594134 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEngineDefaultParameters_594136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_594135(path: JsonNode;
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
  var valid_594137 = query.getOrDefault("Action")
  valid_594137 = validateParameter(valid_594137, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_594137 != nil:
    section.add "Action", valid_594137
  var valid_594138 = query.getOrDefault("Version")
  valid_594138 = validateParameter(valid_594138, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594138 != nil:
    section.add "Version", valid_594138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594139 = header.getOrDefault("X-Amz-Signature")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Signature", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Content-Sha256", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Date")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Date", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Credential")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Credential", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Security-Token")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Security-Token", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Algorithm")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Algorithm", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-SignedHeaders", valid_594145
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_594146 = formData.getOrDefault("MaxRecords")
  valid_594146 = validateParameter(valid_594146, JInt, required = false, default = nil)
  if valid_594146 != nil:
    section.add "MaxRecords", valid_594146
  var valid_594147 = formData.getOrDefault("Marker")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "Marker", valid_594147
  var valid_594148 = formData.getOrDefault("Filters")
  valid_594148 = validateParameter(valid_594148, JArray, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "Filters", valid_594148
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594149 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = nil)
  if valid_594149 != nil:
    section.add "DBParameterGroupFamily", valid_594149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594150: Call_PostDescribeEngineDefaultParameters_594134;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594150.validator(path, query, header, formData, body)
  let scheme = call_594150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594150.url(scheme.get, call_594150.host, call_594150.base,
                         call_594150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594150, url, valid)

proc call*(call_594151: Call_PostDescribeEngineDefaultParameters_594134;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_594152 = newJObject()
  var formData_594153 = newJObject()
  add(formData_594153, "MaxRecords", newJInt(MaxRecords))
  add(formData_594153, "Marker", newJString(Marker))
  add(query_594152, "Action", newJString(Action))
  if Filters != nil:
    formData_594153.add "Filters", Filters
  add(query_594152, "Version", newJString(Version))
  add(formData_594153, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_594151.call(nil, query_594152, nil, formData_594153, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_594134(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_594135, base: "/",
    url: url_PostDescribeEngineDefaultParameters_594136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_594115 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEngineDefaultParameters_594117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_594116(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594118 = query.getOrDefault("Marker")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "Marker", valid_594118
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594119 = query.getOrDefault("DBParameterGroupFamily")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = nil)
  if valid_594119 != nil:
    section.add "DBParameterGroupFamily", valid_594119
  var valid_594120 = query.getOrDefault("Action")
  valid_594120 = validateParameter(valid_594120, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_594120 != nil:
    section.add "Action", valid_594120
  var valid_594121 = query.getOrDefault("Version")
  valid_594121 = validateParameter(valid_594121, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594121 != nil:
    section.add "Version", valid_594121
  var valid_594122 = query.getOrDefault("Filters")
  valid_594122 = validateParameter(valid_594122, JArray, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "Filters", valid_594122
  var valid_594123 = query.getOrDefault("MaxRecords")
  valid_594123 = validateParameter(valid_594123, JInt, required = false, default = nil)
  if valid_594123 != nil:
    section.add "MaxRecords", valid_594123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594124 = header.getOrDefault("X-Amz-Signature")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Signature", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Date")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Date", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Security-Token")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Security-Token", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Algorithm")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Algorithm", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-SignedHeaders", valid_594130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594131: Call_GetDescribeEngineDefaultParameters_594115;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594131.validator(path, query, header, formData, body)
  let scheme = call_594131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594131.url(scheme.get, call_594131.host, call_594131.base,
                         call_594131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594131, url, valid)

proc call*(call_594132: Call_GetDescribeEngineDefaultParameters_594115;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594133 = newJObject()
  add(query_594133, "Marker", newJString(Marker))
  add(query_594133, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_594133, "Action", newJString(Action))
  add(query_594133, "Version", newJString(Version))
  if Filters != nil:
    query_594133.add "Filters", Filters
  add(query_594133, "MaxRecords", newJInt(MaxRecords))
  result = call_594132.call(nil, query_594133, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_594115(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_594116, base: "/",
    url: url_GetDescribeEngineDefaultParameters_594117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_594171 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventCategories_594173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_594172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594174 = query.getOrDefault("Action")
  valid_594174 = validateParameter(valid_594174, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594174 != nil:
    section.add "Action", valid_594174
  var valid_594175 = query.getOrDefault("Version")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594175 != nil:
    section.add "Version", valid_594175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594176 = header.getOrDefault("X-Amz-Signature")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Signature", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Content-Sha256", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Credential")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Credential", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Security-Token")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Security-Token", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-SignedHeaders", valid_594182
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594183 = formData.getOrDefault("SourceType")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "SourceType", valid_594183
  var valid_594184 = formData.getOrDefault("Filters")
  valid_594184 = validateParameter(valid_594184, JArray, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "Filters", valid_594184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_PostDescribeEventCategories_594171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_PostDescribeEventCategories_594171;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594187 = newJObject()
  var formData_594188 = newJObject()
  add(formData_594188, "SourceType", newJString(SourceType))
  add(query_594187, "Action", newJString(Action))
  if Filters != nil:
    formData_594188.add "Filters", Filters
  add(query_594187, "Version", newJString(Version))
  result = call_594186.call(nil, query_594187, nil, formData_594188, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_594171(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_594172, base: "/",
    url: url_PostDescribeEventCategories_594173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_594154 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventCategories_594156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_594155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  var valid_594157 = query.getOrDefault("SourceType")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "SourceType", valid_594157
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594158 = query.getOrDefault("Action")
  valid_594158 = validateParameter(valid_594158, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594158 != nil:
    section.add "Action", valid_594158
  var valid_594159 = query.getOrDefault("Version")
  valid_594159 = validateParameter(valid_594159, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594159 != nil:
    section.add "Version", valid_594159
  var valid_594160 = query.getOrDefault("Filters")
  valid_594160 = validateParameter(valid_594160, JArray, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "Filters", valid_594160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594161 = header.getOrDefault("X-Amz-Signature")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Signature", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Content-Sha256", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Date")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Date", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Credential")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Credential", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Security-Token")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Security-Token", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Algorithm")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Algorithm", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-SignedHeaders", valid_594167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_GetDescribeEventCategories_594154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_GetDescribeEventCategories_594154;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-09-01"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_594170 = newJObject()
  add(query_594170, "SourceType", newJString(SourceType))
  add(query_594170, "Action", newJString(Action))
  add(query_594170, "Version", newJString(Version))
  if Filters != nil:
    query_594170.add "Filters", Filters
  result = call_594169.call(nil, query_594170, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_594154(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_594155, base: "/",
    url: url_GetDescribeEventCategories_594156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_594208 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventSubscriptions_594210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_594209(path: JsonNode;
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
  var valid_594211 = query.getOrDefault("Action")
  valid_594211 = validateParameter(valid_594211, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594211 != nil:
    section.add "Action", valid_594211
  var valid_594212 = query.getOrDefault("Version")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594212 != nil:
    section.add "Version", valid_594212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594213 = header.getOrDefault("X-Amz-Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Signature", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Date")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Date", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Credential")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Credential", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Security-Token")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Security-Token", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Algorithm")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Algorithm", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-SignedHeaders", valid_594219
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594220 = formData.getOrDefault("MaxRecords")
  valid_594220 = validateParameter(valid_594220, JInt, required = false, default = nil)
  if valid_594220 != nil:
    section.add "MaxRecords", valid_594220
  var valid_594221 = formData.getOrDefault("Marker")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "Marker", valid_594221
  var valid_594222 = formData.getOrDefault("SubscriptionName")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "SubscriptionName", valid_594222
  var valid_594223 = formData.getOrDefault("Filters")
  valid_594223 = validateParameter(valid_594223, JArray, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "Filters", valid_594223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594224: Call_PostDescribeEventSubscriptions_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594224.validator(path, query, header, formData, body)
  let scheme = call_594224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594224.url(scheme.get, call_594224.host, call_594224.base,
                         call_594224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594224, url, valid)

proc call*(call_594225: Call_PostDescribeEventSubscriptions_594208;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594226 = newJObject()
  var formData_594227 = newJObject()
  add(formData_594227, "MaxRecords", newJInt(MaxRecords))
  add(formData_594227, "Marker", newJString(Marker))
  add(formData_594227, "SubscriptionName", newJString(SubscriptionName))
  add(query_594226, "Action", newJString(Action))
  if Filters != nil:
    formData_594227.add "Filters", Filters
  add(query_594226, "Version", newJString(Version))
  result = call_594225.call(nil, query_594226, nil, formData_594227, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_594208(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_594209, base: "/",
    url: url_PostDescribeEventSubscriptions_594210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_594189 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventSubscriptions_594191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_594190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594192 = query.getOrDefault("Marker")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "Marker", valid_594192
  var valid_594193 = query.getOrDefault("SubscriptionName")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "SubscriptionName", valid_594193
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594194 = query.getOrDefault("Action")
  valid_594194 = validateParameter(valid_594194, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594194 != nil:
    section.add "Action", valid_594194
  var valid_594195 = query.getOrDefault("Version")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594195 != nil:
    section.add "Version", valid_594195
  var valid_594196 = query.getOrDefault("Filters")
  valid_594196 = validateParameter(valid_594196, JArray, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "Filters", valid_594196
  var valid_594197 = query.getOrDefault("MaxRecords")
  valid_594197 = validateParameter(valid_594197, JInt, required = false, default = nil)
  if valid_594197 != nil:
    section.add "MaxRecords", valid_594197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594198 = header.getOrDefault("X-Amz-Signature")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Signature", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Date")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Date", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Credential")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Credential", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Security-Token")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Security-Token", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Algorithm")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Algorithm", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-SignedHeaders", valid_594204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_GetDescribeEventSubscriptions_594189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_GetDescribeEventSubscriptions_594189;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594207 = newJObject()
  add(query_594207, "Marker", newJString(Marker))
  add(query_594207, "SubscriptionName", newJString(SubscriptionName))
  add(query_594207, "Action", newJString(Action))
  add(query_594207, "Version", newJString(Version))
  if Filters != nil:
    query_594207.add "Filters", Filters
  add(query_594207, "MaxRecords", newJInt(MaxRecords))
  result = call_594206.call(nil, query_594207, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_594189(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_594190, base: "/",
    url: url_GetDescribeEventSubscriptions_594191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_594252 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEvents_594254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_594253(path: JsonNode; query: JsonNode;
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
  var valid_594255 = query.getOrDefault("Action")
  valid_594255 = validateParameter(valid_594255, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594255 != nil:
    section.add "Action", valid_594255
  var valid_594256 = query.getOrDefault("Version")
  valid_594256 = validateParameter(valid_594256, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594256 != nil:
    section.add "Version", valid_594256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594257 = header.getOrDefault("X-Amz-Signature")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Signature", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Content-Sha256", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Date")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Date", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Credential")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Credential", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Security-Token")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Security-Token", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Algorithm")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Algorithm", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-SignedHeaders", valid_594263
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
  ##   Filters: JArray
  section = newJObject()
  var valid_594264 = formData.getOrDefault("MaxRecords")
  valid_594264 = validateParameter(valid_594264, JInt, required = false, default = nil)
  if valid_594264 != nil:
    section.add "MaxRecords", valid_594264
  var valid_594265 = formData.getOrDefault("Marker")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "Marker", valid_594265
  var valid_594266 = formData.getOrDefault("SourceIdentifier")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "SourceIdentifier", valid_594266
  var valid_594267 = formData.getOrDefault("SourceType")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594267 != nil:
    section.add "SourceType", valid_594267
  var valid_594268 = formData.getOrDefault("Duration")
  valid_594268 = validateParameter(valid_594268, JInt, required = false, default = nil)
  if valid_594268 != nil:
    section.add "Duration", valid_594268
  var valid_594269 = formData.getOrDefault("EndTime")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "EndTime", valid_594269
  var valid_594270 = formData.getOrDefault("StartTime")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "StartTime", valid_594270
  var valid_594271 = formData.getOrDefault("EventCategories")
  valid_594271 = validateParameter(valid_594271, JArray, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "EventCategories", valid_594271
  var valid_594272 = formData.getOrDefault("Filters")
  valid_594272 = validateParameter(valid_594272, JArray, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "Filters", valid_594272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594273: Call_PostDescribeEvents_594252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594273.validator(path, query, header, formData, body)
  let scheme = call_594273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594273.url(scheme.get, call_594273.host, call_594273.base,
                         call_594273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594273, url, valid)

proc call*(call_594274: Call_PostDescribeEvents_594252; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeEvents
  ##   MaxRecords: int
  ##   Marker: string
  ##   SourceIdentifier: string
  ##   SourceType: string
  ##   Duration: int
  ##   EndTime: string
  ##   StartTime: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594275 = newJObject()
  var formData_594276 = newJObject()
  add(formData_594276, "MaxRecords", newJInt(MaxRecords))
  add(formData_594276, "Marker", newJString(Marker))
  add(formData_594276, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594276, "SourceType", newJString(SourceType))
  add(formData_594276, "Duration", newJInt(Duration))
  add(formData_594276, "EndTime", newJString(EndTime))
  add(formData_594276, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_594276.add "EventCategories", EventCategories
  add(query_594275, "Action", newJString(Action))
  if Filters != nil:
    formData_594276.add "Filters", Filters
  add(query_594275, "Version", newJString(Version))
  result = call_594274.call(nil, query_594275, nil, formData_594276, nil)

var postDescribeEvents* = Call_PostDescribeEvents_594252(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_594253, base: "/",
    url: url_PostDescribeEvents_594254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_594228 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEvents_594230(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_594229(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SourceType: JString
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594231 = query.getOrDefault("Marker")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "Marker", valid_594231
  var valid_594232 = query.getOrDefault("SourceType")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594232 != nil:
    section.add "SourceType", valid_594232
  var valid_594233 = query.getOrDefault("SourceIdentifier")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "SourceIdentifier", valid_594233
  var valid_594234 = query.getOrDefault("EventCategories")
  valid_594234 = validateParameter(valid_594234, JArray, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "EventCategories", valid_594234
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594235 = query.getOrDefault("Action")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594235 != nil:
    section.add "Action", valid_594235
  var valid_594236 = query.getOrDefault("StartTime")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "StartTime", valid_594236
  var valid_594237 = query.getOrDefault("Duration")
  valid_594237 = validateParameter(valid_594237, JInt, required = false, default = nil)
  if valid_594237 != nil:
    section.add "Duration", valid_594237
  var valid_594238 = query.getOrDefault("EndTime")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "EndTime", valid_594238
  var valid_594239 = query.getOrDefault("Version")
  valid_594239 = validateParameter(valid_594239, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594239 != nil:
    section.add "Version", valid_594239
  var valid_594240 = query.getOrDefault("Filters")
  valid_594240 = validateParameter(valid_594240, JArray, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "Filters", valid_594240
  var valid_594241 = query.getOrDefault("MaxRecords")
  valid_594241 = validateParameter(valid_594241, JInt, required = false, default = nil)
  if valid_594241 != nil:
    section.add "MaxRecords", valid_594241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594242 = header.getOrDefault("X-Amz-Signature")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Signature", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Content-Sha256", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Date")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Date", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Credential")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Credential", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Security-Token")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Security-Token", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Algorithm")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Algorithm", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-SignedHeaders", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594249: Call_GetDescribeEvents_594228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594249.validator(path, query, header, formData, body)
  let scheme = call_594249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594249.url(scheme.get, call_594249.host, call_594249.base,
                         call_594249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594249, url, valid)

proc call*(call_594250: Call_GetDescribeEvents_594228; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEvents
  ##   Marker: string
  ##   SourceType: string
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   StartTime: string
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594251 = newJObject()
  add(query_594251, "Marker", newJString(Marker))
  add(query_594251, "SourceType", newJString(SourceType))
  add(query_594251, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_594251.add "EventCategories", EventCategories
  add(query_594251, "Action", newJString(Action))
  add(query_594251, "StartTime", newJString(StartTime))
  add(query_594251, "Duration", newJInt(Duration))
  add(query_594251, "EndTime", newJString(EndTime))
  add(query_594251, "Version", newJString(Version))
  if Filters != nil:
    query_594251.add "Filters", Filters
  add(query_594251, "MaxRecords", newJInt(MaxRecords))
  result = call_594250.call(nil, query_594251, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_594228(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_594229,
    base: "/", url: url_GetDescribeEvents_594230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_594297 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroupOptions_594299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_594298(path: JsonNode;
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
  var valid_594300 = query.getOrDefault("Action")
  valid_594300 = validateParameter(valid_594300, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594300 != nil:
    section.add "Action", valid_594300
  var valid_594301 = query.getOrDefault("Version")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594301 != nil:
    section.add "Version", valid_594301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594302 = header.getOrDefault("X-Amz-Signature")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Signature", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Content-Sha256", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Date")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Date", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Credential")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Credential", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Security-Token")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Security-Token", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Algorithm")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Algorithm", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-SignedHeaders", valid_594308
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594309 = formData.getOrDefault("MaxRecords")
  valid_594309 = validateParameter(valid_594309, JInt, required = false, default = nil)
  if valid_594309 != nil:
    section.add "MaxRecords", valid_594309
  var valid_594310 = formData.getOrDefault("Marker")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "Marker", valid_594310
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_594311 = formData.getOrDefault("EngineName")
  valid_594311 = validateParameter(valid_594311, JString, required = true,
                                 default = nil)
  if valid_594311 != nil:
    section.add "EngineName", valid_594311
  var valid_594312 = formData.getOrDefault("MajorEngineVersion")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "MajorEngineVersion", valid_594312
  var valid_594313 = formData.getOrDefault("Filters")
  valid_594313 = validateParameter(valid_594313, JArray, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "Filters", valid_594313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594314: Call_PostDescribeOptionGroupOptions_594297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594314.validator(path, query, header, formData, body)
  let scheme = call_594314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594314.url(scheme.get, call_594314.host, call_594314.base,
                         call_594314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594314, url, valid)

proc call*(call_594315: Call_PostDescribeOptionGroupOptions_594297;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594316 = newJObject()
  var formData_594317 = newJObject()
  add(formData_594317, "MaxRecords", newJInt(MaxRecords))
  add(formData_594317, "Marker", newJString(Marker))
  add(formData_594317, "EngineName", newJString(EngineName))
  add(formData_594317, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594316, "Action", newJString(Action))
  if Filters != nil:
    formData_594317.add "Filters", Filters
  add(query_594316, "Version", newJString(Version))
  result = call_594315.call(nil, query_594316, nil, formData_594317, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_594297(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_594298, base: "/",
    url: url_PostDescribeOptionGroupOptions_594299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_594277 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroupOptions_594279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_594278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   Marker: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_594280 = query.getOrDefault("EngineName")
  valid_594280 = validateParameter(valid_594280, JString, required = true,
                                 default = nil)
  if valid_594280 != nil:
    section.add "EngineName", valid_594280
  var valid_594281 = query.getOrDefault("Marker")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "Marker", valid_594281
  var valid_594282 = query.getOrDefault("Action")
  valid_594282 = validateParameter(valid_594282, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594282 != nil:
    section.add "Action", valid_594282
  var valid_594283 = query.getOrDefault("Version")
  valid_594283 = validateParameter(valid_594283, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594283 != nil:
    section.add "Version", valid_594283
  var valid_594284 = query.getOrDefault("Filters")
  valid_594284 = validateParameter(valid_594284, JArray, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "Filters", valid_594284
  var valid_594285 = query.getOrDefault("MaxRecords")
  valid_594285 = validateParameter(valid_594285, JInt, required = false, default = nil)
  if valid_594285 != nil:
    section.add "MaxRecords", valid_594285
  var valid_594286 = query.getOrDefault("MajorEngineVersion")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "MajorEngineVersion", valid_594286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594287 = header.getOrDefault("X-Amz-Signature")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Signature", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Content-Sha256", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Date")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Date", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Credential")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Credential", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Security-Token")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Security-Token", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Algorithm")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Algorithm", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-SignedHeaders", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594294: Call_GetDescribeOptionGroupOptions_594277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594294.validator(path, query, header, formData, body)
  let scheme = call_594294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594294.url(scheme.get, call_594294.host, call_594294.base,
                         call_594294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594294, url, valid)

proc call*(call_594295: Call_GetDescribeOptionGroupOptions_594277;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_594296 = newJObject()
  add(query_594296, "EngineName", newJString(EngineName))
  add(query_594296, "Marker", newJString(Marker))
  add(query_594296, "Action", newJString(Action))
  add(query_594296, "Version", newJString(Version))
  if Filters != nil:
    query_594296.add "Filters", Filters
  add(query_594296, "MaxRecords", newJInt(MaxRecords))
  add(query_594296, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594295.call(nil, query_594296, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_594277(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_594278, base: "/",
    url: url_GetDescribeOptionGroupOptions_594279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_594339 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroups_594341(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_594340(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594342 = query.getOrDefault("Action")
  valid_594342 = validateParameter(valid_594342, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594342 != nil:
    section.add "Action", valid_594342
  var valid_594343 = query.getOrDefault("Version")
  valid_594343 = validateParameter(valid_594343, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594343 != nil:
    section.add "Version", valid_594343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594344 = header.getOrDefault("X-Amz-Signature")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Signature", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Content-Sha256", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Credential")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Credential", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Security-Token")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Security-Token", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Algorithm")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Algorithm", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-SignedHeaders", valid_594350
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594351 = formData.getOrDefault("MaxRecords")
  valid_594351 = validateParameter(valid_594351, JInt, required = false, default = nil)
  if valid_594351 != nil:
    section.add "MaxRecords", valid_594351
  var valid_594352 = formData.getOrDefault("Marker")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "Marker", valid_594352
  var valid_594353 = formData.getOrDefault("EngineName")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "EngineName", valid_594353
  var valid_594354 = formData.getOrDefault("MajorEngineVersion")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "MajorEngineVersion", valid_594354
  var valid_594355 = formData.getOrDefault("OptionGroupName")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "OptionGroupName", valid_594355
  var valid_594356 = formData.getOrDefault("Filters")
  valid_594356 = validateParameter(valid_594356, JArray, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "Filters", valid_594356
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594357: Call_PostDescribeOptionGroups_594339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594357.validator(path, query, header, formData, body)
  let scheme = call_594357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594357.url(scheme.get, call_594357.host, call_594357.base,
                         call_594357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594357, url, valid)

proc call*(call_594358: Call_PostDescribeOptionGroups_594339; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594359 = newJObject()
  var formData_594360 = newJObject()
  add(formData_594360, "MaxRecords", newJInt(MaxRecords))
  add(formData_594360, "Marker", newJString(Marker))
  add(formData_594360, "EngineName", newJString(EngineName))
  add(formData_594360, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594359, "Action", newJString(Action))
  add(formData_594360, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_594360.add "Filters", Filters
  add(query_594359, "Version", newJString(Version))
  result = call_594358.call(nil, query_594359, nil, formData_594360, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_594339(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_594340, base: "/",
    url: url_PostDescribeOptionGroups_594341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_594318 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroups_594320(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_594319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString
  ##   Marker: JString
  ##   Action: JString (required)
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_594321 = query.getOrDefault("EngineName")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "EngineName", valid_594321
  var valid_594322 = query.getOrDefault("Marker")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "Marker", valid_594322
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594323 = query.getOrDefault("Action")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594323 != nil:
    section.add "Action", valid_594323
  var valid_594324 = query.getOrDefault("OptionGroupName")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "OptionGroupName", valid_594324
  var valid_594325 = query.getOrDefault("Version")
  valid_594325 = validateParameter(valid_594325, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594325 != nil:
    section.add "Version", valid_594325
  var valid_594326 = query.getOrDefault("Filters")
  valid_594326 = validateParameter(valid_594326, JArray, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "Filters", valid_594326
  var valid_594327 = query.getOrDefault("MaxRecords")
  valid_594327 = validateParameter(valid_594327, JInt, required = false, default = nil)
  if valid_594327 != nil:
    section.add "MaxRecords", valid_594327
  var valid_594328 = query.getOrDefault("MajorEngineVersion")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "MajorEngineVersion", valid_594328
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594329 = header.getOrDefault("X-Amz-Signature")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Signature", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Content-Sha256", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Credential")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Credential", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Security-Token")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Security-Token", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Algorithm")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Algorithm", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-SignedHeaders", valid_594335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594336: Call_GetDescribeOptionGroups_594318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594336.validator(path, query, header, formData, body)
  let scheme = call_594336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594336.url(scheme.get, call_594336.host, call_594336.base,
                         call_594336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594336, url, valid)

proc call*(call_594337: Call_GetDescribeOptionGroups_594318;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_594338 = newJObject()
  add(query_594338, "EngineName", newJString(EngineName))
  add(query_594338, "Marker", newJString(Marker))
  add(query_594338, "Action", newJString(Action))
  add(query_594338, "OptionGroupName", newJString(OptionGroupName))
  add(query_594338, "Version", newJString(Version))
  if Filters != nil:
    query_594338.add "Filters", Filters
  add(query_594338, "MaxRecords", newJInt(MaxRecords))
  add(query_594338, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594337.call(nil, query_594338, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_594318(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_594319, base: "/",
    url: url_GetDescribeOptionGroups_594320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_594384 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOrderableDBInstanceOptions_594386(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_594385(path: JsonNode;
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
  var valid_594387 = query.getOrDefault("Action")
  valid_594387 = validateParameter(valid_594387, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594387 != nil:
    section.add "Action", valid_594387
  var valid_594388 = query.getOrDefault("Version")
  valid_594388 = validateParameter(valid_594388, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594388 != nil:
    section.add "Version", valid_594388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594389 = header.getOrDefault("X-Amz-Signature")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Signature", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Content-Sha256", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Credential")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Credential", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Algorithm")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Algorithm", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-SignedHeaders", valid_594395
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594396 = formData.getOrDefault("DBInstanceClass")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "DBInstanceClass", valid_594396
  var valid_594397 = formData.getOrDefault("MaxRecords")
  valid_594397 = validateParameter(valid_594397, JInt, required = false, default = nil)
  if valid_594397 != nil:
    section.add "MaxRecords", valid_594397
  var valid_594398 = formData.getOrDefault("EngineVersion")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "EngineVersion", valid_594398
  var valid_594399 = formData.getOrDefault("Marker")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "Marker", valid_594399
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594400 = formData.getOrDefault("Engine")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = nil)
  if valid_594400 != nil:
    section.add "Engine", valid_594400
  var valid_594401 = formData.getOrDefault("Vpc")
  valid_594401 = validateParameter(valid_594401, JBool, required = false, default = nil)
  if valid_594401 != nil:
    section.add "Vpc", valid_594401
  var valid_594402 = formData.getOrDefault("LicenseModel")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "LicenseModel", valid_594402
  var valid_594403 = formData.getOrDefault("Filters")
  valid_594403 = validateParameter(valid_594403, JArray, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "Filters", valid_594403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_PostDescribeOrderableDBInstanceOptions_594384;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_PostDescribeOrderableDBInstanceOptions_594384;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594406 = newJObject()
  var formData_594407 = newJObject()
  add(formData_594407, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594407, "MaxRecords", newJInt(MaxRecords))
  add(formData_594407, "EngineVersion", newJString(EngineVersion))
  add(formData_594407, "Marker", newJString(Marker))
  add(formData_594407, "Engine", newJString(Engine))
  add(formData_594407, "Vpc", newJBool(Vpc))
  add(query_594406, "Action", newJString(Action))
  add(formData_594407, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_594407.add "Filters", Filters
  add(query_594406, "Version", newJString(Version))
  result = call_594405.call(nil, query_594406, nil, formData_594407, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_594384(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_594385, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_594386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_594361 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOrderableDBInstanceOptions_594363(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_594362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594364 = query.getOrDefault("Marker")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "Marker", valid_594364
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594365 = query.getOrDefault("Engine")
  valid_594365 = validateParameter(valid_594365, JString, required = true,
                                 default = nil)
  if valid_594365 != nil:
    section.add "Engine", valid_594365
  var valid_594366 = query.getOrDefault("LicenseModel")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "LicenseModel", valid_594366
  var valid_594367 = query.getOrDefault("Vpc")
  valid_594367 = validateParameter(valid_594367, JBool, required = false, default = nil)
  if valid_594367 != nil:
    section.add "Vpc", valid_594367
  var valid_594368 = query.getOrDefault("EngineVersion")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "EngineVersion", valid_594368
  var valid_594369 = query.getOrDefault("Action")
  valid_594369 = validateParameter(valid_594369, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594369 != nil:
    section.add "Action", valid_594369
  var valid_594370 = query.getOrDefault("Version")
  valid_594370 = validateParameter(valid_594370, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594370 != nil:
    section.add "Version", valid_594370
  var valid_594371 = query.getOrDefault("DBInstanceClass")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "DBInstanceClass", valid_594371
  var valid_594372 = query.getOrDefault("Filters")
  valid_594372 = validateParameter(valid_594372, JArray, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "Filters", valid_594372
  var valid_594373 = query.getOrDefault("MaxRecords")
  valid_594373 = validateParameter(valid_594373, JInt, required = false, default = nil)
  if valid_594373 != nil:
    section.add "MaxRecords", valid_594373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594374 = header.getOrDefault("X-Amz-Signature")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Signature", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Content-Sha256", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Credential")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Credential", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Security-Token")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Security-Token", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Algorithm")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Algorithm", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-SignedHeaders", valid_594380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594381: Call_GetDescribeOrderableDBInstanceOptions_594361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594381.validator(path, query, header, formData, body)
  let scheme = call_594381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594381.url(scheme.get, call_594381.host, call_594381.base,
                         call_594381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594381, url, valid)

proc call*(call_594382: Call_GetDescribeOrderableDBInstanceOptions_594361;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594383 = newJObject()
  add(query_594383, "Marker", newJString(Marker))
  add(query_594383, "Engine", newJString(Engine))
  add(query_594383, "LicenseModel", newJString(LicenseModel))
  add(query_594383, "Vpc", newJBool(Vpc))
  add(query_594383, "EngineVersion", newJString(EngineVersion))
  add(query_594383, "Action", newJString(Action))
  add(query_594383, "Version", newJString(Version))
  add(query_594383, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594383.add "Filters", Filters
  add(query_594383, "MaxRecords", newJInt(MaxRecords))
  result = call_594382.call(nil, query_594383, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_594361(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_594362, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_594363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_594433 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstances_594435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_594434(path: JsonNode;
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
  var valid_594436 = query.getOrDefault("Action")
  valid_594436 = validateParameter(valid_594436, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594436 != nil:
    section.add "Action", valid_594436
  var valid_594437 = query.getOrDefault("Version")
  valid_594437 = validateParameter(valid_594437, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594437 != nil:
    section.add "Version", valid_594437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594438 = header.getOrDefault("X-Amz-Signature")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Signature", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Credential")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Credential", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Security-Token")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Security-Token", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Algorithm")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Algorithm", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-SignedHeaders", valid_594444
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_594445 = formData.getOrDefault("DBInstanceClass")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "DBInstanceClass", valid_594445
  var valid_594446 = formData.getOrDefault("MultiAZ")
  valid_594446 = validateParameter(valid_594446, JBool, required = false, default = nil)
  if valid_594446 != nil:
    section.add "MultiAZ", valid_594446
  var valid_594447 = formData.getOrDefault("MaxRecords")
  valid_594447 = validateParameter(valid_594447, JInt, required = false, default = nil)
  if valid_594447 != nil:
    section.add "MaxRecords", valid_594447
  var valid_594448 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "ReservedDBInstanceId", valid_594448
  var valid_594449 = formData.getOrDefault("Marker")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "Marker", valid_594449
  var valid_594450 = formData.getOrDefault("Duration")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "Duration", valid_594450
  var valid_594451 = formData.getOrDefault("OfferingType")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "OfferingType", valid_594451
  var valid_594452 = formData.getOrDefault("ProductDescription")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "ProductDescription", valid_594452
  var valid_594453 = formData.getOrDefault("Filters")
  valid_594453 = validateParameter(valid_594453, JArray, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "Filters", valid_594453
  var valid_594454 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594454
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594455: Call_PostDescribeReservedDBInstances_594433;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594455.validator(path, query, header, formData, body)
  let scheme = call_594455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594455.url(scheme.get, call_594455.host, call_594455.base,
                         call_594455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594455, url, valid)

proc call*(call_594456: Call_PostDescribeReservedDBInstances_594433;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postDescribeReservedDBInstances
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_594457 = newJObject()
  var formData_594458 = newJObject()
  add(formData_594458, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594458, "MultiAZ", newJBool(MultiAZ))
  add(formData_594458, "MaxRecords", newJInt(MaxRecords))
  add(formData_594458, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_594458, "Marker", newJString(Marker))
  add(formData_594458, "Duration", newJString(Duration))
  add(formData_594458, "OfferingType", newJString(OfferingType))
  add(formData_594458, "ProductDescription", newJString(ProductDescription))
  add(query_594457, "Action", newJString(Action))
  if Filters != nil:
    formData_594458.add "Filters", Filters
  add(formData_594458, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594457, "Version", newJString(Version))
  result = call_594456.call(nil, query_594457, nil, formData_594458, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_594433(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_594434, base: "/",
    url: url_PostDescribeReservedDBInstances_594435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_594408 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstances_594410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_594409(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594411 = query.getOrDefault("Marker")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "Marker", valid_594411
  var valid_594412 = query.getOrDefault("ProductDescription")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "ProductDescription", valid_594412
  var valid_594413 = query.getOrDefault("OfferingType")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "OfferingType", valid_594413
  var valid_594414 = query.getOrDefault("ReservedDBInstanceId")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "ReservedDBInstanceId", valid_594414
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594415 = query.getOrDefault("Action")
  valid_594415 = validateParameter(valid_594415, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594415 != nil:
    section.add "Action", valid_594415
  var valid_594416 = query.getOrDefault("MultiAZ")
  valid_594416 = validateParameter(valid_594416, JBool, required = false, default = nil)
  if valid_594416 != nil:
    section.add "MultiAZ", valid_594416
  var valid_594417 = query.getOrDefault("Duration")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "Duration", valid_594417
  var valid_594418 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594418
  var valid_594419 = query.getOrDefault("Version")
  valid_594419 = validateParameter(valid_594419, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594419 != nil:
    section.add "Version", valid_594419
  var valid_594420 = query.getOrDefault("DBInstanceClass")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "DBInstanceClass", valid_594420
  var valid_594421 = query.getOrDefault("Filters")
  valid_594421 = validateParameter(valid_594421, JArray, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "Filters", valid_594421
  var valid_594422 = query.getOrDefault("MaxRecords")
  valid_594422 = validateParameter(valid_594422, JInt, required = false, default = nil)
  if valid_594422 != nil:
    section.add "MaxRecords", valid_594422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594423 = header.getOrDefault("X-Amz-Signature")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Signature", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Credential")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Credential", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Security-Token")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Security-Token", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Algorithm")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Algorithm", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-SignedHeaders", valid_594429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594430: Call_GetDescribeReservedDBInstances_594408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594430.validator(path, query, header, formData, body)
  let scheme = call_594430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594430.url(scheme.get, call_594430.host, call_594430.base,
                         call_594430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594430, url, valid)

proc call*(call_594431: Call_GetDescribeReservedDBInstances_594408;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstances
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594432 = newJObject()
  add(query_594432, "Marker", newJString(Marker))
  add(query_594432, "ProductDescription", newJString(ProductDescription))
  add(query_594432, "OfferingType", newJString(OfferingType))
  add(query_594432, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594432, "Action", newJString(Action))
  add(query_594432, "MultiAZ", newJBool(MultiAZ))
  add(query_594432, "Duration", newJString(Duration))
  add(query_594432, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594432, "Version", newJString(Version))
  add(query_594432, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594432.add "Filters", Filters
  add(query_594432, "MaxRecords", newJInt(MaxRecords))
  result = call_594431.call(nil, query_594432, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_594408(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_594409, base: "/",
    url: url_GetDescribeReservedDBInstances_594410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_594483 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstancesOfferings_594485(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_594484(path: JsonNode;
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
  var valid_594486 = query.getOrDefault("Action")
  valid_594486 = validateParameter(valid_594486, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594486 != nil:
    section.add "Action", valid_594486
  var valid_594487 = query.getOrDefault("Version")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594487 != nil:
    section.add "Version", valid_594487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594488 = header.getOrDefault("X-Amz-Signature")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Signature", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Content-Sha256", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Date")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Date", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Credential")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Credential", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Security-Token")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Security-Token", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Algorithm")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Algorithm", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-SignedHeaders", valid_594494
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_594495 = formData.getOrDefault("DBInstanceClass")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "DBInstanceClass", valid_594495
  var valid_594496 = formData.getOrDefault("MultiAZ")
  valid_594496 = validateParameter(valid_594496, JBool, required = false, default = nil)
  if valid_594496 != nil:
    section.add "MultiAZ", valid_594496
  var valid_594497 = formData.getOrDefault("MaxRecords")
  valid_594497 = validateParameter(valid_594497, JInt, required = false, default = nil)
  if valid_594497 != nil:
    section.add "MaxRecords", valid_594497
  var valid_594498 = formData.getOrDefault("Marker")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "Marker", valid_594498
  var valid_594499 = formData.getOrDefault("Duration")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "Duration", valid_594499
  var valid_594500 = formData.getOrDefault("OfferingType")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "OfferingType", valid_594500
  var valid_594501 = formData.getOrDefault("ProductDescription")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "ProductDescription", valid_594501
  var valid_594502 = formData.getOrDefault("Filters")
  valid_594502 = validateParameter(valid_594502, JArray, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "Filters", valid_594502
  var valid_594503 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594504: Call_PostDescribeReservedDBInstancesOfferings_594483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594504.validator(path, query, header, formData, body)
  let scheme = call_594504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594504.url(scheme.get, call_594504.host, call_594504.base,
                         call_594504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594504, url, valid)

proc call*(call_594505: Call_PostDescribeReservedDBInstancesOfferings_594483;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_594506 = newJObject()
  var formData_594507 = newJObject()
  add(formData_594507, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594507, "MultiAZ", newJBool(MultiAZ))
  add(formData_594507, "MaxRecords", newJInt(MaxRecords))
  add(formData_594507, "Marker", newJString(Marker))
  add(formData_594507, "Duration", newJString(Duration))
  add(formData_594507, "OfferingType", newJString(OfferingType))
  add(formData_594507, "ProductDescription", newJString(ProductDescription))
  add(query_594506, "Action", newJString(Action))
  if Filters != nil:
    formData_594507.add "Filters", Filters
  add(formData_594507, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594506, "Version", newJString(Version))
  result = call_594505.call(nil, query_594506, nil, formData_594507, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_594483(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_594484,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_594485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_594459 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstancesOfferings_594461(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_594460(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594462 = query.getOrDefault("Marker")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "Marker", valid_594462
  var valid_594463 = query.getOrDefault("ProductDescription")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "ProductDescription", valid_594463
  var valid_594464 = query.getOrDefault("OfferingType")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "OfferingType", valid_594464
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594465 = query.getOrDefault("Action")
  valid_594465 = validateParameter(valid_594465, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594465 != nil:
    section.add "Action", valid_594465
  var valid_594466 = query.getOrDefault("MultiAZ")
  valid_594466 = validateParameter(valid_594466, JBool, required = false, default = nil)
  if valid_594466 != nil:
    section.add "MultiAZ", valid_594466
  var valid_594467 = query.getOrDefault("Duration")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "Duration", valid_594467
  var valid_594468 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594468
  var valid_594469 = query.getOrDefault("Version")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594469 != nil:
    section.add "Version", valid_594469
  var valid_594470 = query.getOrDefault("DBInstanceClass")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "DBInstanceClass", valid_594470
  var valid_594471 = query.getOrDefault("Filters")
  valid_594471 = validateParameter(valid_594471, JArray, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "Filters", valid_594471
  var valid_594472 = query.getOrDefault("MaxRecords")
  valid_594472 = validateParameter(valid_594472, JInt, required = false, default = nil)
  if valid_594472 != nil:
    section.add "MaxRecords", valid_594472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594473 = header.getOrDefault("X-Amz-Signature")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Signature", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Content-Sha256", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Date")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Date", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Credential")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Credential", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Security-Token")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Security-Token", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Algorithm")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Algorithm", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-SignedHeaders", valid_594479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594480: Call_GetDescribeReservedDBInstancesOfferings_594459;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594480.validator(path, query, header, formData, body)
  let scheme = call_594480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594480.url(scheme.get, call_594480.host, call_594480.base,
                         call_594480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594480, url, valid)

proc call*(call_594481: Call_GetDescribeReservedDBInstancesOfferings_594459;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594482 = newJObject()
  add(query_594482, "Marker", newJString(Marker))
  add(query_594482, "ProductDescription", newJString(ProductDescription))
  add(query_594482, "OfferingType", newJString(OfferingType))
  add(query_594482, "Action", newJString(Action))
  add(query_594482, "MultiAZ", newJBool(MultiAZ))
  add(query_594482, "Duration", newJString(Duration))
  add(query_594482, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594482, "Version", newJString(Version))
  add(query_594482, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594482.add "Filters", Filters
  add(query_594482, "MaxRecords", newJInt(MaxRecords))
  result = call_594481.call(nil, query_594482, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_594459(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_594460, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_594461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_594527 = ref object of OpenApiRestCall_592348
proc url_PostDownloadDBLogFilePortion_594529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_594528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594530 = query.getOrDefault("Action")
  valid_594530 = validateParameter(valid_594530, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594530 != nil:
    section.add "Action", valid_594530
  var valid_594531 = query.getOrDefault("Version")
  valid_594531 = validateParameter(valid_594531, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594531 != nil:
    section.add "Version", valid_594531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594532 = header.getOrDefault("X-Amz-Signature")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Signature", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Content-Sha256", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Date")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Date", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Credential")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Credential", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Security-Token")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Security-Token", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Algorithm")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Algorithm", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-SignedHeaders", valid_594538
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594539 = formData.getOrDefault("NumberOfLines")
  valid_594539 = validateParameter(valid_594539, JInt, required = false, default = nil)
  if valid_594539 != nil:
    section.add "NumberOfLines", valid_594539
  var valid_594540 = formData.getOrDefault("Marker")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "Marker", valid_594540
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_594541 = formData.getOrDefault("LogFileName")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = nil)
  if valid_594541 != nil:
    section.add "LogFileName", valid_594541
  var valid_594542 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594542 = validateParameter(valid_594542, JString, required = true,
                                 default = nil)
  if valid_594542 != nil:
    section.add "DBInstanceIdentifier", valid_594542
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594543: Call_PostDownloadDBLogFilePortion_594527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594543.validator(path, query, header, formData, body)
  let scheme = call_594543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594543.url(scheme.get, call_594543.host, call_594543.base,
                         call_594543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594543, url, valid)

proc call*(call_594544: Call_PostDownloadDBLogFilePortion_594527;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594545 = newJObject()
  var formData_594546 = newJObject()
  add(formData_594546, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_594546, "Marker", newJString(Marker))
  add(formData_594546, "LogFileName", newJString(LogFileName))
  add(formData_594546, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594545, "Action", newJString(Action))
  add(query_594545, "Version", newJString(Version))
  result = call_594544.call(nil, query_594545, nil, formData_594546, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_594527(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_594528, base: "/",
    url: url_PostDownloadDBLogFilePortion_594529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_594508 = ref object of OpenApiRestCall_592348
proc url_GetDownloadDBLogFilePortion_594510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_594509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   LogFileName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594511 = query.getOrDefault("Marker")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "Marker", valid_594511
  var valid_594512 = query.getOrDefault("NumberOfLines")
  valid_594512 = validateParameter(valid_594512, JInt, required = false, default = nil)
  if valid_594512 != nil:
    section.add "NumberOfLines", valid_594512
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594513 = query.getOrDefault("DBInstanceIdentifier")
  valid_594513 = validateParameter(valid_594513, JString, required = true,
                                 default = nil)
  if valid_594513 != nil:
    section.add "DBInstanceIdentifier", valid_594513
  var valid_594514 = query.getOrDefault("Action")
  valid_594514 = validateParameter(valid_594514, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594514 != nil:
    section.add "Action", valid_594514
  var valid_594515 = query.getOrDefault("LogFileName")
  valid_594515 = validateParameter(valid_594515, JString, required = true,
                                 default = nil)
  if valid_594515 != nil:
    section.add "LogFileName", valid_594515
  var valid_594516 = query.getOrDefault("Version")
  valid_594516 = validateParameter(valid_594516, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594516 != nil:
    section.add "Version", valid_594516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594517 = header.getOrDefault("X-Amz-Signature")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Signature", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Content-Sha256", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Date")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Date", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Credential")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Credential", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Security-Token")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Security-Token", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Algorithm")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Algorithm", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594524: Call_GetDownloadDBLogFilePortion_594508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594524.validator(path, query, header, formData, body)
  let scheme = call_594524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594524.url(scheme.get, call_594524.host, call_594524.base,
                         call_594524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594524, url, valid)

proc call*(call_594525: Call_GetDownloadDBLogFilePortion_594508;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_594526 = newJObject()
  add(query_594526, "Marker", newJString(Marker))
  add(query_594526, "NumberOfLines", newJInt(NumberOfLines))
  add(query_594526, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594526, "Action", newJString(Action))
  add(query_594526, "LogFileName", newJString(LogFileName))
  add(query_594526, "Version", newJString(Version))
  result = call_594525.call(nil, query_594526, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_594508(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_594509, base: "/",
    url: url_GetDownloadDBLogFilePortion_594510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594564 = ref object of OpenApiRestCall_592348
proc url_PostListTagsForResource_594566(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594567 = query.getOrDefault("Action")
  valid_594567 = validateParameter(valid_594567, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594567 != nil:
    section.add "Action", valid_594567
  var valid_594568 = query.getOrDefault("Version")
  valid_594568 = validateParameter(valid_594568, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594568 != nil:
    section.add "Version", valid_594568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594569 = header.getOrDefault("X-Amz-Signature")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Signature", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Content-Sha256", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Credential")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Credential", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Security-Token")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Security-Token", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Algorithm")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Algorithm", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-SignedHeaders", valid_594575
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_594576 = formData.getOrDefault("Filters")
  valid_594576 = validateParameter(valid_594576, JArray, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "Filters", valid_594576
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_594577 = formData.getOrDefault("ResourceName")
  valid_594577 = validateParameter(valid_594577, JString, required = true,
                                 default = nil)
  if valid_594577 != nil:
    section.add "ResourceName", valid_594577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594578: Call_PostListTagsForResource_594564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594578.validator(path, query, header, formData, body)
  let scheme = call_594578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594578.url(scheme.get, call_594578.host, call_594578.base,
                         call_594578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594578, url, valid)

proc call*(call_594579: Call_PostListTagsForResource_594564; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594580 = newJObject()
  var formData_594581 = newJObject()
  add(query_594580, "Action", newJString(Action))
  if Filters != nil:
    formData_594581.add "Filters", Filters
  add(query_594580, "Version", newJString(Version))
  add(formData_594581, "ResourceName", newJString(ResourceName))
  result = call_594579.call(nil, query_594580, nil, formData_594581, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594564(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594565, base: "/",
    url: url_PostListTagsForResource_594566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594547 = ref object of OpenApiRestCall_592348
proc url_GetListTagsForResource_594549(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_594550 = query.getOrDefault("ResourceName")
  valid_594550 = validateParameter(valid_594550, JString, required = true,
                                 default = nil)
  if valid_594550 != nil:
    section.add "ResourceName", valid_594550
  var valid_594551 = query.getOrDefault("Action")
  valid_594551 = validateParameter(valid_594551, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594551 != nil:
    section.add "Action", valid_594551
  var valid_594552 = query.getOrDefault("Version")
  valid_594552 = validateParameter(valid_594552, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594552 != nil:
    section.add "Version", valid_594552
  var valid_594553 = query.getOrDefault("Filters")
  valid_594553 = validateParameter(valid_594553, JArray, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "Filters", valid_594553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594554 = header.getOrDefault("X-Amz-Signature")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Signature", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Content-Sha256", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Credential")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Credential", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Security-Token")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Security-Token", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Algorithm")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Algorithm", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-SignedHeaders", valid_594560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594561: Call_GetListTagsForResource_594547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594561.validator(path, query, header, formData, body)
  let scheme = call_594561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594561.url(scheme.get, call_594561.host, call_594561.base,
                         call_594561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594561, url, valid)

proc call*(call_594562: Call_GetListTagsForResource_594547; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_594563 = newJObject()
  add(query_594563, "ResourceName", newJString(ResourceName))
  add(query_594563, "Action", newJString(Action))
  add(query_594563, "Version", newJString(Version))
  if Filters != nil:
    query_594563.add "Filters", Filters
  result = call_594562.call(nil, query_594563, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594547(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594548, base: "/",
    url: url_GetListTagsForResource_594549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_594618 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBInstance_594620(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_594619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594621 = query.getOrDefault("Action")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594621 != nil:
    section.add "Action", valid_594621
  var valid_594622 = query.getOrDefault("Version")
  valid_594622 = validateParameter(valid_594622, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594622 != nil:
    section.add "Version", valid_594622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594623 = header.getOrDefault("X-Amz-Signature")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Signature", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Content-Sha256", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Date")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Date", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Credential")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Credential", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Security-Token")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Security-Token", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Algorithm")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Algorithm", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-SignedHeaders", valid_594629
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString
  ##   MultiAZ: JBool
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: JInt
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_594630 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "PreferredMaintenanceWindow", valid_594630
  var valid_594631 = formData.getOrDefault("DBInstanceClass")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "DBInstanceClass", valid_594631
  var valid_594632 = formData.getOrDefault("PreferredBackupWindow")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "PreferredBackupWindow", valid_594632
  var valid_594633 = formData.getOrDefault("MasterUserPassword")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "MasterUserPassword", valid_594633
  var valid_594634 = formData.getOrDefault("MultiAZ")
  valid_594634 = validateParameter(valid_594634, JBool, required = false, default = nil)
  if valid_594634 != nil:
    section.add "MultiAZ", valid_594634
  var valid_594635 = formData.getOrDefault("DBParameterGroupName")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "DBParameterGroupName", valid_594635
  var valid_594636 = formData.getOrDefault("EngineVersion")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "EngineVersion", valid_594636
  var valid_594637 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594637 = validateParameter(valid_594637, JArray, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "VpcSecurityGroupIds", valid_594637
  var valid_594638 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594638 = validateParameter(valid_594638, JInt, required = false, default = nil)
  if valid_594638 != nil:
    section.add "BackupRetentionPeriod", valid_594638
  var valid_594639 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594639 = validateParameter(valid_594639, JBool, required = false, default = nil)
  if valid_594639 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594639
  var valid_594640 = formData.getOrDefault("TdeCredentialPassword")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "TdeCredentialPassword", valid_594640
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594641 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594641 = validateParameter(valid_594641, JString, required = true,
                                 default = nil)
  if valid_594641 != nil:
    section.add "DBInstanceIdentifier", valid_594641
  var valid_594642 = formData.getOrDefault("ApplyImmediately")
  valid_594642 = validateParameter(valid_594642, JBool, required = false, default = nil)
  if valid_594642 != nil:
    section.add "ApplyImmediately", valid_594642
  var valid_594643 = formData.getOrDefault("Iops")
  valid_594643 = validateParameter(valid_594643, JInt, required = false, default = nil)
  if valid_594643 != nil:
    section.add "Iops", valid_594643
  var valid_594644 = formData.getOrDefault("TdeCredentialArn")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "TdeCredentialArn", valid_594644
  var valid_594645 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_594645 = validateParameter(valid_594645, JBool, required = false, default = nil)
  if valid_594645 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594645
  var valid_594646 = formData.getOrDefault("OptionGroupName")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "OptionGroupName", valid_594646
  var valid_594647 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "NewDBInstanceIdentifier", valid_594647
  var valid_594648 = formData.getOrDefault("DBSecurityGroups")
  valid_594648 = validateParameter(valid_594648, JArray, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "DBSecurityGroups", valid_594648
  var valid_594649 = formData.getOrDefault("StorageType")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "StorageType", valid_594649
  var valid_594650 = formData.getOrDefault("AllocatedStorage")
  valid_594650 = validateParameter(valid_594650, JInt, required = false, default = nil)
  if valid_594650 != nil:
    section.add "AllocatedStorage", valid_594650
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594651: Call_PostModifyDBInstance_594618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594651.validator(path, query, header, formData, body)
  let scheme = call_594651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594651.url(scheme.get, call_594651.host, call_594651.base,
                         call_594651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594651, url, valid)

proc call*(call_594652: Call_PostModifyDBInstance_594618;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          ApplyImmediately: bool = false; Iops: int = 0; TdeCredentialArn: string = "";
          Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2014-09-01";
          DBSecurityGroups: JsonNode = nil; StorageType: string = "";
          AllocatedStorage: int = 0): Recallable =
  ## postModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string
  ##   MultiAZ: bool
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: int
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int
  var query_594653 = newJObject()
  var formData_594654 = newJObject()
  add(formData_594654, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594654, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594654, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594654, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594654, "MultiAZ", newJBool(MultiAZ))
  add(formData_594654, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594654, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594654.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594654, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594654, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594654, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_594654, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594654, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_594654, "Iops", newJInt(Iops))
  add(formData_594654, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_594653, "Action", newJString(Action))
  add(formData_594654, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_594654, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594654, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_594653, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_594654.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594654, "StorageType", newJString(StorageType))
  add(formData_594654, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_594652.call(nil, query_594653, nil, formData_594654, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_594618(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_594619, base: "/",
    url: url_PostModifyDBInstance_594620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_594582 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBInstance_594584(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_594583(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   TdeCredentialPassword: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: JBool
  ##   MasterUserPassword: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   PreferredMaintenanceWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_594585 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "NewDBInstanceIdentifier", valid_594585
  var valid_594586 = query.getOrDefault("TdeCredentialPassword")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "TdeCredentialPassword", valid_594586
  var valid_594587 = query.getOrDefault("DBParameterGroupName")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "DBParameterGroupName", valid_594587
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594588 = query.getOrDefault("DBInstanceIdentifier")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = nil)
  if valid_594588 != nil:
    section.add "DBInstanceIdentifier", valid_594588
  var valid_594589 = query.getOrDefault("TdeCredentialArn")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "TdeCredentialArn", valid_594589
  var valid_594590 = query.getOrDefault("BackupRetentionPeriod")
  valid_594590 = validateParameter(valid_594590, JInt, required = false, default = nil)
  if valid_594590 != nil:
    section.add "BackupRetentionPeriod", valid_594590
  var valid_594591 = query.getOrDefault("StorageType")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "StorageType", valid_594591
  var valid_594592 = query.getOrDefault("EngineVersion")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "EngineVersion", valid_594592
  var valid_594593 = query.getOrDefault("Action")
  valid_594593 = validateParameter(valid_594593, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594593 != nil:
    section.add "Action", valid_594593
  var valid_594594 = query.getOrDefault("MultiAZ")
  valid_594594 = validateParameter(valid_594594, JBool, required = false, default = nil)
  if valid_594594 != nil:
    section.add "MultiAZ", valid_594594
  var valid_594595 = query.getOrDefault("DBSecurityGroups")
  valid_594595 = validateParameter(valid_594595, JArray, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "DBSecurityGroups", valid_594595
  var valid_594596 = query.getOrDefault("ApplyImmediately")
  valid_594596 = validateParameter(valid_594596, JBool, required = false, default = nil)
  if valid_594596 != nil:
    section.add "ApplyImmediately", valid_594596
  var valid_594597 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594597 = validateParameter(valid_594597, JArray, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "VpcSecurityGroupIds", valid_594597
  var valid_594598 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_594598 = validateParameter(valid_594598, JBool, required = false, default = nil)
  if valid_594598 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594598
  var valid_594599 = query.getOrDefault("MasterUserPassword")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "MasterUserPassword", valid_594599
  var valid_594600 = query.getOrDefault("OptionGroupName")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "OptionGroupName", valid_594600
  var valid_594601 = query.getOrDefault("Version")
  valid_594601 = validateParameter(valid_594601, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594601 != nil:
    section.add "Version", valid_594601
  var valid_594602 = query.getOrDefault("AllocatedStorage")
  valid_594602 = validateParameter(valid_594602, JInt, required = false, default = nil)
  if valid_594602 != nil:
    section.add "AllocatedStorage", valid_594602
  var valid_594603 = query.getOrDefault("DBInstanceClass")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "DBInstanceClass", valid_594603
  var valid_594604 = query.getOrDefault("PreferredBackupWindow")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "PreferredBackupWindow", valid_594604
  var valid_594605 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "PreferredMaintenanceWindow", valid_594605
  var valid_594606 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594606 = validateParameter(valid_594606, JBool, required = false, default = nil)
  if valid_594606 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594606
  var valid_594607 = query.getOrDefault("Iops")
  valid_594607 = validateParameter(valid_594607, JInt, required = false, default = nil)
  if valid_594607 != nil:
    section.add "Iops", valid_594607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594608 = header.getOrDefault("X-Amz-Signature")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Signature", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Content-Sha256", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Date")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Date", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Credential")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Credential", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Security-Token")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Security-Token", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Algorithm")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Algorithm", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-SignedHeaders", valid_594614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594615: Call_GetModifyDBInstance_594582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594615.validator(path, query, header, formData, body)
  let scheme = call_594615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594615.url(scheme.get, call_594615.host, call_594615.base,
                         call_594615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594615, url, valid)

proc call*(call_594616: Call_GetModifyDBInstance_594582;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          TdeCredentialPassword: string = ""; DBParameterGroupName: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
          Action: string = "ModifyDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2014-09-01";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   TdeCredentialPassword: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: bool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: bool
  ##   MasterUserPassword: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_594617 = newJObject()
  add(query_594617, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_594617, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_594617, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594617, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594617, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_594617, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594617, "StorageType", newJString(StorageType))
  add(query_594617, "EngineVersion", newJString(EngineVersion))
  add(query_594617, "Action", newJString(Action))
  add(query_594617, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_594617.add "DBSecurityGroups", DBSecurityGroups
  add(query_594617, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_594617.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594617, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_594617, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594617, "OptionGroupName", newJString(OptionGroupName))
  add(query_594617, "Version", newJString(Version))
  add(query_594617, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594617, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594617, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594617, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594617, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594617, "Iops", newJInt(Iops))
  result = call_594616.call(nil, query_594617, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_594582(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_594583, base: "/",
    url: url_GetModifyDBInstance_594584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_594672 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBParameterGroup_594674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_594673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594675 = query.getOrDefault("Action")
  valid_594675 = validateParameter(valid_594675, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594675 != nil:
    section.add "Action", valid_594675
  var valid_594676 = query.getOrDefault("Version")
  valid_594676 = validateParameter(valid_594676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594676 != nil:
    section.add "Version", valid_594676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594677 = header.getOrDefault("X-Amz-Signature")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Signature", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Content-Sha256", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Date")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Date", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Credential")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Credential", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Security-Token")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Security-Token", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-Algorithm")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-Algorithm", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-SignedHeaders", valid_594683
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594684 = formData.getOrDefault("DBParameterGroupName")
  valid_594684 = validateParameter(valid_594684, JString, required = true,
                                 default = nil)
  if valid_594684 != nil:
    section.add "DBParameterGroupName", valid_594684
  var valid_594685 = formData.getOrDefault("Parameters")
  valid_594685 = validateParameter(valid_594685, JArray, required = true, default = nil)
  if valid_594685 != nil:
    section.add "Parameters", valid_594685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594686: Call_PostModifyDBParameterGroup_594672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594686.validator(path, query, header, formData, body)
  let scheme = call_594686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594686.url(scheme.get, call_594686.host, call_594686.base,
                         call_594686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594686, url, valid)

proc call*(call_594687: Call_PostModifyDBParameterGroup_594672;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_594688 = newJObject()
  var formData_594689 = newJObject()
  add(formData_594689, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594688, "Action", newJString(Action))
  if Parameters != nil:
    formData_594689.add "Parameters", Parameters
  add(query_594688, "Version", newJString(Version))
  result = call_594687.call(nil, query_594688, nil, formData_594689, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_594672(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_594673, base: "/",
    url: url_PostModifyDBParameterGroup_594674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_594655 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBParameterGroup_594657(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_594656(path: JsonNode; query: JsonNode;
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
  var valid_594658 = query.getOrDefault("DBParameterGroupName")
  valid_594658 = validateParameter(valid_594658, JString, required = true,
                                 default = nil)
  if valid_594658 != nil:
    section.add "DBParameterGroupName", valid_594658
  var valid_594659 = query.getOrDefault("Parameters")
  valid_594659 = validateParameter(valid_594659, JArray, required = true, default = nil)
  if valid_594659 != nil:
    section.add "Parameters", valid_594659
  var valid_594660 = query.getOrDefault("Action")
  valid_594660 = validateParameter(valid_594660, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594660 != nil:
    section.add "Action", valid_594660
  var valid_594661 = query.getOrDefault("Version")
  valid_594661 = validateParameter(valid_594661, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594661 != nil:
    section.add "Version", valid_594661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594662 = header.getOrDefault("X-Amz-Signature")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Signature", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Content-Sha256", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Date")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Date", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Credential")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Credential", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Security-Token")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Security-Token", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Algorithm")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Algorithm", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-SignedHeaders", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594669: Call_GetModifyDBParameterGroup_594655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594669.validator(path, query, header, formData, body)
  let scheme = call_594669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594669.url(scheme.get, call_594669.host, call_594669.base,
                         call_594669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594669, url, valid)

proc call*(call_594670: Call_GetModifyDBParameterGroup_594655;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594671 = newJObject()
  add(query_594671, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594671.add "Parameters", Parameters
  add(query_594671, "Action", newJString(Action))
  add(query_594671, "Version", newJString(Version))
  result = call_594670.call(nil, query_594671, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_594655(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_594656, base: "/",
    url: url_GetModifyDBParameterGroup_594657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_594708 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBSubnetGroup_594710(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_594709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594711 = query.getOrDefault("Action")
  valid_594711 = validateParameter(valid_594711, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594711 != nil:
    section.add "Action", valid_594711
  var valid_594712 = query.getOrDefault("Version")
  valid_594712 = validateParameter(valid_594712, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594712 != nil:
    section.add "Version", valid_594712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594713 = header.getOrDefault("X-Amz-Signature")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Signature", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Content-Sha256", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Date")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Date", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Credential")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Credential", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Security-Token")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Security-Token", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-Algorithm")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-Algorithm", valid_594718
  var valid_594719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-SignedHeaders", valid_594719
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_594720 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "DBSubnetGroupDescription", valid_594720
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594721 = formData.getOrDefault("DBSubnetGroupName")
  valid_594721 = validateParameter(valid_594721, JString, required = true,
                                 default = nil)
  if valid_594721 != nil:
    section.add "DBSubnetGroupName", valid_594721
  var valid_594722 = formData.getOrDefault("SubnetIds")
  valid_594722 = validateParameter(valid_594722, JArray, required = true, default = nil)
  if valid_594722 != nil:
    section.add "SubnetIds", valid_594722
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594723: Call_PostModifyDBSubnetGroup_594708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594723.validator(path, query, header, formData, body)
  let scheme = call_594723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594723.url(scheme.get, call_594723.host, call_594723.base,
                         call_594723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594723, url, valid)

proc call*(call_594724: Call_PostModifyDBSubnetGroup_594708;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_594725 = newJObject()
  var formData_594726 = newJObject()
  add(formData_594726, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594725, "Action", newJString(Action))
  add(formData_594726, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594725, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_594726.add "SubnetIds", SubnetIds
  result = call_594724.call(nil, query_594725, nil, formData_594726, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_594708(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_594709, base: "/",
    url: url_PostModifyDBSubnetGroup_594710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_594690 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBSubnetGroup_594692(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_594691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_594693 = query.getOrDefault("SubnetIds")
  valid_594693 = validateParameter(valid_594693, JArray, required = true, default = nil)
  if valid_594693 != nil:
    section.add "SubnetIds", valid_594693
  var valid_594694 = query.getOrDefault("Action")
  valid_594694 = validateParameter(valid_594694, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594694 != nil:
    section.add "Action", valid_594694
  var valid_594695 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "DBSubnetGroupDescription", valid_594695
  var valid_594696 = query.getOrDefault("DBSubnetGroupName")
  valid_594696 = validateParameter(valid_594696, JString, required = true,
                                 default = nil)
  if valid_594696 != nil:
    section.add "DBSubnetGroupName", valid_594696
  var valid_594697 = query.getOrDefault("Version")
  valid_594697 = validateParameter(valid_594697, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594697 != nil:
    section.add "Version", valid_594697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594698 = header.getOrDefault("X-Amz-Signature")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Signature", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Content-Sha256", valid_594699
  var valid_594700 = header.getOrDefault("X-Amz-Date")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Date", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Credential")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Credential", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Security-Token")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Security-Token", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Algorithm")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Algorithm", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-SignedHeaders", valid_594704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594705: Call_GetModifyDBSubnetGroup_594690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594705.validator(path, query, header, formData, body)
  let scheme = call_594705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594705.url(scheme.get, call_594705.host, call_594705.base,
                         call_594705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594705, url, valid)

proc call*(call_594706: Call_GetModifyDBSubnetGroup_594690; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594707 = newJObject()
  if SubnetIds != nil:
    query_594707.add "SubnetIds", SubnetIds
  add(query_594707, "Action", newJString(Action))
  add(query_594707, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594707, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594707, "Version", newJString(Version))
  result = call_594706.call(nil, query_594707, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_594690(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_594691, base: "/",
    url: url_GetModifyDBSubnetGroup_594692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_594747 = ref object of OpenApiRestCall_592348
proc url_PostModifyEventSubscription_594749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_594748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594750 = query.getOrDefault("Action")
  valid_594750 = validateParameter(valid_594750, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594750 != nil:
    section.add "Action", valid_594750
  var valid_594751 = query.getOrDefault("Version")
  valid_594751 = validateParameter(valid_594751, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594751 != nil:
    section.add "Version", valid_594751
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594752 = header.getOrDefault("X-Amz-Signature")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Signature", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Content-Sha256", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Date")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Date", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Credential")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Credential", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Security-Token")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Security-Token", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Algorithm")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Algorithm", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-SignedHeaders", valid_594758
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_594759 = formData.getOrDefault("SnsTopicArn")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "SnsTopicArn", valid_594759
  var valid_594760 = formData.getOrDefault("Enabled")
  valid_594760 = validateParameter(valid_594760, JBool, required = false, default = nil)
  if valid_594760 != nil:
    section.add "Enabled", valid_594760
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594761 = formData.getOrDefault("SubscriptionName")
  valid_594761 = validateParameter(valid_594761, JString, required = true,
                                 default = nil)
  if valid_594761 != nil:
    section.add "SubscriptionName", valid_594761
  var valid_594762 = formData.getOrDefault("SourceType")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "SourceType", valid_594762
  var valid_594763 = formData.getOrDefault("EventCategories")
  valid_594763 = validateParameter(valid_594763, JArray, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "EventCategories", valid_594763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594764: Call_PostModifyEventSubscription_594747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594764.validator(path, query, header, formData, body)
  let scheme = call_594764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594764.url(scheme.get, call_594764.host, call_594764.base,
                         call_594764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594764, url, valid)

proc call*(call_594765: Call_PostModifyEventSubscription_594747;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2014-09-01"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594766 = newJObject()
  var formData_594767 = newJObject()
  add(formData_594767, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_594767, "Enabled", newJBool(Enabled))
  add(formData_594767, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594767, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_594767.add "EventCategories", EventCategories
  add(query_594766, "Action", newJString(Action))
  add(query_594766, "Version", newJString(Version))
  result = call_594765.call(nil, query_594766, nil, formData_594767, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_594747(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_594748, base: "/",
    url: url_PostModifyEventSubscription_594749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_594727 = ref object of OpenApiRestCall_592348
proc url_GetModifyEventSubscription_594729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_594728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_594730 = query.getOrDefault("SourceType")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "SourceType", valid_594730
  var valid_594731 = query.getOrDefault("Enabled")
  valid_594731 = validateParameter(valid_594731, JBool, required = false, default = nil)
  if valid_594731 != nil:
    section.add "Enabled", valid_594731
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_594732 = query.getOrDefault("SubscriptionName")
  valid_594732 = validateParameter(valid_594732, JString, required = true,
                                 default = nil)
  if valid_594732 != nil:
    section.add "SubscriptionName", valid_594732
  var valid_594733 = query.getOrDefault("EventCategories")
  valid_594733 = validateParameter(valid_594733, JArray, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "EventCategories", valid_594733
  var valid_594734 = query.getOrDefault("Action")
  valid_594734 = validateParameter(valid_594734, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594734 != nil:
    section.add "Action", valid_594734
  var valid_594735 = query.getOrDefault("SnsTopicArn")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "SnsTopicArn", valid_594735
  var valid_594736 = query.getOrDefault("Version")
  valid_594736 = validateParameter(valid_594736, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594736 != nil:
    section.add "Version", valid_594736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594737 = header.getOrDefault("X-Amz-Signature")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Signature", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Content-Sha256", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Date")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Date", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Credential")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Credential", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Security-Token")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Security-Token", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Algorithm")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Algorithm", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-SignedHeaders", valid_594743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594744: Call_GetModifyEventSubscription_594727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594744.validator(path, query, header, formData, body)
  let scheme = call_594744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594744.url(scheme.get, call_594744.host, call_594744.base,
                         call_594744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594744, url, valid)

proc call*(call_594745: Call_GetModifyEventSubscription_594727;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_594746 = newJObject()
  add(query_594746, "SourceType", newJString(SourceType))
  add(query_594746, "Enabled", newJBool(Enabled))
  add(query_594746, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_594746.add "EventCategories", EventCategories
  add(query_594746, "Action", newJString(Action))
  add(query_594746, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_594746, "Version", newJString(Version))
  result = call_594745.call(nil, query_594746, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_594727(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_594728, base: "/",
    url: url_GetModifyEventSubscription_594729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_594787 = ref object of OpenApiRestCall_592348
proc url_PostModifyOptionGroup_594789(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_594788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594790 = query.getOrDefault("Action")
  valid_594790 = validateParameter(valid_594790, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594790 != nil:
    section.add "Action", valid_594790
  var valid_594791 = query.getOrDefault("Version")
  valid_594791 = validateParameter(valid_594791, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594791 != nil:
    section.add "Version", valid_594791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594792 = header.getOrDefault("X-Amz-Signature")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Signature", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Content-Sha256", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Date")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Date", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Credential")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Credential", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Security-Token")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Security-Token", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Algorithm")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Algorithm", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-SignedHeaders", valid_594798
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_594799 = formData.getOrDefault("OptionsToRemove")
  valid_594799 = validateParameter(valid_594799, JArray, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "OptionsToRemove", valid_594799
  var valid_594800 = formData.getOrDefault("ApplyImmediately")
  valid_594800 = validateParameter(valid_594800, JBool, required = false, default = nil)
  if valid_594800 != nil:
    section.add "ApplyImmediately", valid_594800
  var valid_594801 = formData.getOrDefault("OptionsToInclude")
  valid_594801 = validateParameter(valid_594801, JArray, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "OptionsToInclude", valid_594801
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594802 = formData.getOrDefault("OptionGroupName")
  valid_594802 = validateParameter(valid_594802, JString, required = true,
                                 default = nil)
  if valid_594802 != nil:
    section.add "OptionGroupName", valid_594802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594803: Call_PostModifyOptionGroup_594787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594803.validator(path, query, header, formData, body)
  let scheme = call_594803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594803.url(scheme.get, call_594803.host, call_594803.base,
                         call_594803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594803, url, valid)

proc call*(call_594804: Call_PostModifyOptionGroup_594787; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594805 = newJObject()
  var formData_594806 = newJObject()
  if OptionsToRemove != nil:
    formData_594806.add "OptionsToRemove", OptionsToRemove
  add(formData_594806, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_594806.add "OptionsToInclude", OptionsToInclude
  add(query_594805, "Action", newJString(Action))
  add(formData_594806, "OptionGroupName", newJString(OptionGroupName))
  add(query_594805, "Version", newJString(Version))
  result = call_594804.call(nil, query_594805, nil, formData_594806, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_594787(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_594788, base: "/",
    url: url_PostModifyOptionGroup_594789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_594768 = ref object of OpenApiRestCall_592348
proc url_GetModifyOptionGroup_594770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_594769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594771 = query.getOrDefault("Action")
  valid_594771 = validateParameter(valid_594771, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594771 != nil:
    section.add "Action", valid_594771
  var valid_594772 = query.getOrDefault("ApplyImmediately")
  valid_594772 = validateParameter(valid_594772, JBool, required = false, default = nil)
  if valid_594772 != nil:
    section.add "ApplyImmediately", valid_594772
  var valid_594773 = query.getOrDefault("OptionsToRemove")
  valid_594773 = validateParameter(valid_594773, JArray, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "OptionsToRemove", valid_594773
  var valid_594774 = query.getOrDefault("OptionsToInclude")
  valid_594774 = validateParameter(valid_594774, JArray, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "OptionsToInclude", valid_594774
  var valid_594775 = query.getOrDefault("OptionGroupName")
  valid_594775 = validateParameter(valid_594775, JString, required = true,
                                 default = nil)
  if valid_594775 != nil:
    section.add "OptionGroupName", valid_594775
  var valid_594776 = query.getOrDefault("Version")
  valid_594776 = validateParameter(valid_594776, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594776 != nil:
    section.add "Version", valid_594776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594777 = header.getOrDefault("X-Amz-Signature")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Signature", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Content-Sha256", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Date")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Date", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Credential")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Credential", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Security-Token")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Security-Token", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Algorithm")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Algorithm", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-SignedHeaders", valid_594783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594784: Call_GetModifyOptionGroup_594768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594784.validator(path, query, header, formData, body)
  let scheme = call_594784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594784.url(scheme.get, call_594784.host, call_594784.base,
                         call_594784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594784, url, valid)

proc call*(call_594785: Call_GetModifyOptionGroup_594768; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594786 = newJObject()
  add(query_594786, "Action", newJString(Action))
  add(query_594786, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_594786.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_594786.add "OptionsToInclude", OptionsToInclude
  add(query_594786, "OptionGroupName", newJString(OptionGroupName))
  add(query_594786, "Version", newJString(Version))
  result = call_594785.call(nil, query_594786, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_594768(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_594769, base: "/",
    url: url_GetModifyOptionGroup_594770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_594825 = ref object of OpenApiRestCall_592348
proc url_PostPromoteReadReplica_594827(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_594826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594828 = query.getOrDefault("Action")
  valid_594828 = validateParameter(valid_594828, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594828 != nil:
    section.add "Action", valid_594828
  var valid_594829 = query.getOrDefault("Version")
  valid_594829 = validateParameter(valid_594829, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594829 != nil:
    section.add "Version", valid_594829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594830 = header.getOrDefault("X-Amz-Signature")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Signature", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Content-Sha256", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Date")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Date", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Security-Token")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Security-Token", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Algorithm")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Algorithm", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-SignedHeaders", valid_594836
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594837 = formData.getOrDefault("PreferredBackupWindow")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "PreferredBackupWindow", valid_594837
  var valid_594838 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594838 = validateParameter(valid_594838, JInt, required = false, default = nil)
  if valid_594838 != nil:
    section.add "BackupRetentionPeriod", valid_594838
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594839 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594839 = validateParameter(valid_594839, JString, required = true,
                                 default = nil)
  if valid_594839 != nil:
    section.add "DBInstanceIdentifier", valid_594839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594840: Call_PostPromoteReadReplica_594825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594840.validator(path, query, header, formData, body)
  let scheme = call_594840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594840.url(scheme.get, call_594840.host, call_594840.base,
                         call_594840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594840, url, valid)

proc call*(call_594841: Call_PostPromoteReadReplica_594825;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594842 = newJObject()
  var formData_594843 = newJObject()
  add(formData_594843, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594843, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594843, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594842, "Action", newJString(Action))
  add(query_594842, "Version", newJString(Version))
  result = call_594841.call(nil, query_594842, nil, formData_594843, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_594825(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_594826, base: "/",
    url: url_PostPromoteReadReplica_594827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_594807 = ref object of OpenApiRestCall_592348
proc url_GetPromoteReadReplica_594809(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_594808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594810 = query.getOrDefault("DBInstanceIdentifier")
  valid_594810 = validateParameter(valid_594810, JString, required = true,
                                 default = nil)
  if valid_594810 != nil:
    section.add "DBInstanceIdentifier", valid_594810
  var valid_594811 = query.getOrDefault("BackupRetentionPeriod")
  valid_594811 = validateParameter(valid_594811, JInt, required = false, default = nil)
  if valid_594811 != nil:
    section.add "BackupRetentionPeriod", valid_594811
  var valid_594812 = query.getOrDefault("Action")
  valid_594812 = validateParameter(valid_594812, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594812 != nil:
    section.add "Action", valid_594812
  var valid_594813 = query.getOrDefault("Version")
  valid_594813 = validateParameter(valid_594813, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594813 != nil:
    section.add "Version", valid_594813
  var valid_594814 = query.getOrDefault("PreferredBackupWindow")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "PreferredBackupWindow", valid_594814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594815 = header.getOrDefault("X-Amz-Signature")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Signature", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Content-Sha256", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Date")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Date", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Credential")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Credential", valid_594818
  var valid_594819 = header.getOrDefault("X-Amz-Security-Token")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Security-Token", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Algorithm")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Algorithm", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-SignedHeaders", valid_594821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594822: Call_GetPromoteReadReplica_594807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594822.validator(path, query, header, formData, body)
  let scheme = call_594822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594822.url(scheme.get, call_594822.host, call_594822.base,
                         call_594822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594822, url, valid)

proc call*(call_594823: Call_GetPromoteReadReplica_594807;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2014-09-01";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_594824 = newJObject()
  add(query_594824, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594824, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594824, "Action", newJString(Action))
  add(query_594824, "Version", newJString(Version))
  add(query_594824, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_594823.call(nil, query_594824, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_594807(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_594808, base: "/",
    url: url_GetPromoteReadReplica_594809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_594863 = ref object of OpenApiRestCall_592348
proc url_PostPurchaseReservedDBInstancesOffering_594865(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_594864(path: JsonNode;
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
  var valid_594866 = query.getOrDefault("Action")
  valid_594866 = validateParameter(valid_594866, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594866 != nil:
    section.add "Action", valid_594866
  var valid_594867 = query.getOrDefault("Version")
  valid_594867 = validateParameter(valid_594867, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594867 != nil:
    section.add "Version", valid_594867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594868 = header.getOrDefault("X-Amz-Signature")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Signature", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Content-Sha256", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Date")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Date", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-Credential")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Credential", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Security-Token")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Security-Token", valid_594872
  var valid_594873 = header.getOrDefault("X-Amz-Algorithm")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Algorithm", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-SignedHeaders", valid_594874
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_594875 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "ReservedDBInstanceId", valid_594875
  var valid_594876 = formData.getOrDefault("Tags")
  valid_594876 = validateParameter(valid_594876, JArray, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "Tags", valid_594876
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_594877 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594877 = validateParameter(valid_594877, JString, required = true,
                                 default = nil)
  if valid_594877 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594877
  var valid_594878 = formData.getOrDefault("DBInstanceCount")
  valid_594878 = validateParameter(valid_594878, JInt, required = false, default = nil)
  if valid_594878 != nil:
    section.add "DBInstanceCount", valid_594878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594879: Call_PostPurchaseReservedDBInstancesOffering_594863;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594879.validator(path, query, header, formData, body)
  let scheme = call_594879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594879.url(scheme.get, call_594879.host, call_594879.base,
                         call_594879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594879, url, valid)

proc call*(call_594880: Call_PostPurchaseReservedDBInstancesOffering_594863;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2014-09-01"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_594881 = newJObject()
  var formData_594882 = newJObject()
  add(formData_594882, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594881, "Action", newJString(Action))
  if Tags != nil:
    formData_594882.add "Tags", Tags
  add(formData_594882, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594881, "Version", newJString(Version))
  add(formData_594882, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_594880.call(nil, query_594881, nil, formData_594882, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_594863(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_594864, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_594865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_594844 = ref object of OpenApiRestCall_592348
proc url_GetPurchaseReservedDBInstancesOffering_594846(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_594845(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594847 = query.getOrDefault("Tags")
  valid_594847 = validateParameter(valid_594847, JArray, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "Tags", valid_594847
  var valid_594848 = query.getOrDefault("DBInstanceCount")
  valid_594848 = validateParameter(valid_594848, JInt, required = false, default = nil)
  if valid_594848 != nil:
    section.add "DBInstanceCount", valid_594848
  var valid_594849 = query.getOrDefault("ReservedDBInstanceId")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "ReservedDBInstanceId", valid_594849
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594850 = query.getOrDefault("Action")
  valid_594850 = validateParameter(valid_594850, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594850 != nil:
    section.add "Action", valid_594850
  var valid_594851 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594851 = validateParameter(valid_594851, JString, required = true,
                                 default = nil)
  if valid_594851 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594851
  var valid_594852 = query.getOrDefault("Version")
  valid_594852 = validateParameter(valid_594852, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594852 != nil:
    section.add "Version", valid_594852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594853 = header.getOrDefault("X-Amz-Signature")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Signature", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-Content-Sha256", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-Date")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-Date", valid_594855
  var valid_594856 = header.getOrDefault("X-Amz-Credential")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Credential", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-Algorithm")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Algorithm", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-SignedHeaders", valid_594859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594860: Call_GetPurchaseReservedDBInstancesOffering_594844;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594860.validator(path, query, header, formData, body)
  let scheme = call_594860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594860.url(scheme.get, call_594860.host, call_594860.base,
                         call_594860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594860, url, valid)

proc call*(call_594861: Call_GetPurchaseReservedDBInstancesOffering_594844;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_594862 = newJObject()
  if Tags != nil:
    query_594862.add "Tags", Tags
  add(query_594862, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_594862, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594862, "Action", newJString(Action))
  add(query_594862, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594862, "Version", newJString(Version))
  result = call_594861.call(nil, query_594862, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_594844(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_594845, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_594846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_594900 = ref object of OpenApiRestCall_592348
proc url_PostRebootDBInstance_594902(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_594901(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594903 = query.getOrDefault("Action")
  valid_594903 = validateParameter(valid_594903, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594903 != nil:
    section.add "Action", valid_594903
  var valid_594904 = query.getOrDefault("Version")
  valid_594904 = validateParameter(valid_594904, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594904 != nil:
    section.add "Version", valid_594904
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594905 = header.getOrDefault("X-Amz-Signature")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Signature", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Content-Sha256", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Date")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Date", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Credential")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Credential", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Security-Token")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Security-Token", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Algorithm")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Algorithm", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-SignedHeaders", valid_594911
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594912 = formData.getOrDefault("ForceFailover")
  valid_594912 = validateParameter(valid_594912, JBool, required = false, default = nil)
  if valid_594912 != nil:
    section.add "ForceFailover", valid_594912
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594913 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594913 = validateParameter(valid_594913, JString, required = true,
                                 default = nil)
  if valid_594913 != nil:
    section.add "DBInstanceIdentifier", valid_594913
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594914: Call_PostRebootDBInstance_594900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594914.validator(path, query, header, formData, body)
  let scheme = call_594914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594914.url(scheme.get, call_594914.host, call_594914.base,
                         call_594914.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594914, url, valid)

proc call*(call_594915: Call_PostRebootDBInstance_594900;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594916 = newJObject()
  var formData_594917 = newJObject()
  add(formData_594917, "ForceFailover", newJBool(ForceFailover))
  add(formData_594917, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594916, "Action", newJString(Action))
  add(query_594916, "Version", newJString(Version))
  result = call_594915.call(nil, query_594916, nil, formData_594917, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_594900(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_594901, base: "/",
    url: url_PostRebootDBInstance_594902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_594883 = ref object of OpenApiRestCall_592348
proc url_GetRebootDBInstance_594885(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_594884(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594886 = query.getOrDefault("ForceFailover")
  valid_594886 = validateParameter(valid_594886, JBool, required = false, default = nil)
  if valid_594886 != nil:
    section.add "ForceFailover", valid_594886
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594887 = query.getOrDefault("DBInstanceIdentifier")
  valid_594887 = validateParameter(valid_594887, JString, required = true,
                                 default = nil)
  if valid_594887 != nil:
    section.add "DBInstanceIdentifier", valid_594887
  var valid_594888 = query.getOrDefault("Action")
  valid_594888 = validateParameter(valid_594888, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594888 != nil:
    section.add "Action", valid_594888
  var valid_594889 = query.getOrDefault("Version")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594889 != nil:
    section.add "Version", valid_594889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594890 = header.getOrDefault("X-Amz-Signature")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Signature", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Content-Sha256", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Date")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Date", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Credential")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Credential", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-Security-Token")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Security-Token", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Algorithm")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Algorithm", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-SignedHeaders", valid_594896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594897: Call_GetRebootDBInstance_594883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594897.validator(path, query, header, formData, body)
  let scheme = call_594897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594897.url(scheme.get, call_594897.host, call_594897.base,
                         call_594897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594897, url, valid)

proc call*(call_594898: Call_GetRebootDBInstance_594883;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594899 = newJObject()
  add(query_594899, "ForceFailover", newJBool(ForceFailover))
  add(query_594899, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594899, "Action", newJString(Action))
  add(query_594899, "Version", newJString(Version))
  result = call_594898.call(nil, query_594899, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_594883(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_594884, base: "/",
    url: url_GetRebootDBInstance_594885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_594935 = ref object of OpenApiRestCall_592348
proc url_PostRemoveSourceIdentifierFromSubscription_594937(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_594936(path: JsonNode;
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
  var valid_594938 = query.getOrDefault("Action")
  valid_594938 = validateParameter(valid_594938, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594938 != nil:
    section.add "Action", valid_594938
  var valid_594939 = query.getOrDefault("Version")
  valid_594939 = validateParameter(valid_594939, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594939 != nil:
    section.add "Version", valid_594939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594940 = header.getOrDefault("X-Amz-Signature")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Signature", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Content-Sha256", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Date")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Date", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Credential")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Credential", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Security-Token")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Security-Token", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Algorithm")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Algorithm", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-SignedHeaders", valid_594946
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594947 = formData.getOrDefault("SubscriptionName")
  valid_594947 = validateParameter(valid_594947, JString, required = true,
                                 default = nil)
  if valid_594947 != nil:
    section.add "SubscriptionName", valid_594947
  var valid_594948 = formData.getOrDefault("SourceIdentifier")
  valid_594948 = validateParameter(valid_594948, JString, required = true,
                                 default = nil)
  if valid_594948 != nil:
    section.add "SourceIdentifier", valid_594948
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594949: Call_PostRemoveSourceIdentifierFromSubscription_594935;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594949.validator(path, query, header, formData, body)
  let scheme = call_594949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594949.url(scheme.get, call_594949.host, call_594949.base,
                         call_594949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594949, url, valid)

proc call*(call_594950: Call_PostRemoveSourceIdentifierFromSubscription_594935;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594951 = newJObject()
  var formData_594952 = newJObject()
  add(formData_594952, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594952, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594951, "Action", newJString(Action))
  add(query_594951, "Version", newJString(Version))
  result = call_594950.call(nil, query_594951, nil, formData_594952, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_594935(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_594936,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_594937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_594918 = ref object of OpenApiRestCall_592348
proc url_GetRemoveSourceIdentifierFromSubscription_594920(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_594919(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_594921 = query.getOrDefault("SourceIdentifier")
  valid_594921 = validateParameter(valid_594921, JString, required = true,
                                 default = nil)
  if valid_594921 != nil:
    section.add "SourceIdentifier", valid_594921
  var valid_594922 = query.getOrDefault("SubscriptionName")
  valid_594922 = validateParameter(valid_594922, JString, required = true,
                                 default = nil)
  if valid_594922 != nil:
    section.add "SubscriptionName", valid_594922
  var valid_594923 = query.getOrDefault("Action")
  valid_594923 = validateParameter(valid_594923, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594923 != nil:
    section.add "Action", valid_594923
  var valid_594924 = query.getOrDefault("Version")
  valid_594924 = validateParameter(valid_594924, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594924 != nil:
    section.add "Version", valid_594924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594925 = header.getOrDefault("X-Amz-Signature")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Signature", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Content-Sha256", valid_594926
  var valid_594927 = header.getOrDefault("X-Amz-Date")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "X-Amz-Date", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-Credential")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-Credential", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Security-Token")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Security-Token", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Algorithm")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Algorithm", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-SignedHeaders", valid_594931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594932: Call_GetRemoveSourceIdentifierFromSubscription_594918;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594932.validator(path, query, header, formData, body)
  let scheme = call_594932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594932.url(scheme.get, call_594932.host, call_594932.base,
                         call_594932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594932, url, valid)

proc call*(call_594933: Call_GetRemoveSourceIdentifierFromSubscription_594918;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594934 = newJObject()
  add(query_594934, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594934, "SubscriptionName", newJString(SubscriptionName))
  add(query_594934, "Action", newJString(Action))
  add(query_594934, "Version", newJString(Version))
  result = call_594933.call(nil, query_594934, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_594918(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_594919,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_594920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_594970 = ref object of OpenApiRestCall_592348
proc url_PostRemoveTagsFromResource_594972(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_594971(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594973 = query.getOrDefault("Action")
  valid_594973 = validateParameter(valid_594973, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594973 != nil:
    section.add "Action", valid_594973
  var valid_594974 = query.getOrDefault("Version")
  valid_594974 = validateParameter(valid_594974, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594974 != nil:
    section.add "Version", valid_594974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594975 = header.getOrDefault("X-Amz-Signature")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Signature", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Content-Sha256", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Date")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Date", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Credential")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Credential", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-Security-Token")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-Security-Token", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-Algorithm")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-Algorithm", valid_594980
  var valid_594981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-SignedHeaders", valid_594981
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594982 = formData.getOrDefault("TagKeys")
  valid_594982 = validateParameter(valid_594982, JArray, required = true, default = nil)
  if valid_594982 != nil:
    section.add "TagKeys", valid_594982
  var valid_594983 = formData.getOrDefault("ResourceName")
  valid_594983 = validateParameter(valid_594983, JString, required = true,
                                 default = nil)
  if valid_594983 != nil:
    section.add "ResourceName", valid_594983
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594984: Call_PostRemoveTagsFromResource_594970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594984.validator(path, query, header, formData, body)
  let scheme = call_594984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594984.url(scheme.get, call_594984.host, call_594984.base,
                         call_594984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594984, url, valid)

proc call*(call_594985: Call_PostRemoveTagsFromResource_594970; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594986 = newJObject()
  var formData_594987 = newJObject()
  if TagKeys != nil:
    formData_594987.add "TagKeys", TagKeys
  add(query_594986, "Action", newJString(Action))
  add(query_594986, "Version", newJString(Version))
  add(formData_594987, "ResourceName", newJString(ResourceName))
  result = call_594985.call(nil, query_594986, nil, formData_594987, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_594970(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_594971, base: "/",
    url: url_PostRemoveTagsFromResource_594972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_594953 = ref object of OpenApiRestCall_592348
proc url_GetRemoveTagsFromResource_594955(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_594954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   TagKeys: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_594956 = query.getOrDefault("ResourceName")
  valid_594956 = validateParameter(valid_594956, JString, required = true,
                                 default = nil)
  if valid_594956 != nil:
    section.add "ResourceName", valid_594956
  var valid_594957 = query.getOrDefault("TagKeys")
  valid_594957 = validateParameter(valid_594957, JArray, required = true, default = nil)
  if valid_594957 != nil:
    section.add "TagKeys", valid_594957
  var valid_594958 = query.getOrDefault("Action")
  valid_594958 = validateParameter(valid_594958, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594958 != nil:
    section.add "Action", valid_594958
  var valid_594959 = query.getOrDefault("Version")
  valid_594959 = validateParameter(valid_594959, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594959 != nil:
    section.add "Version", valid_594959
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594960 = header.getOrDefault("X-Amz-Signature")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Signature", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Content-Sha256", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Date")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Date", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-Credential")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Credential", valid_594963
  var valid_594964 = header.getOrDefault("X-Amz-Security-Token")
  valid_594964 = validateParameter(valid_594964, JString, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "X-Amz-Security-Token", valid_594964
  var valid_594965 = header.getOrDefault("X-Amz-Algorithm")
  valid_594965 = validateParameter(valid_594965, JString, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "X-Amz-Algorithm", valid_594965
  var valid_594966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594966 = validateParameter(valid_594966, JString, required = false,
                                 default = nil)
  if valid_594966 != nil:
    section.add "X-Amz-SignedHeaders", valid_594966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594967: Call_GetRemoveTagsFromResource_594953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594967.validator(path, query, header, formData, body)
  let scheme = call_594967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594967.url(scheme.get, call_594967.host, call_594967.base,
                         call_594967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594967, url, valid)

proc call*(call_594968: Call_GetRemoveTagsFromResource_594953;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594969 = newJObject()
  add(query_594969, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_594969.add "TagKeys", TagKeys
  add(query_594969, "Action", newJString(Action))
  add(query_594969, "Version", newJString(Version))
  result = call_594968.call(nil, query_594969, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_594953(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_594954, base: "/",
    url: url_GetRemoveTagsFromResource_594955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_595006 = ref object of OpenApiRestCall_592348
proc url_PostResetDBParameterGroup_595008(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_595007(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595009 = query.getOrDefault("Action")
  valid_595009 = validateParameter(valid_595009, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595009 != nil:
    section.add "Action", valid_595009
  var valid_595010 = query.getOrDefault("Version")
  valid_595010 = validateParameter(valid_595010, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595010 != nil:
    section.add "Version", valid_595010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595011 = header.getOrDefault("X-Amz-Signature")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Signature", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-Content-Sha256", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Date")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Date", valid_595013
  var valid_595014 = header.getOrDefault("X-Amz-Credential")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = nil)
  if valid_595014 != nil:
    section.add "X-Amz-Credential", valid_595014
  var valid_595015 = header.getOrDefault("X-Amz-Security-Token")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "X-Amz-Security-Token", valid_595015
  var valid_595016 = header.getOrDefault("X-Amz-Algorithm")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Algorithm", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-SignedHeaders", valid_595017
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_595018 = formData.getOrDefault("ResetAllParameters")
  valid_595018 = validateParameter(valid_595018, JBool, required = false, default = nil)
  if valid_595018 != nil:
    section.add "ResetAllParameters", valid_595018
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595019 = formData.getOrDefault("DBParameterGroupName")
  valid_595019 = validateParameter(valid_595019, JString, required = true,
                                 default = nil)
  if valid_595019 != nil:
    section.add "DBParameterGroupName", valid_595019
  var valid_595020 = formData.getOrDefault("Parameters")
  valid_595020 = validateParameter(valid_595020, JArray, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "Parameters", valid_595020
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595021: Call_PostResetDBParameterGroup_595006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595021.validator(path, query, header, formData, body)
  let scheme = call_595021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595021.url(scheme.get, call_595021.host, call_595021.base,
                         call_595021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595021, url, valid)

proc call*(call_595022: Call_PostResetDBParameterGroup_595006;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_595023 = newJObject()
  var formData_595024 = newJObject()
  add(formData_595024, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_595024, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595023, "Action", newJString(Action))
  if Parameters != nil:
    formData_595024.add "Parameters", Parameters
  add(query_595023, "Version", newJString(Version))
  result = call_595022.call(nil, query_595023, nil, formData_595024, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_595006(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_595007, base: "/",
    url: url_PostResetDBParameterGroup_595008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_594988 = ref object of OpenApiRestCall_592348
proc url_GetResetDBParameterGroup_594990(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_594989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_594991 = query.getOrDefault("DBParameterGroupName")
  valid_594991 = validateParameter(valid_594991, JString, required = true,
                                 default = nil)
  if valid_594991 != nil:
    section.add "DBParameterGroupName", valid_594991
  var valid_594992 = query.getOrDefault("Parameters")
  valid_594992 = validateParameter(valid_594992, JArray, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "Parameters", valid_594992
  var valid_594993 = query.getOrDefault("ResetAllParameters")
  valid_594993 = validateParameter(valid_594993, JBool, required = false, default = nil)
  if valid_594993 != nil:
    section.add "ResetAllParameters", valid_594993
  var valid_594994 = query.getOrDefault("Action")
  valid_594994 = validateParameter(valid_594994, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594994 != nil:
    section.add "Action", valid_594994
  var valid_594995 = query.getOrDefault("Version")
  valid_594995 = validateParameter(valid_594995, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_594995 != nil:
    section.add "Version", valid_594995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594996 = header.getOrDefault("X-Amz-Signature")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Signature", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Content-Sha256", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Date")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Date", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-Credential")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-Credential", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Security-Token")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Security-Token", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-Algorithm")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-Algorithm", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-SignedHeaders", valid_595002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595003: Call_GetResetDBParameterGroup_594988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595003.validator(path, query, header, formData, body)
  let scheme = call_595003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595003.url(scheme.get, call_595003.host, call_595003.base,
                         call_595003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595003, url, valid)

proc call*(call_595004: Call_GetResetDBParameterGroup_594988;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595005 = newJObject()
  add(query_595005, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595005.add "Parameters", Parameters
  add(query_595005, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595005, "Action", newJString(Action))
  add(query_595005, "Version", newJString(Version))
  result = call_595004.call(nil, query_595005, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_594988(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_594989, base: "/",
    url: url_GetResetDBParameterGroup_594990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_595058 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceFromDBSnapshot_595060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_595059(path: JsonNode;
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
  var valid_595061 = query.getOrDefault("Action")
  valid_595061 = validateParameter(valid_595061, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595061 != nil:
    section.add "Action", valid_595061
  var valid_595062 = query.getOrDefault("Version")
  valid_595062 = validateParameter(valid_595062, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595062 != nil:
    section.add "Version", valid_595062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595063 = header.getOrDefault("X-Amz-Signature")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Signature", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Content-Sha256", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Date")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Date", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Credential")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Credential", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Security-Token")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Security-Token", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-Algorithm")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-Algorithm", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-SignedHeaders", valid_595069
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   StorageType: JString
  section = newJObject()
  var valid_595070 = formData.getOrDefault("Port")
  valid_595070 = validateParameter(valid_595070, JInt, required = false, default = nil)
  if valid_595070 != nil:
    section.add "Port", valid_595070
  var valid_595071 = formData.getOrDefault("DBInstanceClass")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "DBInstanceClass", valid_595071
  var valid_595072 = formData.getOrDefault("MultiAZ")
  valid_595072 = validateParameter(valid_595072, JBool, required = false, default = nil)
  if valid_595072 != nil:
    section.add "MultiAZ", valid_595072
  var valid_595073 = formData.getOrDefault("AvailabilityZone")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "AvailabilityZone", valid_595073
  var valid_595074 = formData.getOrDefault("Engine")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "Engine", valid_595074
  var valid_595075 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595075 = validateParameter(valid_595075, JBool, required = false, default = nil)
  if valid_595075 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595075
  var valid_595076 = formData.getOrDefault("TdeCredentialPassword")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "TdeCredentialPassword", valid_595076
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595077 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595077 = validateParameter(valid_595077, JString, required = true,
                                 default = nil)
  if valid_595077 != nil:
    section.add "DBInstanceIdentifier", valid_595077
  var valid_595078 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595078 = validateParameter(valid_595078, JString, required = true,
                                 default = nil)
  if valid_595078 != nil:
    section.add "DBSnapshotIdentifier", valid_595078
  var valid_595079 = formData.getOrDefault("DBName")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "DBName", valid_595079
  var valid_595080 = formData.getOrDefault("Iops")
  valid_595080 = validateParameter(valid_595080, JInt, required = false, default = nil)
  if valid_595080 != nil:
    section.add "Iops", valid_595080
  var valid_595081 = formData.getOrDefault("TdeCredentialArn")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "TdeCredentialArn", valid_595081
  var valid_595082 = formData.getOrDefault("PubliclyAccessible")
  valid_595082 = validateParameter(valid_595082, JBool, required = false, default = nil)
  if valid_595082 != nil:
    section.add "PubliclyAccessible", valid_595082
  var valid_595083 = formData.getOrDefault("LicenseModel")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "LicenseModel", valid_595083
  var valid_595084 = formData.getOrDefault("Tags")
  valid_595084 = validateParameter(valid_595084, JArray, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "Tags", valid_595084
  var valid_595085 = formData.getOrDefault("DBSubnetGroupName")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "DBSubnetGroupName", valid_595085
  var valid_595086 = formData.getOrDefault("OptionGroupName")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "OptionGroupName", valid_595086
  var valid_595087 = formData.getOrDefault("StorageType")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "StorageType", valid_595087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595088: Call_PostRestoreDBInstanceFromDBSnapshot_595058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595088.validator(path, query, header, formData, body)
  let scheme = call_595088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595088.url(scheme.get, call_595088.host, call_595088.base,
                         call_595088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595088, url, valid)

proc call*(call_595089: Call_PostRestoreDBInstanceFromDBSnapshot_595058;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          DBName: string = ""; Iops: int = 0; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   StorageType: string
  var query_595090 = newJObject()
  var formData_595091 = newJObject()
  add(formData_595091, "Port", newJInt(Port))
  add(formData_595091, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595091, "MultiAZ", newJBool(MultiAZ))
  add(formData_595091, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_595091, "Engine", newJString(Engine))
  add(formData_595091, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595091, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_595091, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595091, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_595091, "DBName", newJString(DBName))
  add(formData_595091, "Iops", newJInt(Iops))
  add(formData_595091, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_595091, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595090, "Action", newJString(Action))
  add(formData_595091, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_595091.add "Tags", Tags
  add(formData_595091, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595091, "OptionGroupName", newJString(OptionGroupName))
  add(query_595090, "Version", newJString(Version))
  add(formData_595091, "StorageType", newJString(StorageType))
  result = call_595089.call(nil, query_595090, nil, formData_595091, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_595058(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_595059, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_595060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_595025 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceFromDBSnapshot_595027(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_595026(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_595028 = query.getOrDefault("DBName")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "DBName", valid_595028
  var valid_595029 = query.getOrDefault("TdeCredentialPassword")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "TdeCredentialPassword", valid_595029
  var valid_595030 = query.getOrDefault("Engine")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "Engine", valid_595030
  var valid_595031 = query.getOrDefault("Tags")
  valid_595031 = validateParameter(valid_595031, JArray, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "Tags", valid_595031
  var valid_595032 = query.getOrDefault("LicenseModel")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "LicenseModel", valid_595032
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595033 = query.getOrDefault("DBInstanceIdentifier")
  valid_595033 = validateParameter(valid_595033, JString, required = true,
                                 default = nil)
  if valid_595033 != nil:
    section.add "DBInstanceIdentifier", valid_595033
  var valid_595034 = query.getOrDefault("DBSnapshotIdentifier")
  valid_595034 = validateParameter(valid_595034, JString, required = true,
                                 default = nil)
  if valid_595034 != nil:
    section.add "DBSnapshotIdentifier", valid_595034
  var valid_595035 = query.getOrDefault("TdeCredentialArn")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "TdeCredentialArn", valid_595035
  var valid_595036 = query.getOrDefault("StorageType")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "StorageType", valid_595036
  var valid_595037 = query.getOrDefault("Action")
  valid_595037 = validateParameter(valid_595037, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595037 != nil:
    section.add "Action", valid_595037
  var valid_595038 = query.getOrDefault("MultiAZ")
  valid_595038 = validateParameter(valid_595038, JBool, required = false, default = nil)
  if valid_595038 != nil:
    section.add "MultiAZ", valid_595038
  var valid_595039 = query.getOrDefault("Port")
  valid_595039 = validateParameter(valid_595039, JInt, required = false, default = nil)
  if valid_595039 != nil:
    section.add "Port", valid_595039
  var valid_595040 = query.getOrDefault("AvailabilityZone")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "AvailabilityZone", valid_595040
  var valid_595041 = query.getOrDefault("OptionGroupName")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "OptionGroupName", valid_595041
  var valid_595042 = query.getOrDefault("DBSubnetGroupName")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "DBSubnetGroupName", valid_595042
  var valid_595043 = query.getOrDefault("Version")
  valid_595043 = validateParameter(valid_595043, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595043 != nil:
    section.add "Version", valid_595043
  var valid_595044 = query.getOrDefault("DBInstanceClass")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "DBInstanceClass", valid_595044
  var valid_595045 = query.getOrDefault("PubliclyAccessible")
  valid_595045 = validateParameter(valid_595045, JBool, required = false, default = nil)
  if valid_595045 != nil:
    section.add "PubliclyAccessible", valid_595045
  var valid_595046 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595046 = validateParameter(valid_595046, JBool, required = false, default = nil)
  if valid_595046 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595046
  var valid_595047 = query.getOrDefault("Iops")
  valid_595047 = validateParameter(valid_595047, JInt, required = false, default = nil)
  if valid_595047 != nil:
    section.add "Iops", valid_595047
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595048 = header.getOrDefault("X-Amz-Signature")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Signature", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Content-Sha256", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Date")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Date", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Credential")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Credential", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Security-Token")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Security-Token", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Algorithm")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Algorithm", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-SignedHeaders", valid_595054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595055: Call_GetRestoreDBInstanceFromDBSnapshot_595025;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595055.validator(path, query, header, formData, body)
  let scheme = call_595055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595055.url(scheme.get, call_595055.host, call_595055.base,
                         call_595055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595055, url, valid)

proc call*(call_595056: Call_GetRestoreDBInstanceFromDBSnapshot_595025;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; StorageType: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   StorageType: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_595057 = newJObject()
  add(query_595057, "DBName", newJString(DBName))
  add(query_595057, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_595057, "Engine", newJString(Engine))
  if Tags != nil:
    query_595057.add "Tags", Tags
  add(query_595057, "LicenseModel", newJString(LicenseModel))
  add(query_595057, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595057, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_595057, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_595057, "StorageType", newJString(StorageType))
  add(query_595057, "Action", newJString(Action))
  add(query_595057, "MultiAZ", newJBool(MultiAZ))
  add(query_595057, "Port", newJInt(Port))
  add(query_595057, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595057, "OptionGroupName", newJString(OptionGroupName))
  add(query_595057, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595057, "Version", newJString(Version))
  add(query_595057, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595057, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595057, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595057, "Iops", newJInt(Iops))
  result = call_595056.call(nil, query_595057, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_595025(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_595026, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_595027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_595127 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceToPointInTime_595129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_595128(path: JsonNode;
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
  var valid_595130 = query.getOrDefault("Action")
  valid_595130 = validateParameter(valid_595130, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595130 != nil:
    section.add "Action", valid_595130
  var valid_595131 = query.getOrDefault("Version")
  valid_595131 = validateParameter(valid_595131, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595131 != nil:
    section.add "Version", valid_595131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595132 = header.getOrDefault("X-Amz-Signature")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-Signature", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Content-Sha256", valid_595133
  var valid_595134 = header.getOrDefault("X-Amz-Date")
  valid_595134 = validateParameter(valid_595134, JString, required = false,
                                 default = nil)
  if valid_595134 != nil:
    section.add "X-Amz-Date", valid_595134
  var valid_595135 = header.getOrDefault("X-Amz-Credential")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "X-Amz-Credential", valid_595135
  var valid_595136 = header.getOrDefault("X-Amz-Security-Token")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Security-Token", valid_595136
  var valid_595137 = header.getOrDefault("X-Amz-Algorithm")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "X-Amz-Algorithm", valid_595137
  var valid_595138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "X-Amz-SignedHeaders", valid_595138
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  section = newJObject()
  var valid_595139 = formData.getOrDefault("Port")
  valid_595139 = validateParameter(valid_595139, JInt, required = false, default = nil)
  if valid_595139 != nil:
    section.add "Port", valid_595139
  var valid_595140 = formData.getOrDefault("DBInstanceClass")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "DBInstanceClass", valid_595140
  var valid_595141 = formData.getOrDefault("MultiAZ")
  valid_595141 = validateParameter(valid_595141, JBool, required = false, default = nil)
  if valid_595141 != nil:
    section.add "MultiAZ", valid_595141
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_595142 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_595142 = validateParameter(valid_595142, JString, required = true,
                                 default = nil)
  if valid_595142 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595142
  var valid_595143 = formData.getOrDefault("AvailabilityZone")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "AvailabilityZone", valid_595143
  var valid_595144 = formData.getOrDefault("Engine")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "Engine", valid_595144
  var valid_595145 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595145 = validateParameter(valid_595145, JBool, required = false, default = nil)
  if valid_595145 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595145
  var valid_595146 = formData.getOrDefault("TdeCredentialPassword")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "TdeCredentialPassword", valid_595146
  var valid_595147 = formData.getOrDefault("UseLatestRestorableTime")
  valid_595147 = validateParameter(valid_595147, JBool, required = false, default = nil)
  if valid_595147 != nil:
    section.add "UseLatestRestorableTime", valid_595147
  var valid_595148 = formData.getOrDefault("DBName")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "DBName", valid_595148
  var valid_595149 = formData.getOrDefault("Iops")
  valid_595149 = validateParameter(valid_595149, JInt, required = false, default = nil)
  if valid_595149 != nil:
    section.add "Iops", valid_595149
  var valid_595150 = formData.getOrDefault("TdeCredentialArn")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "TdeCredentialArn", valid_595150
  var valid_595151 = formData.getOrDefault("PubliclyAccessible")
  valid_595151 = validateParameter(valid_595151, JBool, required = false, default = nil)
  if valid_595151 != nil:
    section.add "PubliclyAccessible", valid_595151
  var valid_595152 = formData.getOrDefault("LicenseModel")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "LicenseModel", valid_595152
  var valid_595153 = formData.getOrDefault("Tags")
  valid_595153 = validateParameter(valid_595153, JArray, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "Tags", valid_595153
  var valid_595154 = formData.getOrDefault("DBSubnetGroupName")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "DBSubnetGroupName", valid_595154
  var valid_595155 = formData.getOrDefault("OptionGroupName")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "OptionGroupName", valid_595155
  var valid_595156 = formData.getOrDefault("RestoreTime")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "RestoreTime", valid_595156
  var valid_595157 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_595157 = validateParameter(valid_595157, JString, required = true,
                                 default = nil)
  if valid_595157 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595157
  var valid_595158 = formData.getOrDefault("StorageType")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "StorageType", valid_595158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595159: Call_PostRestoreDBInstanceToPointInTime_595127;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595159.validator(path, query, header, formData, body)
  let scheme = call_595159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595159.url(scheme.get, call_595159.host, call_595159.base,
                         call_595159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595159, url, valid)

proc call*(call_595160: Call_PostRestoreDBInstanceToPointInTime_595127;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2014-09-01";
          StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   StorageType: string
  var query_595161 = newJObject()
  var formData_595162 = newJObject()
  add(formData_595162, "Port", newJInt(Port))
  add(formData_595162, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595162, "MultiAZ", newJBool(MultiAZ))
  add(formData_595162, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_595162, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_595162, "Engine", newJString(Engine))
  add(formData_595162, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595162, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_595162, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_595162, "DBName", newJString(DBName))
  add(formData_595162, "Iops", newJInt(Iops))
  add(formData_595162, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_595162, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595161, "Action", newJString(Action))
  add(formData_595162, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_595162.add "Tags", Tags
  add(formData_595162, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595162, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595162, "RestoreTime", newJString(RestoreTime))
  add(formData_595162, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595161, "Version", newJString(Version))
  add(formData_595162, "StorageType", newJString(StorageType))
  result = call_595160.call(nil, query_595161, nil, formData_595162, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_595127(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_595128, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_595129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_595092 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceToPointInTime_595094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_595093(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   RestoreTime: JString
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_595095 = query.getOrDefault("DBName")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "DBName", valid_595095
  var valid_595096 = query.getOrDefault("TdeCredentialPassword")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "TdeCredentialPassword", valid_595096
  var valid_595097 = query.getOrDefault("Engine")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "Engine", valid_595097
  var valid_595098 = query.getOrDefault("UseLatestRestorableTime")
  valid_595098 = validateParameter(valid_595098, JBool, required = false, default = nil)
  if valid_595098 != nil:
    section.add "UseLatestRestorableTime", valid_595098
  var valid_595099 = query.getOrDefault("Tags")
  valid_595099 = validateParameter(valid_595099, JArray, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "Tags", valid_595099
  var valid_595100 = query.getOrDefault("LicenseModel")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "LicenseModel", valid_595100
  var valid_595101 = query.getOrDefault("TdeCredentialArn")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "TdeCredentialArn", valid_595101
  var valid_595102 = query.getOrDefault("StorageType")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "StorageType", valid_595102
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_595103 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_595103 = validateParameter(valid_595103, JString, required = true,
                                 default = nil)
  if valid_595103 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595103
  var valid_595104 = query.getOrDefault("Action")
  valid_595104 = validateParameter(valid_595104, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595104 != nil:
    section.add "Action", valid_595104
  var valid_595105 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_595105 = validateParameter(valid_595105, JString, required = true,
                                 default = nil)
  if valid_595105 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595105
  var valid_595106 = query.getOrDefault("MultiAZ")
  valid_595106 = validateParameter(valid_595106, JBool, required = false, default = nil)
  if valid_595106 != nil:
    section.add "MultiAZ", valid_595106
  var valid_595107 = query.getOrDefault("Port")
  valid_595107 = validateParameter(valid_595107, JInt, required = false, default = nil)
  if valid_595107 != nil:
    section.add "Port", valid_595107
  var valid_595108 = query.getOrDefault("AvailabilityZone")
  valid_595108 = validateParameter(valid_595108, JString, required = false,
                                 default = nil)
  if valid_595108 != nil:
    section.add "AvailabilityZone", valid_595108
  var valid_595109 = query.getOrDefault("OptionGroupName")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "OptionGroupName", valid_595109
  var valid_595110 = query.getOrDefault("DBSubnetGroupName")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "DBSubnetGroupName", valid_595110
  var valid_595111 = query.getOrDefault("RestoreTime")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "RestoreTime", valid_595111
  var valid_595112 = query.getOrDefault("DBInstanceClass")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "DBInstanceClass", valid_595112
  var valid_595113 = query.getOrDefault("PubliclyAccessible")
  valid_595113 = validateParameter(valid_595113, JBool, required = false, default = nil)
  if valid_595113 != nil:
    section.add "PubliclyAccessible", valid_595113
  var valid_595114 = query.getOrDefault("Version")
  valid_595114 = validateParameter(valid_595114, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595114 != nil:
    section.add "Version", valid_595114
  var valid_595115 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595115 = validateParameter(valid_595115, JBool, required = false, default = nil)
  if valid_595115 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595115
  var valid_595116 = query.getOrDefault("Iops")
  valid_595116 = validateParameter(valid_595116, JInt, required = false, default = nil)
  if valid_595116 != nil:
    section.add "Iops", valid_595116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595117 = header.getOrDefault("X-Amz-Signature")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Signature", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Content-Sha256", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-Date")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-Date", valid_595119
  var valid_595120 = header.getOrDefault("X-Amz-Credential")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "X-Amz-Credential", valid_595120
  var valid_595121 = header.getOrDefault("X-Amz-Security-Token")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-Security-Token", valid_595121
  var valid_595122 = header.getOrDefault("X-Amz-Algorithm")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "X-Amz-Algorithm", valid_595122
  var valid_595123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595123 = validateParameter(valid_595123, JString, required = false,
                                 default = nil)
  if valid_595123 != nil:
    section.add "X-Amz-SignedHeaders", valid_595123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595124: Call_GetRestoreDBInstanceToPointInTime_595092;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595124.validator(path, query, header, formData, body)
  let scheme = call_595124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595124.url(scheme.get, call_595124.host, call_595124.base,
                         call_595124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595124, url, valid)

proc call*(call_595125: Call_GetRestoreDBInstanceToPointInTime_595092;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = ""; TdeCredentialArn: string = "";
          StorageType: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2014-09-01"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   TdeCredentialArn: string
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   RestoreTime: string
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_595126 = newJObject()
  add(query_595126, "DBName", newJString(DBName))
  add(query_595126, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_595126, "Engine", newJString(Engine))
  add(query_595126, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_595126.add "Tags", Tags
  add(query_595126, "LicenseModel", newJString(LicenseModel))
  add(query_595126, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_595126, "StorageType", newJString(StorageType))
  add(query_595126, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595126, "Action", newJString(Action))
  add(query_595126, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_595126, "MultiAZ", newJBool(MultiAZ))
  add(query_595126, "Port", newJInt(Port))
  add(query_595126, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595126, "OptionGroupName", newJString(OptionGroupName))
  add(query_595126, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595126, "RestoreTime", newJString(RestoreTime))
  add(query_595126, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595126, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595126, "Version", newJString(Version))
  add(query_595126, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595126, "Iops", newJInt(Iops))
  result = call_595125.call(nil, query_595126, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_595092(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_595093, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_595094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_595183 = ref object of OpenApiRestCall_592348
proc url_PostRevokeDBSecurityGroupIngress_595185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_595184(path: JsonNode;
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
  var valid_595186 = query.getOrDefault("Action")
  valid_595186 = validateParameter(valid_595186, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595186 != nil:
    section.add "Action", valid_595186
  var valid_595187 = query.getOrDefault("Version")
  valid_595187 = validateParameter(valid_595187, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595187 != nil:
    section.add "Version", valid_595187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595188 = header.getOrDefault("X-Amz-Signature")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-Signature", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Content-Sha256", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Date")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Date", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Credential")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Credential", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-Security-Token")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-Security-Token", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-Algorithm")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-Algorithm", valid_595193
  var valid_595194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595194 = validateParameter(valid_595194, JString, required = false,
                                 default = nil)
  if valid_595194 != nil:
    section.add "X-Amz-SignedHeaders", valid_595194
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595195 = formData.getOrDefault("DBSecurityGroupName")
  valid_595195 = validateParameter(valid_595195, JString, required = true,
                                 default = nil)
  if valid_595195 != nil:
    section.add "DBSecurityGroupName", valid_595195
  var valid_595196 = formData.getOrDefault("EC2SecurityGroupName")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "EC2SecurityGroupName", valid_595196
  var valid_595197 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595197
  var valid_595198 = formData.getOrDefault("EC2SecurityGroupId")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "EC2SecurityGroupId", valid_595198
  var valid_595199 = formData.getOrDefault("CIDRIP")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "CIDRIP", valid_595199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595200: Call_PostRevokeDBSecurityGroupIngress_595183;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595200.validator(path, query, header, formData, body)
  let scheme = call_595200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595200.url(scheme.get, call_595200.host, call_595200.base,
                         call_595200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595200, url, valid)

proc call*(call_595201: Call_PostRevokeDBSecurityGroupIngress_595183;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595202 = newJObject()
  var formData_595203 = newJObject()
  add(formData_595203, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_595203, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_595203, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_595203, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_595203, "CIDRIP", newJString(CIDRIP))
  add(query_595202, "Action", newJString(Action))
  add(query_595202, "Version", newJString(Version))
  result = call_595201.call(nil, query_595202, nil, formData_595203, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_595183(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_595184, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_595185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_595163 = ref object of OpenApiRestCall_592348
proc url_GetRevokeDBSecurityGroupIngress_595165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_595164(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_595166 = query.getOrDefault("EC2SecurityGroupName")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "EC2SecurityGroupName", valid_595166
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595167 = query.getOrDefault("DBSecurityGroupName")
  valid_595167 = validateParameter(valid_595167, JString, required = true,
                                 default = nil)
  if valid_595167 != nil:
    section.add "DBSecurityGroupName", valid_595167
  var valid_595168 = query.getOrDefault("EC2SecurityGroupId")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "EC2SecurityGroupId", valid_595168
  var valid_595169 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595169 = validateParameter(valid_595169, JString, required = false,
                                 default = nil)
  if valid_595169 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595169
  var valid_595170 = query.getOrDefault("Action")
  valid_595170 = validateParameter(valid_595170, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595170 != nil:
    section.add "Action", valid_595170
  var valid_595171 = query.getOrDefault("Version")
  valid_595171 = validateParameter(valid_595171, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_595171 != nil:
    section.add "Version", valid_595171
  var valid_595172 = query.getOrDefault("CIDRIP")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "CIDRIP", valid_595172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_595173 = header.getOrDefault("X-Amz-Signature")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "X-Amz-Signature", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Content-Sha256", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Date")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Date", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-Credential")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-Credential", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-Security-Token")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-Security-Token", valid_595177
  var valid_595178 = header.getOrDefault("X-Amz-Algorithm")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "X-Amz-Algorithm", valid_595178
  var valid_595179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "X-Amz-SignedHeaders", valid_595179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595180: Call_GetRevokeDBSecurityGroupIngress_595163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595180.validator(path, query, header, formData, body)
  let scheme = call_595180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595180.url(scheme.get, call_595180.host, call_595180.base,
                         call_595180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595180, url, valid)

proc call*(call_595181: Call_GetRevokeDBSecurityGroupIngress_595163;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_595182 = newJObject()
  add(query_595182, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_595182, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_595182, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_595182, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_595182, "Action", newJString(Action))
  add(query_595182, "Version", newJString(Version))
  add(query_595182, "CIDRIP", newJString(CIDRIP))
  result = call_595181.call(nil, query_595182, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_595163(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_595164, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_595165,
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

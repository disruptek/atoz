
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_593070 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBSnapshot_593072(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_593071(path: JsonNode; query: JsonNode;
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
  var valid_593073 = query.getOrDefault("Action")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593073 != nil:
    section.add "Action", valid_593073
  var valid_593074 = query.getOrDefault("Version")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593074 != nil:
    section.add "Version", valid_593074
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
  var valid_593075 = header.getOrDefault("X-Amz-Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Signature", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Content-Sha256", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Date")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Date", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Credential")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Credential", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Security-Token")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Security-Token", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Algorithm")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Algorithm", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-SignedHeaders", valid_593081
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593082 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593082 = validateParameter(valid_593082, JString, required = true,
                                 default = nil)
  if valid_593082 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593082
  var valid_593083 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = nil)
  if valid_593083 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593084: Call_PostCopyDBSnapshot_593070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593084.validator(path, query, header, formData, body)
  let scheme = call_593084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593084.url(scheme.get, call_593084.host, call_593084.base,
                         call_593084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593084, url, valid)

proc call*(call_593085: Call_PostCopyDBSnapshot_593070;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593086 = newJObject()
  var formData_593087 = newJObject()
  add(formData_593087, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593086, "Action", newJString(Action))
  add(formData_593087, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593086, "Version", newJString(Version))
  result = call_593085.call(nil, query_593086, nil, formData_593087, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_593070(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_593071, base: "/",
    url: url_PostCopyDBSnapshot_593072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_593053 = ref object of OpenApiRestCall_592348
proc url_GetCopyDBSnapshot_593055(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_593054(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593056 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593056
  var valid_593057 = query.getOrDefault("Action")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593057 != nil:
    section.add "Action", valid_593057
  var valid_593058 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593058
  var valid_593059 = query.getOrDefault("Version")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593059 != nil:
    section.add "Version", valid_593059
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
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_GetCopyDBSnapshot_593053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_GetCopyDBSnapshot_593053;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593069 = newJObject()
  add(query_593069, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593069, "Action", newJString(Action))
  add(query_593069, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593069, "Version", newJString(Version))
  result = call_593068.call(nil, query_593069, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_593053(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_593054,
    base: "/", url: url_GetCopyDBSnapshot_593055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_593127 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstance_593129(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_593128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593130 = query.getOrDefault("Action")
  valid_593130 = validateParameter(valid_593130, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593130 != nil:
    section.add "Action", valid_593130
  var valid_593131 = query.getOrDefault("Version")
  valid_593131 = validateParameter(valid_593131, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593131 != nil:
    section.add "Version", valid_593131
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
  var valid_593132 = header.getOrDefault("X-Amz-Signature")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Signature", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Content-Sha256", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Date")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Date", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Credential")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Credential", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Security-Token")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Security-Token", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Algorithm")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Algorithm", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-SignedHeaders", valid_593138
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
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_593139 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "PreferredMaintenanceWindow", valid_593139
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_593140 = formData.getOrDefault("DBInstanceClass")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = nil)
  if valid_593140 != nil:
    section.add "DBInstanceClass", valid_593140
  var valid_593141 = formData.getOrDefault("Port")
  valid_593141 = validateParameter(valid_593141, JInt, required = false, default = nil)
  if valid_593141 != nil:
    section.add "Port", valid_593141
  var valid_593142 = formData.getOrDefault("PreferredBackupWindow")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "PreferredBackupWindow", valid_593142
  var valid_593143 = formData.getOrDefault("MasterUserPassword")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = nil)
  if valid_593143 != nil:
    section.add "MasterUserPassword", valid_593143
  var valid_593144 = formData.getOrDefault("MultiAZ")
  valid_593144 = validateParameter(valid_593144, JBool, required = false, default = nil)
  if valid_593144 != nil:
    section.add "MultiAZ", valid_593144
  var valid_593145 = formData.getOrDefault("MasterUsername")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = nil)
  if valid_593145 != nil:
    section.add "MasterUsername", valid_593145
  var valid_593146 = formData.getOrDefault("DBParameterGroupName")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "DBParameterGroupName", valid_593146
  var valid_593147 = formData.getOrDefault("EngineVersion")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "EngineVersion", valid_593147
  var valid_593148 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_593148 = validateParameter(valid_593148, JArray, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "VpcSecurityGroupIds", valid_593148
  var valid_593149 = formData.getOrDefault("AvailabilityZone")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "AvailabilityZone", valid_593149
  var valid_593150 = formData.getOrDefault("BackupRetentionPeriod")
  valid_593150 = validateParameter(valid_593150, JInt, required = false, default = nil)
  if valid_593150 != nil:
    section.add "BackupRetentionPeriod", valid_593150
  var valid_593151 = formData.getOrDefault("Engine")
  valid_593151 = validateParameter(valid_593151, JString, required = true,
                                 default = nil)
  if valid_593151 != nil:
    section.add "Engine", valid_593151
  var valid_593152 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593152 = validateParameter(valid_593152, JBool, required = false, default = nil)
  if valid_593152 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593152
  var valid_593153 = formData.getOrDefault("DBName")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "DBName", valid_593153
  var valid_593154 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = nil)
  if valid_593154 != nil:
    section.add "DBInstanceIdentifier", valid_593154
  var valid_593155 = formData.getOrDefault("Iops")
  valid_593155 = validateParameter(valid_593155, JInt, required = false, default = nil)
  if valid_593155 != nil:
    section.add "Iops", valid_593155
  var valid_593156 = formData.getOrDefault("PubliclyAccessible")
  valid_593156 = validateParameter(valid_593156, JBool, required = false, default = nil)
  if valid_593156 != nil:
    section.add "PubliclyAccessible", valid_593156
  var valid_593157 = formData.getOrDefault("LicenseModel")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "LicenseModel", valid_593157
  var valid_593158 = formData.getOrDefault("DBSubnetGroupName")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "DBSubnetGroupName", valid_593158
  var valid_593159 = formData.getOrDefault("OptionGroupName")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "OptionGroupName", valid_593159
  var valid_593160 = formData.getOrDefault("CharacterSetName")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "CharacterSetName", valid_593160
  var valid_593161 = formData.getOrDefault("DBSecurityGroups")
  valid_593161 = validateParameter(valid_593161, JArray, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "DBSecurityGroups", valid_593161
  var valid_593162 = formData.getOrDefault("AllocatedStorage")
  valid_593162 = validateParameter(valid_593162, JInt, required = true, default = nil)
  if valid_593162 != nil:
    section.add "AllocatedStorage", valid_593162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_PostCreateDBInstance_593127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_PostCreateDBInstance_593127; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          CharacterSetName: string = ""; Version: string = "2013-01-10";
          DBSecurityGroups: JsonNode = nil): Recallable =
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
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_593165 = newJObject()
  var formData_593166 = newJObject()
  add(formData_593166, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593166, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593166, "Port", newJInt(Port))
  add(formData_593166, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_593166, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_593166, "MultiAZ", newJBool(MultiAZ))
  add(formData_593166, "MasterUsername", newJString(MasterUsername))
  add(formData_593166, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593166, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_593166.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_593166, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593166, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_593166, "Engine", newJString(Engine))
  add(formData_593166, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593166, "DBName", newJString(DBName))
  add(formData_593166, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593166, "Iops", newJInt(Iops))
  add(formData_593166, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593165, "Action", newJString(Action))
  add(formData_593166, "LicenseModel", newJString(LicenseModel))
  add(formData_593166, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593166, "OptionGroupName", newJString(OptionGroupName))
  add(formData_593166, "CharacterSetName", newJString(CharacterSetName))
  add(query_593165, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_593166.add "DBSecurityGroups", DBSecurityGroups
  add(formData_593166, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_593164.call(nil, query_593165, nil, formData_593166, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_593127(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_593128, base: "/",
    url: url_PostCreateDBInstance_593129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_593088 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstance_593090(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_593089(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
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
  var valid_593091 = query.getOrDefault("Version")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593091 != nil:
    section.add "Version", valid_593091
  var valid_593092 = query.getOrDefault("DBName")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "DBName", valid_593092
  var valid_593093 = query.getOrDefault("Engine")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = nil)
  if valid_593093 != nil:
    section.add "Engine", valid_593093
  var valid_593094 = query.getOrDefault("DBParameterGroupName")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "DBParameterGroupName", valid_593094
  var valid_593095 = query.getOrDefault("CharacterSetName")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "CharacterSetName", valid_593095
  var valid_593096 = query.getOrDefault("LicenseModel")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "LicenseModel", valid_593096
  var valid_593097 = query.getOrDefault("DBInstanceIdentifier")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = nil)
  if valid_593097 != nil:
    section.add "DBInstanceIdentifier", valid_593097
  var valid_593098 = query.getOrDefault("MasterUsername")
  valid_593098 = validateParameter(valid_593098, JString, required = true,
                                 default = nil)
  if valid_593098 != nil:
    section.add "MasterUsername", valid_593098
  var valid_593099 = query.getOrDefault("BackupRetentionPeriod")
  valid_593099 = validateParameter(valid_593099, JInt, required = false, default = nil)
  if valid_593099 != nil:
    section.add "BackupRetentionPeriod", valid_593099
  var valid_593100 = query.getOrDefault("EngineVersion")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "EngineVersion", valid_593100
  var valid_593101 = query.getOrDefault("Action")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593101 != nil:
    section.add "Action", valid_593101
  var valid_593102 = query.getOrDefault("MultiAZ")
  valid_593102 = validateParameter(valid_593102, JBool, required = false, default = nil)
  if valid_593102 != nil:
    section.add "MultiAZ", valid_593102
  var valid_593103 = query.getOrDefault("DBSecurityGroups")
  valid_593103 = validateParameter(valid_593103, JArray, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "DBSecurityGroups", valid_593103
  var valid_593104 = query.getOrDefault("Port")
  valid_593104 = validateParameter(valid_593104, JInt, required = false, default = nil)
  if valid_593104 != nil:
    section.add "Port", valid_593104
  var valid_593105 = query.getOrDefault("VpcSecurityGroupIds")
  valid_593105 = validateParameter(valid_593105, JArray, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "VpcSecurityGroupIds", valid_593105
  var valid_593106 = query.getOrDefault("MasterUserPassword")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "MasterUserPassword", valid_593106
  var valid_593107 = query.getOrDefault("AvailabilityZone")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "AvailabilityZone", valid_593107
  var valid_593108 = query.getOrDefault("OptionGroupName")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "OptionGroupName", valid_593108
  var valid_593109 = query.getOrDefault("DBSubnetGroupName")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "DBSubnetGroupName", valid_593109
  var valid_593110 = query.getOrDefault("AllocatedStorage")
  valid_593110 = validateParameter(valid_593110, JInt, required = true, default = nil)
  if valid_593110 != nil:
    section.add "AllocatedStorage", valid_593110
  var valid_593111 = query.getOrDefault("DBInstanceClass")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "DBInstanceClass", valid_593111
  var valid_593112 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "PreferredMaintenanceWindow", valid_593112
  var valid_593113 = query.getOrDefault("PreferredBackupWindow")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "PreferredBackupWindow", valid_593113
  var valid_593114 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593114 = validateParameter(valid_593114, JBool, required = false, default = nil)
  if valid_593114 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593114
  var valid_593115 = query.getOrDefault("Iops")
  valid_593115 = validateParameter(valid_593115, JInt, required = false, default = nil)
  if valid_593115 != nil:
    section.add "Iops", valid_593115
  var valid_593116 = query.getOrDefault("PubliclyAccessible")
  valid_593116 = validateParameter(valid_593116, JBool, required = false, default = nil)
  if valid_593116 != nil:
    section.add "PubliclyAccessible", valid_593116
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
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593124: Call_GetCreateDBInstance_593088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593124.validator(path, query, header, formData, body)
  let scheme = call_593124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593124.url(scheme.get, call_593124.host, call_593124.base,
                         call_593124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593124, url, valid)

proc call*(call_593125: Call_GetCreateDBInstance_593088; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-01-10";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; LicenseModel: string = "";
          BackupRetentionPeriod: int = 0; EngineVersion: string = "";
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
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
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
  var query_593126 = newJObject()
  add(query_593126, "Version", newJString(Version))
  add(query_593126, "DBName", newJString(DBName))
  add(query_593126, "Engine", newJString(Engine))
  add(query_593126, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593126, "CharacterSetName", newJString(CharacterSetName))
  add(query_593126, "LicenseModel", newJString(LicenseModel))
  add(query_593126, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593126, "MasterUsername", newJString(MasterUsername))
  add(query_593126, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_593126, "EngineVersion", newJString(EngineVersion))
  add(query_593126, "Action", newJString(Action))
  add(query_593126, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_593126.add "DBSecurityGroups", DBSecurityGroups
  add(query_593126, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_593126.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_593126, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_593126, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593126, "OptionGroupName", newJString(OptionGroupName))
  add(query_593126, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593126, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_593126, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593126, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593126, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_593126, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593126, "Iops", newJInt(Iops))
  add(query_593126, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_593125.call(nil, query_593126, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_593088(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_593089, base: "/",
    url: url_GetCreateDBInstance_593090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_593191 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstanceReadReplica_593193(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_593192(path: JsonNode;
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
  var valid_593194 = query.getOrDefault("Action")
  valid_593194 = validateParameter(valid_593194, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593194 != nil:
    section.add "Action", valid_593194
  var valid_593195 = query.getOrDefault("Version")
  valid_593195 = validateParameter(valid_593195, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593195 != nil:
    section.add "Version", valid_593195
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
  var valid_593196 = header.getOrDefault("X-Amz-Signature")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Signature", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Content-Sha256", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Date")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Date", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Credential")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Credential", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Security-Token")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Security-Token", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Algorithm")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Algorithm", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-SignedHeaders", valid_593202
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
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_593203 = formData.getOrDefault("Port")
  valid_593203 = validateParameter(valid_593203, JInt, required = false, default = nil)
  if valid_593203 != nil:
    section.add "Port", valid_593203
  var valid_593204 = formData.getOrDefault("DBInstanceClass")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "DBInstanceClass", valid_593204
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_593205 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593205
  var valid_593206 = formData.getOrDefault("AvailabilityZone")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "AvailabilityZone", valid_593206
  var valid_593207 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593207 = validateParameter(valid_593207, JBool, required = false, default = nil)
  if valid_593207 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593207
  var valid_593208 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "DBInstanceIdentifier", valid_593208
  var valid_593209 = formData.getOrDefault("Iops")
  valid_593209 = validateParameter(valid_593209, JInt, required = false, default = nil)
  if valid_593209 != nil:
    section.add "Iops", valid_593209
  var valid_593210 = formData.getOrDefault("PubliclyAccessible")
  valid_593210 = validateParameter(valid_593210, JBool, required = false, default = nil)
  if valid_593210 != nil:
    section.add "PubliclyAccessible", valid_593210
  var valid_593211 = formData.getOrDefault("OptionGroupName")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "OptionGroupName", valid_593211
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_PostCreateDBInstanceReadReplica_593191;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_PostCreateDBInstanceReadReplica_593191;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
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
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_593214 = newJObject()
  var formData_593215 = newJObject()
  add(formData_593215, "Port", newJInt(Port))
  add(formData_593215, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593215, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_593215, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593215, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593215, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593215, "Iops", newJInt(Iops))
  add(formData_593215, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593214, "Action", newJString(Action))
  add(formData_593215, "OptionGroupName", newJString(OptionGroupName))
  add(query_593214, "Version", newJString(Version))
  result = call_593213.call(nil, query_593214, nil, formData_593215, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_593191(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_593192, base: "/",
    url: url_PostCreateDBInstanceReadReplica_593193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_593167 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstanceReadReplica_593169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_593168(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593170 = query.getOrDefault("DBInstanceIdentifier")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "DBInstanceIdentifier", valid_593170
  var valid_593171 = query.getOrDefault("Action")
  valid_593171 = validateParameter(valid_593171, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593171 != nil:
    section.add "Action", valid_593171
  var valid_593172 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_593172 = validateParameter(valid_593172, JString, required = true,
                                 default = nil)
  if valid_593172 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593172
  var valid_593173 = query.getOrDefault("Port")
  valid_593173 = validateParameter(valid_593173, JInt, required = false, default = nil)
  if valid_593173 != nil:
    section.add "Port", valid_593173
  var valid_593174 = query.getOrDefault("AvailabilityZone")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "AvailabilityZone", valid_593174
  var valid_593175 = query.getOrDefault("OptionGroupName")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "OptionGroupName", valid_593175
  var valid_593176 = query.getOrDefault("Version")
  valid_593176 = validateParameter(valid_593176, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593176 != nil:
    section.add "Version", valid_593176
  var valid_593177 = query.getOrDefault("DBInstanceClass")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "DBInstanceClass", valid_593177
  var valid_593178 = query.getOrDefault("PubliclyAccessible")
  valid_593178 = validateParameter(valid_593178, JBool, required = false, default = nil)
  if valid_593178 != nil:
    section.add "PubliclyAccessible", valid_593178
  var valid_593179 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593179 = validateParameter(valid_593179, JBool, required = false, default = nil)
  if valid_593179 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593179
  var valid_593180 = query.getOrDefault("Iops")
  valid_593180 = validateParameter(valid_593180, JInt, required = false, default = nil)
  if valid_593180 != nil:
    section.add "Iops", valid_593180
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
  var valid_593181 = header.getOrDefault("X-Amz-Signature")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Signature", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Content-Sha256", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Date")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Date", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Credential")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Credential", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Security-Token")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Security-Token", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Algorithm")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Algorithm", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-SignedHeaders", valid_593187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593188: Call_GetCreateDBInstanceReadReplica_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593188.validator(path, query, header, formData, body)
  let scheme = call_593188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593188.url(scheme.get, call_593188.host, call_593188.base,
                         call_593188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593188, url, valid)

proc call*(call_593189: Call_GetCreateDBInstanceReadReplica_593167;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_593190 = newJObject()
  add(query_593190, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593190, "Action", newJString(Action))
  add(query_593190, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_593190, "Port", newJInt(Port))
  add(query_593190, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593190, "OptionGroupName", newJString(OptionGroupName))
  add(query_593190, "Version", newJString(Version))
  add(query_593190, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593190, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593190, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593190, "Iops", newJInt(Iops))
  result = call_593189.call(nil, query_593190, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_593167(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_593168, base: "/",
    url: url_GetCreateDBInstanceReadReplica_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_593234 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBParameterGroup_593236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_593235(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593237 = query.getOrDefault("Action")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593237 != nil:
    section.add "Action", valid_593237
  var valid_593238 = query.getOrDefault("Version")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593238 != nil:
    section.add "Version", valid_593238
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
  var valid_593239 = header.getOrDefault("X-Amz-Signature")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Signature", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Content-Sha256", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Date")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Date", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Credential")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Credential", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Security-Token")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Security-Token", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Algorithm")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Algorithm", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-SignedHeaders", valid_593245
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_593246 = formData.getOrDefault("Description")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = nil)
  if valid_593246 != nil:
    section.add "Description", valid_593246
  var valid_593247 = formData.getOrDefault("DBParameterGroupName")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = nil)
  if valid_593247 != nil:
    section.add "DBParameterGroupName", valid_593247
  var valid_593248 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593248 = validateParameter(valid_593248, JString, required = true,
                                 default = nil)
  if valid_593248 != nil:
    section.add "DBParameterGroupFamily", valid_593248
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593249: Call_PostCreateDBParameterGroup_593234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593249.validator(path, query, header, formData, body)
  let scheme = call_593249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593249.url(scheme.get, call_593249.host, call_593249.base,
                         call_593249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593249, url, valid)

proc call*(call_593250: Call_PostCreateDBParameterGroup_593234;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_593251 = newJObject()
  var formData_593252 = newJObject()
  add(formData_593252, "Description", newJString(Description))
  add(formData_593252, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593251, "Action", newJString(Action))
  add(query_593251, "Version", newJString(Version))
  add(formData_593252, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593250.call(nil, query_593251, nil, formData_593252, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_593234(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_593235, base: "/",
    url: url_PostCreateDBParameterGroup_593236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_593216 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBParameterGroup_593218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_593217(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593219 = query.getOrDefault("DBParameterGroupFamily")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "DBParameterGroupFamily", valid_593219
  var valid_593220 = query.getOrDefault("DBParameterGroupName")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "DBParameterGroupName", valid_593220
  var valid_593221 = query.getOrDefault("Action")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593221 != nil:
    section.add "Action", valid_593221
  var valid_593222 = query.getOrDefault("Description")
  valid_593222 = validateParameter(valid_593222, JString, required = true,
                                 default = nil)
  if valid_593222 != nil:
    section.add "Description", valid_593222
  var valid_593223 = query.getOrDefault("Version")
  valid_593223 = validateParameter(valid_593223, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593223 != nil:
    section.add "Version", valid_593223
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
  var valid_593224 = header.getOrDefault("X-Amz-Signature")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Signature", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Content-Sha256", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Date")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Date", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Credential")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Credential", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Security-Token")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Security-Token", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Algorithm")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Algorithm", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-SignedHeaders", valid_593230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593231: Call_GetCreateDBParameterGroup_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593231.validator(path, query, header, formData, body)
  let scheme = call_593231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593231.url(scheme.get, call_593231.host, call_593231.base,
                         call_593231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593231, url, valid)

proc call*(call_593232: Call_GetCreateDBParameterGroup_593216;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_593233 = newJObject()
  add(query_593233, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593233, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593233, "Action", newJString(Action))
  add(query_593233, "Description", newJString(Description))
  add(query_593233, "Version", newJString(Version))
  result = call_593232.call(nil, query_593233, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_593216(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_593217, base: "/",
    url: url_GetCreateDBParameterGroup_593218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_593270 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSecurityGroup_593272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_593271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593273 = query.getOrDefault("Action")
  valid_593273 = validateParameter(valid_593273, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593273 != nil:
    section.add "Action", valid_593273
  var valid_593274 = query.getOrDefault("Version")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593274 != nil:
    section.add "Version", valid_593274
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
  var valid_593275 = header.getOrDefault("X-Amz-Signature")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Signature", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Content-Sha256", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Date")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Date", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Credential")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Credential", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Security-Token")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Security-Token", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Algorithm")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Algorithm", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-SignedHeaders", valid_593281
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_593282 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_593282 = validateParameter(valid_593282, JString, required = true,
                                 default = nil)
  if valid_593282 != nil:
    section.add "DBSecurityGroupDescription", valid_593282
  var valid_593283 = formData.getOrDefault("DBSecurityGroupName")
  valid_593283 = validateParameter(valid_593283, JString, required = true,
                                 default = nil)
  if valid_593283 != nil:
    section.add "DBSecurityGroupName", valid_593283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_PostCreateDBSecurityGroup_593270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_PostCreateDBSecurityGroup_593270;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593286 = newJObject()
  var formData_593287 = newJObject()
  add(formData_593287, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_593287, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593286, "Action", newJString(Action))
  add(query_593286, "Version", newJString(Version))
  result = call_593285.call(nil, query_593286, nil, formData_593287, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_593270(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_593271, base: "/",
    url: url_PostCreateDBSecurityGroup_593272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_593253 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSecurityGroup_593255(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_593254(path: JsonNode; query: JsonNode;
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
  var valid_593256 = query.getOrDefault("DBSecurityGroupName")
  valid_593256 = validateParameter(valid_593256, JString, required = true,
                                 default = nil)
  if valid_593256 != nil:
    section.add "DBSecurityGroupName", valid_593256
  var valid_593257 = query.getOrDefault("DBSecurityGroupDescription")
  valid_593257 = validateParameter(valid_593257, JString, required = true,
                                 default = nil)
  if valid_593257 != nil:
    section.add "DBSecurityGroupDescription", valid_593257
  var valid_593258 = query.getOrDefault("Action")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593258 != nil:
    section.add "Action", valid_593258
  var valid_593259 = query.getOrDefault("Version")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593259 != nil:
    section.add "Version", valid_593259
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
  var valid_593260 = header.getOrDefault("X-Amz-Signature")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Signature", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Content-Sha256", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Date")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Date", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Credential")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Credential", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Security-Token")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Security-Token", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Algorithm")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Algorithm", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-SignedHeaders", valid_593266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_GetCreateDBSecurityGroup_593253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_GetCreateDBSecurityGroup_593253;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593269 = newJObject()
  add(query_593269, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593269, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_593269, "Action", newJString(Action))
  add(query_593269, "Version", newJString(Version))
  result = call_593268.call(nil, query_593269, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_593253(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_593254, base: "/",
    url: url_GetCreateDBSecurityGroup_593255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_593305 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSnapshot_593307(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_593306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593308 = query.getOrDefault("Action")
  valid_593308 = validateParameter(valid_593308, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593308 != nil:
    section.add "Action", valid_593308
  var valid_593309 = query.getOrDefault("Version")
  valid_593309 = validateParameter(valid_593309, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593309 != nil:
    section.add "Version", valid_593309
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
  var valid_593310 = header.getOrDefault("X-Amz-Signature")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Signature", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Content-Sha256", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Date")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Date", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Credential")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Credential", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Security-Token")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Security-Token", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Algorithm")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Algorithm", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-SignedHeaders", valid_593316
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593317 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593317 = validateParameter(valid_593317, JString, required = true,
                                 default = nil)
  if valid_593317 != nil:
    section.add "DBInstanceIdentifier", valid_593317
  var valid_593318 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = nil)
  if valid_593318 != nil:
    section.add "DBSnapshotIdentifier", valid_593318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593319: Call_PostCreateDBSnapshot_593305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593319.validator(path, query, header, formData, body)
  let scheme = call_593319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593319.url(scheme.get, call_593319.host, call_593319.base,
                         call_593319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593319, url, valid)

proc call*(call_593320: Call_PostCreateDBSnapshot_593305;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593321 = newJObject()
  var formData_593322 = newJObject()
  add(formData_593322, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593322, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593321, "Action", newJString(Action))
  add(query_593321, "Version", newJString(Version))
  result = call_593320.call(nil, query_593321, nil, formData_593322, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_593305(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_593306, base: "/",
    url: url_PostCreateDBSnapshot_593307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_593288 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSnapshot_593290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_593289(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593291 = query.getOrDefault("DBInstanceIdentifier")
  valid_593291 = validateParameter(valid_593291, JString, required = true,
                                 default = nil)
  if valid_593291 != nil:
    section.add "DBInstanceIdentifier", valid_593291
  var valid_593292 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593292 = validateParameter(valid_593292, JString, required = true,
                                 default = nil)
  if valid_593292 != nil:
    section.add "DBSnapshotIdentifier", valid_593292
  var valid_593293 = query.getOrDefault("Action")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593293 != nil:
    section.add "Action", valid_593293
  var valid_593294 = query.getOrDefault("Version")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593294 != nil:
    section.add "Version", valid_593294
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
  var valid_593295 = header.getOrDefault("X-Amz-Signature")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Signature", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Content-Sha256", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Date")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Date", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Credential")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Credential", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Security-Token")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Security-Token", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Algorithm")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Algorithm", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-SignedHeaders", valid_593301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593302: Call_GetCreateDBSnapshot_593288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593302.validator(path, query, header, formData, body)
  let scheme = call_593302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593302.url(scheme.get, call_593302.host, call_593302.base,
                         call_593302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593302, url, valid)

proc call*(call_593303: Call_GetCreateDBSnapshot_593288;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593304 = newJObject()
  add(query_593304, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593304, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593304, "Action", newJString(Action))
  add(query_593304, "Version", newJString(Version))
  result = call_593303.call(nil, query_593304, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_593288(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_593289, base: "/",
    url: url_GetCreateDBSnapshot_593290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_593341 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSubnetGroup_593343(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_593342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593344 = query.getOrDefault("Action")
  valid_593344 = validateParameter(valid_593344, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593344 != nil:
    section.add "Action", valid_593344
  var valid_593345 = query.getOrDefault("Version")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593345 != nil:
    section.add "Version", valid_593345
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
  var valid_593346 = header.getOrDefault("X-Amz-Signature")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Signature", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Content-Sha256", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Date")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Date", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Credential")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Credential", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Security-Token")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Security-Token", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Algorithm")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Algorithm", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-SignedHeaders", valid_593352
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_593353 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = nil)
  if valid_593353 != nil:
    section.add "DBSubnetGroupDescription", valid_593353
  var valid_593354 = formData.getOrDefault("DBSubnetGroupName")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = nil)
  if valid_593354 != nil:
    section.add "DBSubnetGroupName", valid_593354
  var valid_593355 = formData.getOrDefault("SubnetIds")
  valid_593355 = validateParameter(valid_593355, JArray, required = true, default = nil)
  if valid_593355 != nil:
    section.add "SubnetIds", valid_593355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_PostCreateDBSubnetGroup_593341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_PostCreateDBSubnetGroup_593341;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_593358 = newJObject()
  var formData_593359 = newJObject()
  add(formData_593359, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593358, "Action", newJString(Action))
  add(formData_593359, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593358, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_593359.add "SubnetIds", SubnetIds
  result = call_593357.call(nil, query_593358, nil, formData_593359, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_593341(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_593342, base: "/",
    url: url_PostCreateDBSubnetGroup_593343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_593323 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSubnetGroup_593325(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_593324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_593326 = query.getOrDefault("SubnetIds")
  valid_593326 = validateParameter(valid_593326, JArray, required = true, default = nil)
  if valid_593326 != nil:
    section.add "SubnetIds", valid_593326
  var valid_593327 = query.getOrDefault("Action")
  valid_593327 = validateParameter(valid_593327, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593327 != nil:
    section.add "Action", valid_593327
  var valid_593328 = query.getOrDefault("DBSubnetGroupDescription")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "DBSubnetGroupDescription", valid_593328
  var valid_593329 = query.getOrDefault("DBSubnetGroupName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "DBSubnetGroupName", valid_593329
  var valid_593330 = query.getOrDefault("Version")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593330 != nil:
    section.add "Version", valid_593330
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
  var valid_593331 = header.getOrDefault("X-Amz-Signature")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Signature", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Content-Sha256", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Date")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Date", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Credential")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Credential", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Security-Token")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Security-Token", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Algorithm")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Algorithm", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-SignedHeaders", valid_593337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_GetCreateDBSubnetGroup_593323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_GetCreateDBSubnetGroup_593323; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593340 = newJObject()
  if SubnetIds != nil:
    query_593340.add "SubnetIds", SubnetIds
  add(query_593340, "Action", newJString(Action))
  add(query_593340, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593340, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593340, "Version", newJString(Version))
  result = call_593339.call(nil, query_593340, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_593323(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_593324, base: "/",
    url: url_GetCreateDBSubnetGroup_593325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_593381 = ref object of OpenApiRestCall_592348
proc url_PostCreateEventSubscription_593383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_593382(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593384 = query.getOrDefault("Action")
  valid_593384 = validateParameter(valid_593384, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593384 != nil:
    section.add "Action", valid_593384
  var valid_593385 = query.getOrDefault("Version")
  valid_593385 = validateParameter(valid_593385, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593385 != nil:
    section.add "Version", valid_593385
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
  var valid_593386 = header.getOrDefault("X-Amz-Signature")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Signature", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Content-Sha256", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Date")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Date", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Credential")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Credential", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Security-Token")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Security-Token", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Algorithm")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Algorithm", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-SignedHeaders", valid_593392
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_593393 = formData.getOrDefault("SourceIds")
  valid_593393 = validateParameter(valid_593393, JArray, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "SourceIds", valid_593393
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_593394 = formData.getOrDefault("SnsTopicArn")
  valid_593394 = validateParameter(valid_593394, JString, required = true,
                                 default = nil)
  if valid_593394 != nil:
    section.add "SnsTopicArn", valid_593394
  var valid_593395 = formData.getOrDefault("Enabled")
  valid_593395 = validateParameter(valid_593395, JBool, required = false, default = nil)
  if valid_593395 != nil:
    section.add "Enabled", valid_593395
  var valid_593396 = formData.getOrDefault("SubscriptionName")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = nil)
  if valid_593396 != nil:
    section.add "SubscriptionName", valid_593396
  var valid_593397 = formData.getOrDefault("SourceType")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "SourceType", valid_593397
  var valid_593398 = formData.getOrDefault("EventCategories")
  valid_593398 = validateParameter(valid_593398, JArray, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "EventCategories", valid_593398
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593399: Call_PostCreateEventSubscription_593381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593399.validator(path, query, header, formData, body)
  let scheme = call_593399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593399.url(scheme.get, call_593399.host, call_593399.base,
                         call_593399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593399, url, valid)

proc call*(call_593400: Call_PostCreateEventSubscription_593381;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593401 = newJObject()
  var formData_593402 = newJObject()
  if SourceIds != nil:
    formData_593402.add "SourceIds", SourceIds
  add(formData_593402, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_593402, "Enabled", newJBool(Enabled))
  add(formData_593402, "SubscriptionName", newJString(SubscriptionName))
  add(formData_593402, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_593402.add "EventCategories", EventCategories
  add(query_593401, "Action", newJString(Action))
  add(query_593401, "Version", newJString(Version))
  result = call_593400.call(nil, query_593401, nil, formData_593402, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_593381(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_593382, base: "/",
    url: url_PostCreateEventSubscription_593383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_593360 = ref object of OpenApiRestCall_592348
proc url_GetCreateEventSubscription_593362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_593361(path: JsonNode; query: JsonNode;
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
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593363 = query.getOrDefault("SourceType")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "SourceType", valid_593363
  var valid_593364 = query.getOrDefault("Enabled")
  valid_593364 = validateParameter(valid_593364, JBool, required = false, default = nil)
  if valid_593364 != nil:
    section.add "Enabled", valid_593364
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_593365 = query.getOrDefault("SubscriptionName")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = nil)
  if valid_593365 != nil:
    section.add "SubscriptionName", valid_593365
  var valid_593366 = query.getOrDefault("EventCategories")
  valid_593366 = validateParameter(valid_593366, JArray, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "EventCategories", valid_593366
  var valid_593367 = query.getOrDefault("SourceIds")
  valid_593367 = validateParameter(valid_593367, JArray, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "SourceIds", valid_593367
  var valid_593368 = query.getOrDefault("Action")
  valid_593368 = validateParameter(valid_593368, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593368 != nil:
    section.add "Action", valid_593368
  var valid_593369 = query.getOrDefault("SnsTopicArn")
  valid_593369 = validateParameter(valid_593369, JString, required = true,
                                 default = nil)
  if valid_593369 != nil:
    section.add "SnsTopicArn", valid_593369
  var valid_593370 = query.getOrDefault("Version")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593370 != nil:
    section.add "Version", valid_593370
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
  var valid_593371 = header.getOrDefault("X-Amz-Signature")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Signature", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Content-Sha256", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Date")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Date", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Credential")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Credential", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Security-Token")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Security-Token", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Algorithm")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Algorithm", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-SignedHeaders", valid_593377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593378: Call_GetCreateEventSubscription_593360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593378.validator(path, query, header, formData, body)
  let scheme = call_593378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593378.url(scheme.get, call_593378.host, call_593378.base,
                         call_593378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593378, url, valid)

proc call*(call_593379: Call_GetCreateEventSubscription_593360;
          SubscriptionName: string; SnsTopicArn: string; SourceType: string = "";
          Enabled: bool = false; EventCategories: JsonNode = nil;
          SourceIds: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_593380 = newJObject()
  add(query_593380, "SourceType", newJString(SourceType))
  add(query_593380, "Enabled", newJBool(Enabled))
  add(query_593380, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_593380.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_593380.add "SourceIds", SourceIds
  add(query_593380, "Action", newJString(Action))
  add(query_593380, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_593380, "Version", newJString(Version))
  result = call_593379.call(nil, query_593380, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_593360(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_593361, base: "/",
    url: url_GetCreateEventSubscription_593362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_593422 = ref object of OpenApiRestCall_592348
proc url_PostCreateOptionGroup_593424(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_593423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593425 = query.getOrDefault("Action")
  valid_593425 = validateParameter(valid_593425, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593425 != nil:
    section.add "Action", valid_593425
  var valid_593426 = query.getOrDefault("Version")
  valid_593426 = validateParameter(valid_593426, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593426 != nil:
    section.add "Version", valid_593426
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
  var valid_593427 = header.getOrDefault("X-Amz-Signature")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Signature", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Content-Sha256", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Date")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Date", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Credential")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Credential", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Security-Token")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Security-Token", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Algorithm")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Algorithm", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-SignedHeaders", valid_593433
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_593434 = formData.getOrDefault("OptionGroupDescription")
  valid_593434 = validateParameter(valid_593434, JString, required = true,
                                 default = nil)
  if valid_593434 != nil:
    section.add "OptionGroupDescription", valid_593434
  var valid_593435 = formData.getOrDefault("EngineName")
  valid_593435 = validateParameter(valid_593435, JString, required = true,
                                 default = nil)
  if valid_593435 != nil:
    section.add "EngineName", valid_593435
  var valid_593436 = formData.getOrDefault("MajorEngineVersion")
  valid_593436 = validateParameter(valid_593436, JString, required = true,
                                 default = nil)
  if valid_593436 != nil:
    section.add "MajorEngineVersion", valid_593436
  var valid_593437 = formData.getOrDefault("OptionGroupName")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "OptionGroupName", valid_593437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593438: Call_PostCreateOptionGroup_593422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593438.validator(path, query, header, formData, body)
  let scheme = call_593438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593438.url(scheme.get, call_593438.host, call_593438.base,
                         call_593438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593438, url, valid)

proc call*(call_593439: Call_PostCreateOptionGroup_593422;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593440 = newJObject()
  var formData_593441 = newJObject()
  add(formData_593441, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_593441, "EngineName", newJString(EngineName))
  add(formData_593441, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_593440, "Action", newJString(Action))
  add(formData_593441, "OptionGroupName", newJString(OptionGroupName))
  add(query_593440, "Version", newJString(Version))
  result = call_593439.call(nil, query_593440, nil, formData_593441, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_593422(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_593423, base: "/",
    url: url_PostCreateOptionGroup_593424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_593403 = ref object of OpenApiRestCall_592348
proc url_GetCreateOptionGroup_593405(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_593404(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_593406 = query.getOrDefault("EngineName")
  valid_593406 = validateParameter(valid_593406, JString, required = true,
                                 default = nil)
  if valid_593406 != nil:
    section.add "EngineName", valid_593406
  var valid_593407 = query.getOrDefault("OptionGroupDescription")
  valid_593407 = validateParameter(valid_593407, JString, required = true,
                                 default = nil)
  if valid_593407 != nil:
    section.add "OptionGroupDescription", valid_593407
  var valid_593408 = query.getOrDefault("Action")
  valid_593408 = validateParameter(valid_593408, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593408 != nil:
    section.add "Action", valid_593408
  var valid_593409 = query.getOrDefault("OptionGroupName")
  valid_593409 = validateParameter(valid_593409, JString, required = true,
                                 default = nil)
  if valid_593409 != nil:
    section.add "OptionGroupName", valid_593409
  var valid_593410 = query.getOrDefault("Version")
  valid_593410 = validateParameter(valid_593410, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593410 != nil:
    section.add "Version", valid_593410
  var valid_593411 = query.getOrDefault("MajorEngineVersion")
  valid_593411 = validateParameter(valid_593411, JString, required = true,
                                 default = nil)
  if valid_593411 != nil:
    section.add "MajorEngineVersion", valid_593411
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
  var valid_593412 = header.getOrDefault("X-Amz-Signature")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Signature", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Content-Sha256", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Date")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Date", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Credential")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Credential", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Security-Token")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Security-Token", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Algorithm")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Algorithm", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-SignedHeaders", valid_593418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593419: Call_GetCreateOptionGroup_593403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593419.validator(path, query, header, formData, body)
  let scheme = call_593419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593419.url(scheme.get, call_593419.host, call_593419.base,
                         call_593419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593419, url, valid)

proc call*(call_593420: Call_GetCreateOptionGroup_593403; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_593421 = newJObject()
  add(query_593421, "EngineName", newJString(EngineName))
  add(query_593421, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_593421, "Action", newJString(Action))
  add(query_593421, "OptionGroupName", newJString(OptionGroupName))
  add(query_593421, "Version", newJString(Version))
  add(query_593421, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_593420.call(nil, query_593421, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_593403(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_593404, base: "/",
    url: url_GetCreateOptionGroup_593405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_593460 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBInstance_593462(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_593461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593463 = query.getOrDefault("Action")
  valid_593463 = validateParameter(valid_593463, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593463 != nil:
    section.add "Action", valid_593463
  var valid_593464 = query.getOrDefault("Version")
  valid_593464 = validateParameter(valid_593464, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593464 != nil:
    section.add "Version", valid_593464
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
  var valid_593465 = header.getOrDefault("X-Amz-Signature")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Signature", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Content-Sha256", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Date")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Date", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Credential")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Credential", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Security-Token")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Security-Token", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Algorithm")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Algorithm", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-SignedHeaders", valid_593471
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593472 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593472 = validateParameter(valid_593472, JString, required = true,
                                 default = nil)
  if valid_593472 != nil:
    section.add "DBInstanceIdentifier", valid_593472
  var valid_593473 = formData.getOrDefault("SkipFinalSnapshot")
  valid_593473 = validateParameter(valid_593473, JBool, required = false, default = nil)
  if valid_593473 != nil:
    section.add "SkipFinalSnapshot", valid_593473
  var valid_593474 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593475: Call_PostDeleteDBInstance_593460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593475.validator(path, query, header, formData, body)
  let scheme = call_593475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593475.url(scheme.get, call_593475.host, call_593475.base,
                         call_593475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593475, url, valid)

proc call*(call_593476: Call_PostDeleteDBInstance_593460;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_593477 = newJObject()
  var formData_593478 = newJObject()
  add(formData_593478, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593477, "Action", newJString(Action))
  add(formData_593478, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_593478, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_593477, "Version", newJString(Version))
  result = call_593476.call(nil, query_593477, nil, formData_593478, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_593460(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_593461, base: "/",
    url: url_PostDeleteDBInstance_593462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_593442 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBInstance_593444(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_593443(path: JsonNode; query: JsonNode;
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
  var valid_593445 = query.getOrDefault("DBInstanceIdentifier")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = nil)
  if valid_593445 != nil:
    section.add "DBInstanceIdentifier", valid_593445
  var valid_593446 = query.getOrDefault("SkipFinalSnapshot")
  valid_593446 = validateParameter(valid_593446, JBool, required = false, default = nil)
  if valid_593446 != nil:
    section.add "SkipFinalSnapshot", valid_593446
  var valid_593447 = query.getOrDefault("Action")
  valid_593447 = validateParameter(valid_593447, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593447 != nil:
    section.add "Action", valid_593447
  var valid_593448 = query.getOrDefault("Version")
  valid_593448 = validateParameter(valid_593448, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593448 != nil:
    section.add "Version", valid_593448
  var valid_593449 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593449
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
  var valid_593450 = header.getOrDefault("X-Amz-Signature")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Signature", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Content-Sha256", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Date")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Date", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Credential")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Credential", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Security-Token")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Security-Token", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Algorithm")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Algorithm", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-SignedHeaders", valid_593456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593457: Call_GetDeleteDBInstance_593442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593457.validator(path, query, header, formData, body)
  let scheme = call_593457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593457.url(scheme.get, call_593457.host, call_593457.base,
                         call_593457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593457, url, valid)

proc call*(call_593458: Call_GetDeleteDBInstance_593442;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_593459 = newJObject()
  add(query_593459, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593459, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_593459, "Action", newJString(Action))
  add(query_593459, "Version", newJString(Version))
  add(query_593459, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_593458.call(nil, query_593459, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_593442(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_593443, base: "/",
    url: url_GetDeleteDBInstance_593444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_593495 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBParameterGroup_593497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_593496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593498 = query.getOrDefault("Action")
  valid_593498 = validateParameter(valid_593498, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593498 != nil:
    section.add "Action", valid_593498
  var valid_593499 = query.getOrDefault("Version")
  valid_593499 = validateParameter(valid_593499, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593499 != nil:
    section.add "Version", valid_593499
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
  var valid_593500 = header.getOrDefault("X-Amz-Signature")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Signature", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Content-Sha256", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Date")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Date", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Credential")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Credential", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Security-Token")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Security-Token", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Algorithm")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Algorithm", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-SignedHeaders", valid_593506
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593507 = formData.getOrDefault("DBParameterGroupName")
  valid_593507 = validateParameter(valid_593507, JString, required = true,
                                 default = nil)
  if valid_593507 != nil:
    section.add "DBParameterGroupName", valid_593507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593508: Call_PostDeleteDBParameterGroup_593495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593508.validator(path, query, header, formData, body)
  let scheme = call_593508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593508.url(scheme.get, call_593508.host, call_593508.base,
                         call_593508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593508, url, valid)

proc call*(call_593509: Call_PostDeleteDBParameterGroup_593495;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593510 = newJObject()
  var formData_593511 = newJObject()
  add(formData_593511, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593510, "Action", newJString(Action))
  add(query_593510, "Version", newJString(Version))
  result = call_593509.call(nil, query_593510, nil, formData_593511, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_593495(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_593496, base: "/",
    url: url_PostDeleteDBParameterGroup_593497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_593479 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBParameterGroup_593481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_593480(path: JsonNode; query: JsonNode;
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
  var valid_593482 = query.getOrDefault("DBParameterGroupName")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = nil)
  if valid_593482 != nil:
    section.add "DBParameterGroupName", valid_593482
  var valid_593483 = query.getOrDefault("Action")
  valid_593483 = validateParameter(valid_593483, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593483 != nil:
    section.add "Action", valid_593483
  var valid_593484 = query.getOrDefault("Version")
  valid_593484 = validateParameter(valid_593484, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593484 != nil:
    section.add "Version", valid_593484
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
  var valid_593485 = header.getOrDefault("X-Amz-Signature")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Signature", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Content-Sha256", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Date")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Date", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Credential")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Credential", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Security-Token")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Security-Token", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Algorithm")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Algorithm", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-SignedHeaders", valid_593491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593492: Call_GetDeleteDBParameterGroup_593479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593492.validator(path, query, header, formData, body)
  let scheme = call_593492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593492.url(scheme.get, call_593492.host, call_593492.base,
                         call_593492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593492, url, valid)

proc call*(call_593493: Call_GetDeleteDBParameterGroup_593479;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593494 = newJObject()
  add(query_593494, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593494, "Action", newJString(Action))
  add(query_593494, "Version", newJString(Version))
  result = call_593493.call(nil, query_593494, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_593479(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_593480, base: "/",
    url: url_GetDeleteDBParameterGroup_593481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_593528 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSecurityGroup_593530(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_593529(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593531 = query.getOrDefault("Action")
  valid_593531 = validateParameter(valid_593531, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593531 != nil:
    section.add "Action", valid_593531
  var valid_593532 = query.getOrDefault("Version")
  valid_593532 = validateParameter(valid_593532, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593532 != nil:
    section.add "Version", valid_593532
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
  var valid_593533 = header.getOrDefault("X-Amz-Signature")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Signature", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Content-Sha256", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Date")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Date", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Credential")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Credential", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Security-Token")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Security-Token", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-Algorithm")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Algorithm", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-SignedHeaders", valid_593539
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593540 = formData.getOrDefault("DBSecurityGroupName")
  valid_593540 = validateParameter(valid_593540, JString, required = true,
                                 default = nil)
  if valid_593540 != nil:
    section.add "DBSecurityGroupName", valid_593540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593541: Call_PostDeleteDBSecurityGroup_593528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593541.validator(path, query, header, formData, body)
  let scheme = call_593541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593541.url(scheme.get, call_593541.host, call_593541.base,
                         call_593541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593541, url, valid)

proc call*(call_593542: Call_PostDeleteDBSecurityGroup_593528;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593543 = newJObject()
  var formData_593544 = newJObject()
  add(formData_593544, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593543, "Action", newJString(Action))
  add(query_593543, "Version", newJString(Version))
  result = call_593542.call(nil, query_593543, nil, formData_593544, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_593528(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_593529, base: "/",
    url: url_PostDeleteDBSecurityGroup_593530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_593512 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSecurityGroup_593514(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_593513(path: JsonNode; query: JsonNode;
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
  var valid_593515 = query.getOrDefault("DBSecurityGroupName")
  valid_593515 = validateParameter(valid_593515, JString, required = true,
                                 default = nil)
  if valid_593515 != nil:
    section.add "DBSecurityGroupName", valid_593515
  var valid_593516 = query.getOrDefault("Action")
  valid_593516 = validateParameter(valid_593516, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593516 != nil:
    section.add "Action", valid_593516
  var valid_593517 = query.getOrDefault("Version")
  valid_593517 = validateParameter(valid_593517, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593517 != nil:
    section.add "Version", valid_593517
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
  var valid_593518 = header.getOrDefault("X-Amz-Signature")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Signature", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Content-Sha256", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Date")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Date", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Credential")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Credential", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Security-Token")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Security-Token", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Algorithm")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Algorithm", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-SignedHeaders", valid_593524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593525: Call_GetDeleteDBSecurityGroup_593512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593525.validator(path, query, header, formData, body)
  let scheme = call_593525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593525.url(scheme.get, call_593525.host, call_593525.base,
                         call_593525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593525, url, valid)

proc call*(call_593526: Call_GetDeleteDBSecurityGroup_593512;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593527 = newJObject()
  add(query_593527, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593527, "Action", newJString(Action))
  add(query_593527, "Version", newJString(Version))
  result = call_593526.call(nil, query_593527, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_593512(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_593513, base: "/",
    url: url_GetDeleteDBSecurityGroup_593514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_593561 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSnapshot_593563(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_593562(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593564 = query.getOrDefault("Action")
  valid_593564 = validateParameter(valid_593564, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593564 != nil:
    section.add "Action", valid_593564
  var valid_593565 = query.getOrDefault("Version")
  valid_593565 = validateParameter(valid_593565, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593565 != nil:
    section.add "Version", valid_593565
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
  var valid_593566 = header.getOrDefault("X-Amz-Signature")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Signature", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Content-Sha256", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Date")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Date", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Credential")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Credential", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Security-Token")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Security-Token", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Algorithm")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Algorithm", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-SignedHeaders", valid_593572
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_593573 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593573 = validateParameter(valid_593573, JString, required = true,
                                 default = nil)
  if valid_593573 != nil:
    section.add "DBSnapshotIdentifier", valid_593573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593574: Call_PostDeleteDBSnapshot_593561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593574.validator(path, query, header, formData, body)
  let scheme = call_593574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593574.url(scheme.get, call_593574.host, call_593574.base,
                         call_593574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593574, url, valid)

proc call*(call_593575: Call_PostDeleteDBSnapshot_593561;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593576 = newJObject()
  var formData_593577 = newJObject()
  add(formData_593577, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593576, "Action", newJString(Action))
  add(query_593576, "Version", newJString(Version))
  result = call_593575.call(nil, query_593576, nil, formData_593577, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_593561(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_593562, base: "/",
    url: url_PostDeleteDBSnapshot_593563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_593545 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSnapshot_593547(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_593546(path: JsonNode; query: JsonNode;
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
  var valid_593548 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593548 = validateParameter(valid_593548, JString, required = true,
                                 default = nil)
  if valid_593548 != nil:
    section.add "DBSnapshotIdentifier", valid_593548
  var valid_593549 = query.getOrDefault("Action")
  valid_593549 = validateParameter(valid_593549, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593549 != nil:
    section.add "Action", valid_593549
  var valid_593550 = query.getOrDefault("Version")
  valid_593550 = validateParameter(valid_593550, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593550 != nil:
    section.add "Version", valid_593550
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
  var valid_593551 = header.getOrDefault("X-Amz-Signature")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Signature", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Content-Sha256", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Date")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Date", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Credential")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Credential", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Security-Token")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Security-Token", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Algorithm")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Algorithm", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-SignedHeaders", valid_593557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593558: Call_GetDeleteDBSnapshot_593545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593558.validator(path, query, header, formData, body)
  let scheme = call_593558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593558.url(scheme.get, call_593558.host, call_593558.base,
                         call_593558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593558, url, valid)

proc call*(call_593559: Call_GetDeleteDBSnapshot_593545;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593560 = newJObject()
  add(query_593560, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593560, "Action", newJString(Action))
  add(query_593560, "Version", newJString(Version))
  result = call_593559.call(nil, query_593560, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_593545(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_593546, base: "/",
    url: url_GetDeleteDBSnapshot_593547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_593594 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSubnetGroup_593596(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_593595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593597 = query.getOrDefault("Action")
  valid_593597 = validateParameter(valid_593597, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593597 != nil:
    section.add "Action", valid_593597
  var valid_593598 = query.getOrDefault("Version")
  valid_593598 = validateParameter(valid_593598, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593598 != nil:
    section.add "Version", valid_593598
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
  var valid_593599 = header.getOrDefault("X-Amz-Signature")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Signature", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Content-Sha256", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Date")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Date", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Credential")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Credential", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Security-Token")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Security-Token", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Algorithm")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Algorithm", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-SignedHeaders", valid_593605
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_593606 = formData.getOrDefault("DBSubnetGroupName")
  valid_593606 = validateParameter(valid_593606, JString, required = true,
                                 default = nil)
  if valid_593606 != nil:
    section.add "DBSubnetGroupName", valid_593606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593607: Call_PostDeleteDBSubnetGroup_593594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593607.validator(path, query, header, formData, body)
  let scheme = call_593607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593607.url(scheme.get, call_593607.host, call_593607.base,
                         call_593607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593607, url, valid)

proc call*(call_593608: Call_PostDeleteDBSubnetGroup_593594;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593609 = newJObject()
  var formData_593610 = newJObject()
  add(query_593609, "Action", newJString(Action))
  add(formData_593610, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593609, "Version", newJString(Version))
  result = call_593608.call(nil, query_593609, nil, formData_593610, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_593594(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_593595, base: "/",
    url: url_PostDeleteDBSubnetGroup_593596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_593578 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSubnetGroup_593580(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_593579(path: JsonNode; query: JsonNode;
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
  var valid_593581 = query.getOrDefault("Action")
  valid_593581 = validateParameter(valid_593581, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593581 != nil:
    section.add "Action", valid_593581
  var valid_593582 = query.getOrDefault("DBSubnetGroupName")
  valid_593582 = validateParameter(valid_593582, JString, required = true,
                                 default = nil)
  if valid_593582 != nil:
    section.add "DBSubnetGroupName", valid_593582
  var valid_593583 = query.getOrDefault("Version")
  valid_593583 = validateParameter(valid_593583, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593583 != nil:
    section.add "Version", valid_593583
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
  var valid_593584 = header.getOrDefault("X-Amz-Signature")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Signature", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Content-Sha256", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Date")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Date", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Credential")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Credential", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Security-Token")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Security-Token", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Algorithm")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Algorithm", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-SignedHeaders", valid_593590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593591: Call_GetDeleteDBSubnetGroup_593578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593591.validator(path, query, header, formData, body)
  let scheme = call_593591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593591.url(scheme.get, call_593591.host, call_593591.base,
                         call_593591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593591, url, valid)

proc call*(call_593592: Call_GetDeleteDBSubnetGroup_593578;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593593 = newJObject()
  add(query_593593, "Action", newJString(Action))
  add(query_593593, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593593, "Version", newJString(Version))
  result = call_593592.call(nil, query_593593, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_593578(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_593579, base: "/",
    url: url_GetDeleteDBSubnetGroup_593580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_593627 = ref object of OpenApiRestCall_592348
proc url_PostDeleteEventSubscription_593629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_593628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593630 = query.getOrDefault("Action")
  valid_593630 = validateParameter(valid_593630, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593630 != nil:
    section.add "Action", valid_593630
  var valid_593631 = query.getOrDefault("Version")
  valid_593631 = validateParameter(valid_593631, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593631 != nil:
    section.add "Version", valid_593631
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
  var valid_593632 = header.getOrDefault("X-Amz-Signature")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Signature", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Content-Sha256", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Date")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Date", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Credential")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Credential", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Security-Token")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Security-Token", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Algorithm")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Algorithm", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-SignedHeaders", valid_593638
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_593639 = formData.getOrDefault("SubscriptionName")
  valid_593639 = validateParameter(valid_593639, JString, required = true,
                                 default = nil)
  if valid_593639 != nil:
    section.add "SubscriptionName", valid_593639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593640: Call_PostDeleteEventSubscription_593627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593640.validator(path, query, header, formData, body)
  let scheme = call_593640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593640.url(scheme.get, call_593640.host, call_593640.base,
                         call_593640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593640, url, valid)

proc call*(call_593641: Call_PostDeleteEventSubscription_593627;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593642 = newJObject()
  var formData_593643 = newJObject()
  add(formData_593643, "SubscriptionName", newJString(SubscriptionName))
  add(query_593642, "Action", newJString(Action))
  add(query_593642, "Version", newJString(Version))
  result = call_593641.call(nil, query_593642, nil, formData_593643, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_593627(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_593628, base: "/",
    url: url_PostDeleteEventSubscription_593629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_593611 = ref object of OpenApiRestCall_592348
proc url_GetDeleteEventSubscription_593613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_593612(path: JsonNode; query: JsonNode;
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
  var valid_593614 = query.getOrDefault("SubscriptionName")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = nil)
  if valid_593614 != nil:
    section.add "SubscriptionName", valid_593614
  var valid_593615 = query.getOrDefault("Action")
  valid_593615 = validateParameter(valid_593615, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593615 != nil:
    section.add "Action", valid_593615
  var valid_593616 = query.getOrDefault("Version")
  valid_593616 = validateParameter(valid_593616, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593616 != nil:
    section.add "Version", valid_593616
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
  var valid_593617 = header.getOrDefault("X-Amz-Signature")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Signature", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Content-Sha256", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Date")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Date", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Credential")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Credential", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Security-Token")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Security-Token", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Algorithm")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Algorithm", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-SignedHeaders", valid_593623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593624: Call_GetDeleteEventSubscription_593611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593624.validator(path, query, header, formData, body)
  let scheme = call_593624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593624.url(scheme.get, call_593624.host, call_593624.base,
                         call_593624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593624, url, valid)

proc call*(call_593625: Call_GetDeleteEventSubscription_593611;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593626 = newJObject()
  add(query_593626, "SubscriptionName", newJString(SubscriptionName))
  add(query_593626, "Action", newJString(Action))
  add(query_593626, "Version", newJString(Version))
  result = call_593625.call(nil, query_593626, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_593611(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_593612, base: "/",
    url: url_GetDeleteEventSubscription_593613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_593660 = ref object of OpenApiRestCall_592348
proc url_PostDeleteOptionGroup_593662(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_593661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593663 = query.getOrDefault("Action")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593663 != nil:
    section.add "Action", valid_593663
  var valid_593664 = query.getOrDefault("Version")
  valid_593664 = validateParameter(valid_593664, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593664 != nil:
    section.add "Version", valid_593664
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
  var valid_593665 = header.getOrDefault("X-Amz-Signature")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Signature", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Content-Sha256", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Date")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Date", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Credential")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Credential", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Security-Token")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Security-Token", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Algorithm")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Algorithm", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-SignedHeaders", valid_593671
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_593672 = formData.getOrDefault("OptionGroupName")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = nil)
  if valid_593672 != nil:
    section.add "OptionGroupName", valid_593672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593673: Call_PostDeleteOptionGroup_593660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593673.validator(path, query, header, formData, body)
  let scheme = call_593673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593673.url(scheme.get, call_593673.host, call_593673.base,
                         call_593673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593673, url, valid)

proc call*(call_593674: Call_PostDeleteOptionGroup_593660; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593675 = newJObject()
  var formData_593676 = newJObject()
  add(query_593675, "Action", newJString(Action))
  add(formData_593676, "OptionGroupName", newJString(OptionGroupName))
  add(query_593675, "Version", newJString(Version))
  result = call_593674.call(nil, query_593675, nil, formData_593676, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_593660(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_593661, base: "/",
    url: url_PostDeleteOptionGroup_593662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_593644 = ref object of OpenApiRestCall_592348
proc url_GetDeleteOptionGroup_593646(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_593645(path: JsonNode; query: JsonNode;
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
  var valid_593647 = query.getOrDefault("Action")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593647 != nil:
    section.add "Action", valid_593647
  var valid_593648 = query.getOrDefault("OptionGroupName")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = nil)
  if valid_593648 != nil:
    section.add "OptionGroupName", valid_593648
  var valid_593649 = query.getOrDefault("Version")
  valid_593649 = validateParameter(valid_593649, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593649 != nil:
    section.add "Version", valid_593649
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
  var valid_593650 = header.getOrDefault("X-Amz-Signature")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Signature", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Content-Sha256", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Date")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Date", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Credential")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Credential", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Security-Token")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Security-Token", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Algorithm")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Algorithm", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-SignedHeaders", valid_593656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593657: Call_GetDeleteOptionGroup_593644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593657.validator(path, query, header, formData, body)
  let scheme = call_593657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593657.url(scheme.get, call_593657.host, call_593657.base,
                         call_593657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593657, url, valid)

proc call*(call_593658: Call_GetDeleteOptionGroup_593644; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593659 = newJObject()
  add(query_593659, "Action", newJString(Action))
  add(query_593659, "OptionGroupName", newJString(OptionGroupName))
  add(query_593659, "Version", newJString(Version))
  result = call_593658.call(nil, query_593659, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_593644(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_593645, base: "/",
    url: url_GetDeleteOptionGroup_593646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_593699 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBEngineVersions_593701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_593700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593702 = query.getOrDefault("Action")
  valid_593702 = validateParameter(valid_593702, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593702 != nil:
    section.add "Action", valid_593702
  var valid_593703 = query.getOrDefault("Version")
  valid_593703 = validateParameter(valid_593703, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593703 != nil:
    section.add "Version", valid_593703
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
  var valid_593704 = header.getOrDefault("X-Amz-Signature")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "X-Amz-Signature", valid_593704
  var valid_593705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Content-Sha256", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-Date")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-Date", valid_593706
  var valid_593707 = header.getOrDefault("X-Amz-Credential")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Credential", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Security-Token")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Security-Token", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Algorithm")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Algorithm", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-SignedHeaders", valid_593710
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_593711 = formData.getOrDefault("DefaultOnly")
  valid_593711 = validateParameter(valid_593711, JBool, required = false, default = nil)
  if valid_593711 != nil:
    section.add "DefaultOnly", valid_593711
  var valid_593712 = formData.getOrDefault("MaxRecords")
  valid_593712 = validateParameter(valid_593712, JInt, required = false, default = nil)
  if valid_593712 != nil:
    section.add "MaxRecords", valid_593712
  var valid_593713 = formData.getOrDefault("EngineVersion")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "EngineVersion", valid_593713
  var valid_593714 = formData.getOrDefault("Marker")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "Marker", valid_593714
  var valid_593715 = formData.getOrDefault("Engine")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "Engine", valid_593715
  var valid_593716 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_593716 = validateParameter(valid_593716, JBool, required = false, default = nil)
  if valid_593716 != nil:
    section.add "ListSupportedCharacterSets", valid_593716
  var valid_593717 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "DBParameterGroupFamily", valid_593717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593718: Call_PostDescribeDBEngineVersions_593699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593718.validator(path, query, header, formData, body)
  let scheme = call_593718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593718.url(scheme.get, call_593718.host, call_593718.base,
                         call_593718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593718, url, valid)

proc call*(call_593719: Call_PostDescribeDBEngineVersions_593699;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          Version: string = "2013-01-10"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_593720 = newJObject()
  var formData_593721 = newJObject()
  add(formData_593721, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_593721, "MaxRecords", newJInt(MaxRecords))
  add(formData_593721, "EngineVersion", newJString(EngineVersion))
  add(formData_593721, "Marker", newJString(Marker))
  add(formData_593721, "Engine", newJString(Engine))
  add(formData_593721, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593720, "Action", newJString(Action))
  add(query_593720, "Version", newJString(Version))
  add(formData_593721, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593719.call(nil, query_593720, nil, formData_593721, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_593699(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_593700, base: "/",
    url: url_PostDescribeDBEngineVersions_593701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_593677 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBEngineVersions_593679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_593678(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_593680 = query.getOrDefault("Marker")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "Marker", valid_593680
  var valid_593681 = query.getOrDefault("DBParameterGroupFamily")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "DBParameterGroupFamily", valid_593681
  var valid_593682 = query.getOrDefault("Engine")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "Engine", valid_593682
  var valid_593683 = query.getOrDefault("EngineVersion")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "EngineVersion", valid_593683
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593684 = query.getOrDefault("Action")
  valid_593684 = validateParameter(valid_593684, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593684 != nil:
    section.add "Action", valid_593684
  var valid_593685 = query.getOrDefault("ListSupportedCharacterSets")
  valid_593685 = validateParameter(valid_593685, JBool, required = false, default = nil)
  if valid_593685 != nil:
    section.add "ListSupportedCharacterSets", valid_593685
  var valid_593686 = query.getOrDefault("Version")
  valid_593686 = validateParameter(valid_593686, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593686 != nil:
    section.add "Version", valid_593686
  var valid_593687 = query.getOrDefault("MaxRecords")
  valid_593687 = validateParameter(valid_593687, JInt, required = false, default = nil)
  if valid_593687 != nil:
    section.add "MaxRecords", valid_593687
  var valid_593688 = query.getOrDefault("DefaultOnly")
  valid_593688 = validateParameter(valid_593688, JBool, required = false, default = nil)
  if valid_593688 != nil:
    section.add "DefaultOnly", valid_593688
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
  var valid_593689 = header.getOrDefault("X-Amz-Signature")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-Signature", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Content-Sha256", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-Date")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-Date", valid_593691
  var valid_593692 = header.getOrDefault("X-Amz-Credential")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Credential", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Security-Token")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Security-Token", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Algorithm")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Algorithm", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-SignedHeaders", valid_593695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593696: Call_GetDescribeDBEngineVersions_593677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593696.validator(path, query, header, formData, body)
  let scheme = call_593696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593696.url(scheme.get, call_593696.host, call_593696.base,
                         call_593696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593696, url, valid)

proc call*(call_593697: Call_GetDescribeDBEngineVersions_593677;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-01-10";
          MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_593698 = newJObject()
  add(query_593698, "Marker", newJString(Marker))
  add(query_593698, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593698, "Engine", newJString(Engine))
  add(query_593698, "EngineVersion", newJString(EngineVersion))
  add(query_593698, "Action", newJString(Action))
  add(query_593698, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593698, "Version", newJString(Version))
  add(query_593698, "MaxRecords", newJInt(MaxRecords))
  add(query_593698, "DefaultOnly", newJBool(DefaultOnly))
  result = call_593697.call(nil, query_593698, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_593677(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_593678, base: "/",
    url: url_GetDescribeDBEngineVersions_593679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_593740 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBInstances_593742(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_593741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593743 = query.getOrDefault("Action")
  valid_593743 = validateParameter(valid_593743, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593743 != nil:
    section.add "Action", valid_593743
  var valid_593744 = query.getOrDefault("Version")
  valid_593744 = validateParameter(valid_593744, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593744 != nil:
    section.add "Version", valid_593744
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
  var valid_593745 = header.getOrDefault("X-Amz-Signature")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Signature", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Content-Sha256", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Date")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Date", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Credential")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Credential", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Security-Token")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Security-Token", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Algorithm")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Algorithm", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-SignedHeaders", valid_593751
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_593752 = formData.getOrDefault("MaxRecords")
  valid_593752 = validateParameter(valid_593752, JInt, required = false, default = nil)
  if valid_593752 != nil:
    section.add "MaxRecords", valid_593752
  var valid_593753 = formData.getOrDefault("Marker")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "Marker", valid_593753
  var valid_593754 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "DBInstanceIdentifier", valid_593754
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593755: Call_PostDescribeDBInstances_593740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593755.validator(path, query, header, formData, body)
  let scheme = call_593755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593755.url(scheme.get, call_593755.host, call_593755.base,
                         call_593755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593755, url, valid)

proc call*(call_593756: Call_PostDescribeDBInstances_593740; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593757 = newJObject()
  var formData_593758 = newJObject()
  add(formData_593758, "MaxRecords", newJInt(MaxRecords))
  add(formData_593758, "Marker", newJString(Marker))
  add(formData_593758, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593757, "Action", newJString(Action))
  add(query_593757, "Version", newJString(Version))
  result = call_593756.call(nil, query_593757, nil, formData_593758, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_593740(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_593741, base: "/",
    url: url_PostDescribeDBInstances_593742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_593722 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBInstances_593724(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_593723(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593725 = query.getOrDefault("Marker")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "Marker", valid_593725
  var valid_593726 = query.getOrDefault("DBInstanceIdentifier")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "DBInstanceIdentifier", valid_593726
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593727 = query.getOrDefault("Action")
  valid_593727 = validateParameter(valid_593727, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593727 != nil:
    section.add "Action", valid_593727
  var valid_593728 = query.getOrDefault("Version")
  valid_593728 = validateParameter(valid_593728, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593728 != nil:
    section.add "Version", valid_593728
  var valid_593729 = query.getOrDefault("MaxRecords")
  valid_593729 = validateParameter(valid_593729, JInt, required = false, default = nil)
  if valid_593729 != nil:
    section.add "MaxRecords", valid_593729
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
  var valid_593730 = header.getOrDefault("X-Amz-Signature")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Signature", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Content-Sha256", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Date")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Date", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Credential")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Credential", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Security-Token")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Security-Token", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Algorithm")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Algorithm", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-SignedHeaders", valid_593736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593737: Call_GetDescribeDBInstances_593722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593737.validator(path, query, header, formData, body)
  let scheme = call_593737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593737.url(scheme.get, call_593737.host, call_593737.base,
                         call_593737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593737, url, valid)

proc call*(call_593738: Call_GetDescribeDBInstances_593722; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593739 = newJObject()
  add(query_593739, "Marker", newJString(Marker))
  add(query_593739, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593739, "Action", newJString(Action))
  add(query_593739, "Version", newJString(Version))
  add(query_593739, "MaxRecords", newJInt(MaxRecords))
  result = call_593738.call(nil, query_593739, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_593722(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_593723, base: "/",
    url: url_GetDescribeDBInstances_593724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_593777 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameterGroups_593779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_593778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593780 = query.getOrDefault("Action")
  valid_593780 = validateParameter(valid_593780, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593780 != nil:
    section.add "Action", valid_593780
  var valid_593781 = query.getOrDefault("Version")
  valid_593781 = validateParameter(valid_593781, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593781 != nil:
    section.add "Version", valid_593781
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
  var valid_593782 = header.getOrDefault("X-Amz-Signature")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "X-Amz-Signature", valid_593782
  var valid_593783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "X-Amz-Content-Sha256", valid_593783
  var valid_593784 = header.getOrDefault("X-Amz-Date")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "X-Amz-Date", valid_593784
  var valid_593785 = header.getOrDefault("X-Amz-Credential")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Credential", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Security-Token")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Security-Token", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Algorithm")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Algorithm", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-SignedHeaders", valid_593788
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_593789 = formData.getOrDefault("MaxRecords")
  valid_593789 = validateParameter(valid_593789, JInt, required = false, default = nil)
  if valid_593789 != nil:
    section.add "MaxRecords", valid_593789
  var valid_593790 = formData.getOrDefault("DBParameterGroupName")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "DBParameterGroupName", valid_593790
  var valid_593791 = formData.getOrDefault("Marker")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "Marker", valid_593791
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593792: Call_PostDescribeDBParameterGroups_593777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593792.validator(path, query, header, formData, body)
  let scheme = call_593792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593792.url(scheme.get, call_593792.host, call_593792.base,
                         call_593792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593792, url, valid)

proc call*(call_593793: Call_PostDescribeDBParameterGroups_593777;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593794 = newJObject()
  var formData_593795 = newJObject()
  add(formData_593795, "MaxRecords", newJInt(MaxRecords))
  add(formData_593795, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593795, "Marker", newJString(Marker))
  add(query_593794, "Action", newJString(Action))
  add(query_593794, "Version", newJString(Version))
  result = call_593793.call(nil, query_593794, nil, formData_593795, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_593777(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_593778, base: "/",
    url: url_PostDescribeDBParameterGroups_593779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_593759 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameterGroups_593761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_593760(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593762 = query.getOrDefault("Marker")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "Marker", valid_593762
  var valid_593763 = query.getOrDefault("DBParameterGroupName")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "DBParameterGroupName", valid_593763
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593764 = query.getOrDefault("Action")
  valid_593764 = validateParameter(valid_593764, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593764 != nil:
    section.add "Action", valid_593764
  var valid_593765 = query.getOrDefault("Version")
  valid_593765 = validateParameter(valid_593765, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593765 != nil:
    section.add "Version", valid_593765
  var valid_593766 = query.getOrDefault("MaxRecords")
  valid_593766 = validateParameter(valid_593766, JInt, required = false, default = nil)
  if valid_593766 != nil:
    section.add "MaxRecords", valid_593766
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
  var valid_593767 = header.getOrDefault("X-Amz-Signature")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Signature", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Content-Sha256", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Date")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Date", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Credential")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Credential", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Security-Token")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Security-Token", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Algorithm")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Algorithm", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-SignedHeaders", valid_593773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593774: Call_GetDescribeDBParameterGroups_593759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593774.validator(path, query, header, formData, body)
  let scheme = call_593774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593774.url(scheme.get, call_593774.host, call_593774.base,
                         call_593774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593774, url, valid)

proc call*(call_593775: Call_GetDescribeDBParameterGroups_593759;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593776 = newJObject()
  add(query_593776, "Marker", newJString(Marker))
  add(query_593776, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593776, "Action", newJString(Action))
  add(query_593776, "Version", newJString(Version))
  add(query_593776, "MaxRecords", newJInt(MaxRecords))
  result = call_593775.call(nil, query_593776, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_593759(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_593760, base: "/",
    url: url_GetDescribeDBParameterGroups_593761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_593815 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameters_593817(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_593816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593818 = query.getOrDefault("Action")
  valid_593818 = validateParameter(valid_593818, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593818 != nil:
    section.add "Action", valid_593818
  var valid_593819 = query.getOrDefault("Version")
  valid_593819 = validateParameter(valid_593819, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593819 != nil:
    section.add "Version", valid_593819
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
  var valid_593820 = header.getOrDefault("X-Amz-Signature")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Signature", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Content-Sha256", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Date")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Date", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-Credential")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Credential", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-Security-Token")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-Security-Token", valid_593824
  var valid_593825 = header.getOrDefault("X-Amz-Algorithm")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-Algorithm", valid_593825
  var valid_593826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "X-Amz-SignedHeaders", valid_593826
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_593827 = formData.getOrDefault("Source")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "Source", valid_593827
  var valid_593828 = formData.getOrDefault("MaxRecords")
  valid_593828 = validateParameter(valid_593828, JInt, required = false, default = nil)
  if valid_593828 != nil:
    section.add "MaxRecords", valid_593828
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593829 = formData.getOrDefault("DBParameterGroupName")
  valid_593829 = validateParameter(valid_593829, JString, required = true,
                                 default = nil)
  if valid_593829 != nil:
    section.add "DBParameterGroupName", valid_593829
  var valid_593830 = formData.getOrDefault("Marker")
  valid_593830 = validateParameter(valid_593830, JString, required = false,
                                 default = nil)
  if valid_593830 != nil:
    section.add "Marker", valid_593830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593831: Call_PostDescribeDBParameters_593815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593831.validator(path, query, header, formData, body)
  let scheme = call_593831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593831.url(scheme.get, call_593831.host, call_593831.base,
                         call_593831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593831, url, valid)

proc call*(call_593832: Call_PostDescribeDBParameters_593815;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593833 = newJObject()
  var formData_593834 = newJObject()
  add(formData_593834, "Source", newJString(Source))
  add(formData_593834, "MaxRecords", newJInt(MaxRecords))
  add(formData_593834, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593834, "Marker", newJString(Marker))
  add(query_593833, "Action", newJString(Action))
  add(query_593833, "Version", newJString(Version))
  result = call_593832.call(nil, query_593833, nil, formData_593834, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_593815(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_593816, base: "/",
    url: url_PostDescribeDBParameters_593817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_593796 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameters_593798(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_593797(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593799 = query.getOrDefault("Marker")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "Marker", valid_593799
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_593800 = query.getOrDefault("DBParameterGroupName")
  valid_593800 = validateParameter(valid_593800, JString, required = true,
                                 default = nil)
  if valid_593800 != nil:
    section.add "DBParameterGroupName", valid_593800
  var valid_593801 = query.getOrDefault("Source")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "Source", valid_593801
  var valid_593802 = query.getOrDefault("Action")
  valid_593802 = validateParameter(valid_593802, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593802 != nil:
    section.add "Action", valid_593802
  var valid_593803 = query.getOrDefault("Version")
  valid_593803 = validateParameter(valid_593803, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593803 != nil:
    section.add "Version", valid_593803
  var valid_593804 = query.getOrDefault("MaxRecords")
  valid_593804 = validateParameter(valid_593804, JInt, required = false, default = nil)
  if valid_593804 != nil:
    section.add "MaxRecords", valid_593804
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
  var valid_593805 = header.getOrDefault("X-Amz-Signature")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Signature", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Content-Sha256", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Date")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Date", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-Credential")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Credential", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Security-Token")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Security-Token", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-Algorithm")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Algorithm", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-SignedHeaders", valid_593811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593812: Call_GetDescribeDBParameters_593796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593812.validator(path, query, header, formData, body)
  let scheme = call_593812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593812.url(scheme.get, call_593812.host, call_593812.base,
                         call_593812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593812, url, valid)

proc call*(call_593813: Call_GetDescribeDBParameters_593796;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-01-10";
          MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593814 = newJObject()
  add(query_593814, "Marker", newJString(Marker))
  add(query_593814, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593814, "Source", newJString(Source))
  add(query_593814, "Action", newJString(Action))
  add(query_593814, "Version", newJString(Version))
  add(query_593814, "MaxRecords", newJInt(MaxRecords))
  result = call_593813.call(nil, query_593814, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_593796(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_593797, base: "/",
    url: url_GetDescribeDBParameters_593798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_593853 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSecurityGroups_593855(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_593854(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593856 = query.getOrDefault("Action")
  valid_593856 = validateParameter(valid_593856, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593856 != nil:
    section.add "Action", valid_593856
  var valid_593857 = query.getOrDefault("Version")
  valid_593857 = validateParameter(valid_593857, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593857 != nil:
    section.add "Version", valid_593857
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
  var valid_593858 = header.getOrDefault("X-Amz-Signature")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Signature", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Content-Sha256", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Date")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Date", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Credential")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Credential", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Security-Token")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Security-Token", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Algorithm")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Algorithm", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-SignedHeaders", valid_593864
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_593865 = formData.getOrDefault("DBSecurityGroupName")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "DBSecurityGroupName", valid_593865
  var valid_593866 = formData.getOrDefault("MaxRecords")
  valid_593866 = validateParameter(valid_593866, JInt, required = false, default = nil)
  if valid_593866 != nil:
    section.add "MaxRecords", valid_593866
  var valid_593867 = formData.getOrDefault("Marker")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "Marker", valid_593867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593868: Call_PostDescribeDBSecurityGroups_593853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593868.validator(path, query, header, formData, body)
  let scheme = call_593868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593868.url(scheme.get, call_593868.host, call_593868.base,
                         call_593868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593868, url, valid)

proc call*(call_593869: Call_PostDescribeDBSecurityGroups_593853;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593870 = newJObject()
  var formData_593871 = newJObject()
  add(formData_593871, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_593871, "MaxRecords", newJInt(MaxRecords))
  add(formData_593871, "Marker", newJString(Marker))
  add(query_593870, "Action", newJString(Action))
  add(query_593870, "Version", newJString(Version))
  result = call_593869.call(nil, query_593870, nil, formData_593871, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_593853(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_593854, base: "/",
    url: url_PostDescribeDBSecurityGroups_593855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_593835 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSecurityGroups_593837(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_593836(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593838 = query.getOrDefault("Marker")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "Marker", valid_593838
  var valid_593839 = query.getOrDefault("DBSecurityGroupName")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "DBSecurityGroupName", valid_593839
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593840 = query.getOrDefault("Action")
  valid_593840 = validateParameter(valid_593840, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593840 != nil:
    section.add "Action", valid_593840
  var valid_593841 = query.getOrDefault("Version")
  valid_593841 = validateParameter(valid_593841, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593841 != nil:
    section.add "Version", valid_593841
  var valid_593842 = query.getOrDefault("MaxRecords")
  valid_593842 = validateParameter(valid_593842, JInt, required = false, default = nil)
  if valid_593842 != nil:
    section.add "MaxRecords", valid_593842
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
  var valid_593843 = header.getOrDefault("X-Amz-Signature")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Signature", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Content-Sha256", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Date")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Date", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Credential")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Credential", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Security-Token")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Security-Token", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Algorithm")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Algorithm", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-SignedHeaders", valid_593849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593850: Call_GetDescribeDBSecurityGroups_593835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593850.validator(path, query, header, formData, body)
  let scheme = call_593850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593850.url(scheme.get, call_593850.host, call_593850.base,
                         call_593850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593850, url, valid)

proc call*(call_593851: Call_GetDescribeDBSecurityGroups_593835;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593852 = newJObject()
  add(query_593852, "Marker", newJString(Marker))
  add(query_593852, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593852, "Action", newJString(Action))
  add(query_593852, "Version", newJString(Version))
  add(query_593852, "MaxRecords", newJInt(MaxRecords))
  result = call_593851.call(nil, query_593852, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_593835(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_593836, base: "/",
    url: url_GetDescribeDBSecurityGroups_593837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_593892 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSnapshots_593894(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_593893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593895 = query.getOrDefault("Action")
  valid_593895 = validateParameter(valid_593895, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593895 != nil:
    section.add "Action", valid_593895
  var valid_593896 = query.getOrDefault("Version")
  valid_593896 = validateParameter(valid_593896, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593896 != nil:
    section.add "Version", valid_593896
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
  var valid_593897 = header.getOrDefault("X-Amz-Signature")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Signature", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-Content-Sha256", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Date")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Date", valid_593899
  var valid_593900 = header.getOrDefault("X-Amz-Credential")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "X-Amz-Credential", valid_593900
  var valid_593901 = header.getOrDefault("X-Amz-Security-Token")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "X-Amz-Security-Token", valid_593901
  var valid_593902 = header.getOrDefault("X-Amz-Algorithm")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "X-Amz-Algorithm", valid_593902
  var valid_593903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-SignedHeaders", valid_593903
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_593904 = formData.getOrDefault("SnapshotType")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "SnapshotType", valid_593904
  var valid_593905 = formData.getOrDefault("MaxRecords")
  valid_593905 = validateParameter(valid_593905, JInt, required = false, default = nil)
  if valid_593905 != nil:
    section.add "MaxRecords", valid_593905
  var valid_593906 = formData.getOrDefault("Marker")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "Marker", valid_593906
  var valid_593907 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "DBInstanceIdentifier", valid_593907
  var valid_593908 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "DBSnapshotIdentifier", valid_593908
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593909: Call_PostDescribeDBSnapshots_593892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593909.validator(path, query, header, formData, body)
  let scheme = call_593909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593909.url(scheme.get, call_593909.host, call_593909.base,
                         call_593909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593909, url, valid)

proc call*(call_593910: Call_PostDescribeDBSnapshots_593892;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593911 = newJObject()
  var formData_593912 = newJObject()
  add(formData_593912, "SnapshotType", newJString(SnapshotType))
  add(formData_593912, "MaxRecords", newJInt(MaxRecords))
  add(formData_593912, "Marker", newJString(Marker))
  add(formData_593912, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593912, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593911, "Action", newJString(Action))
  add(query_593911, "Version", newJString(Version))
  result = call_593910.call(nil, query_593911, nil, formData_593912, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_593892(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_593893, base: "/",
    url: url_PostDescribeDBSnapshots_593894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_593872 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSnapshots_593874(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_593873(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593875 = query.getOrDefault("Marker")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "Marker", valid_593875
  var valid_593876 = query.getOrDefault("DBInstanceIdentifier")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "DBInstanceIdentifier", valid_593876
  var valid_593877 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "DBSnapshotIdentifier", valid_593877
  var valid_593878 = query.getOrDefault("SnapshotType")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "SnapshotType", valid_593878
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593879 = query.getOrDefault("Action")
  valid_593879 = validateParameter(valid_593879, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593879 != nil:
    section.add "Action", valid_593879
  var valid_593880 = query.getOrDefault("Version")
  valid_593880 = validateParameter(valid_593880, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593880 != nil:
    section.add "Version", valid_593880
  var valid_593881 = query.getOrDefault("MaxRecords")
  valid_593881 = validateParameter(valid_593881, JInt, required = false, default = nil)
  if valid_593881 != nil:
    section.add "MaxRecords", valid_593881
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
  var valid_593882 = header.getOrDefault("X-Amz-Signature")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-Signature", valid_593882
  var valid_593883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Content-Sha256", valid_593883
  var valid_593884 = header.getOrDefault("X-Amz-Date")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Date", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Credential")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Credential", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Security-Token")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Security-Token", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Algorithm")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Algorithm", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-SignedHeaders", valid_593888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593889: Call_GetDescribeDBSnapshots_593872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593889.validator(path, query, header, formData, body)
  let scheme = call_593889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593889.url(scheme.get, call_593889.host, call_593889.base,
                         call_593889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593889, url, valid)

proc call*(call_593890: Call_GetDescribeDBSnapshots_593872; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593891 = newJObject()
  add(query_593891, "Marker", newJString(Marker))
  add(query_593891, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593891, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593891, "SnapshotType", newJString(SnapshotType))
  add(query_593891, "Action", newJString(Action))
  add(query_593891, "Version", newJString(Version))
  add(query_593891, "MaxRecords", newJInt(MaxRecords))
  result = call_593890.call(nil, query_593891, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_593872(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_593873, base: "/",
    url: url_GetDescribeDBSnapshots_593874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_593931 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSubnetGroups_593933(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_593932(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593934 = query.getOrDefault("Action")
  valid_593934 = validateParameter(valid_593934, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593934 != nil:
    section.add "Action", valid_593934
  var valid_593935 = query.getOrDefault("Version")
  valid_593935 = validateParameter(valid_593935, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593935 != nil:
    section.add "Version", valid_593935
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
  var valid_593936 = header.getOrDefault("X-Amz-Signature")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Signature", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Content-Sha256", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Date")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Date", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-Credential")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-Credential", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-Security-Token")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Security-Token", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-Algorithm")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Algorithm", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-SignedHeaders", valid_593942
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_593943 = formData.getOrDefault("MaxRecords")
  valid_593943 = validateParameter(valid_593943, JInt, required = false, default = nil)
  if valid_593943 != nil:
    section.add "MaxRecords", valid_593943
  var valid_593944 = formData.getOrDefault("Marker")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "Marker", valid_593944
  var valid_593945 = formData.getOrDefault("DBSubnetGroupName")
  valid_593945 = validateParameter(valid_593945, JString, required = false,
                                 default = nil)
  if valid_593945 != nil:
    section.add "DBSubnetGroupName", valid_593945
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593946: Call_PostDescribeDBSubnetGroups_593931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593946.validator(path, query, header, formData, body)
  let scheme = call_593946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593946.url(scheme.get, call_593946.host, call_593946.base,
                         call_593946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593946, url, valid)

proc call*(call_593947: Call_PostDescribeDBSubnetGroups_593931;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_593948 = newJObject()
  var formData_593949 = newJObject()
  add(formData_593949, "MaxRecords", newJInt(MaxRecords))
  add(formData_593949, "Marker", newJString(Marker))
  add(query_593948, "Action", newJString(Action))
  add(formData_593949, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593948, "Version", newJString(Version))
  result = call_593947.call(nil, query_593948, nil, formData_593949, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_593931(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_593932, base: "/",
    url: url_PostDescribeDBSubnetGroups_593933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_593913 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSubnetGroups_593915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_593914(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593916 = query.getOrDefault("Marker")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "Marker", valid_593916
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593917 = query.getOrDefault("Action")
  valid_593917 = validateParameter(valid_593917, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593917 != nil:
    section.add "Action", valid_593917
  var valid_593918 = query.getOrDefault("DBSubnetGroupName")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "DBSubnetGroupName", valid_593918
  var valid_593919 = query.getOrDefault("Version")
  valid_593919 = validateParameter(valid_593919, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593919 != nil:
    section.add "Version", valid_593919
  var valid_593920 = query.getOrDefault("MaxRecords")
  valid_593920 = validateParameter(valid_593920, JInt, required = false, default = nil)
  if valid_593920 != nil:
    section.add "MaxRecords", valid_593920
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
  var valid_593921 = header.getOrDefault("X-Amz-Signature")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Signature", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Content-Sha256", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Date")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Date", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Credential")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Credential", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Security-Token")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Security-Token", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Algorithm")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Algorithm", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-SignedHeaders", valid_593927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593928: Call_GetDescribeDBSubnetGroups_593913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593928.validator(path, query, header, formData, body)
  let scheme = call_593928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593928.url(scheme.get, call_593928.host, call_593928.base,
                         call_593928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593928, url, valid)

proc call*(call_593929: Call_GetDescribeDBSubnetGroups_593913; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593930 = newJObject()
  add(query_593930, "Marker", newJString(Marker))
  add(query_593930, "Action", newJString(Action))
  add(query_593930, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593930, "Version", newJString(Version))
  add(query_593930, "MaxRecords", newJInt(MaxRecords))
  result = call_593929.call(nil, query_593930, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_593913(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_593914, base: "/",
    url: url_GetDescribeDBSubnetGroups_593915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_593968 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEngineDefaultParameters_593970(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_593969(path: JsonNode;
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
  var valid_593971 = query.getOrDefault("Action")
  valid_593971 = validateParameter(valid_593971, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_593971 != nil:
    section.add "Action", valid_593971
  var valid_593972 = query.getOrDefault("Version")
  valid_593972 = validateParameter(valid_593972, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593972 != nil:
    section.add "Version", valid_593972
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
  var valid_593973 = header.getOrDefault("X-Amz-Signature")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Signature", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Content-Sha256", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Date")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Date", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Credential")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Credential", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-Security-Token")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-Security-Token", valid_593977
  var valid_593978 = header.getOrDefault("X-Amz-Algorithm")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-Algorithm", valid_593978
  var valid_593979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-SignedHeaders", valid_593979
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_593980 = formData.getOrDefault("MaxRecords")
  valid_593980 = validateParameter(valid_593980, JInt, required = false, default = nil)
  if valid_593980 != nil:
    section.add "MaxRecords", valid_593980
  var valid_593981 = formData.getOrDefault("Marker")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "Marker", valid_593981
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593982 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593982 = validateParameter(valid_593982, JString, required = true,
                                 default = nil)
  if valid_593982 != nil:
    section.add "DBParameterGroupFamily", valid_593982
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593983: Call_PostDescribeEngineDefaultParameters_593968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593983.validator(path, query, header, formData, body)
  let scheme = call_593983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593983.url(scheme.get, call_593983.host, call_593983.base,
                         call_593983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593983, url, valid)

proc call*(call_593984: Call_PostDescribeEngineDefaultParameters_593968;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_593985 = newJObject()
  var formData_593986 = newJObject()
  add(formData_593986, "MaxRecords", newJInt(MaxRecords))
  add(formData_593986, "Marker", newJString(Marker))
  add(query_593985, "Action", newJString(Action))
  add(query_593985, "Version", newJString(Version))
  add(formData_593986, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593984.call(nil, query_593985, nil, formData_593986, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_593968(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_593969, base: "/",
    url: url_PostDescribeEngineDefaultParameters_593970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_593950 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEngineDefaultParameters_593952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_593951(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_593953 = query.getOrDefault("Marker")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "Marker", valid_593953
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_593954 = query.getOrDefault("DBParameterGroupFamily")
  valid_593954 = validateParameter(valid_593954, JString, required = true,
                                 default = nil)
  if valid_593954 != nil:
    section.add "DBParameterGroupFamily", valid_593954
  var valid_593955 = query.getOrDefault("Action")
  valid_593955 = validateParameter(valid_593955, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_593955 != nil:
    section.add "Action", valid_593955
  var valid_593956 = query.getOrDefault("Version")
  valid_593956 = validateParameter(valid_593956, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593956 != nil:
    section.add "Version", valid_593956
  var valid_593957 = query.getOrDefault("MaxRecords")
  valid_593957 = validateParameter(valid_593957, JInt, required = false, default = nil)
  if valid_593957 != nil:
    section.add "MaxRecords", valid_593957
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
  var valid_593958 = header.getOrDefault("X-Amz-Signature")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "X-Amz-Signature", valid_593958
  var valid_593959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "X-Amz-Content-Sha256", valid_593959
  var valid_593960 = header.getOrDefault("X-Amz-Date")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "X-Amz-Date", valid_593960
  var valid_593961 = header.getOrDefault("X-Amz-Credential")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "X-Amz-Credential", valid_593961
  var valid_593962 = header.getOrDefault("X-Amz-Security-Token")
  valid_593962 = validateParameter(valid_593962, JString, required = false,
                                 default = nil)
  if valid_593962 != nil:
    section.add "X-Amz-Security-Token", valid_593962
  var valid_593963 = header.getOrDefault("X-Amz-Algorithm")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-Algorithm", valid_593963
  var valid_593964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-SignedHeaders", valid_593964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593965: Call_GetDescribeEngineDefaultParameters_593950;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593965.validator(path, query, header, formData, body)
  let scheme = call_593965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593965.url(scheme.get, call_593965.host, call_593965.base,
                         call_593965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593965, url, valid)

proc call*(call_593966: Call_GetDescribeEngineDefaultParameters_593950;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_593967 = newJObject()
  add(query_593967, "Marker", newJString(Marker))
  add(query_593967, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593967, "Action", newJString(Action))
  add(query_593967, "Version", newJString(Version))
  add(query_593967, "MaxRecords", newJInt(MaxRecords))
  result = call_593966.call(nil, query_593967, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_593950(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_593951, base: "/",
    url: url_GetDescribeEngineDefaultParameters_593952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_594003 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventCategories_594005(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_594004(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594006 = query.getOrDefault("Action")
  valid_594006 = validateParameter(valid_594006, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594006 != nil:
    section.add "Action", valid_594006
  var valid_594007 = query.getOrDefault("Version")
  valid_594007 = validateParameter(valid_594007, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594007 != nil:
    section.add "Version", valid_594007
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
  var valid_594008 = header.getOrDefault("X-Amz-Signature")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Signature", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Content-Sha256", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Date")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Date", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Credential")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Credential", valid_594011
  var valid_594012 = header.getOrDefault("X-Amz-Security-Token")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Security-Token", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-Algorithm")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Algorithm", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-SignedHeaders", valid_594014
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_594015 = formData.getOrDefault("SourceType")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "SourceType", valid_594015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594016: Call_PostDescribeEventCategories_594003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594016.validator(path, query, header, formData, body)
  let scheme = call_594016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594016.url(scheme.get, call_594016.host, call_594016.base,
                         call_594016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594016, url, valid)

proc call*(call_594017: Call_PostDescribeEventCategories_594003;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594018 = newJObject()
  var formData_594019 = newJObject()
  add(formData_594019, "SourceType", newJString(SourceType))
  add(query_594018, "Action", newJString(Action))
  add(query_594018, "Version", newJString(Version))
  result = call_594017.call(nil, query_594018, nil, formData_594019, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_594003(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_594004, base: "/",
    url: url_PostDescribeEventCategories_594005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_593987 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventCategories_593989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_593988(path: JsonNode; query: JsonNode;
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
  var valid_593990 = query.getOrDefault("SourceType")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "SourceType", valid_593990
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593991 = query.getOrDefault("Action")
  valid_593991 = validateParameter(valid_593991, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_593991 != nil:
    section.add "Action", valid_593991
  var valid_593992 = query.getOrDefault("Version")
  valid_593992 = validateParameter(valid_593992, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593992 != nil:
    section.add "Version", valid_593992
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
  var valid_593993 = header.getOrDefault("X-Amz-Signature")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Signature", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-Content-Sha256", valid_593994
  var valid_593995 = header.getOrDefault("X-Amz-Date")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "X-Amz-Date", valid_593995
  var valid_593996 = header.getOrDefault("X-Amz-Credential")
  valid_593996 = validateParameter(valid_593996, JString, required = false,
                                 default = nil)
  if valid_593996 != nil:
    section.add "X-Amz-Credential", valid_593996
  var valid_593997 = header.getOrDefault("X-Amz-Security-Token")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "X-Amz-Security-Token", valid_593997
  var valid_593998 = header.getOrDefault("X-Amz-Algorithm")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "X-Amz-Algorithm", valid_593998
  var valid_593999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-SignedHeaders", valid_593999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594000: Call_GetDescribeEventCategories_593987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594000.validator(path, query, header, formData, body)
  let scheme = call_594000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594000.url(scheme.get, call_594000.host, call_594000.base,
                         call_594000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594000, url, valid)

proc call*(call_594001: Call_GetDescribeEventCategories_593987;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594002 = newJObject()
  add(query_594002, "SourceType", newJString(SourceType))
  add(query_594002, "Action", newJString(Action))
  add(query_594002, "Version", newJString(Version))
  result = call_594001.call(nil, query_594002, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_593987(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_593988, base: "/",
    url: url_GetDescribeEventCategories_593989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_594038 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventSubscriptions_594040(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_594039(path: JsonNode;
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
  var valid_594041 = query.getOrDefault("Action")
  valid_594041 = validateParameter(valid_594041, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594041 != nil:
    section.add "Action", valid_594041
  var valid_594042 = query.getOrDefault("Version")
  valid_594042 = validateParameter(valid_594042, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594042 != nil:
    section.add "Version", valid_594042
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
  var valid_594043 = header.getOrDefault("X-Amz-Signature")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Signature", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Content-Sha256", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Date")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Date", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Credential")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Credential", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Algorithm")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Algorithm", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-SignedHeaders", valid_594049
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_594050 = formData.getOrDefault("MaxRecords")
  valid_594050 = validateParameter(valid_594050, JInt, required = false, default = nil)
  if valid_594050 != nil:
    section.add "MaxRecords", valid_594050
  var valid_594051 = formData.getOrDefault("Marker")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "Marker", valid_594051
  var valid_594052 = formData.getOrDefault("SubscriptionName")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "SubscriptionName", valid_594052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_PostDescribeEventSubscriptions_594038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_PostDescribeEventSubscriptions_594038;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594055 = newJObject()
  var formData_594056 = newJObject()
  add(formData_594056, "MaxRecords", newJInt(MaxRecords))
  add(formData_594056, "Marker", newJString(Marker))
  add(formData_594056, "SubscriptionName", newJString(SubscriptionName))
  add(query_594055, "Action", newJString(Action))
  add(query_594055, "Version", newJString(Version))
  result = call_594054.call(nil, query_594055, nil, formData_594056, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_594038(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_594039, base: "/",
    url: url_PostDescribeEventSubscriptions_594040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_594020 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventSubscriptions_594022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_594021(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594023 = query.getOrDefault("Marker")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "Marker", valid_594023
  var valid_594024 = query.getOrDefault("SubscriptionName")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "SubscriptionName", valid_594024
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594025 = query.getOrDefault("Action")
  valid_594025 = validateParameter(valid_594025, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594025 != nil:
    section.add "Action", valid_594025
  var valid_594026 = query.getOrDefault("Version")
  valid_594026 = validateParameter(valid_594026, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594026 != nil:
    section.add "Version", valid_594026
  var valid_594027 = query.getOrDefault("MaxRecords")
  valid_594027 = validateParameter(valid_594027, JInt, required = false, default = nil)
  if valid_594027 != nil:
    section.add "MaxRecords", valid_594027
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
  var valid_594028 = header.getOrDefault("X-Amz-Signature")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Signature", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Content-Sha256", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Date")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Date", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Credential")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Credential", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Security-Token")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Security-Token", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Algorithm")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Algorithm", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-SignedHeaders", valid_594034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594035: Call_GetDescribeEventSubscriptions_594020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594035.validator(path, query, header, formData, body)
  let scheme = call_594035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594035.url(scheme.get, call_594035.host, call_594035.base,
                         call_594035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594035, url, valid)

proc call*(call_594036: Call_GetDescribeEventSubscriptions_594020;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_594037 = newJObject()
  add(query_594037, "Marker", newJString(Marker))
  add(query_594037, "SubscriptionName", newJString(SubscriptionName))
  add(query_594037, "Action", newJString(Action))
  add(query_594037, "Version", newJString(Version))
  add(query_594037, "MaxRecords", newJInt(MaxRecords))
  result = call_594036.call(nil, query_594037, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_594020(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_594021, base: "/",
    url: url_GetDescribeEventSubscriptions_594022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_594080 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEvents_594082(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_594081(path: JsonNode; query: JsonNode;
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
  var valid_594083 = query.getOrDefault("Action")
  valid_594083 = validateParameter(valid_594083, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594083 != nil:
    section.add "Action", valid_594083
  var valid_594084 = query.getOrDefault("Version")
  valid_594084 = validateParameter(valid_594084, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594084 != nil:
    section.add "Version", valid_594084
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
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_594092 = formData.getOrDefault("MaxRecords")
  valid_594092 = validateParameter(valid_594092, JInt, required = false, default = nil)
  if valid_594092 != nil:
    section.add "MaxRecords", valid_594092
  var valid_594093 = formData.getOrDefault("Marker")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "Marker", valid_594093
  var valid_594094 = formData.getOrDefault("SourceIdentifier")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "SourceIdentifier", valid_594094
  var valid_594095 = formData.getOrDefault("SourceType")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594095 != nil:
    section.add "SourceType", valid_594095
  var valid_594096 = formData.getOrDefault("Duration")
  valid_594096 = validateParameter(valid_594096, JInt, required = false, default = nil)
  if valid_594096 != nil:
    section.add "Duration", valid_594096
  var valid_594097 = formData.getOrDefault("EndTime")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "EndTime", valid_594097
  var valid_594098 = formData.getOrDefault("StartTime")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "StartTime", valid_594098
  var valid_594099 = formData.getOrDefault("EventCategories")
  valid_594099 = validateParameter(valid_594099, JArray, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "EventCategories", valid_594099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_PostDescribeEvents_594080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_PostDescribeEvents_594080; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Version: string = "2013-01-10"): Recallable =
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
  ##   Version: string (required)
  var query_594102 = newJObject()
  var formData_594103 = newJObject()
  add(formData_594103, "MaxRecords", newJInt(MaxRecords))
  add(formData_594103, "Marker", newJString(Marker))
  add(formData_594103, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594103, "SourceType", newJString(SourceType))
  add(formData_594103, "Duration", newJInt(Duration))
  add(formData_594103, "EndTime", newJString(EndTime))
  add(formData_594103, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_594103.add "EventCategories", EventCategories
  add(query_594102, "Action", newJString(Action))
  add(query_594102, "Version", newJString(Version))
  result = call_594101.call(nil, query_594102, nil, formData_594103, nil)

var postDescribeEvents* = Call_PostDescribeEvents_594080(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_594081, base: "/",
    url: url_PostDescribeEvents_594082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_594057 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEvents_594059(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_594058(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594060 = query.getOrDefault("Marker")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "Marker", valid_594060
  var valid_594061 = query.getOrDefault("SourceType")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594061 != nil:
    section.add "SourceType", valid_594061
  var valid_594062 = query.getOrDefault("SourceIdentifier")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "SourceIdentifier", valid_594062
  var valid_594063 = query.getOrDefault("EventCategories")
  valid_594063 = validateParameter(valid_594063, JArray, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "EventCategories", valid_594063
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594064 = query.getOrDefault("Action")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594064 != nil:
    section.add "Action", valid_594064
  var valid_594065 = query.getOrDefault("StartTime")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "StartTime", valid_594065
  var valid_594066 = query.getOrDefault("Duration")
  valid_594066 = validateParameter(valid_594066, JInt, required = false, default = nil)
  if valid_594066 != nil:
    section.add "Duration", valid_594066
  var valid_594067 = query.getOrDefault("EndTime")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "EndTime", valid_594067
  var valid_594068 = query.getOrDefault("Version")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594068 != nil:
    section.add "Version", valid_594068
  var valid_594069 = query.getOrDefault("MaxRecords")
  valid_594069 = validateParameter(valid_594069, JInt, required = false, default = nil)
  if valid_594069 != nil:
    section.add "MaxRecords", valid_594069
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
  var valid_594070 = header.getOrDefault("X-Amz-Signature")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Signature", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Content-Sha256", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Date")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Date", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Credential")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Credential", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Security-Token")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Security-Token", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Algorithm")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Algorithm", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-SignedHeaders", valid_594076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594077: Call_GetDescribeEvents_594057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594077.validator(path, query, header, formData, body)
  let scheme = call_594077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594077.url(scheme.get, call_594077.host, call_594077.base,
                         call_594077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594077, url, valid)

proc call*(call_594078: Call_GetDescribeEvents_594057; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_594079 = newJObject()
  add(query_594079, "Marker", newJString(Marker))
  add(query_594079, "SourceType", newJString(SourceType))
  add(query_594079, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_594079.add "EventCategories", EventCategories
  add(query_594079, "Action", newJString(Action))
  add(query_594079, "StartTime", newJString(StartTime))
  add(query_594079, "Duration", newJInt(Duration))
  add(query_594079, "EndTime", newJString(EndTime))
  add(query_594079, "Version", newJString(Version))
  add(query_594079, "MaxRecords", newJInt(MaxRecords))
  result = call_594078.call(nil, query_594079, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_594057(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_594058,
    base: "/", url: url_GetDescribeEvents_594059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_594123 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroupOptions_594125(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_594124(path: JsonNode;
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
  var valid_594126 = query.getOrDefault("Action")
  valid_594126 = validateParameter(valid_594126, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594126 != nil:
    section.add "Action", valid_594126
  var valid_594127 = query.getOrDefault("Version")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594127 != nil:
    section.add "Version", valid_594127
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
  var valid_594128 = header.getOrDefault("X-Amz-Signature")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Signature", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Content-Sha256", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Credential")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Credential", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-SignedHeaders", valid_594134
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_594135 = formData.getOrDefault("MaxRecords")
  valid_594135 = validateParameter(valid_594135, JInt, required = false, default = nil)
  if valid_594135 != nil:
    section.add "MaxRecords", valid_594135
  var valid_594136 = formData.getOrDefault("Marker")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "Marker", valid_594136
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_594137 = formData.getOrDefault("EngineName")
  valid_594137 = validateParameter(valid_594137, JString, required = true,
                                 default = nil)
  if valid_594137 != nil:
    section.add "EngineName", valid_594137
  var valid_594138 = formData.getOrDefault("MajorEngineVersion")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "MajorEngineVersion", valid_594138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594139: Call_PostDescribeOptionGroupOptions_594123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594139.validator(path, query, header, formData, body)
  let scheme = call_594139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594139.url(scheme.get, call_594139.host, call_594139.base,
                         call_594139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594139, url, valid)

proc call*(call_594140: Call_PostDescribeOptionGroupOptions_594123;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594141 = newJObject()
  var formData_594142 = newJObject()
  add(formData_594142, "MaxRecords", newJInt(MaxRecords))
  add(formData_594142, "Marker", newJString(Marker))
  add(formData_594142, "EngineName", newJString(EngineName))
  add(formData_594142, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594141, "Action", newJString(Action))
  add(query_594141, "Version", newJString(Version))
  result = call_594140.call(nil, query_594141, nil, formData_594142, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_594123(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_594124, base: "/",
    url: url_PostDescribeOptionGroupOptions_594125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_594104 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroupOptions_594106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_594105(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_594107 = query.getOrDefault("EngineName")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = nil)
  if valid_594107 != nil:
    section.add "EngineName", valid_594107
  var valid_594108 = query.getOrDefault("Marker")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "Marker", valid_594108
  var valid_594109 = query.getOrDefault("Action")
  valid_594109 = validateParameter(valid_594109, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594109 != nil:
    section.add "Action", valid_594109
  var valid_594110 = query.getOrDefault("Version")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594110 != nil:
    section.add "Version", valid_594110
  var valid_594111 = query.getOrDefault("MaxRecords")
  valid_594111 = validateParameter(valid_594111, JInt, required = false, default = nil)
  if valid_594111 != nil:
    section.add "MaxRecords", valid_594111
  var valid_594112 = query.getOrDefault("MajorEngineVersion")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "MajorEngineVersion", valid_594112
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
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Content-Sha256", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Credential")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Credential", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Security-Token")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Security-Token", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-SignedHeaders", valid_594119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594120: Call_GetDescribeOptionGroupOptions_594104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594120.validator(path, query, header, formData, body)
  let scheme = call_594120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594120.url(scheme.get, call_594120.host, call_594120.base,
                         call_594120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594120, url, valid)

proc call*(call_594121: Call_GetDescribeOptionGroupOptions_594104;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_594122 = newJObject()
  add(query_594122, "EngineName", newJString(EngineName))
  add(query_594122, "Marker", newJString(Marker))
  add(query_594122, "Action", newJString(Action))
  add(query_594122, "Version", newJString(Version))
  add(query_594122, "MaxRecords", newJInt(MaxRecords))
  add(query_594122, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594121.call(nil, query_594122, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_594104(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_594105, base: "/",
    url: url_GetDescribeOptionGroupOptions_594106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_594163 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroups_594165(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_594164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594166 = query.getOrDefault("Action")
  valid_594166 = validateParameter(valid_594166, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594166 != nil:
    section.add "Action", valid_594166
  var valid_594167 = query.getOrDefault("Version")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594167 != nil:
    section.add "Version", valid_594167
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
  var valid_594168 = header.getOrDefault("X-Amz-Signature")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Signature", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Date")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Date", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Credential")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Credential", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Security-Token")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Security-Token", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Algorithm")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Algorithm", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-SignedHeaders", valid_594174
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_594175 = formData.getOrDefault("MaxRecords")
  valid_594175 = validateParameter(valid_594175, JInt, required = false, default = nil)
  if valid_594175 != nil:
    section.add "MaxRecords", valid_594175
  var valid_594176 = formData.getOrDefault("Marker")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "Marker", valid_594176
  var valid_594177 = formData.getOrDefault("EngineName")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "EngineName", valid_594177
  var valid_594178 = formData.getOrDefault("MajorEngineVersion")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "MajorEngineVersion", valid_594178
  var valid_594179 = formData.getOrDefault("OptionGroupName")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "OptionGroupName", valid_594179
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594180: Call_PostDescribeOptionGroups_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594180.validator(path, query, header, formData, body)
  let scheme = call_594180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594180.url(scheme.get, call_594180.host, call_594180.base,
                         call_594180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594180, url, valid)

proc call*(call_594181: Call_PostDescribeOptionGroups_594163; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_594182 = newJObject()
  var formData_594183 = newJObject()
  add(formData_594183, "MaxRecords", newJInt(MaxRecords))
  add(formData_594183, "Marker", newJString(Marker))
  add(formData_594183, "EngineName", newJString(EngineName))
  add(formData_594183, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594182, "Action", newJString(Action))
  add(formData_594183, "OptionGroupName", newJString(OptionGroupName))
  add(query_594182, "Version", newJString(Version))
  result = call_594181.call(nil, query_594182, nil, formData_594183, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_594163(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_594164, base: "/",
    url: url_PostDescribeOptionGroups_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_594143 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroups_594145(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_594144(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_594146 = query.getOrDefault("EngineName")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "EngineName", valid_594146
  var valid_594147 = query.getOrDefault("Marker")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "Marker", valid_594147
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594148 = query.getOrDefault("Action")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594148 != nil:
    section.add "Action", valid_594148
  var valid_594149 = query.getOrDefault("OptionGroupName")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "OptionGroupName", valid_594149
  var valid_594150 = query.getOrDefault("Version")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594150 != nil:
    section.add "Version", valid_594150
  var valid_594151 = query.getOrDefault("MaxRecords")
  valid_594151 = validateParameter(valid_594151, JInt, required = false, default = nil)
  if valid_594151 != nil:
    section.add "MaxRecords", valid_594151
  var valid_594152 = query.getOrDefault("MajorEngineVersion")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "MajorEngineVersion", valid_594152
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
  var valid_594153 = header.getOrDefault("X-Amz-Signature")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Signature", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Date")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Date", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Credential")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Credential", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Security-Token")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Security-Token", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Algorithm")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Algorithm", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-SignedHeaders", valid_594159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_GetDescribeOptionGroups_594143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_GetDescribeOptionGroups_594143;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_594162 = newJObject()
  add(query_594162, "EngineName", newJString(EngineName))
  add(query_594162, "Marker", newJString(Marker))
  add(query_594162, "Action", newJString(Action))
  add(query_594162, "OptionGroupName", newJString(OptionGroupName))
  add(query_594162, "Version", newJString(Version))
  add(query_594162, "MaxRecords", newJInt(MaxRecords))
  add(query_594162, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594161.call(nil, query_594162, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_594143(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_594144, base: "/",
    url: url_GetDescribeOptionGroups_594145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_594206 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOrderableDBInstanceOptions_594208(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_594207(path: JsonNode;
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
  var valid_594209 = query.getOrDefault("Action")
  valid_594209 = validateParameter(valid_594209, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594209 != nil:
    section.add "Action", valid_594209
  var valid_594210 = query.getOrDefault("Version")
  valid_594210 = validateParameter(valid_594210, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594210 != nil:
    section.add "Version", valid_594210
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
  var valid_594211 = header.getOrDefault("X-Amz-Signature")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Signature", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Content-Sha256", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Date")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Date", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Credential")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Credential", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Security-Token")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Security-Token", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Algorithm")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Algorithm", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  section = newJObject()
  var valid_594218 = formData.getOrDefault("DBInstanceClass")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "DBInstanceClass", valid_594218
  var valid_594219 = formData.getOrDefault("MaxRecords")
  valid_594219 = validateParameter(valid_594219, JInt, required = false, default = nil)
  if valid_594219 != nil:
    section.add "MaxRecords", valid_594219
  var valid_594220 = formData.getOrDefault("EngineVersion")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "EngineVersion", valid_594220
  var valid_594221 = formData.getOrDefault("Marker")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "Marker", valid_594221
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594222 = formData.getOrDefault("Engine")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "Engine", valid_594222
  var valid_594223 = formData.getOrDefault("Vpc")
  valid_594223 = validateParameter(valid_594223, JBool, required = false, default = nil)
  if valid_594223 != nil:
    section.add "Vpc", valid_594223
  var valid_594224 = formData.getOrDefault("LicenseModel")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "LicenseModel", valid_594224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594225: Call_PostDescribeOrderableDBInstanceOptions_594206;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594225.validator(path, query, header, formData, body)
  let scheme = call_594225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594225.url(scheme.get, call_594225.host, call_594225.base,
                         call_594225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594225, url, valid)

proc call*(call_594226: Call_PostDescribeOrderableDBInstanceOptions_594206;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Version: string (required)
  var query_594227 = newJObject()
  var formData_594228 = newJObject()
  add(formData_594228, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594228, "MaxRecords", newJInt(MaxRecords))
  add(formData_594228, "EngineVersion", newJString(EngineVersion))
  add(formData_594228, "Marker", newJString(Marker))
  add(formData_594228, "Engine", newJString(Engine))
  add(formData_594228, "Vpc", newJBool(Vpc))
  add(query_594227, "Action", newJString(Action))
  add(formData_594228, "LicenseModel", newJString(LicenseModel))
  add(query_594227, "Version", newJString(Version))
  result = call_594226.call(nil, query_594227, nil, formData_594228, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_594206(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_594207, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_594208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_594184 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOrderableDBInstanceOptions_594186(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_594185(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594187 = query.getOrDefault("Marker")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "Marker", valid_594187
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594188 = query.getOrDefault("Engine")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "Engine", valid_594188
  var valid_594189 = query.getOrDefault("LicenseModel")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "LicenseModel", valid_594189
  var valid_594190 = query.getOrDefault("Vpc")
  valid_594190 = validateParameter(valid_594190, JBool, required = false, default = nil)
  if valid_594190 != nil:
    section.add "Vpc", valid_594190
  var valid_594191 = query.getOrDefault("EngineVersion")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "EngineVersion", valid_594191
  var valid_594192 = query.getOrDefault("Action")
  valid_594192 = validateParameter(valid_594192, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594192 != nil:
    section.add "Action", valid_594192
  var valid_594193 = query.getOrDefault("Version")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594193 != nil:
    section.add "Version", valid_594193
  var valid_594194 = query.getOrDefault("DBInstanceClass")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "DBInstanceClass", valid_594194
  var valid_594195 = query.getOrDefault("MaxRecords")
  valid_594195 = validateParameter(valid_594195, JInt, required = false, default = nil)
  if valid_594195 != nil:
    section.add "MaxRecords", valid_594195
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
  var valid_594196 = header.getOrDefault("X-Amz-Signature")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Signature", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Content-Sha256", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Date")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Date", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Credential")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Credential", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Security-Token")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Security-Token", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Algorithm")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Algorithm", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_GetDescribeOrderableDBInstanceOptions_594184;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_GetDescribeOrderableDBInstanceOptions_594184;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  var query_594205 = newJObject()
  add(query_594205, "Marker", newJString(Marker))
  add(query_594205, "Engine", newJString(Engine))
  add(query_594205, "LicenseModel", newJString(LicenseModel))
  add(query_594205, "Vpc", newJBool(Vpc))
  add(query_594205, "EngineVersion", newJString(EngineVersion))
  add(query_594205, "Action", newJString(Action))
  add(query_594205, "Version", newJString(Version))
  add(query_594205, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594205, "MaxRecords", newJInt(MaxRecords))
  result = call_594204.call(nil, query_594205, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_594184(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_594185, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_594186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_594253 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstances_594255(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_594254(path: JsonNode;
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
  var valid_594256 = query.getOrDefault("Action")
  valid_594256 = validateParameter(valid_594256, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594256 != nil:
    section.add "Action", valid_594256
  var valid_594257 = query.getOrDefault("Version")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594257 != nil:
    section.add "Version", valid_594257
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
  var valid_594258 = header.getOrDefault("X-Amz-Signature")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Signature", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Date")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Date", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Credential")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Credential", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Security-Token")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Security-Token", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Algorithm")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Algorithm", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-SignedHeaders", valid_594264
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
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_594265 = formData.getOrDefault("DBInstanceClass")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "DBInstanceClass", valid_594265
  var valid_594266 = formData.getOrDefault("MultiAZ")
  valid_594266 = validateParameter(valid_594266, JBool, required = false, default = nil)
  if valid_594266 != nil:
    section.add "MultiAZ", valid_594266
  var valid_594267 = formData.getOrDefault("MaxRecords")
  valid_594267 = validateParameter(valid_594267, JInt, required = false, default = nil)
  if valid_594267 != nil:
    section.add "MaxRecords", valid_594267
  var valid_594268 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "ReservedDBInstanceId", valid_594268
  var valid_594269 = formData.getOrDefault("Marker")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "Marker", valid_594269
  var valid_594270 = formData.getOrDefault("Duration")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "Duration", valid_594270
  var valid_594271 = formData.getOrDefault("OfferingType")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "OfferingType", valid_594271
  var valid_594272 = formData.getOrDefault("ProductDescription")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "ProductDescription", valid_594272
  var valid_594273 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594273
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594274: Call_PostDescribeReservedDBInstances_594253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594274.validator(path, query, header, formData, body)
  let scheme = call_594274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594274.url(scheme.get, call_594274.host, call_594274.base,
                         call_594274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594274, url, valid)

proc call*(call_594275: Call_PostDescribeReservedDBInstances_594253;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
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
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_594276 = newJObject()
  var formData_594277 = newJObject()
  add(formData_594277, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594277, "MultiAZ", newJBool(MultiAZ))
  add(formData_594277, "MaxRecords", newJInt(MaxRecords))
  add(formData_594277, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_594277, "Marker", newJString(Marker))
  add(formData_594277, "Duration", newJString(Duration))
  add(formData_594277, "OfferingType", newJString(OfferingType))
  add(formData_594277, "ProductDescription", newJString(ProductDescription))
  add(query_594276, "Action", newJString(Action))
  add(formData_594277, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594276, "Version", newJString(Version))
  result = call_594275.call(nil, query_594276, nil, formData_594277, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_594253(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_594254, base: "/",
    url: url_PostDescribeReservedDBInstances_594255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_594229 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstances_594231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_594230(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594232 = query.getOrDefault("Marker")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "Marker", valid_594232
  var valid_594233 = query.getOrDefault("ProductDescription")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "ProductDescription", valid_594233
  var valid_594234 = query.getOrDefault("OfferingType")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "OfferingType", valid_594234
  var valid_594235 = query.getOrDefault("ReservedDBInstanceId")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "ReservedDBInstanceId", valid_594235
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594236 = query.getOrDefault("Action")
  valid_594236 = validateParameter(valid_594236, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594236 != nil:
    section.add "Action", valid_594236
  var valid_594237 = query.getOrDefault("MultiAZ")
  valid_594237 = validateParameter(valid_594237, JBool, required = false, default = nil)
  if valid_594237 != nil:
    section.add "MultiAZ", valid_594237
  var valid_594238 = query.getOrDefault("Duration")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "Duration", valid_594238
  var valid_594239 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594239
  var valid_594240 = query.getOrDefault("Version")
  valid_594240 = validateParameter(valid_594240, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594240 != nil:
    section.add "Version", valid_594240
  var valid_594241 = query.getOrDefault("DBInstanceClass")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "DBInstanceClass", valid_594241
  var valid_594242 = query.getOrDefault("MaxRecords")
  valid_594242 = validateParameter(valid_594242, JInt, required = false, default = nil)
  if valid_594242 != nil:
    section.add "MaxRecords", valid_594242
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
  var valid_594243 = header.getOrDefault("X-Amz-Signature")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Signature", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Date")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Date", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Credential")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Credential", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Security-Token")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Security-Token", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Algorithm")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Algorithm", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-SignedHeaders", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_GetDescribeReservedDBInstances_594229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_GetDescribeReservedDBInstances_594229;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_594252 = newJObject()
  add(query_594252, "Marker", newJString(Marker))
  add(query_594252, "ProductDescription", newJString(ProductDescription))
  add(query_594252, "OfferingType", newJString(OfferingType))
  add(query_594252, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594252, "Action", newJString(Action))
  add(query_594252, "MultiAZ", newJBool(MultiAZ))
  add(query_594252, "Duration", newJString(Duration))
  add(query_594252, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594252, "Version", newJString(Version))
  add(query_594252, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594252, "MaxRecords", newJInt(MaxRecords))
  result = call_594251.call(nil, query_594252, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_594229(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_594230, base: "/",
    url: url_GetDescribeReservedDBInstances_594231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_594301 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstancesOfferings_594303(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_594302(path: JsonNode;
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
  var valid_594304 = query.getOrDefault("Action")
  valid_594304 = validateParameter(valid_594304, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594304 != nil:
    section.add "Action", valid_594304
  var valid_594305 = query.getOrDefault("Version")
  valid_594305 = validateParameter(valid_594305, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594305 != nil:
    section.add "Version", valid_594305
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
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Content-Sha256", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Credential")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Credential", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Security-Token")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Security-Token", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-SignedHeaders", valid_594312
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_594313 = formData.getOrDefault("DBInstanceClass")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "DBInstanceClass", valid_594313
  var valid_594314 = formData.getOrDefault("MultiAZ")
  valid_594314 = validateParameter(valid_594314, JBool, required = false, default = nil)
  if valid_594314 != nil:
    section.add "MultiAZ", valid_594314
  var valid_594315 = formData.getOrDefault("MaxRecords")
  valid_594315 = validateParameter(valid_594315, JInt, required = false, default = nil)
  if valid_594315 != nil:
    section.add "MaxRecords", valid_594315
  var valid_594316 = formData.getOrDefault("Marker")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "Marker", valid_594316
  var valid_594317 = formData.getOrDefault("Duration")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "Duration", valid_594317
  var valid_594318 = formData.getOrDefault("OfferingType")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "OfferingType", valid_594318
  var valid_594319 = formData.getOrDefault("ProductDescription")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "ProductDescription", valid_594319
  var valid_594320 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594321: Call_PostDescribeReservedDBInstancesOfferings_594301;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594321.validator(path, query, header, formData, body)
  let scheme = call_594321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594321.url(scheme.get, call_594321.host, call_594321.base,
                         call_594321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594321, url, valid)

proc call*(call_594322: Call_PostDescribeReservedDBInstancesOfferings_594301;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_594323 = newJObject()
  var formData_594324 = newJObject()
  add(formData_594324, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594324, "MultiAZ", newJBool(MultiAZ))
  add(formData_594324, "MaxRecords", newJInt(MaxRecords))
  add(formData_594324, "Marker", newJString(Marker))
  add(formData_594324, "Duration", newJString(Duration))
  add(formData_594324, "OfferingType", newJString(OfferingType))
  add(formData_594324, "ProductDescription", newJString(ProductDescription))
  add(query_594323, "Action", newJString(Action))
  add(formData_594324, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594323, "Version", newJString(Version))
  result = call_594322.call(nil, query_594323, nil, formData_594324, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_594301(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_594302,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_594303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_594278 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstancesOfferings_594280(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_594279(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594281 = query.getOrDefault("Marker")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "Marker", valid_594281
  var valid_594282 = query.getOrDefault("ProductDescription")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "ProductDescription", valid_594282
  var valid_594283 = query.getOrDefault("OfferingType")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "OfferingType", valid_594283
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594284 = query.getOrDefault("Action")
  valid_594284 = validateParameter(valid_594284, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594284 != nil:
    section.add "Action", valid_594284
  var valid_594285 = query.getOrDefault("MultiAZ")
  valid_594285 = validateParameter(valid_594285, JBool, required = false, default = nil)
  if valid_594285 != nil:
    section.add "MultiAZ", valid_594285
  var valid_594286 = query.getOrDefault("Duration")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "Duration", valid_594286
  var valid_594287 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594287
  var valid_594288 = query.getOrDefault("Version")
  valid_594288 = validateParameter(valid_594288, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594288 != nil:
    section.add "Version", valid_594288
  var valid_594289 = query.getOrDefault("DBInstanceClass")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "DBInstanceClass", valid_594289
  var valid_594290 = query.getOrDefault("MaxRecords")
  valid_594290 = validateParameter(valid_594290, JInt, required = false, default = nil)
  if valid_594290 != nil:
    section.add "MaxRecords", valid_594290
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
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Content-Sha256", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Date")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Date", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Credential")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Credential", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Security-Token")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Security-Token", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Algorithm")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Algorithm", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-SignedHeaders", valid_594297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594298: Call_GetDescribeReservedDBInstancesOfferings_594278;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594298.validator(path, query, header, formData, body)
  let scheme = call_594298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594298.url(scheme.get, call_594298.host, call_594298.base,
                         call_594298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594298, url, valid)

proc call*(call_594299: Call_GetDescribeReservedDBInstancesOfferings_594278;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_594300 = newJObject()
  add(query_594300, "Marker", newJString(Marker))
  add(query_594300, "ProductDescription", newJString(ProductDescription))
  add(query_594300, "OfferingType", newJString(OfferingType))
  add(query_594300, "Action", newJString(Action))
  add(query_594300, "MultiAZ", newJBool(MultiAZ))
  add(query_594300, "Duration", newJString(Duration))
  add(query_594300, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594300, "Version", newJString(Version))
  add(query_594300, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594300, "MaxRecords", newJInt(MaxRecords))
  result = call_594299.call(nil, query_594300, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_594278(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_594279, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_594280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594341 = ref object of OpenApiRestCall_592348
proc url_PostListTagsForResource_594343(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594344 = query.getOrDefault("Action")
  valid_594344 = validateParameter(valid_594344, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594344 != nil:
    section.add "Action", valid_594344
  var valid_594345 = query.getOrDefault("Version")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594345 != nil:
    section.add "Version", valid_594345
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
  var valid_594346 = header.getOrDefault("X-Amz-Signature")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Signature", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Content-Sha256", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Date")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Date", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Credential")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Credential", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Security-Token")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Security-Token", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Algorithm")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Algorithm", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_594353 = formData.getOrDefault("ResourceName")
  valid_594353 = validateParameter(valid_594353, JString, required = true,
                                 default = nil)
  if valid_594353 != nil:
    section.add "ResourceName", valid_594353
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594354: Call_PostListTagsForResource_594341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594354.validator(path, query, header, formData, body)
  let scheme = call_594354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594354.url(scheme.get, call_594354.host, call_594354.base,
                         call_594354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594354, url, valid)

proc call*(call_594355: Call_PostListTagsForResource_594341; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594356 = newJObject()
  var formData_594357 = newJObject()
  add(query_594356, "Action", newJString(Action))
  add(query_594356, "Version", newJString(Version))
  add(formData_594357, "ResourceName", newJString(ResourceName))
  result = call_594355.call(nil, query_594356, nil, formData_594357, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594341(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594342, base: "/",
    url: url_PostListTagsForResource_594343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594325 = ref object of OpenApiRestCall_592348
proc url_GetListTagsForResource_594327(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594326(path: JsonNode; query: JsonNode;
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
  var valid_594328 = query.getOrDefault("ResourceName")
  valid_594328 = validateParameter(valid_594328, JString, required = true,
                                 default = nil)
  if valid_594328 != nil:
    section.add "ResourceName", valid_594328
  var valid_594329 = query.getOrDefault("Action")
  valid_594329 = validateParameter(valid_594329, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594329 != nil:
    section.add "Action", valid_594329
  var valid_594330 = query.getOrDefault("Version")
  valid_594330 = validateParameter(valid_594330, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594330 != nil:
    section.add "Version", valid_594330
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
  var valid_594331 = header.getOrDefault("X-Amz-Signature")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Signature", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Date")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Date", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Credential")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Credential", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Security-Token")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Security-Token", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Algorithm")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Algorithm", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_GetListTagsForResource_594325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_GetListTagsForResource_594325; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594340 = newJObject()
  add(query_594340, "ResourceName", newJString(ResourceName))
  add(query_594340, "Action", newJString(Action))
  add(query_594340, "Version", newJString(Version))
  result = call_594339.call(nil, query_594340, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594325(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594326, base: "/",
    url: url_GetListTagsForResource_594327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_594391 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBInstance_594393(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_594392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594394 = query.getOrDefault("Action")
  valid_594394 = validateParameter(valid_594394, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594394 != nil:
    section.add "Action", valid_594394
  var valid_594395 = query.getOrDefault("Version")
  valid_594395 = validateParameter(valid_594395, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594395 != nil:
    section.add "Version", valid_594395
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
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Content-Sha256", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Date")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Date", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Credential")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Credential", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Security-Token")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Security-Token", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Algorithm")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Algorithm", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-SignedHeaders", valid_594402
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
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_594403 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "PreferredMaintenanceWindow", valid_594403
  var valid_594404 = formData.getOrDefault("DBInstanceClass")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "DBInstanceClass", valid_594404
  var valid_594405 = formData.getOrDefault("PreferredBackupWindow")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "PreferredBackupWindow", valid_594405
  var valid_594406 = formData.getOrDefault("MasterUserPassword")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "MasterUserPassword", valid_594406
  var valid_594407 = formData.getOrDefault("MultiAZ")
  valid_594407 = validateParameter(valid_594407, JBool, required = false, default = nil)
  if valid_594407 != nil:
    section.add "MultiAZ", valid_594407
  var valid_594408 = formData.getOrDefault("DBParameterGroupName")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "DBParameterGroupName", valid_594408
  var valid_594409 = formData.getOrDefault("EngineVersion")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "EngineVersion", valid_594409
  var valid_594410 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594410 = validateParameter(valid_594410, JArray, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "VpcSecurityGroupIds", valid_594410
  var valid_594411 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594411 = validateParameter(valid_594411, JInt, required = false, default = nil)
  if valid_594411 != nil:
    section.add "BackupRetentionPeriod", valid_594411
  var valid_594412 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594412 = validateParameter(valid_594412, JBool, required = false, default = nil)
  if valid_594412 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594412
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594413 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = nil)
  if valid_594413 != nil:
    section.add "DBInstanceIdentifier", valid_594413
  var valid_594414 = formData.getOrDefault("ApplyImmediately")
  valid_594414 = validateParameter(valid_594414, JBool, required = false, default = nil)
  if valid_594414 != nil:
    section.add "ApplyImmediately", valid_594414
  var valid_594415 = formData.getOrDefault("Iops")
  valid_594415 = validateParameter(valid_594415, JInt, required = false, default = nil)
  if valid_594415 != nil:
    section.add "Iops", valid_594415
  var valid_594416 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_594416 = validateParameter(valid_594416, JBool, required = false, default = nil)
  if valid_594416 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594416
  var valid_594417 = formData.getOrDefault("OptionGroupName")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "OptionGroupName", valid_594417
  var valid_594418 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "NewDBInstanceIdentifier", valid_594418
  var valid_594419 = formData.getOrDefault("DBSecurityGroups")
  valid_594419 = validateParameter(valid_594419, JArray, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "DBSecurityGroups", valid_594419
  var valid_594420 = formData.getOrDefault("AllocatedStorage")
  valid_594420 = validateParameter(valid_594420, JInt, required = false, default = nil)
  if valid_594420 != nil:
    section.add "AllocatedStorage", valid_594420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594421: Call_PostModifyDBInstance_594391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594421.validator(path, query, header, formData, body)
  let scheme = call_594421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594421.url(scheme.get, call_594421.host, call_594421.base,
                         call_594421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594421, url, valid)

proc call*(call_594422: Call_PostModifyDBInstance_594391;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-01-10";
          DBSecurityGroups: JsonNode = nil; AllocatedStorage: int = 0): Recallable =
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
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int
  var query_594423 = newJObject()
  var formData_594424 = newJObject()
  add(formData_594424, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594424, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594424, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594424, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594424, "MultiAZ", newJBool(MultiAZ))
  add(formData_594424, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594424, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594424.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594424, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594424, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594424, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594424, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_594424, "Iops", newJInt(Iops))
  add(query_594423, "Action", newJString(Action))
  add(formData_594424, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_594424, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594424, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_594423, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_594424.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594424, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_594422.call(nil, query_594423, nil, formData_594424, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_594391(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_594392, base: "/",
    url: url_PostModifyDBInstance_594393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_594358 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBInstance_594360(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_594359(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
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
  var valid_594361 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "NewDBInstanceIdentifier", valid_594361
  var valid_594362 = query.getOrDefault("DBParameterGroupName")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "DBParameterGroupName", valid_594362
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594363 = query.getOrDefault("DBInstanceIdentifier")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = nil)
  if valid_594363 != nil:
    section.add "DBInstanceIdentifier", valid_594363
  var valid_594364 = query.getOrDefault("BackupRetentionPeriod")
  valid_594364 = validateParameter(valid_594364, JInt, required = false, default = nil)
  if valid_594364 != nil:
    section.add "BackupRetentionPeriod", valid_594364
  var valid_594365 = query.getOrDefault("EngineVersion")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "EngineVersion", valid_594365
  var valid_594366 = query.getOrDefault("Action")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594366 != nil:
    section.add "Action", valid_594366
  var valid_594367 = query.getOrDefault("MultiAZ")
  valid_594367 = validateParameter(valid_594367, JBool, required = false, default = nil)
  if valid_594367 != nil:
    section.add "MultiAZ", valid_594367
  var valid_594368 = query.getOrDefault("DBSecurityGroups")
  valid_594368 = validateParameter(valid_594368, JArray, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "DBSecurityGroups", valid_594368
  var valid_594369 = query.getOrDefault("ApplyImmediately")
  valid_594369 = validateParameter(valid_594369, JBool, required = false, default = nil)
  if valid_594369 != nil:
    section.add "ApplyImmediately", valid_594369
  var valid_594370 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594370 = validateParameter(valid_594370, JArray, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "VpcSecurityGroupIds", valid_594370
  var valid_594371 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_594371 = validateParameter(valid_594371, JBool, required = false, default = nil)
  if valid_594371 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594371
  var valid_594372 = query.getOrDefault("MasterUserPassword")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "MasterUserPassword", valid_594372
  var valid_594373 = query.getOrDefault("OptionGroupName")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "OptionGroupName", valid_594373
  var valid_594374 = query.getOrDefault("Version")
  valid_594374 = validateParameter(valid_594374, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594374 != nil:
    section.add "Version", valid_594374
  var valid_594375 = query.getOrDefault("AllocatedStorage")
  valid_594375 = validateParameter(valid_594375, JInt, required = false, default = nil)
  if valid_594375 != nil:
    section.add "AllocatedStorage", valid_594375
  var valid_594376 = query.getOrDefault("DBInstanceClass")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "DBInstanceClass", valid_594376
  var valid_594377 = query.getOrDefault("PreferredBackupWindow")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "PreferredBackupWindow", valid_594377
  var valid_594378 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "PreferredMaintenanceWindow", valid_594378
  var valid_594379 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594379 = validateParameter(valid_594379, JBool, required = false, default = nil)
  if valid_594379 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594379
  var valid_594380 = query.getOrDefault("Iops")
  valid_594380 = validateParameter(valid_594380, JInt, required = false, default = nil)
  if valid_594380 != nil:
    section.add "Iops", valid_594380
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
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Content-Sha256", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Date")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Date", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Credential")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Credential", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Security-Token")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Security-Token", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Algorithm")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Algorithm", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-SignedHeaders", valid_594387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594388: Call_GetModifyDBInstance_594358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594388.validator(path, query, header, formData, body)
  let scheme = call_594388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594388.url(scheme.get, call_594388.host, call_594388.base,
                         call_594388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594388, url, valid)

proc call*(call_594389: Call_GetModifyDBInstance_594358;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
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
  var query_594390 = newJObject()
  add(query_594390, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_594390, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594390, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594390, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594390, "EngineVersion", newJString(EngineVersion))
  add(query_594390, "Action", newJString(Action))
  add(query_594390, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_594390.add "DBSecurityGroups", DBSecurityGroups
  add(query_594390, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_594390.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594390, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_594390, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594390, "OptionGroupName", newJString(OptionGroupName))
  add(query_594390, "Version", newJString(Version))
  add(query_594390, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594390, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594390, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594390, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594390, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594390, "Iops", newJInt(Iops))
  result = call_594389.call(nil, query_594390, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_594358(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_594359, base: "/",
    url: url_GetModifyDBInstance_594360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_594442 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBParameterGroup_594444(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_594443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594445 = query.getOrDefault("Action")
  valid_594445 = validateParameter(valid_594445, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594445 != nil:
    section.add "Action", valid_594445
  var valid_594446 = query.getOrDefault("Version")
  valid_594446 = validateParameter(valid_594446, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594446 != nil:
    section.add "Version", valid_594446
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
  var valid_594447 = header.getOrDefault("X-Amz-Signature")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Signature", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Content-Sha256", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Date")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Date", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Credential")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Credential", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Security-Token")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Security-Token", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Algorithm")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Algorithm", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-SignedHeaders", valid_594453
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594454 = formData.getOrDefault("DBParameterGroupName")
  valid_594454 = validateParameter(valid_594454, JString, required = true,
                                 default = nil)
  if valid_594454 != nil:
    section.add "DBParameterGroupName", valid_594454
  var valid_594455 = formData.getOrDefault("Parameters")
  valid_594455 = validateParameter(valid_594455, JArray, required = true, default = nil)
  if valid_594455 != nil:
    section.add "Parameters", valid_594455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594456: Call_PostModifyDBParameterGroup_594442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594456.validator(path, query, header, formData, body)
  let scheme = call_594456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594456.url(scheme.get, call_594456.host, call_594456.base,
                         call_594456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594456, url, valid)

proc call*(call_594457: Call_PostModifyDBParameterGroup_594442;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_594458 = newJObject()
  var formData_594459 = newJObject()
  add(formData_594459, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594458, "Action", newJString(Action))
  if Parameters != nil:
    formData_594459.add "Parameters", Parameters
  add(query_594458, "Version", newJString(Version))
  result = call_594457.call(nil, query_594458, nil, formData_594459, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_594442(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_594443, base: "/",
    url: url_PostModifyDBParameterGroup_594444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_594425 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBParameterGroup_594427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_594426(path: JsonNode; query: JsonNode;
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
  var valid_594428 = query.getOrDefault("DBParameterGroupName")
  valid_594428 = validateParameter(valid_594428, JString, required = true,
                                 default = nil)
  if valid_594428 != nil:
    section.add "DBParameterGroupName", valid_594428
  var valid_594429 = query.getOrDefault("Parameters")
  valid_594429 = validateParameter(valid_594429, JArray, required = true, default = nil)
  if valid_594429 != nil:
    section.add "Parameters", valid_594429
  var valid_594430 = query.getOrDefault("Action")
  valid_594430 = validateParameter(valid_594430, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594430 != nil:
    section.add "Action", valid_594430
  var valid_594431 = query.getOrDefault("Version")
  valid_594431 = validateParameter(valid_594431, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594431 != nil:
    section.add "Version", valid_594431
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
  var valid_594432 = header.getOrDefault("X-Amz-Signature")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Signature", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Content-Sha256", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Date")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Date", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Credential")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Credential", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Security-Token")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Security-Token", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Algorithm")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Algorithm", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-SignedHeaders", valid_594438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594439: Call_GetModifyDBParameterGroup_594425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594439.validator(path, query, header, formData, body)
  let scheme = call_594439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594439.url(scheme.get, call_594439.host, call_594439.base,
                         call_594439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594439, url, valid)

proc call*(call_594440: Call_GetModifyDBParameterGroup_594425;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594441 = newJObject()
  add(query_594441, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594441.add "Parameters", Parameters
  add(query_594441, "Action", newJString(Action))
  add(query_594441, "Version", newJString(Version))
  result = call_594440.call(nil, query_594441, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_594425(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_594426, base: "/",
    url: url_GetModifyDBParameterGroup_594427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_594478 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBSubnetGroup_594480(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_594479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594481 = query.getOrDefault("Action")
  valid_594481 = validateParameter(valid_594481, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594481 != nil:
    section.add "Action", valid_594481
  var valid_594482 = query.getOrDefault("Version")
  valid_594482 = validateParameter(valid_594482, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594482 != nil:
    section.add "Version", valid_594482
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
  var valid_594483 = header.getOrDefault("X-Amz-Signature")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Signature", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Content-Sha256", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Date")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Date", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Credential")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Credential", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Security-Token")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Security-Token", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Algorithm")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Algorithm", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-SignedHeaders", valid_594489
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_594490 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "DBSubnetGroupDescription", valid_594490
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594491 = formData.getOrDefault("DBSubnetGroupName")
  valid_594491 = validateParameter(valid_594491, JString, required = true,
                                 default = nil)
  if valid_594491 != nil:
    section.add "DBSubnetGroupName", valid_594491
  var valid_594492 = formData.getOrDefault("SubnetIds")
  valid_594492 = validateParameter(valid_594492, JArray, required = true, default = nil)
  if valid_594492 != nil:
    section.add "SubnetIds", valid_594492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594493: Call_PostModifyDBSubnetGroup_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594493.validator(path, query, header, formData, body)
  let scheme = call_594493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594493.url(scheme.get, call_594493.host, call_594493.base,
                         call_594493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594493, url, valid)

proc call*(call_594494: Call_PostModifyDBSubnetGroup_594478;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_594495 = newJObject()
  var formData_594496 = newJObject()
  add(formData_594496, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594495, "Action", newJString(Action))
  add(formData_594496, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594495, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_594496.add "SubnetIds", SubnetIds
  result = call_594494.call(nil, query_594495, nil, formData_594496, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_594478(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_594479, base: "/",
    url: url_PostModifyDBSubnetGroup_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_594460 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBSubnetGroup_594462(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_594461(path: JsonNode; query: JsonNode;
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
  var valid_594463 = query.getOrDefault("SubnetIds")
  valid_594463 = validateParameter(valid_594463, JArray, required = true, default = nil)
  if valid_594463 != nil:
    section.add "SubnetIds", valid_594463
  var valid_594464 = query.getOrDefault("Action")
  valid_594464 = validateParameter(valid_594464, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594464 != nil:
    section.add "Action", valid_594464
  var valid_594465 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "DBSubnetGroupDescription", valid_594465
  var valid_594466 = query.getOrDefault("DBSubnetGroupName")
  valid_594466 = validateParameter(valid_594466, JString, required = true,
                                 default = nil)
  if valid_594466 != nil:
    section.add "DBSubnetGroupName", valid_594466
  var valid_594467 = query.getOrDefault("Version")
  valid_594467 = validateParameter(valid_594467, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594467 != nil:
    section.add "Version", valid_594467
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
  var valid_594468 = header.getOrDefault("X-Amz-Signature")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-Signature", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Credential")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Credential", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Security-Token")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Security-Token", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Algorithm")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Algorithm", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-SignedHeaders", valid_594474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_GetModifyDBSubnetGroup_594460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_GetModifyDBSubnetGroup_594460; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594477 = newJObject()
  if SubnetIds != nil:
    query_594477.add "SubnetIds", SubnetIds
  add(query_594477, "Action", newJString(Action))
  add(query_594477, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594477, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594477, "Version", newJString(Version))
  result = call_594476.call(nil, query_594477, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_594460(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_594461, base: "/",
    url: url_GetModifyDBSubnetGroup_594462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_594517 = ref object of OpenApiRestCall_592348
proc url_PostModifyEventSubscription_594519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_594518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594520 = query.getOrDefault("Action")
  valid_594520 = validateParameter(valid_594520, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594520 != nil:
    section.add "Action", valid_594520
  var valid_594521 = query.getOrDefault("Version")
  valid_594521 = validateParameter(valid_594521, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594521 != nil:
    section.add "Version", valid_594521
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
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Content-Sha256", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Date")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Date", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Credential")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Credential", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Security-Token")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Security-Token", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Algorithm")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Algorithm", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-SignedHeaders", valid_594528
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_594529 = formData.getOrDefault("SnsTopicArn")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "SnsTopicArn", valid_594529
  var valid_594530 = formData.getOrDefault("Enabled")
  valid_594530 = validateParameter(valid_594530, JBool, required = false, default = nil)
  if valid_594530 != nil:
    section.add "Enabled", valid_594530
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594531 = formData.getOrDefault("SubscriptionName")
  valid_594531 = validateParameter(valid_594531, JString, required = true,
                                 default = nil)
  if valid_594531 != nil:
    section.add "SubscriptionName", valid_594531
  var valid_594532 = formData.getOrDefault("SourceType")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "SourceType", valid_594532
  var valid_594533 = formData.getOrDefault("EventCategories")
  valid_594533 = validateParameter(valid_594533, JArray, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "EventCategories", valid_594533
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594534: Call_PostModifyEventSubscription_594517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594534.validator(path, query, header, formData, body)
  let scheme = call_594534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594534.url(scheme.get, call_594534.host, call_594534.base,
                         call_594534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594534, url, valid)

proc call*(call_594535: Call_PostModifyEventSubscription_594517;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594536 = newJObject()
  var formData_594537 = newJObject()
  add(formData_594537, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_594537, "Enabled", newJBool(Enabled))
  add(formData_594537, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594537, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_594537.add "EventCategories", EventCategories
  add(query_594536, "Action", newJString(Action))
  add(query_594536, "Version", newJString(Version))
  result = call_594535.call(nil, query_594536, nil, formData_594537, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_594517(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_594518, base: "/",
    url: url_PostModifyEventSubscription_594519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_594497 = ref object of OpenApiRestCall_592348
proc url_GetModifyEventSubscription_594499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_594498(path: JsonNode; query: JsonNode;
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
  var valid_594500 = query.getOrDefault("SourceType")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "SourceType", valid_594500
  var valid_594501 = query.getOrDefault("Enabled")
  valid_594501 = validateParameter(valid_594501, JBool, required = false, default = nil)
  if valid_594501 != nil:
    section.add "Enabled", valid_594501
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_594502 = query.getOrDefault("SubscriptionName")
  valid_594502 = validateParameter(valid_594502, JString, required = true,
                                 default = nil)
  if valid_594502 != nil:
    section.add "SubscriptionName", valid_594502
  var valid_594503 = query.getOrDefault("EventCategories")
  valid_594503 = validateParameter(valid_594503, JArray, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "EventCategories", valid_594503
  var valid_594504 = query.getOrDefault("Action")
  valid_594504 = validateParameter(valid_594504, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594504 != nil:
    section.add "Action", valid_594504
  var valid_594505 = query.getOrDefault("SnsTopicArn")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "SnsTopicArn", valid_594505
  var valid_594506 = query.getOrDefault("Version")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594506 != nil:
    section.add "Version", valid_594506
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
  var valid_594507 = header.getOrDefault("X-Amz-Signature")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Signature", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Content-Sha256", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Date")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Date", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Credential")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Credential", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Security-Token")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Security-Token", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Algorithm")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Algorithm", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-SignedHeaders", valid_594513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594514: Call_GetModifyEventSubscription_594497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594514.validator(path, query, header, formData, body)
  let scheme = call_594514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594514.url(scheme.get, call_594514.host, call_594514.base,
                         call_594514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594514, url, valid)

proc call*(call_594515: Call_GetModifyEventSubscription_594497;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_594516 = newJObject()
  add(query_594516, "SourceType", newJString(SourceType))
  add(query_594516, "Enabled", newJBool(Enabled))
  add(query_594516, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_594516.add "EventCategories", EventCategories
  add(query_594516, "Action", newJString(Action))
  add(query_594516, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_594516, "Version", newJString(Version))
  result = call_594515.call(nil, query_594516, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_594497(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_594498, base: "/",
    url: url_GetModifyEventSubscription_594499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_594557 = ref object of OpenApiRestCall_592348
proc url_PostModifyOptionGroup_594559(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_594558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594560 = query.getOrDefault("Action")
  valid_594560 = validateParameter(valid_594560, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594560 != nil:
    section.add "Action", valid_594560
  var valid_594561 = query.getOrDefault("Version")
  valid_594561 = validateParameter(valid_594561, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594561 != nil:
    section.add "Version", valid_594561
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
  var valid_594562 = header.getOrDefault("X-Amz-Signature")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Signature", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Content-Sha256", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Date")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Date", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Credential")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Credential", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Security-Token")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Security-Token", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Algorithm")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Algorithm", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-SignedHeaders", valid_594568
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_594569 = formData.getOrDefault("OptionsToRemove")
  valid_594569 = validateParameter(valid_594569, JArray, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "OptionsToRemove", valid_594569
  var valid_594570 = formData.getOrDefault("ApplyImmediately")
  valid_594570 = validateParameter(valid_594570, JBool, required = false, default = nil)
  if valid_594570 != nil:
    section.add "ApplyImmediately", valid_594570
  var valid_594571 = formData.getOrDefault("OptionsToInclude")
  valid_594571 = validateParameter(valid_594571, JArray, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "OptionsToInclude", valid_594571
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594572 = formData.getOrDefault("OptionGroupName")
  valid_594572 = validateParameter(valid_594572, JString, required = true,
                                 default = nil)
  if valid_594572 != nil:
    section.add "OptionGroupName", valid_594572
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594573: Call_PostModifyOptionGroup_594557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594573.validator(path, query, header, formData, body)
  let scheme = call_594573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594573.url(scheme.get, call_594573.host, call_594573.base,
                         call_594573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594573, url, valid)

proc call*(call_594574: Call_PostModifyOptionGroup_594557; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594575 = newJObject()
  var formData_594576 = newJObject()
  if OptionsToRemove != nil:
    formData_594576.add "OptionsToRemove", OptionsToRemove
  add(formData_594576, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_594576.add "OptionsToInclude", OptionsToInclude
  add(query_594575, "Action", newJString(Action))
  add(formData_594576, "OptionGroupName", newJString(OptionGroupName))
  add(query_594575, "Version", newJString(Version))
  result = call_594574.call(nil, query_594575, nil, formData_594576, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_594557(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_594558, base: "/",
    url: url_PostModifyOptionGroup_594559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_594538 = ref object of OpenApiRestCall_592348
proc url_GetModifyOptionGroup_594540(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_594539(path: JsonNode; query: JsonNode;
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
  var valid_594541 = query.getOrDefault("Action")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594541 != nil:
    section.add "Action", valid_594541
  var valid_594542 = query.getOrDefault("ApplyImmediately")
  valid_594542 = validateParameter(valid_594542, JBool, required = false, default = nil)
  if valid_594542 != nil:
    section.add "ApplyImmediately", valid_594542
  var valid_594543 = query.getOrDefault("OptionsToRemove")
  valid_594543 = validateParameter(valid_594543, JArray, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "OptionsToRemove", valid_594543
  var valid_594544 = query.getOrDefault("OptionsToInclude")
  valid_594544 = validateParameter(valid_594544, JArray, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "OptionsToInclude", valid_594544
  var valid_594545 = query.getOrDefault("OptionGroupName")
  valid_594545 = validateParameter(valid_594545, JString, required = true,
                                 default = nil)
  if valid_594545 != nil:
    section.add "OptionGroupName", valid_594545
  var valid_594546 = query.getOrDefault("Version")
  valid_594546 = validateParameter(valid_594546, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594546 != nil:
    section.add "Version", valid_594546
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
  var valid_594547 = header.getOrDefault("X-Amz-Signature")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Signature", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Content-Sha256", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Date")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Date", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Credential")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Credential", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Security-Token")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Security-Token", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Algorithm")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Algorithm", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-SignedHeaders", valid_594553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594554: Call_GetModifyOptionGroup_594538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594554.validator(path, query, header, formData, body)
  let scheme = call_594554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594554.url(scheme.get, call_594554.host, call_594554.base,
                         call_594554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594554, url, valid)

proc call*(call_594555: Call_GetModifyOptionGroup_594538; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594556 = newJObject()
  add(query_594556, "Action", newJString(Action))
  add(query_594556, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_594556.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_594556.add "OptionsToInclude", OptionsToInclude
  add(query_594556, "OptionGroupName", newJString(OptionGroupName))
  add(query_594556, "Version", newJString(Version))
  result = call_594555.call(nil, query_594556, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_594538(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_594539, base: "/",
    url: url_GetModifyOptionGroup_594540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_594595 = ref object of OpenApiRestCall_592348
proc url_PostPromoteReadReplica_594597(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_594596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594598 = query.getOrDefault("Action")
  valid_594598 = validateParameter(valid_594598, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594598 != nil:
    section.add "Action", valid_594598
  var valid_594599 = query.getOrDefault("Version")
  valid_594599 = validateParameter(valid_594599, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594599 != nil:
    section.add "Version", valid_594599
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
  var valid_594600 = header.getOrDefault("X-Amz-Signature")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Signature", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Content-Sha256", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Date")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Date", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Credential")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Credential", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Security-Token")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Security-Token", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-SignedHeaders", valid_594606
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594607 = formData.getOrDefault("PreferredBackupWindow")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "PreferredBackupWindow", valid_594607
  var valid_594608 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594608 = validateParameter(valid_594608, JInt, required = false, default = nil)
  if valid_594608 != nil:
    section.add "BackupRetentionPeriod", valid_594608
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594609 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = nil)
  if valid_594609 != nil:
    section.add "DBInstanceIdentifier", valid_594609
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_PostPromoteReadReplica_594595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_PostPromoteReadReplica_594595;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594612 = newJObject()
  var formData_594613 = newJObject()
  add(formData_594613, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594613, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594613, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594612, "Action", newJString(Action))
  add(query_594612, "Version", newJString(Version))
  result = call_594611.call(nil, query_594612, nil, formData_594613, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_594595(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_594596, base: "/",
    url: url_PostPromoteReadReplica_594597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_594577 = ref object of OpenApiRestCall_592348
proc url_GetPromoteReadReplica_594579(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_594578(path: JsonNode; query: JsonNode;
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
  var valid_594580 = query.getOrDefault("DBInstanceIdentifier")
  valid_594580 = validateParameter(valid_594580, JString, required = true,
                                 default = nil)
  if valid_594580 != nil:
    section.add "DBInstanceIdentifier", valid_594580
  var valid_594581 = query.getOrDefault("BackupRetentionPeriod")
  valid_594581 = validateParameter(valid_594581, JInt, required = false, default = nil)
  if valid_594581 != nil:
    section.add "BackupRetentionPeriod", valid_594581
  var valid_594582 = query.getOrDefault("Action")
  valid_594582 = validateParameter(valid_594582, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594582 != nil:
    section.add "Action", valid_594582
  var valid_594583 = query.getOrDefault("Version")
  valid_594583 = validateParameter(valid_594583, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594583 != nil:
    section.add "Version", valid_594583
  var valid_594584 = query.getOrDefault("PreferredBackupWindow")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "PreferredBackupWindow", valid_594584
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
  var valid_594585 = header.getOrDefault("X-Amz-Signature")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Signature", valid_594585
  var valid_594586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Content-Sha256", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Date")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Date", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Credential")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Credential", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Security-Token")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Security-Token", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-SignedHeaders", valid_594591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594592: Call_GetPromoteReadReplica_594577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594592.validator(path, query, header, formData, body)
  let scheme = call_594592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594592.url(scheme.get, call_594592.host, call_594592.base,
                         call_594592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594592, url, valid)

proc call*(call_594593: Call_GetPromoteReadReplica_594577;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-01-10";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_594594 = newJObject()
  add(query_594594, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594594, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594594, "Action", newJString(Action))
  add(query_594594, "Version", newJString(Version))
  add(query_594594, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_594593.call(nil, query_594594, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_594577(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_594578, base: "/",
    url: url_GetPromoteReadReplica_594579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_594632 = ref object of OpenApiRestCall_592348
proc url_PostPurchaseReservedDBInstancesOffering_594634(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_594633(path: JsonNode;
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
  var valid_594635 = query.getOrDefault("Action")
  valid_594635 = validateParameter(valid_594635, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594635 != nil:
    section.add "Action", valid_594635
  var valid_594636 = query.getOrDefault("Version")
  valid_594636 = validateParameter(valid_594636, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594636 != nil:
    section.add "Version", valid_594636
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
  var valid_594637 = header.getOrDefault("X-Amz-Signature")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Signature", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Content-Sha256", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Date")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Date", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Credential")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Credential", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Security-Token")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Security-Token", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-Algorithm")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Algorithm", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-SignedHeaders", valid_594643
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_594644 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "ReservedDBInstanceId", valid_594644
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_594645 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594645 = validateParameter(valid_594645, JString, required = true,
                                 default = nil)
  if valid_594645 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594645
  var valid_594646 = formData.getOrDefault("DBInstanceCount")
  valid_594646 = validateParameter(valid_594646, JInt, required = false, default = nil)
  if valid_594646 != nil:
    section.add "DBInstanceCount", valid_594646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594647: Call_PostPurchaseReservedDBInstancesOffering_594632;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594647.validator(path, query, header, formData, body)
  let scheme = call_594647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594647.url(scheme.get, call_594647.host, call_594647.base,
                         call_594647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594647, url, valid)

proc call*(call_594648: Call_PostPurchaseReservedDBInstancesOffering_594632;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_594649 = newJObject()
  var formData_594650 = newJObject()
  add(formData_594650, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594649, "Action", newJString(Action))
  add(formData_594650, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594649, "Version", newJString(Version))
  add(formData_594650, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_594648.call(nil, query_594649, nil, formData_594650, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_594632(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_594633, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_594634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_594614 = ref object of OpenApiRestCall_592348
proc url_GetPurchaseReservedDBInstancesOffering_594616(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_594615(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_594617 = query.getOrDefault("DBInstanceCount")
  valid_594617 = validateParameter(valid_594617, JInt, required = false, default = nil)
  if valid_594617 != nil:
    section.add "DBInstanceCount", valid_594617
  var valid_594618 = query.getOrDefault("ReservedDBInstanceId")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "ReservedDBInstanceId", valid_594618
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594619 = query.getOrDefault("Action")
  valid_594619 = validateParameter(valid_594619, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594619 != nil:
    section.add "Action", valid_594619
  var valid_594620 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594620 = validateParameter(valid_594620, JString, required = true,
                                 default = nil)
  if valid_594620 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594620
  var valid_594621 = query.getOrDefault("Version")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594621 != nil:
    section.add "Version", valid_594621
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
  var valid_594622 = header.getOrDefault("X-Amz-Signature")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Signature", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Content-Sha256", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Date")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Date", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Credential")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Credential", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Security-Token")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Security-Token", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Algorithm")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Algorithm", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-SignedHeaders", valid_594628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594629: Call_GetPurchaseReservedDBInstancesOffering_594614;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594629.validator(path, query, header, formData, body)
  let scheme = call_594629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594629.url(scheme.get, call_594629.host, call_594629.base,
                         call_594629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594629, url, valid)

proc call*(call_594630: Call_GetPurchaseReservedDBInstancesOffering_594614;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_594631 = newJObject()
  add(query_594631, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_594631, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594631, "Action", newJString(Action))
  add(query_594631, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594631, "Version", newJString(Version))
  result = call_594630.call(nil, query_594631, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_594614(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_594615, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_594616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_594668 = ref object of OpenApiRestCall_592348
proc url_PostRebootDBInstance_594670(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_594669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594671 = query.getOrDefault("Action")
  valid_594671 = validateParameter(valid_594671, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594671 != nil:
    section.add "Action", valid_594671
  var valid_594672 = query.getOrDefault("Version")
  valid_594672 = validateParameter(valid_594672, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594672 != nil:
    section.add "Version", valid_594672
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
  var valid_594673 = header.getOrDefault("X-Amz-Signature")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Signature", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Content-Sha256", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Date")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Date", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Credential")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Credential", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Security-Token")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Security-Token", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Algorithm")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Algorithm", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-SignedHeaders", valid_594679
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594680 = formData.getOrDefault("ForceFailover")
  valid_594680 = validateParameter(valid_594680, JBool, required = false, default = nil)
  if valid_594680 != nil:
    section.add "ForceFailover", valid_594680
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594681 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = nil)
  if valid_594681 != nil:
    section.add "DBInstanceIdentifier", valid_594681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594682: Call_PostRebootDBInstance_594668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594682.validator(path, query, header, formData, body)
  let scheme = call_594682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594682.url(scheme.get, call_594682.host, call_594682.base,
                         call_594682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594682, url, valid)

proc call*(call_594683: Call_PostRebootDBInstance_594668;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594684 = newJObject()
  var formData_594685 = newJObject()
  add(formData_594685, "ForceFailover", newJBool(ForceFailover))
  add(formData_594685, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594684, "Action", newJString(Action))
  add(query_594684, "Version", newJString(Version))
  result = call_594683.call(nil, query_594684, nil, formData_594685, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_594668(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_594669, base: "/",
    url: url_PostRebootDBInstance_594670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_594651 = ref object of OpenApiRestCall_592348
proc url_GetRebootDBInstance_594653(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_594652(path: JsonNode; query: JsonNode;
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
  var valid_594654 = query.getOrDefault("ForceFailover")
  valid_594654 = validateParameter(valid_594654, JBool, required = false, default = nil)
  if valid_594654 != nil:
    section.add "ForceFailover", valid_594654
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594655 = query.getOrDefault("DBInstanceIdentifier")
  valid_594655 = validateParameter(valid_594655, JString, required = true,
                                 default = nil)
  if valid_594655 != nil:
    section.add "DBInstanceIdentifier", valid_594655
  var valid_594656 = query.getOrDefault("Action")
  valid_594656 = validateParameter(valid_594656, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594656 != nil:
    section.add "Action", valid_594656
  var valid_594657 = query.getOrDefault("Version")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594657 != nil:
    section.add "Version", valid_594657
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
  var valid_594658 = header.getOrDefault("X-Amz-Signature")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Signature", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Content-Sha256", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Date")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Date", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Credential")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Credential", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Algorithm")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Algorithm", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-SignedHeaders", valid_594664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594665: Call_GetRebootDBInstance_594651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594665.validator(path, query, header, formData, body)
  let scheme = call_594665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594665.url(scheme.get, call_594665.host, call_594665.base,
                         call_594665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594665, url, valid)

proc call*(call_594666: Call_GetRebootDBInstance_594651;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594667 = newJObject()
  add(query_594667, "ForceFailover", newJBool(ForceFailover))
  add(query_594667, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594667, "Action", newJString(Action))
  add(query_594667, "Version", newJString(Version))
  result = call_594666.call(nil, query_594667, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_594651(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_594652, base: "/",
    url: url_GetRebootDBInstance_594653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_594703 = ref object of OpenApiRestCall_592348
proc url_PostRemoveSourceIdentifierFromSubscription_594705(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_594704(path: JsonNode;
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
  var valid_594706 = query.getOrDefault("Action")
  valid_594706 = validateParameter(valid_594706, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594706 != nil:
    section.add "Action", valid_594706
  var valid_594707 = query.getOrDefault("Version")
  valid_594707 = validateParameter(valid_594707, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594707 != nil:
    section.add "Version", valid_594707
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
  var valid_594708 = header.getOrDefault("X-Amz-Signature")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Signature", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Content-Sha256", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Date")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Date", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Credential")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Credential", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Security-Token")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Security-Token", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Algorithm")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Algorithm", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-SignedHeaders", valid_594714
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594715 = formData.getOrDefault("SubscriptionName")
  valid_594715 = validateParameter(valid_594715, JString, required = true,
                                 default = nil)
  if valid_594715 != nil:
    section.add "SubscriptionName", valid_594715
  var valid_594716 = formData.getOrDefault("SourceIdentifier")
  valid_594716 = validateParameter(valid_594716, JString, required = true,
                                 default = nil)
  if valid_594716 != nil:
    section.add "SourceIdentifier", valid_594716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594717: Call_PostRemoveSourceIdentifierFromSubscription_594703;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594717.validator(path, query, header, formData, body)
  let scheme = call_594717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594717.url(scheme.get, call_594717.host, call_594717.base,
                         call_594717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594717, url, valid)

proc call*(call_594718: Call_PostRemoveSourceIdentifierFromSubscription_594703;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594719 = newJObject()
  var formData_594720 = newJObject()
  add(formData_594720, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594720, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594719, "Action", newJString(Action))
  add(query_594719, "Version", newJString(Version))
  result = call_594718.call(nil, query_594719, nil, formData_594720, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_594703(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_594704,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_594705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_594686 = ref object of OpenApiRestCall_592348
proc url_GetRemoveSourceIdentifierFromSubscription_594688(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_594687(path: JsonNode;
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
  var valid_594689 = query.getOrDefault("SourceIdentifier")
  valid_594689 = validateParameter(valid_594689, JString, required = true,
                                 default = nil)
  if valid_594689 != nil:
    section.add "SourceIdentifier", valid_594689
  var valid_594690 = query.getOrDefault("SubscriptionName")
  valid_594690 = validateParameter(valid_594690, JString, required = true,
                                 default = nil)
  if valid_594690 != nil:
    section.add "SubscriptionName", valid_594690
  var valid_594691 = query.getOrDefault("Action")
  valid_594691 = validateParameter(valid_594691, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594691 != nil:
    section.add "Action", valid_594691
  var valid_594692 = query.getOrDefault("Version")
  valid_594692 = validateParameter(valid_594692, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594692 != nil:
    section.add "Version", valid_594692
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
  var valid_594693 = header.getOrDefault("X-Amz-Signature")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Signature", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Content-Sha256", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Date")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Date", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Credential")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Credential", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Security-Token")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Security-Token", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Algorithm")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Algorithm", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-SignedHeaders", valid_594699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_GetRemoveSourceIdentifierFromSubscription_594686;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_GetRemoveSourceIdentifierFromSubscription_594686;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594702 = newJObject()
  add(query_594702, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594702, "SubscriptionName", newJString(SubscriptionName))
  add(query_594702, "Action", newJString(Action))
  add(query_594702, "Version", newJString(Version))
  result = call_594701.call(nil, query_594702, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_594686(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_594687,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_594688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_594738 = ref object of OpenApiRestCall_592348
proc url_PostRemoveTagsFromResource_594740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_594739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594741 = query.getOrDefault("Action")
  valid_594741 = validateParameter(valid_594741, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594741 != nil:
    section.add "Action", valid_594741
  var valid_594742 = query.getOrDefault("Version")
  valid_594742 = validateParameter(valid_594742, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594742 != nil:
    section.add "Version", valid_594742
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
  var valid_594743 = header.getOrDefault("X-Amz-Signature")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Signature", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-Content-Sha256", valid_594744
  var valid_594745 = header.getOrDefault("X-Amz-Date")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Date", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Credential")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Credential", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Security-Token")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Security-Token", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Algorithm")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Algorithm", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-SignedHeaders", valid_594749
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594750 = formData.getOrDefault("TagKeys")
  valid_594750 = validateParameter(valid_594750, JArray, required = true, default = nil)
  if valid_594750 != nil:
    section.add "TagKeys", valid_594750
  var valid_594751 = formData.getOrDefault("ResourceName")
  valid_594751 = validateParameter(valid_594751, JString, required = true,
                                 default = nil)
  if valid_594751 != nil:
    section.add "ResourceName", valid_594751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_PostRemoveTagsFromResource_594738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_PostRemoveTagsFromResource_594738; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594754 = newJObject()
  var formData_594755 = newJObject()
  if TagKeys != nil:
    formData_594755.add "TagKeys", TagKeys
  add(query_594754, "Action", newJString(Action))
  add(query_594754, "Version", newJString(Version))
  add(formData_594755, "ResourceName", newJString(ResourceName))
  result = call_594753.call(nil, query_594754, nil, formData_594755, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_594738(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_594739, base: "/",
    url: url_PostRemoveTagsFromResource_594740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_594721 = ref object of OpenApiRestCall_592348
proc url_GetRemoveTagsFromResource_594723(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_594722(path: JsonNode; query: JsonNode;
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
  var valid_594724 = query.getOrDefault("ResourceName")
  valid_594724 = validateParameter(valid_594724, JString, required = true,
                                 default = nil)
  if valid_594724 != nil:
    section.add "ResourceName", valid_594724
  var valid_594725 = query.getOrDefault("TagKeys")
  valid_594725 = validateParameter(valid_594725, JArray, required = true, default = nil)
  if valid_594725 != nil:
    section.add "TagKeys", valid_594725
  var valid_594726 = query.getOrDefault("Action")
  valid_594726 = validateParameter(valid_594726, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594726 != nil:
    section.add "Action", valid_594726
  var valid_594727 = query.getOrDefault("Version")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594727 != nil:
    section.add "Version", valid_594727
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
  var valid_594728 = header.getOrDefault("X-Amz-Signature")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Signature", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Content-Sha256", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Date")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Date", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Credential")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Credential", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Security-Token")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Security-Token", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-Algorithm")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-Algorithm", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-SignedHeaders", valid_594734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594735: Call_GetRemoveTagsFromResource_594721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594735.validator(path, query, header, formData, body)
  let scheme = call_594735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594735.url(scheme.get, call_594735.host, call_594735.base,
                         call_594735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594735, url, valid)

proc call*(call_594736: Call_GetRemoveTagsFromResource_594721;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594737 = newJObject()
  add(query_594737, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_594737.add "TagKeys", TagKeys
  add(query_594737, "Action", newJString(Action))
  add(query_594737, "Version", newJString(Version))
  result = call_594736.call(nil, query_594737, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_594721(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_594722, base: "/",
    url: url_GetRemoveTagsFromResource_594723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_594774 = ref object of OpenApiRestCall_592348
proc url_PostResetDBParameterGroup_594776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_594775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594777 = query.getOrDefault("Action")
  valid_594777 = validateParameter(valid_594777, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594777 != nil:
    section.add "Action", valid_594777
  var valid_594778 = query.getOrDefault("Version")
  valid_594778 = validateParameter(valid_594778, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594778 != nil:
    section.add "Version", valid_594778
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
  var valid_594779 = header.getOrDefault("X-Amz-Signature")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Signature", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Content-Sha256", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Date")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Date", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Credential")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Credential", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Security-Token")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Security-Token", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Algorithm")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Algorithm", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-SignedHeaders", valid_594785
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_594786 = formData.getOrDefault("ResetAllParameters")
  valid_594786 = validateParameter(valid_594786, JBool, required = false, default = nil)
  if valid_594786 != nil:
    section.add "ResetAllParameters", valid_594786
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594787 = formData.getOrDefault("DBParameterGroupName")
  valid_594787 = validateParameter(valid_594787, JString, required = true,
                                 default = nil)
  if valid_594787 != nil:
    section.add "DBParameterGroupName", valid_594787
  var valid_594788 = formData.getOrDefault("Parameters")
  valid_594788 = validateParameter(valid_594788, JArray, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "Parameters", valid_594788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594789: Call_PostResetDBParameterGroup_594774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594789.validator(path, query, header, formData, body)
  let scheme = call_594789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594789.url(scheme.get, call_594789.host, call_594789.base,
                         call_594789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594789, url, valid)

proc call*(call_594790: Call_PostResetDBParameterGroup_594774;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_594791 = newJObject()
  var formData_594792 = newJObject()
  add(formData_594792, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_594792, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594791, "Action", newJString(Action))
  if Parameters != nil:
    formData_594792.add "Parameters", Parameters
  add(query_594791, "Version", newJString(Version))
  result = call_594790.call(nil, query_594791, nil, formData_594792, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_594774(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_594775, base: "/",
    url: url_PostResetDBParameterGroup_594776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_594756 = ref object of OpenApiRestCall_592348
proc url_GetResetDBParameterGroup_594758(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_594757(path: JsonNode; query: JsonNode;
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
  var valid_594759 = query.getOrDefault("DBParameterGroupName")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = nil)
  if valid_594759 != nil:
    section.add "DBParameterGroupName", valid_594759
  var valid_594760 = query.getOrDefault("Parameters")
  valid_594760 = validateParameter(valid_594760, JArray, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "Parameters", valid_594760
  var valid_594761 = query.getOrDefault("ResetAllParameters")
  valid_594761 = validateParameter(valid_594761, JBool, required = false, default = nil)
  if valid_594761 != nil:
    section.add "ResetAllParameters", valid_594761
  var valid_594762 = query.getOrDefault("Action")
  valid_594762 = validateParameter(valid_594762, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594762 != nil:
    section.add "Action", valid_594762
  var valid_594763 = query.getOrDefault("Version")
  valid_594763 = validateParameter(valid_594763, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594763 != nil:
    section.add "Version", valid_594763
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
  var valid_594764 = header.getOrDefault("X-Amz-Signature")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Signature", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Content-Sha256", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Date")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Date", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Credential")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Credential", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-Security-Token")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Security-Token", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Algorithm")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Algorithm", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-SignedHeaders", valid_594770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594771: Call_GetResetDBParameterGroup_594756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594771.validator(path, query, header, formData, body)
  let scheme = call_594771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594771.url(scheme.get, call_594771.host, call_594771.base,
                         call_594771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594771, url, valid)

proc call*(call_594772: Call_GetResetDBParameterGroup_594756;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594773 = newJObject()
  add(query_594773, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594773.add "Parameters", Parameters
  add(query_594773, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_594773, "Action", newJString(Action))
  add(query_594773, "Version", newJString(Version))
  result = call_594772.call(nil, query_594773, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_594756(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_594757, base: "/",
    url: url_GetResetDBParameterGroup_594758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_594822 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceFromDBSnapshot_594824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_594823(path: JsonNode;
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
  var valid_594825 = query.getOrDefault("Action")
  valid_594825 = validateParameter(valid_594825, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594825 != nil:
    section.add "Action", valid_594825
  var valid_594826 = query.getOrDefault("Version")
  valid_594826 = validateParameter(valid_594826, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594826 != nil:
    section.add "Version", valid_594826
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
  var valid_594827 = header.getOrDefault("X-Amz-Signature")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Signature", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Content-Sha256", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Date")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Date", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Credential")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Credential", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Security-Token")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Security-Token", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Algorithm")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Algorithm", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-SignedHeaders", valid_594833
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_594834 = formData.getOrDefault("Port")
  valid_594834 = validateParameter(valid_594834, JInt, required = false, default = nil)
  if valid_594834 != nil:
    section.add "Port", valid_594834
  var valid_594835 = formData.getOrDefault("DBInstanceClass")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "DBInstanceClass", valid_594835
  var valid_594836 = formData.getOrDefault("MultiAZ")
  valid_594836 = validateParameter(valid_594836, JBool, required = false, default = nil)
  if valid_594836 != nil:
    section.add "MultiAZ", valid_594836
  var valid_594837 = formData.getOrDefault("AvailabilityZone")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "AvailabilityZone", valid_594837
  var valid_594838 = formData.getOrDefault("Engine")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "Engine", valid_594838
  var valid_594839 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594839 = validateParameter(valid_594839, JBool, required = false, default = nil)
  if valid_594839 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594839
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594840 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = nil)
  if valid_594840 != nil:
    section.add "DBInstanceIdentifier", valid_594840
  var valid_594841 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594841 = validateParameter(valid_594841, JString, required = true,
                                 default = nil)
  if valid_594841 != nil:
    section.add "DBSnapshotIdentifier", valid_594841
  var valid_594842 = formData.getOrDefault("DBName")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "DBName", valid_594842
  var valid_594843 = formData.getOrDefault("Iops")
  valid_594843 = validateParameter(valid_594843, JInt, required = false, default = nil)
  if valid_594843 != nil:
    section.add "Iops", valid_594843
  var valid_594844 = formData.getOrDefault("PubliclyAccessible")
  valid_594844 = validateParameter(valid_594844, JBool, required = false, default = nil)
  if valid_594844 != nil:
    section.add "PubliclyAccessible", valid_594844
  var valid_594845 = formData.getOrDefault("LicenseModel")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "LicenseModel", valid_594845
  var valid_594846 = formData.getOrDefault("DBSubnetGroupName")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "DBSubnetGroupName", valid_594846
  var valid_594847 = formData.getOrDefault("OptionGroupName")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "OptionGroupName", valid_594847
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594848: Call_PostRestoreDBInstanceFromDBSnapshot_594822;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594848.validator(path, query, header, formData, body)
  let scheme = call_594848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594848.url(scheme.get, call_594848.host, call_594848.base,
                         call_594848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594848, url, valid)

proc call*(call_594849: Call_PostRestoreDBInstanceFromDBSnapshot_594822;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_594850 = newJObject()
  var formData_594851 = newJObject()
  add(formData_594851, "Port", newJInt(Port))
  add(formData_594851, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594851, "MultiAZ", newJBool(MultiAZ))
  add(formData_594851, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594851, "Engine", newJString(Engine))
  add(formData_594851, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594851, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594851, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_594851, "DBName", newJString(DBName))
  add(formData_594851, "Iops", newJInt(Iops))
  add(formData_594851, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594850, "Action", newJString(Action))
  add(formData_594851, "LicenseModel", newJString(LicenseModel))
  add(formData_594851, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594851, "OptionGroupName", newJString(OptionGroupName))
  add(query_594850, "Version", newJString(Version))
  result = call_594849.call(nil, query_594850, nil, formData_594851, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_594822(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_594823, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_594824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_594793 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceFromDBSnapshot_594795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_594794(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
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
  var valid_594796 = query.getOrDefault("DBName")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "DBName", valid_594796
  var valid_594797 = query.getOrDefault("Engine")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "Engine", valid_594797
  var valid_594798 = query.getOrDefault("LicenseModel")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "LicenseModel", valid_594798
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594799 = query.getOrDefault("DBInstanceIdentifier")
  valid_594799 = validateParameter(valid_594799, JString, required = true,
                                 default = nil)
  if valid_594799 != nil:
    section.add "DBInstanceIdentifier", valid_594799
  var valid_594800 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594800 = validateParameter(valid_594800, JString, required = true,
                                 default = nil)
  if valid_594800 != nil:
    section.add "DBSnapshotIdentifier", valid_594800
  var valid_594801 = query.getOrDefault("Action")
  valid_594801 = validateParameter(valid_594801, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594801 != nil:
    section.add "Action", valid_594801
  var valid_594802 = query.getOrDefault("MultiAZ")
  valid_594802 = validateParameter(valid_594802, JBool, required = false, default = nil)
  if valid_594802 != nil:
    section.add "MultiAZ", valid_594802
  var valid_594803 = query.getOrDefault("Port")
  valid_594803 = validateParameter(valid_594803, JInt, required = false, default = nil)
  if valid_594803 != nil:
    section.add "Port", valid_594803
  var valid_594804 = query.getOrDefault("AvailabilityZone")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "AvailabilityZone", valid_594804
  var valid_594805 = query.getOrDefault("OptionGroupName")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "OptionGroupName", valid_594805
  var valid_594806 = query.getOrDefault("DBSubnetGroupName")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "DBSubnetGroupName", valid_594806
  var valid_594807 = query.getOrDefault("Version")
  valid_594807 = validateParameter(valid_594807, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594807 != nil:
    section.add "Version", valid_594807
  var valid_594808 = query.getOrDefault("DBInstanceClass")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "DBInstanceClass", valid_594808
  var valid_594809 = query.getOrDefault("PubliclyAccessible")
  valid_594809 = validateParameter(valid_594809, JBool, required = false, default = nil)
  if valid_594809 != nil:
    section.add "PubliclyAccessible", valid_594809
  var valid_594810 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594810 = validateParameter(valid_594810, JBool, required = false, default = nil)
  if valid_594810 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594810
  var valid_594811 = query.getOrDefault("Iops")
  valid_594811 = validateParameter(valid_594811, JInt, required = false, default = nil)
  if valid_594811 != nil:
    section.add "Iops", valid_594811
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
  var valid_594812 = header.getOrDefault("X-Amz-Signature")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Signature", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Content-Sha256", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Date")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Date", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Credential")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Credential", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Security-Token")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Security-Token", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Algorithm")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Algorithm", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-SignedHeaders", valid_594818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594819: Call_GetRestoreDBInstanceFromDBSnapshot_594793;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594819.validator(path, query, header, formData, body)
  let scheme = call_594819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594819.url(scheme.get, call_594819.host, call_594819.base,
                         call_594819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594819, url, valid)

proc call*(call_594820: Call_GetRestoreDBInstanceFromDBSnapshot_594793;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
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
  var query_594821 = newJObject()
  add(query_594821, "DBName", newJString(DBName))
  add(query_594821, "Engine", newJString(Engine))
  add(query_594821, "LicenseModel", newJString(LicenseModel))
  add(query_594821, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594821, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594821, "Action", newJString(Action))
  add(query_594821, "MultiAZ", newJBool(MultiAZ))
  add(query_594821, "Port", newJInt(Port))
  add(query_594821, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594821, "OptionGroupName", newJString(OptionGroupName))
  add(query_594821, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594821, "Version", newJString(Version))
  add(query_594821, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594821, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594821, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594821, "Iops", newJInt(Iops))
  result = call_594820.call(nil, query_594821, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_594793(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_594794, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_594795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_594883 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceToPointInTime_594885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_594884(path: JsonNode;
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
  var valid_594886 = query.getOrDefault("Action")
  valid_594886 = validateParameter(valid_594886, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_594886 != nil:
    section.add "Action", valid_594886
  var valid_594887 = query.getOrDefault("Version")
  valid_594887 = validateParameter(valid_594887, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594887 != nil:
    section.add "Version", valid_594887
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
  var valid_594888 = header.getOrDefault("X-Amz-Signature")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "X-Amz-Signature", valid_594888
  var valid_594889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Content-Sha256", valid_594889
  var valid_594890 = header.getOrDefault("X-Amz-Date")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Date", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Credential")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Credential", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Security-Token")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Security-Token", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Algorithm")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Algorithm", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-SignedHeaders", valid_594894
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594895 = formData.getOrDefault("Port")
  valid_594895 = validateParameter(valid_594895, JInt, required = false, default = nil)
  if valid_594895 != nil:
    section.add "Port", valid_594895
  var valid_594896 = formData.getOrDefault("DBInstanceClass")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "DBInstanceClass", valid_594896
  var valid_594897 = formData.getOrDefault("MultiAZ")
  valid_594897 = validateParameter(valid_594897, JBool, required = false, default = nil)
  if valid_594897 != nil:
    section.add "MultiAZ", valid_594897
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_594898 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_594898 = validateParameter(valid_594898, JString, required = true,
                                 default = nil)
  if valid_594898 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594898
  var valid_594899 = formData.getOrDefault("AvailabilityZone")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "AvailabilityZone", valid_594899
  var valid_594900 = formData.getOrDefault("Engine")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "Engine", valid_594900
  var valid_594901 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594901 = validateParameter(valid_594901, JBool, required = false, default = nil)
  if valid_594901 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594901
  var valid_594902 = formData.getOrDefault("UseLatestRestorableTime")
  valid_594902 = validateParameter(valid_594902, JBool, required = false, default = nil)
  if valid_594902 != nil:
    section.add "UseLatestRestorableTime", valid_594902
  var valid_594903 = formData.getOrDefault("DBName")
  valid_594903 = validateParameter(valid_594903, JString, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "DBName", valid_594903
  var valid_594904 = formData.getOrDefault("Iops")
  valid_594904 = validateParameter(valid_594904, JInt, required = false, default = nil)
  if valid_594904 != nil:
    section.add "Iops", valid_594904
  var valid_594905 = formData.getOrDefault("PubliclyAccessible")
  valid_594905 = validateParameter(valid_594905, JBool, required = false, default = nil)
  if valid_594905 != nil:
    section.add "PubliclyAccessible", valid_594905
  var valid_594906 = formData.getOrDefault("LicenseModel")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "LicenseModel", valid_594906
  var valid_594907 = formData.getOrDefault("DBSubnetGroupName")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "DBSubnetGroupName", valid_594907
  var valid_594908 = formData.getOrDefault("OptionGroupName")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "OptionGroupName", valid_594908
  var valid_594909 = formData.getOrDefault("RestoreTime")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "RestoreTime", valid_594909
  var valid_594910 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_594910 = validateParameter(valid_594910, JString, required = true,
                                 default = nil)
  if valid_594910 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594910
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594911: Call_PostRestoreDBInstanceToPointInTime_594883;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594911.validator(path, query, header, formData, body)
  let scheme = call_594911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594911.url(scheme.get, call_594911.host, call_594911.base,
                         call_594911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594911, url, valid)

proc call*(call_594912: Call_PostRestoreDBInstanceToPointInTime_594883;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; RestoreTime: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_594913 = newJObject()
  var formData_594914 = newJObject()
  add(formData_594914, "Port", newJInt(Port))
  add(formData_594914, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594914, "MultiAZ", newJBool(MultiAZ))
  add(formData_594914, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_594914, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594914, "Engine", newJString(Engine))
  add(formData_594914, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594914, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_594914, "DBName", newJString(DBName))
  add(formData_594914, "Iops", newJInt(Iops))
  add(formData_594914, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594913, "Action", newJString(Action))
  add(formData_594914, "LicenseModel", newJString(LicenseModel))
  add(formData_594914, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594914, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594914, "RestoreTime", newJString(RestoreTime))
  add(formData_594914, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594913, "Version", newJString(Version))
  result = call_594912.call(nil, query_594913, nil, formData_594914, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_594883(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_594884, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_594885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_594852 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceToPointInTime_594854(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_594853(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   LicenseModel: JString
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
  var valid_594855 = query.getOrDefault("DBName")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "DBName", valid_594855
  var valid_594856 = query.getOrDefault("Engine")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "Engine", valid_594856
  var valid_594857 = query.getOrDefault("UseLatestRestorableTime")
  valid_594857 = validateParameter(valid_594857, JBool, required = false, default = nil)
  if valid_594857 != nil:
    section.add "UseLatestRestorableTime", valid_594857
  var valid_594858 = query.getOrDefault("LicenseModel")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "LicenseModel", valid_594858
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_594859 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_594859 = validateParameter(valid_594859, JString, required = true,
                                 default = nil)
  if valid_594859 != nil:
    section.add "TargetDBInstanceIdentifier", valid_594859
  var valid_594860 = query.getOrDefault("Action")
  valid_594860 = validateParameter(valid_594860, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_594860 != nil:
    section.add "Action", valid_594860
  var valid_594861 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_594861 = validateParameter(valid_594861, JString, required = true,
                                 default = nil)
  if valid_594861 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594861
  var valid_594862 = query.getOrDefault("MultiAZ")
  valid_594862 = validateParameter(valid_594862, JBool, required = false, default = nil)
  if valid_594862 != nil:
    section.add "MultiAZ", valid_594862
  var valid_594863 = query.getOrDefault("Port")
  valid_594863 = validateParameter(valid_594863, JInt, required = false, default = nil)
  if valid_594863 != nil:
    section.add "Port", valid_594863
  var valid_594864 = query.getOrDefault("AvailabilityZone")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "AvailabilityZone", valid_594864
  var valid_594865 = query.getOrDefault("OptionGroupName")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "OptionGroupName", valid_594865
  var valid_594866 = query.getOrDefault("DBSubnetGroupName")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "DBSubnetGroupName", valid_594866
  var valid_594867 = query.getOrDefault("RestoreTime")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "RestoreTime", valid_594867
  var valid_594868 = query.getOrDefault("DBInstanceClass")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "DBInstanceClass", valid_594868
  var valid_594869 = query.getOrDefault("PubliclyAccessible")
  valid_594869 = validateParameter(valid_594869, JBool, required = false, default = nil)
  if valid_594869 != nil:
    section.add "PubliclyAccessible", valid_594869
  var valid_594870 = query.getOrDefault("Version")
  valid_594870 = validateParameter(valid_594870, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594870 != nil:
    section.add "Version", valid_594870
  var valid_594871 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594871 = validateParameter(valid_594871, JBool, required = false, default = nil)
  if valid_594871 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594871
  var valid_594872 = query.getOrDefault("Iops")
  valid_594872 = validateParameter(valid_594872, JInt, required = false, default = nil)
  if valid_594872 != nil:
    section.add "Iops", valid_594872
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
  var valid_594873 = header.getOrDefault("X-Amz-Signature")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Signature", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Content-Sha256", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Date")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Date", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Credential")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Credential", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Security-Token")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Security-Token", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Algorithm")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Algorithm", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-SignedHeaders", valid_594879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594880: Call_GetRestoreDBInstanceToPointInTime_594852;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594880.validator(path, query, header, formData, body)
  let scheme = call_594880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594880.url(scheme.get, call_594880.host, call_594880.base,
                         call_594880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594880, url, valid)

proc call*(call_594881: Call_GetRestoreDBInstanceToPointInTime_594852;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-01-10"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   LicenseModel: string
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
  var query_594882 = newJObject()
  add(query_594882, "DBName", newJString(DBName))
  add(query_594882, "Engine", newJString(Engine))
  add(query_594882, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_594882, "LicenseModel", newJString(LicenseModel))
  add(query_594882, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_594882, "Action", newJString(Action))
  add(query_594882, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_594882, "MultiAZ", newJBool(MultiAZ))
  add(query_594882, "Port", newJInt(Port))
  add(query_594882, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594882, "OptionGroupName", newJString(OptionGroupName))
  add(query_594882, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594882, "RestoreTime", newJString(RestoreTime))
  add(query_594882, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594882, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594882, "Version", newJString(Version))
  add(query_594882, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594882, "Iops", newJInt(Iops))
  result = call_594881.call(nil, query_594882, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_594852(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_594853, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_594854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_594935 = ref object of OpenApiRestCall_592348
proc url_PostRevokeDBSecurityGroupIngress_594937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_594936(path: JsonNode;
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
      "RevokeDBSecurityGroupIngress"))
  if valid_594938 != nil:
    section.add "Action", valid_594938
  var valid_594939 = query.getOrDefault("Version")
  valid_594939 = validateParameter(valid_594939, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594947 = formData.getOrDefault("DBSecurityGroupName")
  valid_594947 = validateParameter(valid_594947, JString, required = true,
                                 default = nil)
  if valid_594947 != nil:
    section.add "DBSecurityGroupName", valid_594947
  var valid_594948 = formData.getOrDefault("EC2SecurityGroupName")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "EC2SecurityGroupName", valid_594948
  var valid_594949 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594949
  var valid_594950 = formData.getOrDefault("EC2SecurityGroupId")
  valid_594950 = validateParameter(valid_594950, JString, required = false,
                                 default = nil)
  if valid_594950 != nil:
    section.add "EC2SecurityGroupId", valid_594950
  var valid_594951 = formData.getOrDefault("CIDRIP")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "CIDRIP", valid_594951
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594952: Call_PostRevokeDBSecurityGroupIngress_594935;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594952.validator(path, query, header, formData, body)
  let scheme = call_594952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594952.url(scheme.get, call_594952.host, call_594952.base,
                         call_594952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594952, url, valid)

proc call*(call_594953: Call_PostRevokeDBSecurityGroupIngress_594935;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594954 = newJObject()
  var formData_594955 = newJObject()
  add(formData_594955, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_594955, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_594955, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_594955, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_594955, "CIDRIP", newJString(CIDRIP))
  add(query_594954, "Action", newJString(Action))
  add(query_594954, "Version", newJString(Version))
  result = call_594953.call(nil, query_594954, nil, formData_594955, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_594935(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_594936, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_594937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_594915 = ref object of OpenApiRestCall_592348
proc url_GetRevokeDBSecurityGroupIngress_594917(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_594916(path: JsonNode;
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
  var valid_594918 = query.getOrDefault("EC2SecurityGroupName")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "EC2SecurityGroupName", valid_594918
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594919 = query.getOrDefault("DBSecurityGroupName")
  valid_594919 = validateParameter(valid_594919, JString, required = true,
                                 default = nil)
  if valid_594919 != nil:
    section.add "DBSecurityGroupName", valid_594919
  var valid_594920 = query.getOrDefault("EC2SecurityGroupId")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "EC2SecurityGroupId", valid_594920
  var valid_594921 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594921
  var valid_594922 = query.getOrDefault("Action")
  valid_594922 = validateParameter(valid_594922, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_594922 != nil:
    section.add "Action", valid_594922
  var valid_594923 = query.getOrDefault("Version")
  valid_594923 = validateParameter(valid_594923, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594923 != nil:
    section.add "Version", valid_594923
  var valid_594924 = query.getOrDefault("CIDRIP")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "CIDRIP", valid_594924
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

proc call*(call_594932: Call_GetRevokeDBSecurityGroupIngress_594915;
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

proc call*(call_594933: Call_GetRevokeDBSecurityGroupIngress_594915;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_594934 = newJObject()
  add(query_594934, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_594934, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594934, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_594934, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_594934, "Action", newJString(Action))
  add(query_594934, "Version", newJString(Version))
  add(query_594934, "CIDRIP", newJString(CIDRIP))
  result = call_594933.call(nil, query_594934, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_594915(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_594916, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_594917,
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

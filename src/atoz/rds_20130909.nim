
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_593071 = ref object of OpenApiRestCall_592348
proc url_PostCopyDBSnapshot_593073(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_593072(path: JsonNode; query: JsonNode;
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
  var valid_593074 = query.getOrDefault("Action")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593074 != nil:
    section.add "Action", valid_593074
  var valid_593075 = query.getOrDefault("Version")
  valid_593075 = validateParameter(valid_593075, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593075 != nil:
    section.add "Version", valid_593075
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
  var valid_593076 = header.getOrDefault("X-Amz-Signature")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Signature", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Content-Sha256", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Date")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Date", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Credential")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Credential", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Security-Token")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Security-Token", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Algorithm")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Algorithm", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-SignedHeaders", valid_593082
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_593083 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = nil)
  if valid_593083 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_593083
  var valid_593084 = formData.getOrDefault("Tags")
  valid_593084 = validateParameter(valid_593084, JArray, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "Tags", valid_593084
  var valid_593085 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = nil)
  if valid_593085 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593086: Call_PostCopyDBSnapshot_593071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593086.validator(path, query, header, formData, body)
  let scheme = call_593086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593086.url(scheme.get, call_593086.host, call_593086.base,
                         call_593086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593086, url, valid)

proc call*(call_593087: Call_PostCopyDBSnapshot_593071;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593088 = newJObject()
  var formData_593089 = newJObject()
  add(formData_593089, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_593088, "Action", newJString(Action))
  if Tags != nil:
    formData_593089.add "Tags", Tags
  add(formData_593089, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593088, "Version", newJString(Version))
  result = call_593087.call(nil, query_593088, nil, formData_593089, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_593071(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_593072, base: "/",
    url: url_PostCopyDBSnapshot_593073, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
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
  var valid_593057 = query.getOrDefault("Tags")
  valid_593057 = validateParameter(valid_593057, JArray, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "Tags", valid_593057
  var valid_593058 = query.getOrDefault("Action")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_593058 != nil:
    section.add "Action", valid_593058
  var valid_593059 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_593059
  var valid_593060 = query.getOrDefault("Version")
  valid_593060 = validateParameter(valid_593060, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593060 != nil:
    section.add "Version", valid_593060
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
  var valid_593061 = header.getOrDefault("X-Amz-Signature")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Signature", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Content-Sha256", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Date")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Date", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Credential")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Credential", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Security-Token")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Security-Token", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Algorithm")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Algorithm", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-SignedHeaders", valid_593067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593068: Call_GetCopyDBSnapshot_593053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593068.validator(path, query, header, formData, body)
  let scheme = call_593068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593068.url(scheme.get, call_593068.host, call_593068.base,
                         call_593068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593068, url, valid)

proc call*(call_593069: Call_GetCopyDBSnapshot_593053;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_593070 = newJObject()
  add(query_593070, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_593070.add "Tags", Tags
  add(query_593070, "Action", newJString(Action))
  add(query_593070, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_593070, "Version", newJString(Version))
  result = call_593069.call(nil, query_593070, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_593053(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_593054,
    base: "/", url: url_GetCopyDBSnapshot_593055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_593130 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstance_593132(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_593131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593133 = query.getOrDefault("Action")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593133 != nil:
    section.add "Action", valid_593133
  var valid_593134 = query.getOrDefault("Version")
  valid_593134 = validateParameter(valid_593134, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593134 != nil:
    section.add "Version", valid_593134
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
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_593142 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "PreferredMaintenanceWindow", valid_593142
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_593143 = formData.getOrDefault("DBInstanceClass")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = nil)
  if valid_593143 != nil:
    section.add "DBInstanceClass", valid_593143
  var valid_593144 = formData.getOrDefault("Port")
  valid_593144 = validateParameter(valid_593144, JInt, required = false, default = nil)
  if valid_593144 != nil:
    section.add "Port", valid_593144
  var valid_593145 = formData.getOrDefault("PreferredBackupWindow")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "PreferredBackupWindow", valid_593145
  var valid_593146 = formData.getOrDefault("MasterUserPassword")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = nil)
  if valid_593146 != nil:
    section.add "MasterUserPassword", valid_593146
  var valid_593147 = formData.getOrDefault("MultiAZ")
  valid_593147 = validateParameter(valid_593147, JBool, required = false, default = nil)
  if valid_593147 != nil:
    section.add "MultiAZ", valid_593147
  var valid_593148 = formData.getOrDefault("MasterUsername")
  valid_593148 = validateParameter(valid_593148, JString, required = true,
                                 default = nil)
  if valid_593148 != nil:
    section.add "MasterUsername", valid_593148
  var valid_593149 = formData.getOrDefault("DBParameterGroupName")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "DBParameterGroupName", valid_593149
  var valid_593150 = formData.getOrDefault("EngineVersion")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "EngineVersion", valid_593150
  var valid_593151 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_593151 = validateParameter(valid_593151, JArray, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "VpcSecurityGroupIds", valid_593151
  var valid_593152 = formData.getOrDefault("AvailabilityZone")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "AvailabilityZone", valid_593152
  var valid_593153 = formData.getOrDefault("BackupRetentionPeriod")
  valid_593153 = validateParameter(valid_593153, JInt, required = false, default = nil)
  if valid_593153 != nil:
    section.add "BackupRetentionPeriod", valid_593153
  var valid_593154 = formData.getOrDefault("Engine")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = nil)
  if valid_593154 != nil:
    section.add "Engine", valid_593154
  var valid_593155 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593155 = validateParameter(valid_593155, JBool, required = false, default = nil)
  if valid_593155 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593155
  var valid_593156 = formData.getOrDefault("DBName")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "DBName", valid_593156
  var valid_593157 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593157 = validateParameter(valid_593157, JString, required = true,
                                 default = nil)
  if valid_593157 != nil:
    section.add "DBInstanceIdentifier", valid_593157
  var valid_593158 = formData.getOrDefault("Iops")
  valid_593158 = validateParameter(valid_593158, JInt, required = false, default = nil)
  if valid_593158 != nil:
    section.add "Iops", valid_593158
  var valid_593159 = formData.getOrDefault("PubliclyAccessible")
  valid_593159 = validateParameter(valid_593159, JBool, required = false, default = nil)
  if valid_593159 != nil:
    section.add "PubliclyAccessible", valid_593159
  var valid_593160 = formData.getOrDefault("LicenseModel")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "LicenseModel", valid_593160
  var valid_593161 = formData.getOrDefault("Tags")
  valid_593161 = validateParameter(valid_593161, JArray, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "Tags", valid_593161
  var valid_593162 = formData.getOrDefault("DBSubnetGroupName")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "DBSubnetGroupName", valid_593162
  var valid_593163 = formData.getOrDefault("OptionGroupName")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "OptionGroupName", valid_593163
  var valid_593164 = formData.getOrDefault("CharacterSetName")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "CharacterSetName", valid_593164
  var valid_593165 = formData.getOrDefault("DBSecurityGroups")
  valid_593165 = validateParameter(valid_593165, JArray, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "DBSecurityGroups", valid_593165
  var valid_593166 = formData.getOrDefault("AllocatedStorage")
  valid_593166 = validateParameter(valid_593166, JInt, required = true, default = nil)
  if valid_593166 != nil:
    section.add "AllocatedStorage", valid_593166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593167: Call_PostCreateDBInstance_593130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593167.validator(path, query, header, formData, body)
  let scheme = call_593167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593167.url(scheme.get, call_593167.host, call_593167.base,
                         call_593167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593167, url, valid)

proc call*(call_593168: Call_PostCreateDBInstance_593130; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2013-09-09"; DBSecurityGroups: JsonNode = nil): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_593169 = newJObject()
  var formData_593170 = newJObject()
  add(formData_593170, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_593170, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593170, "Port", newJInt(Port))
  add(formData_593170, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_593170, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_593170, "MultiAZ", newJBool(MultiAZ))
  add(formData_593170, "MasterUsername", newJString(MasterUsername))
  add(formData_593170, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593170, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_593170.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_593170, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593170, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_593170, "Engine", newJString(Engine))
  add(formData_593170, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593170, "DBName", newJString(DBName))
  add(formData_593170, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593170, "Iops", newJInt(Iops))
  add(formData_593170, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593169, "Action", newJString(Action))
  add(formData_593170, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_593170.add "Tags", Tags
  add(formData_593170, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593170, "OptionGroupName", newJString(OptionGroupName))
  add(formData_593170, "CharacterSetName", newJString(CharacterSetName))
  add(query_593169, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_593170.add "DBSecurityGroups", DBSecurityGroups
  add(formData_593170, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_593168.call(nil, query_593169, nil, formData_593170, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_593130(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_593131, base: "/",
    url: url_PostCreateDBInstance_593132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_593090 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstance_593092(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_593091(path: JsonNode; query: JsonNode;
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
  ##   Tags: JArray
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
  var valid_593093 = query.getOrDefault("Version")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593093 != nil:
    section.add "Version", valid_593093
  var valid_593094 = query.getOrDefault("DBName")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "DBName", valid_593094
  var valid_593095 = query.getOrDefault("Engine")
  valid_593095 = validateParameter(valid_593095, JString, required = true,
                                 default = nil)
  if valid_593095 != nil:
    section.add "Engine", valid_593095
  var valid_593096 = query.getOrDefault("DBParameterGroupName")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "DBParameterGroupName", valid_593096
  var valid_593097 = query.getOrDefault("CharacterSetName")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "CharacterSetName", valid_593097
  var valid_593098 = query.getOrDefault("Tags")
  valid_593098 = validateParameter(valid_593098, JArray, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "Tags", valid_593098
  var valid_593099 = query.getOrDefault("LicenseModel")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "LicenseModel", valid_593099
  var valid_593100 = query.getOrDefault("DBInstanceIdentifier")
  valid_593100 = validateParameter(valid_593100, JString, required = true,
                                 default = nil)
  if valid_593100 != nil:
    section.add "DBInstanceIdentifier", valid_593100
  var valid_593101 = query.getOrDefault("MasterUsername")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = nil)
  if valid_593101 != nil:
    section.add "MasterUsername", valid_593101
  var valid_593102 = query.getOrDefault("BackupRetentionPeriod")
  valid_593102 = validateParameter(valid_593102, JInt, required = false, default = nil)
  if valid_593102 != nil:
    section.add "BackupRetentionPeriod", valid_593102
  var valid_593103 = query.getOrDefault("EngineVersion")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "EngineVersion", valid_593103
  var valid_593104 = query.getOrDefault("Action")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_593104 != nil:
    section.add "Action", valid_593104
  var valid_593105 = query.getOrDefault("MultiAZ")
  valid_593105 = validateParameter(valid_593105, JBool, required = false, default = nil)
  if valid_593105 != nil:
    section.add "MultiAZ", valid_593105
  var valid_593106 = query.getOrDefault("DBSecurityGroups")
  valid_593106 = validateParameter(valid_593106, JArray, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "DBSecurityGroups", valid_593106
  var valid_593107 = query.getOrDefault("Port")
  valid_593107 = validateParameter(valid_593107, JInt, required = false, default = nil)
  if valid_593107 != nil:
    section.add "Port", valid_593107
  var valid_593108 = query.getOrDefault("VpcSecurityGroupIds")
  valid_593108 = validateParameter(valid_593108, JArray, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "VpcSecurityGroupIds", valid_593108
  var valid_593109 = query.getOrDefault("MasterUserPassword")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "MasterUserPassword", valid_593109
  var valid_593110 = query.getOrDefault("AvailabilityZone")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "AvailabilityZone", valid_593110
  var valid_593111 = query.getOrDefault("OptionGroupName")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "OptionGroupName", valid_593111
  var valid_593112 = query.getOrDefault("DBSubnetGroupName")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "DBSubnetGroupName", valid_593112
  var valid_593113 = query.getOrDefault("AllocatedStorage")
  valid_593113 = validateParameter(valid_593113, JInt, required = true, default = nil)
  if valid_593113 != nil:
    section.add "AllocatedStorage", valid_593113
  var valid_593114 = query.getOrDefault("DBInstanceClass")
  valid_593114 = validateParameter(valid_593114, JString, required = true,
                                 default = nil)
  if valid_593114 != nil:
    section.add "DBInstanceClass", valid_593114
  var valid_593115 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "PreferredMaintenanceWindow", valid_593115
  var valid_593116 = query.getOrDefault("PreferredBackupWindow")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "PreferredBackupWindow", valid_593116
  var valid_593117 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593117 = validateParameter(valid_593117, JBool, required = false, default = nil)
  if valid_593117 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593117
  var valid_593118 = query.getOrDefault("Iops")
  valid_593118 = validateParameter(valid_593118, JInt, required = false, default = nil)
  if valid_593118 != nil:
    section.add "Iops", valid_593118
  var valid_593119 = query.getOrDefault("PubliclyAccessible")
  valid_593119 = validateParameter(valid_593119, JBool, required = false, default = nil)
  if valid_593119 != nil:
    section.add "PubliclyAccessible", valid_593119
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
  var valid_593120 = header.getOrDefault("X-Amz-Signature")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Signature", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Content-Sha256", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Date")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Date", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Credential")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Credential", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Security-Token")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Security-Token", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Algorithm")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Algorithm", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-SignedHeaders", valid_593126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593127: Call_GetCreateDBInstance_593090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593127.validator(path, query, header, formData, body)
  let scheme = call_593127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593127.url(scheme.get, call_593127.host, call_593127.base,
                         call_593127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593127, url, valid)

proc call*(call_593128: Call_GetCreateDBInstance_593090; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-09-09";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "CreateDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil; Port: int = 0;
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
  ##   Tags: JArray
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
  var query_593129 = newJObject()
  add(query_593129, "Version", newJString(Version))
  add(query_593129, "DBName", newJString(DBName))
  add(query_593129, "Engine", newJString(Engine))
  add(query_593129, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593129, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_593129.add "Tags", Tags
  add(query_593129, "LicenseModel", newJString(LicenseModel))
  add(query_593129, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593129, "MasterUsername", newJString(MasterUsername))
  add(query_593129, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_593129, "EngineVersion", newJString(EngineVersion))
  add(query_593129, "Action", newJString(Action))
  add(query_593129, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_593129.add "DBSecurityGroups", DBSecurityGroups
  add(query_593129, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_593129.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_593129, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_593129, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593129, "OptionGroupName", newJString(OptionGroupName))
  add(query_593129, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593129, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_593129, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593129, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_593129, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_593129, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593129, "Iops", newJInt(Iops))
  add(query_593129, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_593128.call(nil, query_593129, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_593090(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_593091, base: "/",
    url: url_GetCreateDBInstance_593092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_593197 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBInstanceReadReplica_593199(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_593198(path: JsonNode;
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
  var valid_593200 = query.getOrDefault("Action")
  valid_593200 = validateParameter(valid_593200, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593200 != nil:
    section.add "Action", valid_593200
  var valid_593201 = query.getOrDefault("Version")
  valid_593201 = validateParameter(valid_593201, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593201 != nil:
    section.add "Version", valid_593201
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
  var valid_593202 = header.getOrDefault("X-Amz-Signature")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Signature", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Content-Sha256", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Date")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Date", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Credential")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Credential", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Security-Token")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Security-Token", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Algorithm")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Algorithm", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-SignedHeaders", valid_593208
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
  section = newJObject()
  var valid_593209 = formData.getOrDefault("Port")
  valid_593209 = validateParameter(valid_593209, JInt, required = false, default = nil)
  if valid_593209 != nil:
    section.add "Port", valid_593209
  var valid_593210 = formData.getOrDefault("DBInstanceClass")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "DBInstanceClass", valid_593210
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_593211 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_593211 = validateParameter(valid_593211, JString, required = true,
                                 default = nil)
  if valid_593211 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593211
  var valid_593212 = formData.getOrDefault("AvailabilityZone")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "AvailabilityZone", valid_593212
  var valid_593213 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_593213 = validateParameter(valid_593213, JBool, required = false, default = nil)
  if valid_593213 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593213
  var valid_593214 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = nil)
  if valid_593214 != nil:
    section.add "DBInstanceIdentifier", valid_593214
  var valid_593215 = formData.getOrDefault("Iops")
  valid_593215 = validateParameter(valid_593215, JInt, required = false, default = nil)
  if valid_593215 != nil:
    section.add "Iops", valid_593215
  var valid_593216 = formData.getOrDefault("PubliclyAccessible")
  valid_593216 = validateParameter(valid_593216, JBool, required = false, default = nil)
  if valid_593216 != nil:
    section.add "PubliclyAccessible", valid_593216
  var valid_593217 = formData.getOrDefault("Tags")
  valid_593217 = validateParameter(valid_593217, JArray, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "Tags", valid_593217
  var valid_593218 = formData.getOrDefault("DBSubnetGroupName")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "DBSubnetGroupName", valid_593218
  var valid_593219 = formData.getOrDefault("OptionGroupName")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "OptionGroupName", valid_593219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593220: Call_PostCreateDBInstanceReadReplica_593197;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593220.validator(path, query, header, formData, body)
  let scheme = call_593220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593220.url(scheme.get, call_593220.host, call_593220.base,
                         call_593220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593220, url, valid)

proc call*(call_593221: Call_PostCreateDBInstanceReadReplica_593197;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
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
  var query_593222 = newJObject()
  var formData_593223 = newJObject()
  add(formData_593223, "Port", newJInt(Port))
  add(formData_593223, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_593223, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_593223, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_593223, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_593223, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593223, "Iops", newJInt(Iops))
  add(formData_593223, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593222, "Action", newJString(Action))
  if Tags != nil:
    formData_593223.add "Tags", Tags
  add(formData_593223, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_593223, "OptionGroupName", newJString(OptionGroupName))
  add(query_593222, "Version", newJString(Version))
  result = call_593221.call(nil, query_593222, nil, formData_593223, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_593197(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_593198, base: "/",
    url: url_PostCreateDBInstanceReadReplica_593199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_593171 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBInstanceReadReplica_593173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_593172(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
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
  var valid_593174 = query.getOrDefault("Tags")
  valid_593174 = validateParameter(valid_593174, JArray, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "Tags", valid_593174
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593175 = query.getOrDefault("DBInstanceIdentifier")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = nil)
  if valid_593175 != nil:
    section.add "DBInstanceIdentifier", valid_593175
  var valid_593176 = query.getOrDefault("Action")
  valid_593176 = validateParameter(valid_593176, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_593176 != nil:
    section.add "Action", valid_593176
  var valid_593177 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_593177 = validateParameter(valid_593177, JString, required = true,
                                 default = nil)
  if valid_593177 != nil:
    section.add "SourceDBInstanceIdentifier", valid_593177
  var valid_593178 = query.getOrDefault("Port")
  valid_593178 = validateParameter(valid_593178, JInt, required = false, default = nil)
  if valid_593178 != nil:
    section.add "Port", valid_593178
  var valid_593179 = query.getOrDefault("AvailabilityZone")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "AvailabilityZone", valid_593179
  var valid_593180 = query.getOrDefault("OptionGroupName")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "OptionGroupName", valid_593180
  var valid_593181 = query.getOrDefault("DBSubnetGroupName")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "DBSubnetGroupName", valid_593181
  var valid_593182 = query.getOrDefault("Version")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593182 != nil:
    section.add "Version", valid_593182
  var valid_593183 = query.getOrDefault("DBInstanceClass")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "DBInstanceClass", valid_593183
  var valid_593184 = query.getOrDefault("PubliclyAccessible")
  valid_593184 = validateParameter(valid_593184, JBool, required = false, default = nil)
  if valid_593184 != nil:
    section.add "PubliclyAccessible", valid_593184
  var valid_593185 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_593185 = validateParameter(valid_593185, JBool, required = false, default = nil)
  if valid_593185 != nil:
    section.add "AutoMinorVersionUpgrade", valid_593185
  var valid_593186 = query.getOrDefault("Iops")
  valid_593186 = validateParameter(valid_593186, JInt, required = false, default = nil)
  if valid_593186 != nil:
    section.add "Iops", valid_593186
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
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Security-Token")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Security-Token", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Algorithm")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Algorithm", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-SignedHeaders", valid_593193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_GetCreateDBInstanceReadReplica_593171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_GetCreateDBInstanceReadReplica_593171;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBInstanceReadReplica";
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
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
  var query_593196 = newJObject()
  if Tags != nil:
    query_593196.add "Tags", Tags
  add(query_593196, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593196, "Action", newJString(Action))
  add(query_593196, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_593196, "Port", newJInt(Port))
  add(query_593196, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_593196, "OptionGroupName", newJString(OptionGroupName))
  add(query_593196, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593196, "Version", newJString(Version))
  add(query_593196, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_593196, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_593196, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_593196, "Iops", newJInt(Iops))
  result = call_593195.call(nil, query_593196, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_593171(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_593172, base: "/",
    url: url_GetCreateDBInstanceReadReplica_593173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_593243 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBParameterGroup_593245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_593244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593246 = query.getOrDefault("Action")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593246 != nil:
    section.add "Action", valid_593246
  var valid_593247 = query.getOrDefault("Version")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593247 != nil:
    section.add "Version", valid_593247
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
  var valid_593248 = header.getOrDefault("X-Amz-Signature")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Signature", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Content-Sha256", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Date")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Date", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Credential")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Credential", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Security-Token")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Security-Token", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Algorithm")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Algorithm", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-SignedHeaders", valid_593254
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_593255 = formData.getOrDefault("Description")
  valid_593255 = validateParameter(valid_593255, JString, required = true,
                                 default = nil)
  if valid_593255 != nil:
    section.add "Description", valid_593255
  var valid_593256 = formData.getOrDefault("DBParameterGroupName")
  valid_593256 = validateParameter(valid_593256, JString, required = true,
                                 default = nil)
  if valid_593256 != nil:
    section.add "DBParameterGroupName", valid_593256
  var valid_593257 = formData.getOrDefault("Tags")
  valid_593257 = validateParameter(valid_593257, JArray, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "Tags", valid_593257
  var valid_593258 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593258 = validateParameter(valid_593258, JString, required = true,
                                 default = nil)
  if valid_593258 != nil:
    section.add "DBParameterGroupFamily", valid_593258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593259: Call_PostCreateDBParameterGroup_593243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593259.validator(path, query, header, formData, body)
  let scheme = call_593259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593259.url(scheme.get, call_593259.host, call_593259.base,
                         call_593259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593259, url, valid)

proc call*(call_593260: Call_PostCreateDBParameterGroup_593243;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_593261 = newJObject()
  var formData_593262 = newJObject()
  add(formData_593262, "Description", newJString(Description))
  add(formData_593262, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593261, "Action", newJString(Action))
  if Tags != nil:
    formData_593262.add "Tags", Tags
  add(query_593261, "Version", newJString(Version))
  add(formData_593262, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593260.call(nil, query_593261, nil, formData_593262, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_593243(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_593244, base: "/",
    url: url_PostCreateDBParameterGroup_593245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_593224 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBParameterGroup_593226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_593225(path: JsonNode; query: JsonNode;
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
  var valid_593227 = query.getOrDefault("DBParameterGroupFamily")
  valid_593227 = validateParameter(valid_593227, JString, required = true,
                                 default = nil)
  if valid_593227 != nil:
    section.add "DBParameterGroupFamily", valid_593227
  var valid_593228 = query.getOrDefault("DBParameterGroupName")
  valid_593228 = validateParameter(valid_593228, JString, required = true,
                                 default = nil)
  if valid_593228 != nil:
    section.add "DBParameterGroupName", valid_593228
  var valid_593229 = query.getOrDefault("Tags")
  valid_593229 = validateParameter(valid_593229, JArray, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "Tags", valid_593229
  var valid_593230 = query.getOrDefault("Action")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_593230 != nil:
    section.add "Action", valid_593230
  var valid_593231 = query.getOrDefault("Description")
  valid_593231 = validateParameter(valid_593231, JString, required = true,
                                 default = nil)
  if valid_593231 != nil:
    section.add "Description", valid_593231
  var valid_593232 = query.getOrDefault("Version")
  valid_593232 = validateParameter(valid_593232, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593232 != nil:
    section.add "Version", valid_593232
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
  var valid_593233 = header.getOrDefault("X-Amz-Signature")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Signature", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Content-Sha256", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Date")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Date", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Credential")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Credential", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Security-Token")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Security-Token", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Algorithm")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Algorithm", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-SignedHeaders", valid_593239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593240: Call_GetCreateDBParameterGroup_593224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593240.validator(path, query, header, formData, body)
  let scheme = call_593240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593240.url(scheme.get, call_593240.host, call_593240.base,
                         call_593240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593240, url, valid)

proc call*(call_593241: Call_GetCreateDBParameterGroup_593224;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_593242 = newJObject()
  add(query_593242, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593242, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_593242.add "Tags", Tags
  add(query_593242, "Action", newJString(Action))
  add(query_593242, "Description", newJString(Description))
  add(query_593242, "Version", newJString(Version))
  result = call_593241.call(nil, query_593242, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_593224(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_593225, base: "/",
    url: url_GetCreateDBParameterGroup_593226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_593281 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSecurityGroup_593283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_593282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593284 = query.getOrDefault("Action")
  valid_593284 = validateParameter(valid_593284, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593284 != nil:
    section.add "Action", valid_593284
  var valid_593285 = query.getOrDefault("Version")
  valid_593285 = validateParameter(valid_593285, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593285 != nil:
    section.add "Version", valid_593285
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
  var valid_593286 = header.getOrDefault("X-Amz-Signature")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Signature", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Content-Sha256", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Date")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Date", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Credential")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Credential", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Security-Token")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Security-Token", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Algorithm")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Algorithm", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-SignedHeaders", valid_593292
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_593293 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = nil)
  if valid_593293 != nil:
    section.add "DBSecurityGroupDescription", valid_593293
  var valid_593294 = formData.getOrDefault("DBSecurityGroupName")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = nil)
  if valid_593294 != nil:
    section.add "DBSecurityGroupName", valid_593294
  var valid_593295 = formData.getOrDefault("Tags")
  valid_593295 = validateParameter(valid_593295, JArray, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "Tags", valid_593295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593296: Call_PostCreateDBSecurityGroup_593281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593296.validator(path, query, header, formData, body)
  let scheme = call_593296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593296.url(scheme.get, call_593296.host, call_593296.base,
                         call_593296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593296, url, valid)

proc call*(call_593297: Call_PostCreateDBSecurityGroup_593281;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593298 = newJObject()
  var formData_593299 = newJObject()
  add(formData_593299, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_593299, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593298, "Action", newJString(Action))
  if Tags != nil:
    formData_593299.add "Tags", Tags
  add(query_593298, "Version", newJString(Version))
  result = call_593297.call(nil, query_593298, nil, formData_593299, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_593281(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_593282, base: "/",
    url: url_PostCreateDBSecurityGroup_593283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_593263 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSecurityGroup_593265(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_593264(path: JsonNode; query: JsonNode;
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
  var valid_593266 = query.getOrDefault("DBSecurityGroupName")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = nil)
  if valid_593266 != nil:
    section.add "DBSecurityGroupName", valid_593266
  var valid_593267 = query.getOrDefault("Tags")
  valid_593267 = validateParameter(valid_593267, JArray, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "Tags", valid_593267
  var valid_593268 = query.getOrDefault("DBSecurityGroupDescription")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = nil)
  if valid_593268 != nil:
    section.add "DBSecurityGroupDescription", valid_593268
  var valid_593269 = query.getOrDefault("Action")
  valid_593269 = validateParameter(valid_593269, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_593269 != nil:
    section.add "Action", valid_593269
  var valid_593270 = query.getOrDefault("Version")
  valid_593270 = validateParameter(valid_593270, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593270 != nil:
    section.add "Version", valid_593270
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
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Algorithm")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Algorithm", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-SignedHeaders", valid_593277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593278: Call_GetCreateDBSecurityGroup_593263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593278.validator(path, query, header, formData, body)
  let scheme = call_593278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593278.url(scheme.get, call_593278.host, call_593278.base,
                         call_593278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593278, url, valid)

proc call*(call_593279: Call_GetCreateDBSecurityGroup_593263;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593280 = newJObject()
  add(query_593280, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_593280.add "Tags", Tags
  add(query_593280, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_593280, "Action", newJString(Action))
  add(query_593280, "Version", newJString(Version))
  result = call_593279.call(nil, query_593280, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_593263(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_593264, base: "/",
    url: url_GetCreateDBSecurityGroup_593265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_593318 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSnapshot_593320(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_593319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593321 = query.getOrDefault("Action")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593321 != nil:
    section.add "Action", valid_593321
  var valid_593322 = query.getOrDefault("Version")
  valid_593322 = validateParameter(valid_593322, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593322 != nil:
    section.add "Version", valid_593322
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
  var valid_593323 = header.getOrDefault("X-Amz-Signature")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Signature", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Content-Sha256", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Date")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Date", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Credential")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Credential", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Security-Token")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Security-Token", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Algorithm")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Algorithm", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-SignedHeaders", valid_593329
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593330 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = nil)
  if valid_593330 != nil:
    section.add "DBInstanceIdentifier", valid_593330
  var valid_593331 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593331 = validateParameter(valid_593331, JString, required = true,
                                 default = nil)
  if valid_593331 != nil:
    section.add "DBSnapshotIdentifier", valid_593331
  var valid_593332 = formData.getOrDefault("Tags")
  valid_593332 = validateParameter(valid_593332, JArray, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "Tags", valid_593332
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593333: Call_PostCreateDBSnapshot_593318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593333.validator(path, query, header, formData, body)
  let scheme = call_593333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593333.url(scheme.get, call_593333.host, call_593333.base,
                         call_593333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593333, url, valid)

proc call*(call_593334: Call_PostCreateDBSnapshot_593318;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_593335 = newJObject()
  var formData_593336 = newJObject()
  add(formData_593336, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593336, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593335, "Action", newJString(Action))
  if Tags != nil:
    formData_593336.add "Tags", Tags
  add(query_593335, "Version", newJString(Version))
  result = call_593334.call(nil, query_593335, nil, formData_593336, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_593318(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_593319, base: "/",
    url: url_PostCreateDBSnapshot_593320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_593300 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSnapshot_593302(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_593301(path: JsonNode; query: JsonNode;
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
  var valid_593303 = query.getOrDefault("Tags")
  valid_593303 = validateParameter(valid_593303, JArray, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "Tags", valid_593303
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593304 = query.getOrDefault("DBInstanceIdentifier")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = nil)
  if valid_593304 != nil:
    section.add "DBInstanceIdentifier", valid_593304
  var valid_593305 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = nil)
  if valid_593305 != nil:
    section.add "DBSnapshotIdentifier", valid_593305
  var valid_593306 = query.getOrDefault("Action")
  valid_593306 = validateParameter(valid_593306, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_593306 != nil:
    section.add "Action", valid_593306
  var valid_593307 = query.getOrDefault("Version")
  valid_593307 = validateParameter(valid_593307, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593307 != nil:
    section.add "Version", valid_593307
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
  var valid_593308 = header.getOrDefault("X-Amz-Signature")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Signature", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Content-Sha256", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Date")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Date", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Credential")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Credential", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Security-Token")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Security-Token", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Algorithm")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Algorithm", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-SignedHeaders", valid_593314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593315: Call_GetCreateDBSnapshot_593300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593315.validator(path, query, header, formData, body)
  let scheme = call_593315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593315.url(scheme.get, call_593315.host, call_593315.base,
                         call_593315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593315, url, valid)

proc call*(call_593316: Call_GetCreateDBSnapshot_593300;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593317 = newJObject()
  if Tags != nil:
    query_593317.add "Tags", Tags
  add(query_593317, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593317, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593317, "Action", newJString(Action))
  add(query_593317, "Version", newJString(Version))
  result = call_593316.call(nil, query_593317, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_593300(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_593301, base: "/",
    url: url_GetCreateDBSnapshot_593302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_593356 = ref object of OpenApiRestCall_592348
proc url_PostCreateDBSubnetGroup_593358(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_593357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593359 = query.getOrDefault("Action")
  valid_593359 = validateParameter(valid_593359, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593359 != nil:
    section.add "Action", valid_593359
  var valid_593360 = query.getOrDefault("Version")
  valid_593360 = validateParameter(valid_593360, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593360 != nil:
    section.add "Version", valid_593360
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
  var valid_593361 = header.getOrDefault("X-Amz-Signature")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Signature", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Content-Sha256", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Date")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Date", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Credential")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Credential", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Security-Token")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Security-Token", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Algorithm")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Algorithm", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-SignedHeaders", valid_593367
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_593368 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_593368 = validateParameter(valid_593368, JString, required = true,
                                 default = nil)
  if valid_593368 != nil:
    section.add "DBSubnetGroupDescription", valid_593368
  var valid_593369 = formData.getOrDefault("Tags")
  valid_593369 = validateParameter(valid_593369, JArray, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "Tags", valid_593369
  var valid_593370 = formData.getOrDefault("DBSubnetGroupName")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = nil)
  if valid_593370 != nil:
    section.add "DBSubnetGroupName", valid_593370
  var valid_593371 = formData.getOrDefault("SubnetIds")
  valid_593371 = validateParameter(valid_593371, JArray, required = true, default = nil)
  if valid_593371 != nil:
    section.add "SubnetIds", valid_593371
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593372: Call_PostCreateDBSubnetGroup_593356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593372.validator(path, query, header, formData, body)
  let scheme = call_593372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593372.url(scheme.get, call_593372.host, call_593372.base,
                         call_593372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593372, url, valid)

proc call*(call_593373: Call_PostCreateDBSubnetGroup_593356;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_593374 = newJObject()
  var formData_593375 = newJObject()
  add(formData_593375, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593374, "Action", newJString(Action))
  if Tags != nil:
    formData_593375.add "Tags", Tags
  add(formData_593375, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593374, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_593375.add "SubnetIds", SubnetIds
  result = call_593373.call(nil, query_593374, nil, formData_593375, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_593356(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_593357, base: "/",
    url: url_PostCreateDBSubnetGroup_593358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_593337 = ref object of OpenApiRestCall_592348
proc url_GetCreateDBSubnetGroup_593339(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_593338(path: JsonNode; query: JsonNode;
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
  var valid_593340 = query.getOrDefault("Tags")
  valid_593340 = validateParameter(valid_593340, JArray, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "Tags", valid_593340
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_593341 = query.getOrDefault("SubnetIds")
  valid_593341 = validateParameter(valid_593341, JArray, required = true, default = nil)
  if valid_593341 != nil:
    section.add "SubnetIds", valid_593341
  var valid_593342 = query.getOrDefault("Action")
  valid_593342 = validateParameter(valid_593342, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_593342 != nil:
    section.add "Action", valid_593342
  var valid_593343 = query.getOrDefault("DBSubnetGroupDescription")
  valid_593343 = validateParameter(valid_593343, JString, required = true,
                                 default = nil)
  if valid_593343 != nil:
    section.add "DBSubnetGroupDescription", valid_593343
  var valid_593344 = query.getOrDefault("DBSubnetGroupName")
  valid_593344 = validateParameter(valid_593344, JString, required = true,
                                 default = nil)
  if valid_593344 != nil:
    section.add "DBSubnetGroupName", valid_593344
  var valid_593345 = query.getOrDefault("Version")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593353: Call_GetCreateDBSubnetGroup_593337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593353.validator(path, query, header, formData, body)
  let scheme = call_593353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593353.url(scheme.get, call_593353.host, call_593353.base,
                         call_593353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593353, url, valid)

proc call*(call_593354: Call_GetCreateDBSubnetGroup_593337; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593355 = newJObject()
  if Tags != nil:
    query_593355.add "Tags", Tags
  if SubnetIds != nil:
    query_593355.add "SubnetIds", SubnetIds
  add(query_593355, "Action", newJString(Action))
  add(query_593355, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_593355, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593355, "Version", newJString(Version))
  result = call_593354.call(nil, query_593355, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_593337(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_593338, base: "/",
    url: url_GetCreateDBSubnetGroup_593339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_593398 = ref object of OpenApiRestCall_592348
proc url_PostCreateEventSubscription_593400(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_593399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593401 = query.getOrDefault("Action")
  valid_593401 = validateParameter(valid_593401, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593401 != nil:
    section.add "Action", valid_593401
  var valid_593402 = query.getOrDefault("Version")
  valid_593402 = validateParameter(valid_593402, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593402 != nil:
    section.add "Version", valid_593402
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
  var valid_593403 = header.getOrDefault("X-Amz-Signature")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Signature", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Content-Sha256", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Date")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Date", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Credential")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Credential", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Security-Token")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Security-Token", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-Algorithm")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-Algorithm", valid_593408
  var valid_593409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-SignedHeaders", valid_593409
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
  var valid_593410 = formData.getOrDefault("SourceIds")
  valid_593410 = validateParameter(valid_593410, JArray, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "SourceIds", valid_593410
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_593411 = formData.getOrDefault("SnsTopicArn")
  valid_593411 = validateParameter(valid_593411, JString, required = true,
                                 default = nil)
  if valid_593411 != nil:
    section.add "SnsTopicArn", valid_593411
  var valid_593412 = formData.getOrDefault("Enabled")
  valid_593412 = validateParameter(valid_593412, JBool, required = false, default = nil)
  if valid_593412 != nil:
    section.add "Enabled", valid_593412
  var valid_593413 = formData.getOrDefault("SubscriptionName")
  valid_593413 = validateParameter(valid_593413, JString, required = true,
                                 default = nil)
  if valid_593413 != nil:
    section.add "SubscriptionName", valid_593413
  var valid_593414 = formData.getOrDefault("SourceType")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "SourceType", valid_593414
  var valid_593415 = formData.getOrDefault("EventCategories")
  valid_593415 = validateParameter(valid_593415, JArray, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "EventCategories", valid_593415
  var valid_593416 = formData.getOrDefault("Tags")
  valid_593416 = validateParameter(valid_593416, JArray, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "Tags", valid_593416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593417: Call_PostCreateEventSubscription_593398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593417.validator(path, query, header, formData, body)
  let scheme = call_593417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593417.url(scheme.get, call_593417.host, call_593417.base,
                         call_593417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593417, url, valid)

proc call*(call_593418: Call_PostCreateEventSubscription_593398;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
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
  var query_593419 = newJObject()
  var formData_593420 = newJObject()
  if SourceIds != nil:
    formData_593420.add "SourceIds", SourceIds
  add(formData_593420, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_593420, "Enabled", newJBool(Enabled))
  add(formData_593420, "SubscriptionName", newJString(SubscriptionName))
  add(formData_593420, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_593420.add "EventCategories", EventCategories
  add(query_593419, "Action", newJString(Action))
  if Tags != nil:
    formData_593420.add "Tags", Tags
  add(query_593419, "Version", newJString(Version))
  result = call_593418.call(nil, query_593419, nil, formData_593420, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_593398(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_593399, base: "/",
    url: url_PostCreateEventSubscription_593400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_593376 = ref object of OpenApiRestCall_592348
proc url_GetCreateEventSubscription_593378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_593377(path: JsonNode; query: JsonNode;
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
  var valid_593379 = query.getOrDefault("Tags")
  valid_593379 = validateParameter(valid_593379, JArray, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "Tags", valid_593379
  var valid_593380 = query.getOrDefault("SourceType")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "SourceType", valid_593380
  var valid_593381 = query.getOrDefault("Enabled")
  valid_593381 = validateParameter(valid_593381, JBool, required = false, default = nil)
  if valid_593381 != nil:
    section.add "Enabled", valid_593381
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_593382 = query.getOrDefault("SubscriptionName")
  valid_593382 = validateParameter(valid_593382, JString, required = true,
                                 default = nil)
  if valid_593382 != nil:
    section.add "SubscriptionName", valid_593382
  var valid_593383 = query.getOrDefault("EventCategories")
  valid_593383 = validateParameter(valid_593383, JArray, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "EventCategories", valid_593383
  var valid_593384 = query.getOrDefault("SourceIds")
  valid_593384 = validateParameter(valid_593384, JArray, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "SourceIds", valid_593384
  var valid_593385 = query.getOrDefault("Action")
  valid_593385 = validateParameter(valid_593385, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_593385 != nil:
    section.add "Action", valid_593385
  var valid_593386 = query.getOrDefault("SnsTopicArn")
  valid_593386 = validateParameter(valid_593386, JString, required = true,
                                 default = nil)
  if valid_593386 != nil:
    section.add "SnsTopicArn", valid_593386
  var valid_593387 = query.getOrDefault("Version")
  valid_593387 = validateParameter(valid_593387, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593387 != nil:
    section.add "Version", valid_593387
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
  var valid_593388 = header.getOrDefault("X-Amz-Signature")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Signature", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Content-Sha256", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Date")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Date", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Credential")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Credential", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Security-Token")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Security-Token", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Algorithm")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Algorithm", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-SignedHeaders", valid_593394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593395: Call_GetCreateEventSubscription_593376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593395.validator(path, query, header, formData, body)
  let scheme = call_593395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593395.url(scheme.get, call_593395.host, call_593395.base,
                         call_593395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593395, url, valid)

proc call*(call_593396: Call_GetCreateEventSubscription_593376;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-09-09"): Recallable =
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
  var query_593397 = newJObject()
  if Tags != nil:
    query_593397.add "Tags", Tags
  add(query_593397, "SourceType", newJString(SourceType))
  add(query_593397, "Enabled", newJBool(Enabled))
  add(query_593397, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_593397.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_593397.add "SourceIds", SourceIds
  add(query_593397, "Action", newJString(Action))
  add(query_593397, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_593397, "Version", newJString(Version))
  result = call_593396.call(nil, query_593397, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_593376(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_593377, base: "/",
    url: url_GetCreateEventSubscription_593378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_593441 = ref object of OpenApiRestCall_592348
proc url_PostCreateOptionGroup_593443(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_593442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593444 = query.getOrDefault("Action")
  valid_593444 = validateParameter(valid_593444, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593444 != nil:
    section.add "Action", valid_593444
  var valid_593445 = query.getOrDefault("Version")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593445 != nil:
    section.add "Version", valid_593445
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
  var valid_593446 = header.getOrDefault("X-Amz-Signature")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Signature", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Content-Sha256", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Date")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Date", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Credential")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Credential", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Security-Token")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Security-Token", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Algorithm")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Algorithm", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-SignedHeaders", valid_593452
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_593453 = formData.getOrDefault("OptionGroupDescription")
  valid_593453 = validateParameter(valid_593453, JString, required = true,
                                 default = nil)
  if valid_593453 != nil:
    section.add "OptionGroupDescription", valid_593453
  var valid_593454 = formData.getOrDefault("EngineName")
  valid_593454 = validateParameter(valid_593454, JString, required = true,
                                 default = nil)
  if valid_593454 != nil:
    section.add "EngineName", valid_593454
  var valid_593455 = formData.getOrDefault("MajorEngineVersion")
  valid_593455 = validateParameter(valid_593455, JString, required = true,
                                 default = nil)
  if valid_593455 != nil:
    section.add "MajorEngineVersion", valid_593455
  var valid_593456 = formData.getOrDefault("Tags")
  valid_593456 = validateParameter(valid_593456, JArray, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "Tags", valid_593456
  var valid_593457 = formData.getOrDefault("OptionGroupName")
  valid_593457 = validateParameter(valid_593457, JString, required = true,
                                 default = nil)
  if valid_593457 != nil:
    section.add "OptionGroupName", valid_593457
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593458: Call_PostCreateOptionGroup_593441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593458.validator(path, query, header, formData, body)
  let scheme = call_593458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593458.url(scheme.get, call_593458.host, call_593458.base,
                         call_593458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593458, url, valid)

proc call*(call_593459: Call_PostCreateOptionGroup_593441;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593460 = newJObject()
  var formData_593461 = newJObject()
  add(formData_593461, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_593461, "EngineName", newJString(EngineName))
  add(formData_593461, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_593460, "Action", newJString(Action))
  if Tags != nil:
    formData_593461.add "Tags", Tags
  add(formData_593461, "OptionGroupName", newJString(OptionGroupName))
  add(query_593460, "Version", newJString(Version))
  result = call_593459.call(nil, query_593460, nil, formData_593461, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_593441(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_593442, base: "/",
    url: url_PostCreateOptionGroup_593443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_593421 = ref object of OpenApiRestCall_592348
proc url_GetCreateOptionGroup_593423(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_593422(path: JsonNode; query: JsonNode;
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
  var valid_593424 = query.getOrDefault("EngineName")
  valid_593424 = validateParameter(valid_593424, JString, required = true,
                                 default = nil)
  if valid_593424 != nil:
    section.add "EngineName", valid_593424
  var valid_593425 = query.getOrDefault("OptionGroupDescription")
  valid_593425 = validateParameter(valid_593425, JString, required = true,
                                 default = nil)
  if valid_593425 != nil:
    section.add "OptionGroupDescription", valid_593425
  var valid_593426 = query.getOrDefault("Tags")
  valid_593426 = validateParameter(valid_593426, JArray, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "Tags", valid_593426
  var valid_593427 = query.getOrDefault("Action")
  valid_593427 = validateParameter(valid_593427, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_593427 != nil:
    section.add "Action", valid_593427
  var valid_593428 = query.getOrDefault("OptionGroupName")
  valid_593428 = validateParameter(valid_593428, JString, required = true,
                                 default = nil)
  if valid_593428 != nil:
    section.add "OptionGroupName", valid_593428
  var valid_593429 = query.getOrDefault("Version")
  valid_593429 = validateParameter(valid_593429, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593429 != nil:
    section.add "Version", valid_593429
  var valid_593430 = query.getOrDefault("MajorEngineVersion")
  valid_593430 = validateParameter(valid_593430, JString, required = true,
                                 default = nil)
  if valid_593430 != nil:
    section.add "MajorEngineVersion", valid_593430
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
  var valid_593431 = header.getOrDefault("X-Amz-Signature")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Signature", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Content-Sha256", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Date")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Date", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Credential")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Credential", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Security-Token")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Security-Token", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Algorithm")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Algorithm", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-SignedHeaders", valid_593437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593438: Call_GetCreateOptionGroup_593421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593438.validator(path, query, header, formData, body)
  let scheme = call_593438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593438.url(scheme.get, call_593438.host, call_593438.base,
                         call_593438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593438, url, valid)

proc call*(call_593439: Call_GetCreateOptionGroup_593421; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_593440 = newJObject()
  add(query_593440, "EngineName", newJString(EngineName))
  add(query_593440, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_593440.add "Tags", Tags
  add(query_593440, "Action", newJString(Action))
  add(query_593440, "OptionGroupName", newJString(OptionGroupName))
  add(query_593440, "Version", newJString(Version))
  add(query_593440, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_593439.call(nil, query_593440, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_593421(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_593422, base: "/",
    url: url_GetCreateOptionGroup_593423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_593480 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBInstance_593482(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_593481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593483 = query.getOrDefault("Action")
  valid_593483 = validateParameter(valid_593483, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593483 != nil:
    section.add "Action", valid_593483
  var valid_593484 = query.getOrDefault("Version")
  valid_593484 = validateParameter(valid_593484, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593492 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593492 = validateParameter(valid_593492, JString, required = true,
                                 default = nil)
  if valid_593492 != nil:
    section.add "DBInstanceIdentifier", valid_593492
  var valid_593493 = formData.getOrDefault("SkipFinalSnapshot")
  valid_593493 = validateParameter(valid_593493, JBool, required = false, default = nil)
  if valid_593493 != nil:
    section.add "SkipFinalSnapshot", valid_593493
  var valid_593494 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593495: Call_PostDeleteDBInstance_593480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593495.validator(path, query, header, formData, body)
  let scheme = call_593495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593495.url(scheme.get, call_593495.host, call_593495.base,
                         call_593495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593495, url, valid)

proc call*(call_593496: Call_PostDeleteDBInstance_593480;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_593497 = newJObject()
  var formData_593498 = newJObject()
  add(formData_593498, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593497, "Action", newJString(Action))
  add(formData_593498, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_593498, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_593497, "Version", newJString(Version))
  result = call_593496.call(nil, query_593497, nil, formData_593498, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_593480(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_593481, base: "/",
    url: url_PostDeleteDBInstance_593482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_593462 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBInstance_593464(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_593463(path: JsonNode; query: JsonNode;
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
  var valid_593465 = query.getOrDefault("DBInstanceIdentifier")
  valid_593465 = validateParameter(valid_593465, JString, required = true,
                                 default = nil)
  if valid_593465 != nil:
    section.add "DBInstanceIdentifier", valid_593465
  var valid_593466 = query.getOrDefault("SkipFinalSnapshot")
  valid_593466 = validateParameter(valid_593466, JBool, required = false, default = nil)
  if valid_593466 != nil:
    section.add "SkipFinalSnapshot", valid_593466
  var valid_593467 = query.getOrDefault("Action")
  valid_593467 = validateParameter(valid_593467, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_593467 != nil:
    section.add "Action", valid_593467
  var valid_593468 = query.getOrDefault("Version")
  valid_593468 = validateParameter(valid_593468, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593468 != nil:
    section.add "Version", valid_593468
  var valid_593469 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_593469
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
  var valid_593470 = header.getOrDefault("X-Amz-Signature")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Signature", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Content-Sha256", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Date")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Date", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Credential")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Credential", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Security-Token")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Security-Token", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Algorithm")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Algorithm", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-SignedHeaders", valid_593476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593477: Call_GetDeleteDBInstance_593462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593477.validator(path, query, header, formData, body)
  let scheme = call_593477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593477.url(scheme.get, call_593477.host, call_593477.base,
                         call_593477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593477, url, valid)

proc call*(call_593478: Call_GetDeleteDBInstance_593462;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_593479 = newJObject()
  add(query_593479, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593479, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_593479, "Action", newJString(Action))
  add(query_593479, "Version", newJString(Version))
  add(query_593479, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_593478.call(nil, query_593479, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_593462(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_593463, base: "/",
    url: url_GetDeleteDBInstance_593464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_593515 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBParameterGroup_593517(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_593516(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593518 = query.getOrDefault("Action")
  valid_593518 = validateParameter(valid_593518, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593518 != nil:
    section.add "Action", valid_593518
  var valid_593519 = query.getOrDefault("Version")
  valid_593519 = validateParameter(valid_593519, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593519 != nil:
    section.add "Version", valid_593519
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
  var valid_593520 = header.getOrDefault("X-Amz-Signature")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Signature", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Content-Sha256", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Date")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Date", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Credential")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Credential", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Security-Token")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Security-Token", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Algorithm")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Algorithm", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-SignedHeaders", valid_593526
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593527 = formData.getOrDefault("DBParameterGroupName")
  valid_593527 = validateParameter(valid_593527, JString, required = true,
                                 default = nil)
  if valid_593527 != nil:
    section.add "DBParameterGroupName", valid_593527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593528: Call_PostDeleteDBParameterGroup_593515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593528.validator(path, query, header, formData, body)
  let scheme = call_593528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593528.url(scheme.get, call_593528.host, call_593528.base,
                         call_593528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593528, url, valid)

proc call*(call_593529: Call_PostDeleteDBParameterGroup_593515;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593530 = newJObject()
  var formData_593531 = newJObject()
  add(formData_593531, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593530, "Action", newJString(Action))
  add(query_593530, "Version", newJString(Version))
  result = call_593529.call(nil, query_593530, nil, formData_593531, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_593515(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_593516, base: "/",
    url: url_PostDeleteDBParameterGroup_593517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_593499 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBParameterGroup_593501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_593500(path: JsonNode; query: JsonNode;
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
  var valid_593502 = query.getOrDefault("DBParameterGroupName")
  valid_593502 = validateParameter(valid_593502, JString, required = true,
                                 default = nil)
  if valid_593502 != nil:
    section.add "DBParameterGroupName", valid_593502
  var valid_593503 = query.getOrDefault("Action")
  valid_593503 = validateParameter(valid_593503, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_593503 != nil:
    section.add "Action", valid_593503
  var valid_593504 = query.getOrDefault("Version")
  valid_593504 = validateParameter(valid_593504, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593504 != nil:
    section.add "Version", valid_593504
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
  var valid_593505 = header.getOrDefault("X-Amz-Signature")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Signature", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Content-Sha256", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Date")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Date", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Credential")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Credential", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Security-Token")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Security-Token", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Algorithm")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Algorithm", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-SignedHeaders", valid_593511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593512: Call_GetDeleteDBParameterGroup_593499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593512.validator(path, query, header, formData, body)
  let scheme = call_593512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593512.url(scheme.get, call_593512.host, call_593512.base,
                         call_593512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593512, url, valid)

proc call*(call_593513: Call_GetDeleteDBParameterGroup_593499;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593514 = newJObject()
  add(query_593514, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593514, "Action", newJString(Action))
  add(query_593514, "Version", newJString(Version))
  result = call_593513.call(nil, query_593514, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_593499(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_593500, base: "/",
    url: url_GetDeleteDBParameterGroup_593501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_593548 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSecurityGroup_593550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_593549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593551 = query.getOrDefault("Action")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593551 != nil:
    section.add "Action", valid_593551
  var valid_593552 = query.getOrDefault("Version")
  valid_593552 = validateParameter(valid_593552, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593552 != nil:
    section.add "Version", valid_593552
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
  var valid_593553 = header.getOrDefault("X-Amz-Signature")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Signature", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Content-Sha256", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Date")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Date", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Credential")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Credential", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Security-Token")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Security-Token", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Algorithm")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Algorithm", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-SignedHeaders", valid_593559
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_593560 = formData.getOrDefault("DBSecurityGroupName")
  valid_593560 = validateParameter(valid_593560, JString, required = true,
                                 default = nil)
  if valid_593560 != nil:
    section.add "DBSecurityGroupName", valid_593560
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593561: Call_PostDeleteDBSecurityGroup_593548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593561.validator(path, query, header, formData, body)
  let scheme = call_593561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593561.url(scheme.get, call_593561.host, call_593561.base,
                         call_593561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593561, url, valid)

proc call*(call_593562: Call_PostDeleteDBSecurityGroup_593548;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593563 = newJObject()
  var formData_593564 = newJObject()
  add(formData_593564, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593563, "Action", newJString(Action))
  add(query_593563, "Version", newJString(Version))
  result = call_593562.call(nil, query_593563, nil, formData_593564, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_593548(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_593549, base: "/",
    url: url_PostDeleteDBSecurityGroup_593550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_593532 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSecurityGroup_593534(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_593533(path: JsonNode; query: JsonNode;
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
  var valid_593535 = query.getOrDefault("DBSecurityGroupName")
  valid_593535 = validateParameter(valid_593535, JString, required = true,
                                 default = nil)
  if valid_593535 != nil:
    section.add "DBSecurityGroupName", valid_593535
  var valid_593536 = query.getOrDefault("Action")
  valid_593536 = validateParameter(valid_593536, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_593536 != nil:
    section.add "Action", valid_593536
  var valid_593537 = query.getOrDefault("Version")
  valid_593537 = validateParameter(valid_593537, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593537 != nil:
    section.add "Version", valid_593537
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
  var valid_593538 = header.getOrDefault("X-Amz-Signature")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Signature", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Content-Sha256", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Date")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Date", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Credential")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Credential", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Security-Token")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Security-Token", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Algorithm")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Algorithm", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-SignedHeaders", valid_593544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593545: Call_GetDeleteDBSecurityGroup_593532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593545.validator(path, query, header, formData, body)
  let scheme = call_593545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593545.url(scheme.get, call_593545.host, call_593545.base,
                         call_593545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593545, url, valid)

proc call*(call_593546: Call_GetDeleteDBSecurityGroup_593532;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593547 = newJObject()
  add(query_593547, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593547, "Action", newJString(Action))
  add(query_593547, "Version", newJString(Version))
  result = call_593546.call(nil, query_593547, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_593532(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_593533, base: "/",
    url: url_GetDeleteDBSecurityGroup_593534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_593581 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSnapshot_593583(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_593582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593584 = query.getOrDefault("Action")
  valid_593584 = validateParameter(valid_593584, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593584 != nil:
    section.add "Action", valid_593584
  var valid_593585 = query.getOrDefault("Version")
  valid_593585 = validateParameter(valid_593585, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593585 != nil:
    section.add "Version", valid_593585
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
  var valid_593586 = header.getOrDefault("X-Amz-Signature")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Signature", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Content-Sha256", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Date")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Date", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Credential")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Credential", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Security-Token")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Security-Token", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Algorithm")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Algorithm", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-SignedHeaders", valid_593592
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_593593 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593593 = validateParameter(valid_593593, JString, required = true,
                                 default = nil)
  if valid_593593 != nil:
    section.add "DBSnapshotIdentifier", valid_593593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593594: Call_PostDeleteDBSnapshot_593581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593594.validator(path, query, header, formData, body)
  let scheme = call_593594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593594.url(scheme.get, call_593594.host, call_593594.base,
                         call_593594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593594, url, valid)

proc call*(call_593595: Call_PostDeleteDBSnapshot_593581;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593596 = newJObject()
  var formData_593597 = newJObject()
  add(formData_593597, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593596, "Action", newJString(Action))
  add(query_593596, "Version", newJString(Version))
  result = call_593595.call(nil, query_593596, nil, formData_593597, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_593581(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_593582, base: "/",
    url: url_PostDeleteDBSnapshot_593583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_593565 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSnapshot_593567(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_593566(path: JsonNode; query: JsonNode;
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
  var valid_593568 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593568 = validateParameter(valid_593568, JString, required = true,
                                 default = nil)
  if valid_593568 != nil:
    section.add "DBSnapshotIdentifier", valid_593568
  var valid_593569 = query.getOrDefault("Action")
  valid_593569 = validateParameter(valid_593569, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_593569 != nil:
    section.add "Action", valid_593569
  var valid_593570 = query.getOrDefault("Version")
  valid_593570 = validateParameter(valid_593570, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593578: Call_GetDeleteDBSnapshot_593565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593578.validator(path, query, header, formData, body)
  let scheme = call_593578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593578.url(scheme.get, call_593578.host, call_593578.base,
                         call_593578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593578, url, valid)

proc call*(call_593579: Call_GetDeleteDBSnapshot_593565;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593580 = newJObject()
  add(query_593580, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593580, "Action", newJString(Action))
  add(query_593580, "Version", newJString(Version))
  result = call_593579.call(nil, query_593580, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_593565(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_593566, base: "/",
    url: url_GetDeleteDBSnapshot_593567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_593614 = ref object of OpenApiRestCall_592348
proc url_PostDeleteDBSubnetGroup_593616(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_593615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593617 = query.getOrDefault("Action")
  valid_593617 = validateParameter(valid_593617, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593617 != nil:
    section.add "Action", valid_593617
  var valid_593618 = query.getOrDefault("Version")
  valid_593618 = validateParameter(valid_593618, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593618 != nil:
    section.add "Version", valid_593618
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
  var valid_593619 = header.getOrDefault("X-Amz-Signature")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Signature", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Content-Sha256", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Date")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Date", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Credential")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Credential", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Security-Token")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Security-Token", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Algorithm")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Algorithm", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-SignedHeaders", valid_593625
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_593626 = formData.getOrDefault("DBSubnetGroupName")
  valid_593626 = validateParameter(valid_593626, JString, required = true,
                                 default = nil)
  if valid_593626 != nil:
    section.add "DBSubnetGroupName", valid_593626
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593627: Call_PostDeleteDBSubnetGroup_593614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593627.validator(path, query, header, formData, body)
  let scheme = call_593627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593627.url(scheme.get, call_593627.host, call_593627.base,
                         call_593627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593627, url, valid)

proc call*(call_593628: Call_PostDeleteDBSubnetGroup_593614;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593629 = newJObject()
  var formData_593630 = newJObject()
  add(query_593629, "Action", newJString(Action))
  add(formData_593630, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593629, "Version", newJString(Version))
  result = call_593628.call(nil, query_593629, nil, formData_593630, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_593614(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_593615, base: "/",
    url: url_PostDeleteDBSubnetGroup_593616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_593598 = ref object of OpenApiRestCall_592348
proc url_GetDeleteDBSubnetGroup_593600(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_593599(path: JsonNode; query: JsonNode;
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
  var valid_593601 = query.getOrDefault("Action")
  valid_593601 = validateParameter(valid_593601, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_593601 != nil:
    section.add "Action", valid_593601
  var valid_593602 = query.getOrDefault("DBSubnetGroupName")
  valid_593602 = validateParameter(valid_593602, JString, required = true,
                                 default = nil)
  if valid_593602 != nil:
    section.add "DBSubnetGroupName", valid_593602
  var valid_593603 = query.getOrDefault("Version")
  valid_593603 = validateParameter(valid_593603, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593603 != nil:
    section.add "Version", valid_593603
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
  var valid_593604 = header.getOrDefault("X-Amz-Signature")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Signature", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Content-Sha256", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Date")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Date", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Credential")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Credential", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Security-Token")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Security-Token", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Algorithm")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Algorithm", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-SignedHeaders", valid_593610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593611: Call_GetDeleteDBSubnetGroup_593598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593611.validator(path, query, header, formData, body)
  let scheme = call_593611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593611.url(scheme.get, call_593611.host, call_593611.base,
                         call_593611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593611, url, valid)

proc call*(call_593612: Call_GetDeleteDBSubnetGroup_593598;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_593613 = newJObject()
  add(query_593613, "Action", newJString(Action))
  add(query_593613, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_593613, "Version", newJString(Version))
  result = call_593612.call(nil, query_593613, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_593598(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_593599, base: "/",
    url: url_GetDeleteDBSubnetGroup_593600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_593647 = ref object of OpenApiRestCall_592348
proc url_PostDeleteEventSubscription_593649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_593648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593650 = query.getOrDefault("Action")
  valid_593650 = validateParameter(valid_593650, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593650 != nil:
    section.add "Action", valid_593650
  var valid_593651 = query.getOrDefault("Version")
  valid_593651 = validateParameter(valid_593651, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593651 != nil:
    section.add "Version", valid_593651
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
  var valid_593652 = header.getOrDefault("X-Amz-Signature")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Signature", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Content-Sha256", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Date")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Date", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Credential")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Credential", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-Security-Token")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Security-Token", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Algorithm")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Algorithm", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-SignedHeaders", valid_593658
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_593659 = formData.getOrDefault("SubscriptionName")
  valid_593659 = validateParameter(valid_593659, JString, required = true,
                                 default = nil)
  if valid_593659 != nil:
    section.add "SubscriptionName", valid_593659
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593660: Call_PostDeleteEventSubscription_593647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593660.validator(path, query, header, formData, body)
  let scheme = call_593660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593660.url(scheme.get, call_593660.host, call_593660.base,
                         call_593660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593660, url, valid)

proc call*(call_593661: Call_PostDeleteEventSubscription_593647;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593662 = newJObject()
  var formData_593663 = newJObject()
  add(formData_593663, "SubscriptionName", newJString(SubscriptionName))
  add(query_593662, "Action", newJString(Action))
  add(query_593662, "Version", newJString(Version))
  result = call_593661.call(nil, query_593662, nil, formData_593663, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_593647(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_593648, base: "/",
    url: url_PostDeleteEventSubscription_593649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_593631 = ref object of OpenApiRestCall_592348
proc url_GetDeleteEventSubscription_593633(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_593632(path: JsonNode; query: JsonNode;
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
  var valid_593634 = query.getOrDefault("SubscriptionName")
  valid_593634 = validateParameter(valid_593634, JString, required = true,
                                 default = nil)
  if valid_593634 != nil:
    section.add "SubscriptionName", valid_593634
  var valid_593635 = query.getOrDefault("Action")
  valid_593635 = validateParameter(valid_593635, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_593635 != nil:
    section.add "Action", valid_593635
  var valid_593636 = query.getOrDefault("Version")
  valid_593636 = validateParameter(valid_593636, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593636 != nil:
    section.add "Version", valid_593636
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
  var valid_593637 = header.getOrDefault("X-Amz-Signature")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Signature", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Content-Sha256", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Date")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Date", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Credential")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Credential", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Security-Token")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Security-Token", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Algorithm")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Algorithm", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-SignedHeaders", valid_593643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593644: Call_GetDeleteEventSubscription_593631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593644.validator(path, query, header, formData, body)
  let scheme = call_593644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593644.url(scheme.get, call_593644.host, call_593644.base,
                         call_593644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593644, url, valid)

proc call*(call_593645: Call_GetDeleteEventSubscription_593631;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593646 = newJObject()
  add(query_593646, "SubscriptionName", newJString(SubscriptionName))
  add(query_593646, "Action", newJString(Action))
  add(query_593646, "Version", newJString(Version))
  result = call_593645.call(nil, query_593646, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_593631(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_593632, base: "/",
    url: url_GetDeleteEventSubscription_593633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_593680 = ref object of OpenApiRestCall_592348
proc url_PostDeleteOptionGroup_593682(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_593681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593683 = query.getOrDefault("Action")
  valid_593683 = validateParameter(valid_593683, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593683 != nil:
    section.add "Action", valid_593683
  var valid_593684 = query.getOrDefault("Version")
  valid_593684 = validateParameter(valid_593684, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593684 != nil:
    section.add "Version", valid_593684
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
  var valid_593685 = header.getOrDefault("X-Amz-Signature")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Signature", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Content-Sha256", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-Date")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-Date", valid_593687
  var valid_593688 = header.getOrDefault("X-Amz-Credential")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "X-Amz-Credential", valid_593688
  var valid_593689 = header.getOrDefault("X-Amz-Security-Token")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-Security-Token", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Algorithm")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Algorithm", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-SignedHeaders", valid_593691
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_593692 = formData.getOrDefault("OptionGroupName")
  valid_593692 = validateParameter(valid_593692, JString, required = true,
                                 default = nil)
  if valid_593692 != nil:
    section.add "OptionGroupName", valid_593692
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593693: Call_PostDeleteOptionGroup_593680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593693.validator(path, query, header, formData, body)
  let scheme = call_593693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593693.url(scheme.get, call_593693.host, call_593693.base,
                         call_593693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593693, url, valid)

proc call*(call_593694: Call_PostDeleteOptionGroup_593680; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593695 = newJObject()
  var formData_593696 = newJObject()
  add(query_593695, "Action", newJString(Action))
  add(formData_593696, "OptionGroupName", newJString(OptionGroupName))
  add(query_593695, "Version", newJString(Version))
  result = call_593694.call(nil, query_593695, nil, formData_593696, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_593680(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_593681, base: "/",
    url: url_PostDeleteOptionGroup_593682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_593664 = ref object of OpenApiRestCall_592348
proc url_GetDeleteOptionGroup_593666(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_593665(path: JsonNode; query: JsonNode;
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
  var valid_593667 = query.getOrDefault("Action")
  valid_593667 = validateParameter(valid_593667, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_593667 != nil:
    section.add "Action", valid_593667
  var valid_593668 = query.getOrDefault("OptionGroupName")
  valid_593668 = validateParameter(valid_593668, JString, required = true,
                                 default = nil)
  if valid_593668 != nil:
    section.add "OptionGroupName", valid_593668
  var valid_593669 = query.getOrDefault("Version")
  valid_593669 = validateParameter(valid_593669, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593669 != nil:
    section.add "Version", valid_593669
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
  var valid_593670 = header.getOrDefault("X-Amz-Signature")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Signature", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-Content-Sha256", valid_593671
  var valid_593672 = header.getOrDefault("X-Amz-Date")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-Date", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Credential")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Credential", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Security-Token")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Security-Token", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Algorithm")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Algorithm", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-SignedHeaders", valid_593676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593677: Call_GetDeleteOptionGroup_593664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593677.validator(path, query, header, formData, body)
  let scheme = call_593677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593677.url(scheme.get, call_593677.host, call_593677.base,
                         call_593677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593677, url, valid)

proc call*(call_593678: Call_GetDeleteOptionGroup_593664; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_593679 = newJObject()
  add(query_593679, "Action", newJString(Action))
  add(query_593679, "OptionGroupName", newJString(OptionGroupName))
  add(query_593679, "Version", newJString(Version))
  result = call_593678.call(nil, query_593679, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_593664(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_593665, base: "/",
    url: url_GetDeleteOptionGroup_593666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_593720 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBEngineVersions_593722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_593721(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593723 = query.getOrDefault("Action")
  valid_593723 = validateParameter(valid_593723, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593723 != nil:
    section.add "Action", valid_593723
  var valid_593724 = query.getOrDefault("Version")
  valid_593724 = validateParameter(valid_593724, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593724 != nil:
    section.add "Version", valid_593724
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
  var valid_593725 = header.getOrDefault("X-Amz-Signature")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Signature", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Content-Sha256", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Date")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Date", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Credential")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Credential", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Security-Token")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Security-Token", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-Algorithm")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Algorithm", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-SignedHeaders", valid_593731
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
  var valid_593732 = formData.getOrDefault("DefaultOnly")
  valid_593732 = validateParameter(valid_593732, JBool, required = false, default = nil)
  if valid_593732 != nil:
    section.add "DefaultOnly", valid_593732
  var valid_593733 = formData.getOrDefault("MaxRecords")
  valid_593733 = validateParameter(valid_593733, JInt, required = false, default = nil)
  if valid_593733 != nil:
    section.add "MaxRecords", valid_593733
  var valid_593734 = formData.getOrDefault("EngineVersion")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "EngineVersion", valid_593734
  var valid_593735 = formData.getOrDefault("Marker")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "Marker", valid_593735
  var valid_593736 = formData.getOrDefault("Engine")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "Engine", valid_593736
  var valid_593737 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_593737 = validateParameter(valid_593737, JBool, required = false, default = nil)
  if valid_593737 != nil:
    section.add "ListSupportedCharacterSets", valid_593737
  var valid_593738 = formData.getOrDefault("Filters")
  valid_593738 = validateParameter(valid_593738, JArray, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "Filters", valid_593738
  var valid_593739 = formData.getOrDefault("DBParameterGroupFamily")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "DBParameterGroupFamily", valid_593739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593740: Call_PostDescribeDBEngineVersions_593720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593740.validator(path, query, header, formData, body)
  let scheme = call_593740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593740.url(scheme.get, call_593740.host, call_593740.base,
                         call_593740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593740, url, valid)

proc call*(call_593741: Call_PostDescribeDBEngineVersions_593720;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; DBParameterGroupFamily: string = ""): Recallable =
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
  var query_593742 = newJObject()
  var formData_593743 = newJObject()
  add(formData_593743, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_593743, "MaxRecords", newJInt(MaxRecords))
  add(formData_593743, "EngineVersion", newJString(EngineVersion))
  add(formData_593743, "Marker", newJString(Marker))
  add(formData_593743, "Engine", newJString(Engine))
  add(formData_593743, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593742, "Action", newJString(Action))
  if Filters != nil:
    formData_593743.add "Filters", Filters
  add(query_593742, "Version", newJString(Version))
  add(formData_593743, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_593741.call(nil, query_593742, nil, formData_593743, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_593720(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_593721, base: "/",
    url: url_PostDescribeDBEngineVersions_593722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_593697 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBEngineVersions_593699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_593698(path: JsonNode; query: JsonNode;
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
  var valid_593700 = query.getOrDefault("Marker")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "Marker", valid_593700
  var valid_593701 = query.getOrDefault("DBParameterGroupFamily")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "DBParameterGroupFamily", valid_593701
  var valid_593702 = query.getOrDefault("Engine")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "Engine", valid_593702
  var valid_593703 = query.getOrDefault("EngineVersion")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "EngineVersion", valid_593703
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593704 = query.getOrDefault("Action")
  valid_593704 = validateParameter(valid_593704, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_593704 != nil:
    section.add "Action", valid_593704
  var valid_593705 = query.getOrDefault("ListSupportedCharacterSets")
  valid_593705 = validateParameter(valid_593705, JBool, required = false, default = nil)
  if valid_593705 != nil:
    section.add "ListSupportedCharacterSets", valid_593705
  var valid_593706 = query.getOrDefault("Version")
  valid_593706 = validateParameter(valid_593706, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593706 != nil:
    section.add "Version", valid_593706
  var valid_593707 = query.getOrDefault("Filters")
  valid_593707 = validateParameter(valid_593707, JArray, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "Filters", valid_593707
  var valid_593708 = query.getOrDefault("MaxRecords")
  valid_593708 = validateParameter(valid_593708, JInt, required = false, default = nil)
  if valid_593708 != nil:
    section.add "MaxRecords", valid_593708
  var valid_593709 = query.getOrDefault("DefaultOnly")
  valid_593709 = validateParameter(valid_593709, JBool, required = false, default = nil)
  if valid_593709 != nil:
    section.add "DefaultOnly", valid_593709
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
  var valid_593710 = header.getOrDefault("X-Amz-Signature")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Signature", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Content-Sha256", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Date")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Date", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Credential")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Credential", valid_593713
  var valid_593714 = header.getOrDefault("X-Amz-Security-Token")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "X-Amz-Security-Token", valid_593714
  var valid_593715 = header.getOrDefault("X-Amz-Algorithm")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Algorithm", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-SignedHeaders", valid_593716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593717: Call_GetDescribeDBEngineVersions_593697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593717.validator(path, query, header, formData, body)
  let scheme = call_593717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593717.url(scheme.get, call_593717.host, call_593717.base,
                         call_593717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593717, url, valid)

proc call*(call_593718: Call_GetDescribeDBEngineVersions_593697;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-09-09";
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
  var query_593719 = newJObject()
  add(query_593719, "Marker", newJString(Marker))
  add(query_593719, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_593719, "Engine", newJString(Engine))
  add(query_593719, "EngineVersion", newJString(EngineVersion))
  add(query_593719, "Action", newJString(Action))
  add(query_593719, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_593719, "Version", newJString(Version))
  if Filters != nil:
    query_593719.add "Filters", Filters
  add(query_593719, "MaxRecords", newJInt(MaxRecords))
  add(query_593719, "DefaultOnly", newJBool(DefaultOnly))
  result = call_593718.call(nil, query_593719, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_593697(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_593698, base: "/",
    url: url_GetDescribeDBEngineVersions_593699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_593763 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBInstances_593765(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_593764(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593766 = query.getOrDefault("Action")
  valid_593766 = validateParameter(valid_593766, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593766 != nil:
    section.add "Action", valid_593766
  var valid_593767 = query.getOrDefault("Version")
  valid_593767 = validateParameter(valid_593767, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593767 != nil:
    section.add "Version", valid_593767
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
  var valid_593768 = header.getOrDefault("X-Amz-Signature")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Signature", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Content-Sha256", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Date")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Date", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Credential")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Credential", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Security-Token")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Security-Token", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Algorithm")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Algorithm", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-SignedHeaders", valid_593774
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593775 = formData.getOrDefault("MaxRecords")
  valid_593775 = validateParameter(valid_593775, JInt, required = false, default = nil)
  if valid_593775 != nil:
    section.add "MaxRecords", valid_593775
  var valid_593776 = formData.getOrDefault("Marker")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "Marker", valid_593776
  var valid_593777 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "DBInstanceIdentifier", valid_593777
  var valid_593778 = formData.getOrDefault("Filters")
  valid_593778 = validateParameter(valid_593778, JArray, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "Filters", valid_593778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593779: Call_PostDescribeDBInstances_593763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593779.validator(path, query, header, formData, body)
  let scheme = call_593779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593779.url(scheme.get, call_593779.host, call_593779.base,
                         call_593779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593779, url, valid)

proc call*(call_593780: Call_PostDescribeDBInstances_593763; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593781 = newJObject()
  var formData_593782 = newJObject()
  add(formData_593782, "MaxRecords", newJInt(MaxRecords))
  add(formData_593782, "Marker", newJString(Marker))
  add(formData_593782, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593781, "Action", newJString(Action))
  if Filters != nil:
    formData_593782.add "Filters", Filters
  add(query_593781, "Version", newJString(Version))
  result = call_593780.call(nil, query_593781, nil, formData_593782, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_593763(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_593764, base: "/",
    url: url_PostDescribeDBInstances_593765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_593744 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBInstances_593746(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_593745(path: JsonNode; query: JsonNode;
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
  var valid_593747 = query.getOrDefault("Marker")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "Marker", valid_593747
  var valid_593748 = query.getOrDefault("DBInstanceIdentifier")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "DBInstanceIdentifier", valid_593748
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593749 = query.getOrDefault("Action")
  valid_593749 = validateParameter(valid_593749, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_593749 != nil:
    section.add "Action", valid_593749
  var valid_593750 = query.getOrDefault("Version")
  valid_593750 = validateParameter(valid_593750, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593750 != nil:
    section.add "Version", valid_593750
  var valid_593751 = query.getOrDefault("Filters")
  valid_593751 = validateParameter(valid_593751, JArray, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "Filters", valid_593751
  var valid_593752 = query.getOrDefault("MaxRecords")
  valid_593752 = validateParameter(valid_593752, JInt, required = false, default = nil)
  if valid_593752 != nil:
    section.add "MaxRecords", valid_593752
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
  var valid_593753 = header.getOrDefault("X-Amz-Signature")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "X-Amz-Signature", valid_593753
  var valid_593754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "X-Amz-Content-Sha256", valid_593754
  var valid_593755 = header.getOrDefault("X-Amz-Date")
  valid_593755 = validateParameter(valid_593755, JString, required = false,
                                 default = nil)
  if valid_593755 != nil:
    section.add "X-Amz-Date", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-Credential")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Credential", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Security-Token")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Security-Token", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Algorithm")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Algorithm", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-SignedHeaders", valid_593759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593760: Call_GetDescribeDBInstances_593744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593760.validator(path, query, header, formData, body)
  let scheme = call_593760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593760.url(scheme.get, call_593760.host, call_593760.base,
                         call_593760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593760, url, valid)

proc call*(call_593761: Call_GetDescribeDBInstances_593744; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593762 = newJObject()
  add(query_593762, "Marker", newJString(Marker))
  add(query_593762, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593762, "Action", newJString(Action))
  add(query_593762, "Version", newJString(Version))
  if Filters != nil:
    query_593762.add "Filters", Filters
  add(query_593762, "MaxRecords", newJInt(MaxRecords))
  result = call_593761.call(nil, query_593762, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_593744(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_593745, base: "/",
    url: url_GetDescribeDBInstances_593746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_593805 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBLogFiles_593807(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_593806(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593808 = query.getOrDefault("Action")
  valid_593808 = validateParameter(valid_593808, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593808 != nil:
    section.add "Action", valid_593808
  var valid_593809 = query.getOrDefault("Version")
  valid_593809 = validateParameter(valid_593809, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593809 != nil:
    section.add "Version", valid_593809
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
  var valid_593810 = header.getOrDefault("X-Amz-Signature")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Signature", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Content-Sha256", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Date")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Date", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Credential")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Credential", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Security-Token")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Security-Token", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Algorithm")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Algorithm", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-SignedHeaders", valid_593816
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
  var valid_593817 = formData.getOrDefault("FileSize")
  valid_593817 = validateParameter(valid_593817, JInt, required = false, default = nil)
  if valid_593817 != nil:
    section.add "FileSize", valid_593817
  var valid_593818 = formData.getOrDefault("MaxRecords")
  valid_593818 = validateParameter(valid_593818, JInt, required = false, default = nil)
  if valid_593818 != nil:
    section.add "MaxRecords", valid_593818
  var valid_593819 = formData.getOrDefault("Marker")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "Marker", valid_593819
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593820 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593820 = validateParameter(valid_593820, JString, required = true,
                                 default = nil)
  if valid_593820 != nil:
    section.add "DBInstanceIdentifier", valid_593820
  var valid_593821 = formData.getOrDefault("FilenameContains")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "FilenameContains", valid_593821
  var valid_593822 = formData.getOrDefault("Filters")
  valid_593822 = validateParameter(valid_593822, JArray, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "Filters", valid_593822
  var valid_593823 = formData.getOrDefault("FileLastWritten")
  valid_593823 = validateParameter(valid_593823, JInt, required = false, default = nil)
  if valid_593823 != nil:
    section.add "FileLastWritten", valid_593823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593824: Call_PostDescribeDBLogFiles_593805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593824.validator(path, query, header, formData, body)
  let scheme = call_593824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593824.url(scheme.get, call_593824.host, call_593824.base,
                         call_593824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593824, url, valid)

proc call*(call_593825: Call_PostDescribeDBLogFiles_593805;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; FileLastWritten: int = 0): Recallable =
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
  var query_593826 = newJObject()
  var formData_593827 = newJObject()
  add(formData_593827, "FileSize", newJInt(FileSize))
  add(formData_593827, "MaxRecords", newJInt(MaxRecords))
  add(formData_593827, "Marker", newJString(Marker))
  add(formData_593827, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593827, "FilenameContains", newJString(FilenameContains))
  add(query_593826, "Action", newJString(Action))
  if Filters != nil:
    formData_593827.add "Filters", Filters
  add(query_593826, "Version", newJString(Version))
  add(formData_593827, "FileLastWritten", newJInt(FileLastWritten))
  result = call_593825.call(nil, query_593826, nil, formData_593827, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_593805(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_593806, base: "/",
    url: url_PostDescribeDBLogFiles_593807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_593783 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBLogFiles_593785(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_593784(path: JsonNode; query: JsonNode;
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
  var valid_593786 = query.getOrDefault("Marker")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "Marker", valid_593786
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_593787 = query.getOrDefault("DBInstanceIdentifier")
  valid_593787 = validateParameter(valid_593787, JString, required = true,
                                 default = nil)
  if valid_593787 != nil:
    section.add "DBInstanceIdentifier", valid_593787
  var valid_593788 = query.getOrDefault("FileLastWritten")
  valid_593788 = validateParameter(valid_593788, JInt, required = false, default = nil)
  if valid_593788 != nil:
    section.add "FileLastWritten", valid_593788
  var valid_593789 = query.getOrDefault("Action")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_593789 != nil:
    section.add "Action", valid_593789
  var valid_593790 = query.getOrDefault("FilenameContains")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "FilenameContains", valid_593790
  var valid_593791 = query.getOrDefault("Version")
  valid_593791 = validateParameter(valid_593791, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593791 != nil:
    section.add "Version", valid_593791
  var valid_593792 = query.getOrDefault("Filters")
  valid_593792 = validateParameter(valid_593792, JArray, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "Filters", valid_593792
  var valid_593793 = query.getOrDefault("MaxRecords")
  valid_593793 = validateParameter(valid_593793, JInt, required = false, default = nil)
  if valid_593793 != nil:
    section.add "MaxRecords", valid_593793
  var valid_593794 = query.getOrDefault("FileSize")
  valid_593794 = validateParameter(valid_593794, JInt, required = false, default = nil)
  if valid_593794 != nil:
    section.add "FileSize", valid_593794
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
  var valid_593795 = header.getOrDefault("X-Amz-Signature")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Signature", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Content-Sha256", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Date")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Date", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Credential")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Credential", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Security-Token")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Security-Token", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Algorithm")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Algorithm", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-SignedHeaders", valid_593801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593802: Call_GetDescribeDBLogFiles_593783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593802.validator(path, query, header, formData, body)
  let scheme = call_593802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593802.url(scheme.get, call_593802.host, call_593802.base,
                         call_593802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593802, url, valid)

proc call*(call_593803: Call_GetDescribeDBLogFiles_593783;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_593804 = newJObject()
  add(query_593804, "Marker", newJString(Marker))
  add(query_593804, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593804, "FileLastWritten", newJInt(FileLastWritten))
  add(query_593804, "Action", newJString(Action))
  add(query_593804, "FilenameContains", newJString(FilenameContains))
  add(query_593804, "Version", newJString(Version))
  if Filters != nil:
    query_593804.add "Filters", Filters
  add(query_593804, "MaxRecords", newJInt(MaxRecords))
  add(query_593804, "FileSize", newJInt(FileSize))
  result = call_593803.call(nil, query_593804, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_593783(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_593784, base: "/",
    url: url_GetDescribeDBLogFiles_593785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_593847 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameterGroups_593849(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_593848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593850 = query.getOrDefault("Action")
  valid_593850 = validateParameter(valid_593850, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593850 != nil:
    section.add "Action", valid_593850
  var valid_593851 = query.getOrDefault("Version")
  valid_593851 = validateParameter(valid_593851, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593851 != nil:
    section.add "Version", valid_593851
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
  var valid_593852 = header.getOrDefault("X-Amz-Signature")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Signature", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Content-Sha256", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-Date")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Date", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Credential")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Credential", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Security-Token")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Security-Token", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Algorithm")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Algorithm", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-SignedHeaders", valid_593858
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593859 = formData.getOrDefault("MaxRecords")
  valid_593859 = validateParameter(valid_593859, JInt, required = false, default = nil)
  if valid_593859 != nil:
    section.add "MaxRecords", valid_593859
  var valid_593860 = formData.getOrDefault("DBParameterGroupName")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "DBParameterGroupName", valid_593860
  var valid_593861 = formData.getOrDefault("Marker")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "Marker", valid_593861
  var valid_593862 = formData.getOrDefault("Filters")
  valid_593862 = validateParameter(valid_593862, JArray, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "Filters", valid_593862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593863: Call_PostDescribeDBParameterGroups_593847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593863.validator(path, query, header, formData, body)
  let scheme = call_593863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593863.url(scheme.get, call_593863.host, call_593863.base,
                         call_593863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593863, url, valid)

proc call*(call_593864: Call_PostDescribeDBParameterGroups_593847;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593865 = newJObject()
  var formData_593866 = newJObject()
  add(formData_593866, "MaxRecords", newJInt(MaxRecords))
  add(formData_593866, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593866, "Marker", newJString(Marker))
  add(query_593865, "Action", newJString(Action))
  if Filters != nil:
    formData_593866.add "Filters", Filters
  add(query_593865, "Version", newJString(Version))
  result = call_593864.call(nil, query_593865, nil, formData_593866, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_593847(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_593848, base: "/",
    url: url_PostDescribeDBParameterGroups_593849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_593828 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameterGroups_593830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_593829(path: JsonNode; query: JsonNode;
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
  var valid_593831 = query.getOrDefault("Marker")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "Marker", valid_593831
  var valid_593832 = query.getOrDefault("DBParameterGroupName")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "DBParameterGroupName", valid_593832
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593833 = query.getOrDefault("Action")
  valid_593833 = validateParameter(valid_593833, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_593833 != nil:
    section.add "Action", valid_593833
  var valid_593834 = query.getOrDefault("Version")
  valid_593834 = validateParameter(valid_593834, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593834 != nil:
    section.add "Version", valid_593834
  var valid_593835 = query.getOrDefault("Filters")
  valid_593835 = validateParameter(valid_593835, JArray, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "Filters", valid_593835
  var valid_593836 = query.getOrDefault("MaxRecords")
  valid_593836 = validateParameter(valid_593836, JInt, required = false, default = nil)
  if valid_593836 != nil:
    section.add "MaxRecords", valid_593836
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
  var valid_593837 = header.getOrDefault("X-Amz-Signature")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Signature", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Content-Sha256", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-Date")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-Date", valid_593839
  var valid_593840 = header.getOrDefault("X-Amz-Credential")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Credential", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Security-Token")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Security-Token", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Algorithm")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Algorithm", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-SignedHeaders", valid_593843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593844: Call_GetDescribeDBParameterGroups_593828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593844.validator(path, query, header, formData, body)
  let scheme = call_593844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593844.url(scheme.get, call_593844.host, call_593844.base,
                         call_593844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593844, url, valid)

proc call*(call_593845: Call_GetDescribeDBParameterGroups_593828;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593846 = newJObject()
  add(query_593846, "Marker", newJString(Marker))
  add(query_593846, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593846, "Action", newJString(Action))
  add(query_593846, "Version", newJString(Version))
  if Filters != nil:
    query_593846.add "Filters", Filters
  add(query_593846, "MaxRecords", newJInt(MaxRecords))
  result = call_593845.call(nil, query_593846, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_593828(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_593829, base: "/",
    url: url_GetDescribeDBParameterGroups_593830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_593887 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBParameters_593889(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_593888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593890 = query.getOrDefault("Action")
  valid_593890 = validateParameter(valid_593890, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593890 != nil:
    section.add "Action", valid_593890
  var valid_593891 = query.getOrDefault("Version")
  valid_593891 = validateParameter(valid_593891, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593891 != nil:
    section.add "Version", valid_593891
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
  var valid_593892 = header.getOrDefault("X-Amz-Signature")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Signature", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Content-Sha256", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Date")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Date", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Credential")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Credential", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Security-Token")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Security-Token", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-Algorithm")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Algorithm", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-SignedHeaders", valid_593898
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593899 = formData.getOrDefault("Source")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "Source", valid_593899
  var valid_593900 = formData.getOrDefault("MaxRecords")
  valid_593900 = validateParameter(valid_593900, JInt, required = false, default = nil)
  if valid_593900 != nil:
    section.add "MaxRecords", valid_593900
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_593901 = formData.getOrDefault("DBParameterGroupName")
  valid_593901 = validateParameter(valid_593901, JString, required = true,
                                 default = nil)
  if valid_593901 != nil:
    section.add "DBParameterGroupName", valid_593901
  var valid_593902 = formData.getOrDefault("Marker")
  valid_593902 = validateParameter(valid_593902, JString, required = false,
                                 default = nil)
  if valid_593902 != nil:
    section.add "Marker", valid_593902
  var valid_593903 = formData.getOrDefault("Filters")
  valid_593903 = validateParameter(valid_593903, JArray, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "Filters", valid_593903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593904: Call_PostDescribeDBParameters_593887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593904.validator(path, query, header, formData, body)
  let scheme = call_593904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593904.url(scheme.get, call_593904.host, call_593904.base,
                         call_593904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593904, url, valid)

proc call*(call_593905: Call_PostDescribeDBParameters_593887;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593906 = newJObject()
  var formData_593907 = newJObject()
  add(formData_593907, "Source", newJString(Source))
  add(formData_593907, "MaxRecords", newJInt(MaxRecords))
  add(formData_593907, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_593907, "Marker", newJString(Marker))
  add(query_593906, "Action", newJString(Action))
  if Filters != nil:
    formData_593907.add "Filters", Filters
  add(query_593906, "Version", newJString(Version))
  result = call_593905.call(nil, query_593906, nil, formData_593907, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_593887(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_593888, base: "/",
    url: url_PostDescribeDBParameters_593889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_593867 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBParameters_593869(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_593868(path: JsonNode; query: JsonNode;
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
  var valid_593870 = query.getOrDefault("Marker")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "Marker", valid_593870
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_593871 = query.getOrDefault("DBParameterGroupName")
  valid_593871 = validateParameter(valid_593871, JString, required = true,
                                 default = nil)
  if valid_593871 != nil:
    section.add "DBParameterGroupName", valid_593871
  var valid_593872 = query.getOrDefault("Source")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "Source", valid_593872
  var valid_593873 = query.getOrDefault("Action")
  valid_593873 = validateParameter(valid_593873, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_593873 != nil:
    section.add "Action", valid_593873
  var valid_593874 = query.getOrDefault("Version")
  valid_593874 = validateParameter(valid_593874, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593874 != nil:
    section.add "Version", valid_593874
  var valid_593875 = query.getOrDefault("Filters")
  valid_593875 = validateParameter(valid_593875, JArray, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "Filters", valid_593875
  var valid_593876 = query.getOrDefault("MaxRecords")
  valid_593876 = validateParameter(valid_593876, JInt, required = false, default = nil)
  if valid_593876 != nil:
    section.add "MaxRecords", valid_593876
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
  var valid_593877 = header.getOrDefault("X-Amz-Signature")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Signature", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Content-Sha256", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Date")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Date", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-Credential")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-Credential", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-Security-Token")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Security-Token", valid_593881
  var valid_593882 = header.getOrDefault("X-Amz-Algorithm")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "X-Amz-Algorithm", valid_593882
  var valid_593883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-SignedHeaders", valid_593883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593884: Call_GetDescribeDBParameters_593867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593884.validator(path, query, header, formData, body)
  let scheme = call_593884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593884.url(scheme.get, call_593884.host, call_593884.base,
                         call_593884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593884, url, valid)

proc call*(call_593885: Call_GetDescribeDBParameters_593867;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-09-09";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593886 = newJObject()
  add(query_593886, "Marker", newJString(Marker))
  add(query_593886, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_593886, "Source", newJString(Source))
  add(query_593886, "Action", newJString(Action))
  add(query_593886, "Version", newJString(Version))
  if Filters != nil:
    query_593886.add "Filters", Filters
  add(query_593886, "MaxRecords", newJInt(MaxRecords))
  result = call_593885.call(nil, query_593886, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_593867(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_593868, base: "/",
    url: url_GetDescribeDBParameters_593869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_593927 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSecurityGroups_593929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_593928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593930 = query.getOrDefault("Action")
  valid_593930 = validateParameter(valid_593930, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593930 != nil:
    section.add "Action", valid_593930
  var valid_593931 = query.getOrDefault("Version")
  valid_593931 = validateParameter(valid_593931, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593931 != nil:
    section.add "Version", valid_593931
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
  var valid_593932 = header.getOrDefault("X-Amz-Signature")
  valid_593932 = validateParameter(valid_593932, JString, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "X-Amz-Signature", valid_593932
  var valid_593933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "X-Amz-Content-Sha256", valid_593933
  var valid_593934 = header.getOrDefault("X-Amz-Date")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Date", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-Credential")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-Credential", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Security-Token")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Security-Token", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Algorithm")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Algorithm", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-SignedHeaders", valid_593938
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593939 = formData.getOrDefault("DBSecurityGroupName")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "DBSecurityGroupName", valid_593939
  var valid_593940 = formData.getOrDefault("MaxRecords")
  valid_593940 = validateParameter(valid_593940, JInt, required = false, default = nil)
  if valid_593940 != nil:
    section.add "MaxRecords", valid_593940
  var valid_593941 = formData.getOrDefault("Marker")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "Marker", valid_593941
  var valid_593942 = formData.getOrDefault("Filters")
  valid_593942 = validateParameter(valid_593942, JArray, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "Filters", valid_593942
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593943: Call_PostDescribeDBSecurityGroups_593927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593943.validator(path, query, header, formData, body)
  let scheme = call_593943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593943.url(scheme.get, call_593943.host, call_593943.base,
                         call_593943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593943, url, valid)

proc call*(call_593944: Call_PostDescribeDBSecurityGroups_593927;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593945 = newJObject()
  var formData_593946 = newJObject()
  add(formData_593946, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_593946, "MaxRecords", newJInt(MaxRecords))
  add(formData_593946, "Marker", newJString(Marker))
  add(query_593945, "Action", newJString(Action))
  if Filters != nil:
    formData_593946.add "Filters", Filters
  add(query_593945, "Version", newJString(Version))
  result = call_593944.call(nil, query_593945, nil, formData_593946, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_593927(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_593928, base: "/",
    url: url_PostDescribeDBSecurityGroups_593929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_593908 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSecurityGroups_593910(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_593909(path: JsonNode; query: JsonNode;
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
  var valid_593911 = query.getOrDefault("Marker")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "Marker", valid_593911
  var valid_593912 = query.getOrDefault("DBSecurityGroupName")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "DBSecurityGroupName", valid_593912
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593913 = query.getOrDefault("Action")
  valid_593913 = validateParameter(valid_593913, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_593913 != nil:
    section.add "Action", valid_593913
  var valid_593914 = query.getOrDefault("Version")
  valid_593914 = validateParameter(valid_593914, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593914 != nil:
    section.add "Version", valid_593914
  var valid_593915 = query.getOrDefault("Filters")
  valid_593915 = validateParameter(valid_593915, JArray, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "Filters", valid_593915
  var valid_593916 = query.getOrDefault("MaxRecords")
  valid_593916 = validateParameter(valid_593916, JInt, required = false, default = nil)
  if valid_593916 != nil:
    section.add "MaxRecords", valid_593916
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
  var valid_593917 = header.getOrDefault("X-Amz-Signature")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "X-Amz-Signature", valid_593917
  var valid_593918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593918 = validateParameter(valid_593918, JString, required = false,
                                 default = nil)
  if valid_593918 != nil:
    section.add "X-Amz-Content-Sha256", valid_593918
  var valid_593919 = header.getOrDefault("X-Amz-Date")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Date", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Credential")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Credential", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Security-Token")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Security-Token", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Algorithm")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Algorithm", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-SignedHeaders", valid_593923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593924: Call_GetDescribeDBSecurityGroups_593908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593924.validator(path, query, header, formData, body)
  let scheme = call_593924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593924.url(scheme.get, call_593924.host, call_593924.base,
                         call_593924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593924, url, valid)

proc call*(call_593925: Call_GetDescribeDBSecurityGroups_593908;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593926 = newJObject()
  add(query_593926, "Marker", newJString(Marker))
  add(query_593926, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_593926, "Action", newJString(Action))
  add(query_593926, "Version", newJString(Version))
  if Filters != nil:
    query_593926.add "Filters", Filters
  add(query_593926, "MaxRecords", newJInt(MaxRecords))
  result = call_593925.call(nil, query_593926, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_593908(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_593909, base: "/",
    url: url_GetDescribeDBSecurityGroups_593910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_593968 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSnapshots_593970(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_593969(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_593971 = validateParameter(valid_593971, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593971 != nil:
    section.add "Action", valid_593971
  var valid_593972 = query.getOrDefault("Version")
  valid_593972 = validateParameter(valid_593972, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_593980 = formData.getOrDefault("SnapshotType")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "SnapshotType", valid_593980
  var valid_593981 = formData.getOrDefault("MaxRecords")
  valid_593981 = validateParameter(valid_593981, JInt, required = false, default = nil)
  if valid_593981 != nil:
    section.add "MaxRecords", valid_593981
  var valid_593982 = formData.getOrDefault("Marker")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "Marker", valid_593982
  var valid_593983 = formData.getOrDefault("DBInstanceIdentifier")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "DBInstanceIdentifier", valid_593983
  var valid_593984 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "DBSnapshotIdentifier", valid_593984
  var valid_593985 = formData.getOrDefault("Filters")
  valid_593985 = validateParameter(valid_593985, JArray, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "Filters", valid_593985
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593986: Call_PostDescribeDBSnapshots_593968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593986.validator(path, query, header, formData, body)
  let scheme = call_593986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593986.url(scheme.get, call_593986.host, call_593986.base,
                         call_593986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593986, url, valid)

proc call*(call_593987: Call_PostDescribeDBSnapshots_593968;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_593988 = newJObject()
  var formData_593989 = newJObject()
  add(formData_593989, "SnapshotType", newJString(SnapshotType))
  add(formData_593989, "MaxRecords", newJInt(MaxRecords))
  add(formData_593989, "Marker", newJString(Marker))
  add(formData_593989, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_593989, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593988, "Action", newJString(Action))
  if Filters != nil:
    formData_593989.add "Filters", Filters
  add(query_593988, "Version", newJString(Version))
  result = call_593987.call(nil, query_593988, nil, formData_593989, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_593968(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_593969, base: "/",
    url: url_PostDescribeDBSnapshots_593970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_593947 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSnapshots_593949(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_593948(path: JsonNode; query: JsonNode;
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
  var valid_593950 = query.getOrDefault("Marker")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "Marker", valid_593950
  var valid_593951 = query.getOrDefault("DBInstanceIdentifier")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "DBInstanceIdentifier", valid_593951
  var valid_593952 = query.getOrDefault("DBSnapshotIdentifier")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "DBSnapshotIdentifier", valid_593952
  var valid_593953 = query.getOrDefault("SnapshotType")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "SnapshotType", valid_593953
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593954 = query.getOrDefault("Action")
  valid_593954 = validateParameter(valid_593954, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_593954 != nil:
    section.add "Action", valid_593954
  var valid_593955 = query.getOrDefault("Version")
  valid_593955 = validateParameter(valid_593955, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593955 != nil:
    section.add "Version", valid_593955
  var valid_593956 = query.getOrDefault("Filters")
  valid_593956 = validateParameter(valid_593956, JArray, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "Filters", valid_593956
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

proc call*(call_593965: Call_GetDescribeDBSnapshots_593947; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593965.validator(path, query, header, formData, body)
  let scheme = call_593965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593965.url(scheme.get, call_593965.host, call_593965.base,
                         call_593965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593965, url, valid)

proc call*(call_593966: Call_GetDescribeDBSnapshots_593947; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_593967 = newJObject()
  add(query_593967, "Marker", newJString(Marker))
  add(query_593967, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_593967, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_593967, "SnapshotType", newJString(SnapshotType))
  add(query_593967, "Action", newJString(Action))
  add(query_593967, "Version", newJString(Version))
  if Filters != nil:
    query_593967.add "Filters", Filters
  add(query_593967, "MaxRecords", newJInt(MaxRecords))
  result = call_593966.call(nil, query_593967, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_593947(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_593948, base: "/",
    url: url_GetDescribeDBSnapshots_593949, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_594009 = ref object of OpenApiRestCall_592348
proc url_PostDescribeDBSubnetGroups_594011(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_594010(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594012 = query.getOrDefault("Action")
  valid_594012 = validateParameter(valid_594012, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594012 != nil:
    section.add "Action", valid_594012
  var valid_594013 = query.getOrDefault("Version")
  valid_594013 = validateParameter(valid_594013, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594013 != nil:
    section.add "Version", valid_594013
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
  var valid_594014 = header.getOrDefault("X-Amz-Signature")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-Signature", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Content-Sha256", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Date")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Date", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Credential")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Credential", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Security-Token")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Security-Token", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Algorithm")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Algorithm", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-SignedHeaders", valid_594020
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594021 = formData.getOrDefault("MaxRecords")
  valid_594021 = validateParameter(valid_594021, JInt, required = false, default = nil)
  if valid_594021 != nil:
    section.add "MaxRecords", valid_594021
  var valid_594022 = formData.getOrDefault("Marker")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "Marker", valid_594022
  var valid_594023 = formData.getOrDefault("DBSubnetGroupName")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "DBSubnetGroupName", valid_594023
  var valid_594024 = formData.getOrDefault("Filters")
  valid_594024 = validateParameter(valid_594024, JArray, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "Filters", valid_594024
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594025: Call_PostDescribeDBSubnetGroups_594009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594025.validator(path, query, header, formData, body)
  let scheme = call_594025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594025.url(scheme.get, call_594025.host, call_594025.base,
                         call_594025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594025, url, valid)

proc call*(call_594026: Call_PostDescribeDBSubnetGroups_594009;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594027 = newJObject()
  var formData_594028 = newJObject()
  add(formData_594028, "MaxRecords", newJInt(MaxRecords))
  add(formData_594028, "Marker", newJString(Marker))
  add(query_594027, "Action", newJString(Action))
  add(formData_594028, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_594028.add "Filters", Filters
  add(query_594027, "Version", newJString(Version))
  result = call_594026.call(nil, query_594027, nil, formData_594028, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_594009(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_594010, base: "/",
    url: url_PostDescribeDBSubnetGroups_594011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_593990 = ref object of OpenApiRestCall_592348
proc url_GetDescribeDBSubnetGroups_593992(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_593991(path: JsonNode; query: JsonNode;
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
  var valid_593993 = query.getOrDefault("Marker")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "Marker", valid_593993
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593994 = query.getOrDefault("Action")
  valid_593994 = validateParameter(valid_593994, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_593994 != nil:
    section.add "Action", valid_593994
  var valid_593995 = query.getOrDefault("DBSubnetGroupName")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "DBSubnetGroupName", valid_593995
  var valid_593996 = query.getOrDefault("Version")
  valid_593996 = validateParameter(valid_593996, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_593996 != nil:
    section.add "Version", valid_593996
  var valid_593997 = query.getOrDefault("Filters")
  valid_593997 = validateParameter(valid_593997, JArray, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "Filters", valid_593997
  var valid_593998 = query.getOrDefault("MaxRecords")
  valid_593998 = validateParameter(valid_593998, JInt, required = false, default = nil)
  if valid_593998 != nil:
    section.add "MaxRecords", valid_593998
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
  var valid_593999 = header.getOrDefault("X-Amz-Signature")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-Signature", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Content-Sha256", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Date")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Date", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Credential")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Credential", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Security-Token")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Security-Token", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Algorithm")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Algorithm", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-SignedHeaders", valid_594005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594006: Call_GetDescribeDBSubnetGroups_593990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594006.validator(path, query, header, formData, body)
  let scheme = call_594006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594006.url(scheme.get, call_594006.host, call_594006.base,
                         call_594006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594006, url, valid)

proc call*(call_594007: Call_GetDescribeDBSubnetGroups_593990; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594008 = newJObject()
  add(query_594008, "Marker", newJString(Marker))
  add(query_594008, "Action", newJString(Action))
  add(query_594008, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594008, "Version", newJString(Version))
  if Filters != nil:
    query_594008.add "Filters", Filters
  add(query_594008, "MaxRecords", newJInt(MaxRecords))
  result = call_594007.call(nil, query_594008, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_593990(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_593991, base: "/",
    url: url_GetDescribeDBSubnetGroups_593992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_594048 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEngineDefaultParameters_594050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_594049(path: JsonNode;
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
  var valid_594051 = query.getOrDefault("Action")
  valid_594051 = validateParameter(valid_594051, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_594051 != nil:
    section.add "Action", valid_594051
  var valid_594052 = query.getOrDefault("Version")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594052 != nil:
    section.add "Version", valid_594052
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
  var valid_594053 = header.getOrDefault("X-Amz-Signature")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Signature", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Content-Sha256", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Date")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Date", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Credential")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Credential", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Security-Token")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Security-Token", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Algorithm")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Algorithm", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-SignedHeaders", valid_594059
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_594060 = formData.getOrDefault("MaxRecords")
  valid_594060 = validateParameter(valid_594060, JInt, required = false, default = nil)
  if valid_594060 != nil:
    section.add "MaxRecords", valid_594060
  var valid_594061 = formData.getOrDefault("Marker")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "Marker", valid_594061
  var valid_594062 = formData.getOrDefault("Filters")
  valid_594062 = validateParameter(valid_594062, JArray, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "Filters", valid_594062
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594063 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "DBParameterGroupFamily", valid_594063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594064: Call_PostDescribeEngineDefaultParameters_594048;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594064.validator(path, query, header, formData, body)
  let scheme = call_594064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594064.url(scheme.get, call_594064.host, call_594064.base,
                         call_594064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594064, url, valid)

proc call*(call_594065: Call_PostDescribeEngineDefaultParameters_594048;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_594066 = newJObject()
  var formData_594067 = newJObject()
  add(formData_594067, "MaxRecords", newJInt(MaxRecords))
  add(formData_594067, "Marker", newJString(Marker))
  add(query_594066, "Action", newJString(Action))
  if Filters != nil:
    formData_594067.add "Filters", Filters
  add(query_594066, "Version", newJString(Version))
  add(formData_594067, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_594065.call(nil, query_594066, nil, formData_594067, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_594048(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_594049, base: "/",
    url: url_PostDescribeEngineDefaultParameters_594050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_594029 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEngineDefaultParameters_594031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_594030(path: JsonNode;
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
  var valid_594032 = query.getOrDefault("Marker")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "Marker", valid_594032
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594033 = query.getOrDefault("DBParameterGroupFamily")
  valid_594033 = validateParameter(valid_594033, JString, required = true,
                                 default = nil)
  if valid_594033 != nil:
    section.add "DBParameterGroupFamily", valid_594033
  var valid_594034 = query.getOrDefault("Action")
  valid_594034 = validateParameter(valid_594034, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_594034 != nil:
    section.add "Action", valid_594034
  var valid_594035 = query.getOrDefault("Version")
  valid_594035 = validateParameter(valid_594035, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594035 != nil:
    section.add "Version", valid_594035
  var valid_594036 = query.getOrDefault("Filters")
  valid_594036 = validateParameter(valid_594036, JArray, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "Filters", valid_594036
  var valid_594037 = query.getOrDefault("MaxRecords")
  valid_594037 = validateParameter(valid_594037, JInt, required = false, default = nil)
  if valid_594037 != nil:
    section.add "MaxRecords", valid_594037
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
  var valid_594038 = header.getOrDefault("X-Amz-Signature")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Signature", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Content-Sha256", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Date")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Date", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Security-Token")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Security-Token", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Algorithm")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Algorithm", valid_594043
  var valid_594044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-SignedHeaders", valid_594044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594045: Call_GetDescribeEngineDefaultParameters_594029;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594045.validator(path, query, header, formData, body)
  let scheme = call_594045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594045.url(scheme.get, call_594045.host, call_594045.base,
                         call_594045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594045, url, valid)

proc call*(call_594046: Call_GetDescribeEngineDefaultParameters_594029;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594047 = newJObject()
  add(query_594047, "Marker", newJString(Marker))
  add(query_594047, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_594047, "Action", newJString(Action))
  add(query_594047, "Version", newJString(Version))
  if Filters != nil:
    query_594047.add "Filters", Filters
  add(query_594047, "MaxRecords", newJInt(MaxRecords))
  result = call_594046.call(nil, query_594047, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_594029(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_594030, base: "/",
    url: url_GetDescribeEngineDefaultParameters_594031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_594085 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventCategories_594087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_594086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594088 = query.getOrDefault("Action")
  valid_594088 = validateParameter(valid_594088, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594088 != nil:
    section.add "Action", valid_594088
  var valid_594089 = query.getOrDefault("Version")
  valid_594089 = validateParameter(valid_594089, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594089 != nil:
    section.add "Version", valid_594089
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
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594097 = formData.getOrDefault("SourceType")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "SourceType", valid_594097
  var valid_594098 = formData.getOrDefault("Filters")
  valid_594098 = validateParameter(valid_594098, JArray, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "Filters", valid_594098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_PostDescribeEventCategories_594085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_PostDescribeEventCategories_594085;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594101 = newJObject()
  var formData_594102 = newJObject()
  add(formData_594102, "SourceType", newJString(SourceType))
  add(query_594101, "Action", newJString(Action))
  if Filters != nil:
    formData_594102.add "Filters", Filters
  add(query_594101, "Version", newJString(Version))
  result = call_594100.call(nil, query_594101, nil, formData_594102, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_594085(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_594086, base: "/",
    url: url_PostDescribeEventCategories_594087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_594068 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventCategories_594070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_594069(path: JsonNode; query: JsonNode;
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
  var valid_594071 = query.getOrDefault("SourceType")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "SourceType", valid_594071
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594072 = query.getOrDefault("Action")
  valid_594072 = validateParameter(valid_594072, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594072 != nil:
    section.add "Action", valid_594072
  var valid_594073 = query.getOrDefault("Version")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594073 != nil:
    section.add "Version", valid_594073
  var valid_594074 = query.getOrDefault("Filters")
  valid_594074 = validateParameter(valid_594074, JArray, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "Filters", valid_594074
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
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Credential")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Credential", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594082: Call_GetDescribeEventCategories_594068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594082.validator(path, query, header, formData, body)
  let scheme = call_594082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594082.url(scheme.get, call_594082.host, call_594082.base,
                         call_594082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594082, url, valid)

proc call*(call_594083: Call_GetDescribeEventCategories_594068;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-09-09"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_594084 = newJObject()
  add(query_594084, "SourceType", newJString(SourceType))
  add(query_594084, "Action", newJString(Action))
  add(query_594084, "Version", newJString(Version))
  if Filters != nil:
    query_594084.add "Filters", Filters
  result = call_594083.call(nil, query_594084, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_594068(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_594069, base: "/",
    url: url_GetDescribeEventCategories_594070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_594122 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEventSubscriptions_594124(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_594123(path: JsonNode;
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
  var valid_594125 = query.getOrDefault("Action")
  valid_594125 = validateParameter(valid_594125, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594125 != nil:
    section.add "Action", valid_594125
  var valid_594126 = query.getOrDefault("Version")
  valid_594126 = validateParameter(valid_594126, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594126 != nil:
    section.add "Version", valid_594126
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
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Content-Sha256", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Date")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Date", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Credential")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Credential", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Algorithm")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Algorithm", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594134 = formData.getOrDefault("MaxRecords")
  valid_594134 = validateParameter(valid_594134, JInt, required = false, default = nil)
  if valid_594134 != nil:
    section.add "MaxRecords", valid_594134
  var valid_594135 = formData.getOrDefault("Marker")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "Marker", valid_594135
  var valid_594136 = formData.getOrDefault("SubscriptionName")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "SubscriptionName", valid_594136
  var valid_594137 = formData.getOrDefault("Filters")
  valid_594137 = validateParameter(valid_594137, JArray, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "Filters", valid_594137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_PostDescribeEventSubscriptions_594122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_PostDescribeEventSubscriptions_594122;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594140 = newJObject()
  var formData_594141 = newJObject()
  add(formData_594141, "MaxRecords", newJInt(MaxRecords))
  add(formData_594141, "Marker", newJString(Marker))
  add(formData_594141, "SubscriptionName", newJString(SubscriptionName))
  add(query_594140, "Action", newJString(Action))
  if Filters != nil:
    formData_594141.add "Filters", Filters
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, formData_594141, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_594122(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_594123, base: "/",
    url: url_PostDescribeEventSubscriptions_594124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_594103 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEventSubscriptions_594105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_594104(path: JsonNode; query: JsonNode;
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
  var valid_594106 = query.getOrDefault("Marker")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "Marker", valid_594106
  var valid_594107 = query.getOrDefault("SubscriptionName")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "SubscriptionName", valid_594107
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594108 = query.getOrDefault("Action")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_594108 != nil:
    section.add "Action", valid_594108
  var valid_594109 = query.getOrDefault("Version")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594109 != nil:
    section.add "Version", valid_594109
  var valid_594110 = query.getOrDefault("Filters")
  valid_594110 = validateParameter(valid_594110, JArray, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "Filters", valid_594110
  var valid_594111 = query.getOrDefault("MaxRecords")
  valid_594111 = validateParameter(valid_594111, JInt, required = false, default = nil)
  if valid_594111 != nil:
    section.add "MaxRecords", valid_594111
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
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Content-Sha256", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Date")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Date", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Algorithm")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Algorithm", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-SignedHeaders", valid_594118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594119: Call_GetDescribeEventSubscriptions_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594119.validator(path, query, header, formData, body)
  let scheme = call_594119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594119.url(scheme.get, call_594119.host, call_594119.base,
                         call_594119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594119, url, valid)

proc call*(call_594120: Call_GetDescribeEventSubscriptions_594103;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_594121 = newJObject()
  add(query_594121, "Marker", newJString(Marker))
  add(query_594121, "SubscriptionName", newJString(SubscriptionName))
  add(query_594121, "Action", newJString(Action))
  add(query_594121, "Version", newJString(Version))
  if Filters != nil:
    query_594121.add "Filters", Filters
  add(query_594121, "MaxRecords", newJInt(MaxRecords))
  result = call_594120.call(nil, query_594121, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_594103(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_594104, base: "/",
    url: url_GetDescribeEventSubscriptions_594105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_594166 = ref object of OpenApiRestCall_592348
proc url_PostDescribeEvents_594168(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_594167(path: JsonNode; query: JsonNode;
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
  var valid_594169 = query.getOrDefault("Action")
  valid_594169 = validateParameter(valid_594169, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594169 != nil:
    section.add "Action", valid_594169
  var valid_594170 = query.getOrDefault("Version")
  valid_594170 = validateParameter(valid_594170, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594170 != nil:
    section.add "Version", valid_594170
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
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Content-Sha256", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Date")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Date", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Credential")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Credential", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Security-Token")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Security-Token", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Algorithm")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Algorithm", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-SignedHeaders", valid_594177
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
  var valid_594178 = formData.getOrDefault("MaxRecords")
  valid_594178 = validateParameter(valid_594178, JInt, required = false, default = nil)
  if valid_594178 != nil:
    section.add "MaxRecords", valid_594178
  var valid_594179 = formData.getOrDefault("Marker")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Marker", valid_594179
  var valid_594180 = formData.getOrDefault("SourceIdentifier")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "SourceIdentifier", valid_594180
  var valid_594181 = formData.getOrDefault("SourceType")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594181 != nil:
    section.add "SourceType", valid_594181
  var valid_594182 = formData.getOrDefault("Duration")
  valid_594182 = validateParameter(valid_594182, JInt, required = false, default = nil)
  if valid_594182 != nil:
    section.add "Duration", valid_594182
  var valid_594183 = formData.getOrDefault("EndTime")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "EndTime", valid_594183
  var valid_594184 = formData.getOrDefault("StartTime")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "StartTime", valid_594184
  var valid_594185 = formData.getOrDefault("EventCategories")
  valid_594185 = validateParameter(valid_594185, JArray, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "EventCategories", valid_594185
  var valid_594186 = formData.getOrDefault("Filters")
  valid_594186 = validateParameter(valid_594186, JArray, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "Filters", valid_594186
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594187: Call_PostDescribeEvents_594166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594187.validator(path, query, header, formData, body)
  let scheme = call_594187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594187.url(scheme.get, call_594187.host, call_594187.base,
                         call_594187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594187, url, valid)

proc call*(call_594188: Call_PostDescribeEvents_594166; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
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
  var query_594189 = newJObject()
  var formData_594190 = newJObject()
  add(formData_594190, "MaxRecords", newJInt(MaxRecords))
  add(formData_594190, "Marker", newJString(Marker))
  add(formData_594190, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594190, "SourceType", newJString(SourceType))
  add(formData_594190, "Duration", newJInt(Duration))
  add(formData_594190, "EndTime", newJString(EndTime))
  add(formData_594190, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_594190.add "EventCategories", EventCategories
  add(query_594189, "Action", newJString(Action))
  if Filters != nil:
    formData_594190.add "Filters", Filters
  add(query_594189, "Version", newJString(Version))
  result = call_594188.call(nil, query_594189, nil, formData_594190, nil)

var postDescribeEvents* = Call_PostDescribeEvents_594166(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_594167, base: "/",
    url: url_PostDescribeEvents_594168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_594142 = ref object of OpenApiRestCall_592348
proc url_GetDescribeEvents_594144(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_594143(path: JsonNode; query: JsonNode;
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
  var valid_594145 = query.getOrDefault("Marker")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "Marker", valid_594145
  var valid_594146 = query.getOrDefault("SourceType")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594146 != nil:
    section.add "SourceType", valid_594146
  var valid_594147 = query.getOrDefault("SourceIdentifier")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "SourceIdentifier", valid_594147
  var valid_594148 = query.getOrDefault("EventCategories")
  valid_594148 = validateParameter(valid_594148, JArray, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "EventCategories", valid_594148
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594149 = query.getOrDefault("Action")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594149 != nil:
    section.add "Action", valid_594149
  var valid_594150 = query.getOrDefault("StartTime")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "StartTime", valid_594150
  var valid_594151 = query.getOrDefault("Duration")
  valid_594151 = validateParameter(valid_594151, JInt, required = false, default = nil)
  if valid_594151 != nil:
    section.add "Duration", valid_594151
  var valid_594152 = query.getOrDefault("EndTime")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "EndTime", valid_594152
  var valid_594153 = query.getOrDefault("Version")
  valid_594153 = validateParameter(valid_594153, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594153 != nil:
    section.add "Version", valid_594153
  var valid_594154 = query.getOrDefault("Filters")
  valid_594154 = validateParameter(valid_594154, JArray, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "Filters", valid_594154
  var valid_594155 = query.getOrDefault("MaxRecords")
  valid_594155 = validateParameter(valid_594155, JInt, required = false, default = nil)
  if valid_594155 != nil:
    section.add "MaxRecords", valid_594155
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
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Content-Sha256", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Date")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Date", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Credential")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Credential", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Security-Token")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Security-Token", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Algorithm")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Algorithm", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-SignedHeaders", valid_594162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594163: Call_GetDescribeEvents_594142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594163.validator(path, query, header, formData, body)
  let scheme = call_594163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594163.url(scheme.get, call_594163.host, call_594163.base,
                         call_594163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594163, url, valid)

proc call*(call_594164: Call_GetDescribeEvents_594142; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  var query_594165 = newJObject()
  add(query_594165, "Marker", newJString(Marker))
  add(query_594165, "SourceType", newJString(SourceType))
  add(query_594165, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_594165.add "EventCategories", EventCategories
  add(query_594165, "Action", newJString(Action))
  add(query_594165, "StartTime", newJString(StartTime))
  add(query_594165, "Duration", newJInt(Duration))
  add(query_594165, "EndTime", newJString(EndTime))
  add(query_594165, "Version", newJString(Version))
  if Filters != nil:
    query_594165.add "Filters", Filters
  add(query_594165, "MaxRecords", newJInt(MaxRecords))
  result = call_594164.call(nil, query_594165, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_594142(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_594143,
    base: "/", url: url_GetDescribeEvents_594144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_594211 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroupOptions_594213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_594212(path: JsonNode;
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
  var valid_594214 = query.getOrDefault("Action")
  valid_594214 = validateParameter(valid_594214, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594214 != nil:
    section.add "Action", valid_594214
  var valid_594215 = query.getOrDefault("Version")
  valid_594215 = validateParameter(valid_594215, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594215 != nil:
    section.add "Version", valid_594215
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
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Content-Sha256", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Date")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Date", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Credential")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Credential", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Security-Token")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Security-Token", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Algorithm")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Algorithm", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-SignedHeaders", valid_594222
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594223 = formData.getOrDefault("MaxRecords")
  valid_594223 = validateParameter(valid_594223, JInt, required = false, default = nil)
  if valid_594223 != nil:
    section.add "MaxRecords", valid_594223
  var valid_594224 = formData.getOrDefault("Marker")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "Marker", valid_594224
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_594225 = formData.getOrDefault("EngineName")
  valid_594225 = validateParameter(valid_594225, JString, required = true,
                                 default = nil)
  if valid_594225 != nil:
    section.add "EngineName", valid_594225
  var valid_594226 = formData.getOrDefault("MajorEngineVersion")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "MajorEngineVersion", valid_594226
  var valid_594227 = formData.getOrDefault("Filters")
  valid_594227 = validateParameter(valid_594227, JArray, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "Filters", valid_594227
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594228: Call_PostDescribeOptionGroupOptions_594211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594228.validator(path, query, header, formData, body)
  let scheme = call_594228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594228.url(scheme.get, call_594228.host, call_594228.base,
                         call_594228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594228, url, valid)

proc call*(call_594229: Call_PostDescribeOptionGroupOptions_594211;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594230 = newJObject()
  var formData_594231 = newJObject()
  add(formData_594231, "MaxRecords", newJInt(MaxRecords))
  add(formData_594231, "Marker", newJString(Marker))
  add(formData_594231, "EngineName", newJString(EngineName))
  add(formData_594231, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594230, "Action", newJString(Action))
  if Filters != nil:
    formData_594231.add "Filters", Filters
  add(query_594230, "Version", newJString(Version))
  result = call_594229.call(nil, query_594230, nil, formData_594231, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_594211(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_594212, base: "/",
    url: url_PostDescribeOptionGroupOptions_594213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_594191 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroupOptions_594193(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_594192(path: JsonNode; query: JsonNode;
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
  var valid_594194 = query.getOrDefault("EngineName")
  valid_594194 = validateParameter(valid_594194, JString, required = true,
                                 default = nil)
  if valid_594194 != nil:
    section.add "EngineName", valid_594194
  var valid_594195 = query.getOrDefault("Marker")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "Marker", valid_594195
  var valid_594196 = query.getOrDefault("Action")
  valid_594196 = validateParameter(valid_594196, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_594196 != nil:
    section.add "Action", valid_594196
  var valid_594197 = query.getOrDefault("Version")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594197 != nil:
    section.add "Version", valid_594197
  var valid_594198 = query.getOrDefault("Filters")
  valid_594198 = validateParameter(valid_594198, JArray, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "Filters", valid_594198
  var valid_594199 = query.getOrDefault("MaxRecords")
  valid_594199 = validateParameter(valid_594199, JInt, required = false, default = nil)
  if valid_594199 != nil:
    section.add "MaxRecords", valid_594199
  var valid_594200 = query.getOrDefault("MajorEngineVersion")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "MajorEngineVersion", valid_594200
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
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Content-Sha256", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Date")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Date", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Credential")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Credential", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Security-Token")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Security-Token", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Algorithm")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Algorithm", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-SignedHeaders", valid_594207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594208: Call_GetDescribeOptionGroupOptions_594191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594208.validator(path, query, header, formData, body)
  let scheme = call_594208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594208.url(scheme.get, call_594208.host, call_594208.base,
                         call_594208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594208, url, valid)

proc call*(call_594209: Call_GetDescribeOptionGroupOptions_594191;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_594210 = newJObject()
  add(query_594210, "EngineName", newJString(EngineName))
  add(query_594210, "Marker", newJString(Marker))
  add(query_594210, "Action", newJString(Action))
  add(query_594210, "Version", newJString(Version))
  if Filters != nil:
    query_594210.add "Filters", Filters
  add(query_594210, "MaxRecords", newJInt(MaxRecords))
  add(query_594210, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594209.call(nil, query_594210, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_594191(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_594192, base: "/",
    url: url_GetDescribeOptionGroupOptions_594193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_594253 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOptionGroups_594255(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_594254(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_594256 = validateParameter(valid_594256, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594256 != nil:
    section.add "Action", valid_594256
  var valid_594257 = query.getOrDefault("Version")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_594265 = formData.getOrDefault("MaxRecords")
  valid_594265 = validateParameter(valid_594265, JInt, required = false, default = nil)
  if valid_594265 != nil:
    section.add "MaxRecords", valid_594265
  var valid_594266 = formData.getOrDefault("Marker")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "Marker", valid_594266
  var valid_594267 = formData.getOrDefault("EngineName")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "EngineName", valid_594267
  var valid_594268 = formData.getOrDefault("MajorEngineVersion")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "MajorEngineVersion", valid_594268
  var valid_594269 = formData.getOrDefault("OptionGroupName")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "OptionGroupName", valid_594269
  var valid_594270 = formData.getOrDefault("Filters")
  valid_594270 = validateParameter(valid_594270, JArray, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "Filters", valid_594270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594271: Call_PostDescribeOptionGroups_594253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594271.validator(path, query, header, formData, body)
  let scheme = call_594271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594271.url(scheme.get, call_594271.host, call_594271.base,
                         call_594271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594271, url, valid)

proc call*(call_594272: Call_PostDescribeOptionGroups_594253; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_594273 = newJObject()
  var formData_594274 = newJObject()
  add(formData_594274, "MaxRecords", newJInt(MaxRecords))
  add(formData_594274, "Marker", newJString(Marker))
  add(formData_594274, "EngineName", newJString(EngineName))
  add(formData_594274, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_594273, "Action", newJString(Action))
  add(formData_594274, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_594274.add "Filters", Filters
  add(query_594273, "Version", newJString(Version))
  result = call_594272.call(nil, query_594273, nil, formData_594274, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_594253(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_594254, base: "/",
    url: url_PostDescribeOptionGroups_594255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_594232 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOptionGroups_594234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_594233(path: JsonNode; query: JsonNode;
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
  var valid_594235 = query.getOrDefault("EngineName")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "EngineName", valid_594235
  var valid_594236 = query.getOrDefault("Marker")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "Marker", valid_594236
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594237 = query.getOrDefault("Action")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_594237 != nil:
    section.add "Action", valid_594237
  var valid_594238 = query.getOrDefault("OptionGroupName")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "OptionGroupName", valid_594238
  var valid_594239 = query.getOrDefault("Version")
  valid_594239 = validateParameter(valid_594239, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_594242 = query.getOrDefault("MajorEngineVersion")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "MajorEngineVersion", valid_594242
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

proc call*(call_594250: Call_GetDescribeOptionGroups_594232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_GetDescribeOptionGroups_594232;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_594252 = newJObject()
  add(query_594252, "EngineName", newJString(EngineName))
  add(query_594252, "Marker", newJString(Marker))
  add(query_594252, "Action", newJString(Action))
  add(query_594252, "OptionGroupName", newJString(OptionGroupName))
  add(query_594252, "Version", newJString(Version))
  if Filters != nil:
    query_594252.add "Filters", Filters
  add(query_594252, "MaxRecords", newJInt(MaxRecords))
  add(query_594252, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594251.call(nil, query_594252, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_594232(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_594233, base: "/",
    url: url_GetDescribeOptionGroups_594234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_594298 = ref object of OpenApiRestCall_592348
proc url_PostDescribeOrderableDBInstanceOptions_594300(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_594299(path: JsonNode;
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
  var valid_594301 = query.getOrDefault("Action")
  valid_594301 = validateParameter(valid_594301, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594301 != nil:
    section.add "Action", valid_594301
  var valid_594302 = query.getOrDefault("Version")
  valid_594302 = validateParameter(valid_594302, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594302 != nil:
    section.add "Version", valid_594302
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
  var valid_594303 = header.getOrDefault("X-Amz-Signature")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Signature", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Date")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Date", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Credential")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Credential", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Security-Token")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Security-Token", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Algorithm")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Algorithm", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-SignedHeaders", valid_594309
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
  var valid_594310 = formData.getOrDefault("DBInstanceClass")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "DBInstanceClass", valid_594310
  var valid_594311 = formData.getOrDefault("MaxRecords")
  valid_594311 = validateParameter(valid_594311, JInt, required = false, default = nil)
  if valid_594311 != nil:
    section.add "MaxRecords", valid_594311
  var valid_594312 = formData.getOrDefault("EngineVersion")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "EngineVersion", valid_594312
  var valid_594313 = formData.getOrDefault("Marker")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "Marker", valid_594313
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594314 = formData.getOrDefault("Engine")
  valid_594314 = validateParameter(valid_594314, JString, required = true,
                                 default = nil)
  if valid_594314 != nil:
    section.add "Engine", valid_594314
  var valid_594315 = formData.getOrDefault("Vpc")
  valid_594315 = validateParameter(valid_594315, JBool, required = false, default = nil)
  if valid_594315 != nil:
    section.add "Vpc", valid_594315
  var valid_594316 = formData.getOrDefault("LicenseModel")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "LicenseModel", valid_594316
  var valid_594317 = formData.getOrDefault("Filters")
  valid_594317 = validateParameter(valid_594317, JArray, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "Filters", valid_594317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594318: Call_PostDescribeOrderableDBInstanceOptions_594298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594318.validator(path, query, header, formData, body)
  let scheme = call_594318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594318.url(scheme.get, call_594318.host, call_594318.base,
                         call_594318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594318, url, valid)

proc call*(call_594319: Call_PostDescribeOrderableDBInstanceOptions_594298;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
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
  var query_594320 = newJObject()
  var formData_594321 = newJObject()
  add(formData_594321, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594321, "MaxRecords", newJInt(MaxRecords))
  add(formData_594321, "EngineVersion", newJString(EngineVersion))
  add(formData_594321, "Marker", newJString(Marker))
  add(formData_594321, "Engine", newJString(Engine))
  add(formData_594321, "Vpc", newJBool(Vpc))
  add(query_594320, "Action", newJString(Action))
  add(formData_594321, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_594321.add "Filters", Filters
  add(query_594320, "Version", newJString(Version))
  result = call_594319.call(nil, query_594320, nil, formData_594321, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_594298(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_594299, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_594300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_594275 = ref object of OpenApiRestCall_592348
proc url_GetDescribeOrderableDBInstanceOptions_594277(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_594276(path: JsonNode;
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
  var valid_594278 = query.getOrDefault("Marker")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "Marker", valid_594278
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594279 = query.getOrDefault("Engine")
  valid_594279 = validateParameter(valid_594279, JString, required = true,
                                 default = nil)
  if valid_594279 != nil:
    section.add "Engine", valid_594279
  var valid_594280 = query.getOrDefault("LicenseModel")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "LicenseModel", valid_594280
  var valid_594281 = query.getOrDefault("Vpc")
  valid_594281 = validateParameter(valid_594281, JBool, required = false, default = nil)
  if valid_594281 != nil:
    section.add "Vpc", valid_594281
  var valid_594282 = query.getOrDefault("EngineVersion")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "EngineVersion", valid_594282
  var valid_594283 = query.getOrDefault("Action")
  valid_594283 = validateParameter(valid_594283, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_594283 != nil:
    section.add "Action", valid_594283
  var valid_594284 = query.getOrDefault("Version")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594284 != nil:
    section.add "Version", valid_594284
  var valid_594285 = query.getOrDefault("DBInstanceClass")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "DBInstanceClass", valid_594285
  var valid_594286 = query.getOrDefault("Filters")
  valid_594286 = validateParameter(valid_594286, JArray, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "Filters", valid_594286
  var valid_594287 = query.getOrDefault("MaxRecords")
  valid_594287 = validateParameter(valid_594287, JInt, required = false, default = nil)
  if valid_594287 != nil:
    section.add "MaxRecords", valid_594287
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
  var valid_594288 = header.getOrDefault("X-Amz-Signature")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Signature", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Date")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Date", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Credential")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Credential", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Security-Token")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Security-Token", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Algorithm")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Algorithm", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-SignedHeaders", valid_594294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_GetDescribeOrderableDBInstanceOptions_594275;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_GetDescribeOrderableDBInstanceOptions_594275;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
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
  var query_594297 = newJObject()
  add(query_594297, "Marker", newJString(Marker))
  add(query_594297, "Engine", newJString(Engine))
  add(query_594297, "LicenseModel", newJString(LicenseModel))
  add(query_594297, "Vpc", newJBool(Vpc))
  add(query_594297, "EngineVersion", newJString(EngineVersion))
  add(query_594297, "Action", newJString(Action))
  add(query_594297, "Version", newJString(Version))
  add(query_594297, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594297.add "Filters", Filters
  add(query_594297, "MaxRecords", newJInt(MaxRecords))
  result = call_594296.call(nil, query_594297, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_594275(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_594276, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_594277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_594347 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstances_594349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_594348(path: JsonNode;
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
  var valid_594350 = query.getOrDefault("Action")
  valid_594350 = validateParameter(valid_594350, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594350 != nil:
    section.add "Action", valid_594350
  var valid_594351 = query.getOrDefault("Version")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594351 != nil:
    section.add "Version", valid_594351
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
  var valid_594352 = header.getOrDefault("X-Amz-Signature")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Signature", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Content-Sha256", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Date")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Date", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Credential")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Credential", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Security-Token")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Security-Token", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Algorithm")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Algorithm", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-SignedHeaders", valid_594358
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
  var valid_594359 = formData.getOrDefault("DBInstanceClass")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "DBInstanceClass", valid_594359
  var valid_594360 = formData.getOrDefault("MultiAZ")
  valid_594360 = validateParameter(valid_594360, JBool, required = false, default = nil)
  if valid_594360 != nil:
    section.add "MultiAZ", valid_594360
  var valid_594361 = formData.getOrDefault("MaxRecords")
  valid_594361 = validateParameter(valid_594361, JInt, required = false, default = nil)
  if valid_594361 != nil:
    section.add "MaxRecords", valid_594361
  var valid_594362 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "ReservedDBInstanceId", valid_594362
  var valid_594363 = formData.getOrDefault("Marker")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "Marker", valid_594363
  var valid_594364 = formData.getOrDefault("Duration")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "Duration", valid_594364
  var valid_594365 = formData.getOrDefault("OfferingType")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "OfferingType", valid_594365
  var valid_594366 = formData.getOrDefault("ProductDescription")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "ProductDescription", valid_594366
  var valid_594367 = formData.getOrDefault("Filters")
  valid_594367 = validateParameter(valid_594367, JArray, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "Filters", valid_594367
  var valid_594368 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594368
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594369: Call_PostDescribeReservedDBInstances_594347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594369.validator(path, query, header, formData, body)
  let scheme = call_594369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594369.url(scheme.get, call_594369.host, call_594369.base,
                         call_594369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594369, url, valid)

proc call*(call_594370: Call_PostDescribeReservedDBInstances_594347;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
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
  var query_594371 = newJObject()
  var formData_594372 = newJObject()
  add(formData_594372, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594372, "MultiAZ", newJBool(MultiAZ))
  add(formData_594372, "MaxRecords", newJInt(MaxRecords))
  add(formData_594372, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_594372, "Marker", newJString(Marker))
  add(formData_594372, "Duration", newJString(Duration))
  add(formData_594372, "OfferingType", newJString(OfferingType))
  add(formData_594372, "ProductDescription", newJString(ProductDescription))
  add(query_594371, "Action", newJString(Action))
  if Filters != nil:
    formData_594372.add "Filters", Filters
  add(formData_594372, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594371, "Version", newJString(Version))
  result = call_594370.call(nil, query_594371, nil, formData_594372, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_594347(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_594348, base: "/",
    url: url_PostDescribeReservedDBInstances_594349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_594322 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstances_594324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_594323(path: JsonNode;
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
  var valid_594325 = query.getOrDefault("Marker")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "Marker", valid_594325
  var valid_594326 = query.getOrDefault("ProductDescription")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "ProductDescription", valid_594326
  var valid_594327 = query.getOrDefault("OfferingType")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "OfferingType", valid_594327
  var valid_594328 = query.getOrDefault("ReservedDBInstanceId")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "ReservedDBInstanceId", valid_594328
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594329 = query.getOrDefault("Action")
  valid_594329 = validateParameter(valid_594329, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_594329 != nil:
    section.add "Action", valid_594329
  var valid_594330 = query.getOrDefault("MultiAZ")
  valid_594330 = validateParameter(valid_594330, JBool, required = false, default = nil)
  if valid_594330 != nil:
    section.add "MultiAZ", valid_594330
  var valid_594331 = query.getOrDefault("Duration")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "Duration", valid_594331
  var valid_594332 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594332
  var valid_594333 = query.getOrDefault("Version")
  valid_594333 = validateParameter(valid_594333, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594333 != nil:
    section.add "Version", valid_594333
  var valid_594334 = query.getOrDefault("DBInstanceClass")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "DBInstanceClass", valid_594334
  var valid_594335 = query.getOrDefault("Filters")
  valid_594335 = validateParameter(valid_594335, JArray, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "Filters", valid_594335
  var valid_594336 = query.getOrDefault("MaxRecords")
  valid_594336 = validateParameter(valid_594336, JInt, required = false, default = nil)
  if valid_594336 != nil:
    section.add "MaxRecords", valid_594336
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
  var valid_594337 = header.getOrDefault("X-Amz-Signature")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Signature", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Content-Sha256", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Date")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Date", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Credential")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Credential", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Security-Token")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Security-Token", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Algorithm")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Algorithm", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-SignedHeaders", valid_594343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594344: Call_GetDescribeReservedDBInstances_594322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594344.validator(path, query, header, formData, body)
  let scheme = call_594344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594344.url(scheme.get, call_594344.host, call_594344.base,
                         call_594344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594344, url, valid)

proc call*(call_594345: Call_GetDescribeReservedDBInstances_594322;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
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
  var query_594346 = newJObject()
  add(query_594346, "Marker", newJString(Marker))
  add(query_594346, "ProductDescription", newJString(ProductDescription))
  add(query_594346, "OfferingType", newJString(OfferingType))
  add(query_594346, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594346, "Action", newJString(Action))
  add(query_594346, "MultiAZ", newJBool(MultiAZ))
  add(query_594346, "Duration", newJString(Duration))
  add(query_594346, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594346, "Version", newJString(Version))
  add(query_594346, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594346.add "Filters", Filters
  add(query_594346, "MaxRecords", newJInt(MaxRecords))
  result = call_594345.call(nil, query_594346, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_594322(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_594323, base: "/",
    url: url_GetDescribeReservedDBInstances_594324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_594397 = ref object of OpenApiRestCall_592348
proc url_PostDescribeReservedDBInstancesOfferings_594399(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_594398(path: JsonNode;
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
  var valid_594400 = query.getOrDefault("Action")
  valid_594400 = validateParameter(valid_594400, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594400 != nil:
    section.add "Action", valid_594400
  var valid_594401 = query.getOrDefault("Version")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594401 != nil:
    section.add "Version", valid_594401
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
  var valid_594402 = header.getOrDefault("X-Amz-Signature")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Signature", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Content-Sha256", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Date")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Date", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Credential")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Credential", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Security-Token")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Security-Token", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Algorithm")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Algorithm", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-SignedHeaders", valid_594408
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
  var valid_594409 = formData.getOrDefault("DBInstanceClass")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "DBInstanceClass", valid_594409
  var valid_594410 = formData.getOrDefault("MultiAZ")
  valid_594410 = validateParameter(valid_594410, JBool, required = false, default = nil)
  if valid_594410 != nil:
    section.add "MultiAZ", valid_594410
  var valid_594411 = formData.getOrDefault("MaxRecords")
  valid_594411 = validateParameter(valid_594411, JInt, required = false, default = nil)
  if valid_594411 != nil:
    section.add "MaxRecords", valid_594411
  var valid_594412 = formData.getOrDefault("Marker")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "Marker", valid_594412
  var valid_594413 = formData.getOrDefault("Duration")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "Duration", valid_594413
  var valid_594414 = formData.getOrDefault("OfferingType")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "OfferingType", valid_594414
  var valid_594415 = formData.getOrDefault("ProductDescription")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "ProductDescription", valid_594415
  var valid_594416 = formData.getOrDefault("Filters")
  valid_594416 = validateParameter(valid_594416, JArray, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "Filters", valid_594416
  var valid_594417 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594417
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594418: Call_PostDescribeReservedDBInstancesOfferings_594397;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594418.validator(path, query, header, formData, body)
  let scheme = call_594418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594418.url(scheme.get, call_594418.host, call_594418.base,
                         call_594418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594418, url, valid)

proc call*(call_594419: Call_PostDescribeReservedDBInstancesOfferings_594397;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"): Recallable =
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
  var query_594420 = newJObject()
  var formData_594421 = newJObject()
  add(formData_594421, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594421, "MultiAZ", newJBool(MultiAZ))
  add(formData_594421, "MaxRecords", newJInt(MaxRecords))
  add(formData_594421, "Marker", newJString(Marker))
  add(formData_594421, "Duration", newJString(Duration))
  add(formData_594421, "OfferingType", newJString(OfferingType))
  add(formData_594421, "ProductDescription", newJString(ProductDescription))
  add(query_594420, "Action", newJString(Action))
  if Filters != nil:
    formData_594421.add "Filters", Filters
  add(formData_594421, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594420, "Version", newJString(Version))
  result = call_594419.call(nil, query_594420, nil, formData_594421, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_594397(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_594398,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_594399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_594373 = ref object of OpenApiRestCall_592348
proc url_GetDescribeReservedDBInstancesOfferings_594375(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_594374(path: JsonNode;
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
  var valid_594376 = query.getOrDefault("Marker")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "Marker", valid_594376
  var valid_594377 = query.getOrDefault("ProductDescription")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "ProductDescription", valid_594377
  var valid_594378 = query.getOrDefault("OfferingType")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "OfferingType", valid_594378
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594379 = query.getOrDefault("Action")
  valid_594379 = validateParameter(valid_594379, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_594379 != nil:
    section.add "Action", valid_594379
  var valid_594380 = query.getOrDefault("MultiAZ")
  valid_594380 = validateParameter(valid_594380, JBool, required = false, default = nil)
  if valid_594380 != nil:
    section.add "MultiAZ", valid_594380
  var valid_594381 = query.getOrDefault("Duration")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "Duration", valid_594381
  var valid_594382 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594382
  var valid_594383 = query.getOrDefault("Version")
  valid_594383 = validateParameter(valid_594383, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594383 != nil:
    section.add "Version", valid_594383
  var valid_594384 = query.getOrDefault("DBInstanceClass")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "DBInstanceClass", valid_594384
  var valid_594385 = query.getOrDefault("Filters")
  valid_594385 = validateParameter(valid_594385, JArray, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "Filters", valid_594385
  var valid_594386 = query.getOrDefault("MaxRecords")
  valid_594386 = validateParameter(valid_594386, JInt, required = false, default = nil)
  if valid_594386 != nil:
    section.add "MaxRecords", valid_594386
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
  var valid_594387 = header.getOrDefault("X-Amz-Signature")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Signature", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Content-Sha256", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Date")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Date", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Credential")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Credential", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Security-Token")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Security-Token", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Algorithm")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Algorithm", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-SignedHeaders", valid_594393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594394: Call_GetDescribeReservedDBInstancesOfferings_594373;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594394.validator(path, query, header, formData, body)
  let scheme = call_594394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594394.url(scheme.get, call_594394.host, call_594394.base,
                         call_594394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594394, url, valid)

proc call*(call_594395: Call_GetDescribeReservedDBInstancesOfferings_594373;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
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
  var query_594396 = newJObject()
  add(query_594396, "Marker", newJString(Marker))
  add(query_594396, "ProductDescription", newJString(ProductDescription))
  add(query_594396, "OfferingType", newJString(OfferingType))
  add(query_594396, "Action", newJString(Action))
  add(query_594396, "MultiAZ", newJBool(MultiAZ))
  add(query_594396, "Duration", newJString(Duration))
  add(query_594396, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594396, "Version", newJString(Version))
  add(query_594396, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_594396.add "Filters", Filters
  add(query_594396, "MaxRecords", newJInt(MaxRecords))
  result = call_594395.call(nil, query_594396, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_594373(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_594374, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_594375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_594441 = ref object of OpenApiRestCall_592348
proc url_PostDownloadDBLogFilePortion_594443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_594442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594444 = query.getOrDefault("Action")
  valid_594444 = validateParameter(valid_594444, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594444 != nil:
    section.add "Action", valid_594444
  var valid_594445 = query.getOrDefault("Version")
  valid_594445 = validateParameter(valid_594445, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594445 != nil:
    section.add "Version", valid_594445
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
  var valid_594446 = header.getOrDefault("X-Amz-Signature")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Signature", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Content-Sha256", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Date")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Date", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Credential")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Credential", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Security-Token")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Security-Token", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Algorithm")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Algorithm", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-SignedHeaders", valid_594452
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594453 = formData.getOrDefault("NumberOfLines")
  valid_594453 = validateParameter(valid_594453, JInt, required = false, default = nil)
  if valid_594453 != nil:
    section.add "NumberOfLines", valid_594453
  var valid_594454 = formData.getOrDefault("Marker")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "Marker", valid_594454
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_594455 = formData.getOrDefault("LogFileName")
  valid_594455 = validateParameter(valid_594455, JString, required = true,
                                 default = nil)
  if valid_594455 != nil:
    section.add "LogFileName", valid_594455
  var valid_594456 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594456 = validateParameter(valid_594456, JString, required = true,
                                 default = nil)
  if valid_594456 != nil:
    section.add "DBInstanceIdentifier", valid_594456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594457: Call_PostDownloadDBLogFilePortion_594441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594457.validator(path, query, header, formData, body)
  let scheme = call_594457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594457.url(scheme.get, call_594457.host, call_594457.base,
                         call_594457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594457, url, valid)

proc call*(call_594458: Call_PostDownloadDBLogFilePortion_594441;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594459 = newJObject()
  var formData_594460 = newJObject()
  add(formData_594460, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_594460, "Marker", newJString(Marker))
  add(formData_594460, "LogFileName", newJString(LogFileName))
  add(formData_594460, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594459, "Action", newJString(Action))
  add(query_594459, "Version", newJString(Version))
  result = call_594458.call(nil, query_594459, nil, formData_594460, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_594441(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_594442, base: "/",
    url: url_PostDownloadDBLogFilePortion_594443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_594422 = ref object of OpenApiRestCall_592348
proc url_GetDownloadDBLogFilePortion_594424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_594423(path: JsonNode; query: JsonNode;
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
  var valid_594425 = query.getOrDefault("Marker")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "Marker", valid_594425
  var valid_594426 = query.getOrDefault("NumberOfLines")
  valid_594426 = validateParameter(valid_594426, JInt, required = false, default = nil)
  if valid_594426 != nil:
    section.add "NumberOfLines", valid_594426
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594427 = query.getOrDefault("DBInstanceIdentifier")
  valid_594427 = validateParameter(valid_594427, JString, required = true,
                                 default = nil)
  if valid_594427 != nil:
    section.add "DBInstanceIdentifier", valid_594427
  var valid_594428 = query.getOrDefault("Action")
  valid_594428 = validateParameter(valid_594428, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_594428 != nil:
    section.add "Action", valid_594428
  var valid_594429 = query.getOrDefault("LogFileName")
  valid_594429 = validateParameter(valid_594429, JString, required = true,
                                 default = nil)
  if valid_594429 != nil:
    section.add "LogFileName", valid_594429
  var valid_594430 = query.getOrDefault("Version")
  valid_594430 = validateParameter(valid_594430, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594430 != nil:
    section.add "Version", valid_594430
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
  var valid_594431 = header.getOrDefault("X-Amz-Signature")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Signature", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Content-Sha256", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Date")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Date", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Credential")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Credential", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Security-Token")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Security-Token", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Algorithm")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Algorithm", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-SignedHeaders", valid_594437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594438: Call_GetDownloadDBLogFilePortion_594422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594438.validator(path, query, header, formData, body)
  let scheme = call_594438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594438.url(scheme.get, call_594438.host, call_594438.base,
                         call_594438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594438, url, valid)

proc call*(call_594439: Call_GetDownloadDBLogFilePortion_594422;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_594440 = newJObject()
  add(query_594440, "Marker", newJString(Marker))
  add(query_594440, "NumberOfLines", newJInt(NumberOfLines))
  add(query_594440, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594440, "Action", newJString(Action))
  add(query_594440, "LogFileName", newJString(LogFileName))
  add(query_594440, "Version", newJString(Version))
  result = call_594439.call(nil, query_594440, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_594422(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_594423, base: "/",
    url: url_GetDownloadDBLogFilePortion_594424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594478 = ref object of OpenApiRestCall_592348
proc url_PostListTagsForResource_594480(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("ListTagsForResource"))
  if valid_594481 != nil:
    section.add "Action", valid_594481
  var valid_594482 = query.getOrDefault("Version")
  valid_594482 = validateParameter(valid_594482, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_594490 = formData.getOrDefault("Filters")
  valid_594490 = validateParameter(valid_594490, JArray, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "Filters", valid_594490
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_594491 = formData.getOrDefault("ResourceName")
  valid_594491 = validateParameter(valid_594491, JString, required = true,
                                 default = nil)
  if valid_594491 != nil:
    section.add "ResourceName", valid_594491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594492: Call_PostListTagsForResource_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594492.validator(path, query, header, formData, body)
  let scheme = call_594492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594492.url(scheme.get, call_594492.host, call_594492.base,
                         call_594492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594492, url, valid)

proc call*(call_594493: Call_PostListTagsForResource_594478; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594494 = newJObject()
  var formData_594495 = newJObject()
  add(query_594494, "Action", newJString(Action))
  if Filters != nil:
    formData_594495.add "Filters", Filters
  add(query_594494, "Version", newJString(Version))
  add(formData_594495, "ResourceName", newJString(ResourceName))
  result = call_594493.call(nil, query_594494, nil, formData_594495, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594478(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594479, base: "/",
    url: url_PostListTagsForResource_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594461 = ref object of OpenApiRestCall_592348
proc url_GetListTagsForResource_594463(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594462(path: JsonNode; query: JsonNode;
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
  var valid_594464 = query.getOrDefault("ResourceName")
  valid_594464 = validateParameter(valid_594464, JString, required = true,
                                 default = nil)
  if valid_594464 != nil:
    section.add "ResourceName", valid_594464
  var valid_594465 = query.getOrDefault("Action")
  valid_594465 = validateParameter(valid_594465, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594465 != nil:
    section.add "Action", valid_594465
  var valid_594466 = query.getOrDefault("Version")
  valid_594466 = validateParameter(valid_594466, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594466 != nil:
    section.add "Version", valid_594466
  var valid_594467 = query.getOrDefault("Filters")
  valid_594467 = validateParameter(valid_594467, JArray, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "Filters", valid_594467
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

proc call*(call_594475: Call_GetListTagsForResource_594461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_GetListTagsForResource_594461; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_594477 = newJObject()
  add(query_594477, "ResourceName", newJString(ResourceName))
  add(query_594477, "Action", newJString(Action))
  add(query_594477, "Version", newJString(Version))
  if Filters != nil:
    query_594477.add "Filters", Filters
  result = call_594476.call(nil, query_594477, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594461(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594462, base: "/",
    url: url_GetListTagsForResource_594463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_594529 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBInstance_594531(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_594530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594532 = query.getOrDefault("Action")
  valid_594532 = validateParameter(valid_594532, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594532 != nil:
    section.add "Action", valid_594532
  var valid_594533 = query.getOrDefault("Version")
  valid_594533 = validateParameter(valid_594533, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594533 != nil:
    section.add "Version", valid_594533
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
  var valid_594534 = header.getOrDefault("X-Amz-Signature")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Signature", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Content-Sha256", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Date")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Date", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Credential")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Credential", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Security-Token")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Security-Token", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Algorithm")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Algorithm", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-SignedHeaders", valid_594540
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
  var valid_594541 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "PreferredMaintenanceWindow", valid_594541
  var valid_594542 = formData.getOrDefault("DBInstanceClass")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "DBInstanceClass", valid_594542
  var valid_594543 = formData.getOrDefault("PreferredBackupWindow")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "PreferredBackupWindow", valid_594543
  var valid_594544 = formData.getOrDefault("MasterUserPassword")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "MasterUserPassword", valid_594544
  var valid_594545 = formData.getOrDefault("MultiAZ")
  valid_594545 = validateParameter(valid_594545, JBool, required = false, default = nil)
  if valid_594545 != nil:
    section.add "MultiAZ", valid_594545
  var valid_594546 = formData.getOrDefault("DBParameterGroupName")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "DBParameterGroupName", valid_594546
  var valid_594547 = formData.getOrDefault("EngineVersion")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "EngineVersion", valid_594547
  var valid_594548 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594548 = validateParameter(valid_594548, JArray, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "VpcSecurityGroupIds", valid_594548
  var valid_594549 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594549 = validateParameter(valid_594549, JInt, required = false, default = nil)
  if valid_594549 != nil:
    section.add "BackupRetentionPeriod", valid_594549
  var valid_594550 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594550 = validateParameter(valid_594550, JBool, required = false, default = nil)
  if valid_594550 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594550
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594551 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594551 = validateParameter(valid_594551, JString, required = true,
                                 default = nil)
  if valid_594551 != nil:
    section.add "DBInstanceIdentifier", valid_594551
  var valid_594552 = formData.getOrDefault("ApplyImmediately")
  valid_594552 = validateParameter(valid_594552, JBool, required = false, default = nil)
  if valid_594552 != nil:
    section.add "ApplyImmediately", valid_594552
  var valid_594553 = formData.getOrDefault("Iops")
  valid_594553 = validateParameter(valid_594553, JInt, required = false, default = nil)
  if valid_594553 != nil:
    section.add "Iops", valid_594553
  var valid_594554 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_594554 = validateParameter(valid_594554, JBool, required = false, default = nil)
  if valid_594554 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594554
  var valid_594555 = formData.getOrDefault("OptionGroupName")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "OptionGroupName", valid_594555
  var valid_594556 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "NewDBInstanceIdentifier", valid_594556
  var valid_594557 = formData.getOrDefault("DBSecurityGroups")
  valid_594557 = validateParameter(valid_594557, JArray, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "DBSecurityGroups", valid_594557
  var valid_594558 = formData.getOrDefault("AllocatedStorage")
  valid_594558 = validateParameter(valid_594558, JInt, required = false, default = nil)
  if valid_594558 != nil:
    section.add "AllocatedStorage", valid_594558
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594559: Call_PostModifyDBInstance_594529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594559.validator(path, query, header, formData, body)
  let scheme = call_594559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594559.url(scheme.get, call_594559.host, call_594559.base,
                         call_594559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594559, url, valid)

proc call*(call_594560: Call_PostModifyDBInstance_594529;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-09-09";
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
  var query_594561 = newJObject()
  var formData_594562 = newJObject()
  add(formData_594562, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_594562, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594562, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594562, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594562, "MultiAZ", newJBool(MultiAZ))
  add(formData_594562, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594562, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_594562.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594562, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594562, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594562, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594562, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_594562, "Iops", newJInt(Iops))
  add(query_594561, "Action", newJString(Action))
  add(formData_594562, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_594562, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594562, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_594561, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_594562.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594562, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_594560.call(nil, query_594561, nil, formData_594562, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_594529(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_594530, base: "/",
    url: url_PostModifyDBInstance_594531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_594496 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBInstance_594498(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_594497(path: JsonNode; query: JsonNode;
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
  var valid_594499 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "NewDBInstanceIdentifier", valid_594499
  var valid_594500 = query.getOrDefault("DBParameterGroupName")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "DBParameterGroupName", valid_594500
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594501 = query.getOrDefault("DBInstanceIdentifier")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "DBInstanceIdentifier", valid_594501
  var valid_594502 = query.getOrDefault("BackupRetentionPeriod")
  valid_594502 = validateParameter(valid_594502, JInt, required = false, default = nil)
  if valid_594502 != nil:
    section.add "BackupRetentionPeriod", valid_594502
  var valid_594503 = query.getOrDefault("EngineVersion")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "EngineVersion", valid_594503
  var valid_594504 = query.getOrDefault("Action")
  valid_594504 = validateParameter(valid_594504, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_594504 != nil:
    section.add "Action", valid_594504
  var valid_594505 = query.getOrDefault("MultiAZ")
  valid_594505 = validateParameter(valid_594505, JBool, required = false, default = nil)
  if valid_594505 != nil:
    section.add "MultiAZ", valid_594505
  var valid_594506 = query.getOrDefault("DBSecurityGroups")
  valid_594506 = validateParameter(valid_594506, JArray, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "DBSecurityGroups", valid_594506
  var valid_594507 = query.getOrDefault("ApplyImmediately")
  valid_594507 = validateParameter(valid_594507, JBool, required = false, default = nil)
  if valid_594507 != nil:
    section.add "ApplyImmediately", valid_594507
  var valid_594508 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594508 = validateParameter(valid_594508, JArray, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "VpcSecurityGroupIds", valid_594508
  var valid_594509 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_594509 = validateParameter(valid_594509, JBool, required = false, default = nil)
  if valid_594509 != nil:
    section.add "AllowMajorVersionUpgrade", valid_594509
  var valid_594510 = query.getOrDefault("MasterUserPassword")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "MasterUserPassword", valid_594510
  var valid_594511 = query.getOrDefault("OptionGroupName")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "OptionGroupName", valid_594511
  var valid_594512 = query.getOrDefault("Version")
  valid_594512 = validateParameter(valid_594512, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594512 != nil:
    section.add "Version", valid_594512
  var valid_594513 = query.getOrDefault("AllocatedStorage")
  valid_594513 = validateParameter(valid_594513, JInt, required = false, default = nil)
  if valid_594513 != nil:
    section.add "AllocatedStorage", valid_594513
  var valid_594514 = query.getOrDefault("DBInstanceClass")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "DBInstanceClass", valid_594514
  var valid_594515 = query.getOrDefault("PreferredBackupWindow")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "PreferredBackupWindow", valid_594515
  var valid_594516 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "PreferredMaintenanceWindow", valid_594516
  var valid_594517 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594517 = validateParameter(valid_594517, JBool, required = false, default = nil)
  if valid_594517 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594517
  var valid_594518 = query.getOrDefault("Iops")
  valid_594518 = validateParameter(valid_594518, JInt, required = false, default = nil)
  if valid_594518 != nil:
    section.add "Iops", valid_594518
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
  var valid_594519 = header.getOrDefault("X-Amz-Signature")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Signature", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Date")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Date", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Credential")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Credential", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Security-Token")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Security-Token", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Algorithm")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Algorithm", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-SignedHeaders", valid_594525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594526: Call_GetModifyDBInstance_594496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594526.validator(path, query, header, formData, body)
  let scheme = call_594526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594526.url(scheme.get, call_594526.host, call_594526.base,
                         call_594526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594526, url, valid)

proc call*(call_594527: Call_GetModifyDBInstance_594496;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-09-09";
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
  var query_594528 = newJObject()
  add(query_594528, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_594528, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594528, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594528, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594528, "EngineVersion", newJString(EngineVersion))
  add(query_594528, "Action", newJString(Action))
  add(query_594528, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_594528.add "DBSecurityGroups", DBSecurityGroups
  add(query_594528, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_594528.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594528, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_594528, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594528, "OptionGroupName", newJString(OptionGroupName))
  add(query_594528, "Version", newJString(Version))
  add(query_594528, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594528, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594528, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594528, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594528, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594528, "Iops", newJInt(Iops))
  result = call_594527.call(nil, query_594528, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_594496(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_594497, base: "/",
    url: url_GetModifyDBInstance_594498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_594580 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBParameterGroup_594582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_594581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594583 = query.getOrDefault("Action")
  valid_594583 = validateParameter(valid_594583, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594583 != nil:
    section.add "Action", valid_594583
  var valid_594584 = query.getOrDefault("Version")
  valid_594584 = validateParameter(valid_594584, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594584 != nil:
    section.add "Version", valid_594584
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594592 = formData.getOrDefault("DBParameterGroupName")
  valid_594592 = validateParameter(valid_594592, JString, required = true,
                                 default = nil)
  if valid_594592 != nil:
    section.add "DBParameterGroupName", valid_594592
  var valid_594593 = formData.getOrDefault("Parameters")
  valid_594593 = validateParameter(valid_594593, JArray, required = true, default = nil)
  if valid_594593 != nil:
    section.add "Parameters", valid_594593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594594: Call_PostModifyDBParameterGroup_594580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594594.validator(path, query, header, formData, body)
  let scheme = call_594594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594594.url(scheme.get, call_594594.host, call_594594.base,
                         call_594594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594594, url, valid)

proc call*(call_594595: Call_PostModifyDBParameterGroup_594580;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_594596 = newJObject()
  var formData_594597 = newJObject()
  add(formData_594597, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594596, "Action", newJString(Action))
  if Parameters != nil:
    formData_594597.add "Parameters", Parameters
  add(query_594596, "Version", newJString(Version))
  result = call_594595.call(nil, query_594596, nil, formData_594597, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_594580(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_594581, base: "/",
    url: url_PostModifyDBParameterGroup_594582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_594563 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBParameterGroup_594565(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_594564(path: JsonNode; query: JsonNode;
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
  var valid_594566 = query.getOrDefault("DBParameterGroupName")
  valid_594566 = validateParameter(valid_594566, JString, required = true,
                                 default = nil)
  if valid_594566 != nil:
    section.add "DBParameterGroupName", valid_594566
  var valid_594567 = query.getOrDefault("Parameters")
  valid_594567 = validateParameter(valid_594567, JArray, required = true, default = nil)
  if valid_594567 != nil:
    section.add "Parameters", valid_594567
  var valid_594568 = query.getOrDefault("Action")
  valid_594568 = validateParameter(valid_594568, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_594568 != nil:
    section.add "Action", valid_594568
  var valid_594569 = query.getOrDefault("Version")
  valid_594569 = validateParameter(valid_594569, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594569 != nil:
    section.add "Version", valid_594569
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
  var valid_594570 = header.getOrDefault("X-Amz-Signature")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Signature", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Content-Sha256", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Date")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Date", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Credential")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Credential", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Security-Token")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Security-Token", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Algorithm")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Algorithm", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-SignedHeaders", valid_594576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594577: Call_GetModifyDBParameterGroup_594563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594577.validator(path, query, header, formData, body)
  let scheme = call_594577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594577.url(scheme.get, call_594577.host, call_594577.base,
                         call_594577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594577, url, valid)

proc call*(call_594578: Call_GetModifyDBParameterGroup_594563;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594579 = newJObject()
  add(query_594579, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594579.add "Parameters", Parameters
  add(query_594579, "Action", newJString(Action))
  add(query_594579, "Version", newJString(Version))
  result = call_594578.call(nil, query_594579, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_594563(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_594564, base: "/",
    url: url_GetModifyDBParameterGroup_594565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_594616 = ref object of OpenApiRestCall_592348
proc url_PostModifyDBSubnetGroup_594618(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_594617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594619 = query.getOrDefault("Action")
  valid_594619 = validateParameter(valid_594619, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594619 != nil:
    section.add "Action", valid_594619
  var valid_594620 = query.getOrDefault("Version")
  valid_594620 = validateParameter(valid_594620, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594620 != nil:
    section.add "Version", valid_594620
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
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Content-Sha256", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Date")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Date", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Credential")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Credential", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Security-Token")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Security-Token", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Algorithm")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Algorithm", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-SignedHeaders", valid_594627
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_594628 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "DBSubnetGroupDescription", valid_594628
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594629 = formData.getOrDefault("DBSubnetGroupName")
  valid_594629 = validateParameter(valid_594629, JString, required = true,
                                 default = nil)
  if valid_594629 != nil:
    section.add "DBSubnetGroupName", valid_594629
  var valid_594630 = formData.getOrDefault("SubnetIds")
  valid_594630 = validateParameter(valid_594630, JArray, required = true, default = nil)
  if valid_594630 != nil:
    section.add "SubnetIds", valid_594630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594631: Call_PostModifyDBSubnetGroup_594616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594631.validator(path, query, header, formData, body)
  let scheme = call_594631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594631.url(scheme.get, call_594631.host, call_594631.base,
                         call_594631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594631, url, valid)

proc call*(call_594632: Call_PostModifyDBSubnetGroup_594616;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_594633 = newJObject()
  var formData_594634 = newJObject()
  add(formData_594634, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594633, "Action", newJString(Action))
  add(formData_594634, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594633, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_594634.add "SubnetIds", SubnetIds
  result = call_594632.call(nil, query_594633, nil, formData_594634, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_594616(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_594617, base: "/",
    url: url_PostModifyDBSubnetGroup_594618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_594598 = ref object of OpenApiRestCall_592348
proc url_GetModifyDBSubnetGroup_594600(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_594599(path: JsonNode; query: JsonNode;
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
  var valid_594601 = query.getOrDefault("SubnetIds")
  valid_594601 = validateParameter(valid_594601, JArray, required = true, default = nil)
  if valid_594601 != nil:
    section.add "SubnetIds", valid_594601
  var valid_594602 = query.getOrDefault("Action")
  valid_594602 = validateParameter(valid_594602, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_594602 != nil:
    section.add "Action", valid_594602
  var valid_594603 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "DBSubnetGroupDescription", valid_594603
  var valid_594604 = query.getOrDefault("DBSubnetGroupName")
  valid_594604 = validateParameter(valid_594604, JString, required = true,
                                 default = nil)
  if valid_594604 != nil:
    section.add "DBSubnetGroupName", valid_594604
  var valid_594605 = query.getOrDefault("Version")
  valid_594605 = validateParameter(valid_594605, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594605 != nil:
    section.add "Version", valid_594605
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
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Content-Sha256", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Date")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Date", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-Credential")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Credential", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Security-Token")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Security-Token", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Algorithm")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Algorithm", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-SignedHeaders", valid_594612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594613: Call_GetModifyDBSubnetGroup_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594613.validator(path, query, header, formData, body)
  let scheme = call_594613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594613.url(scheme.get, call_594613.host, call_594613.base,
                         call_594613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594613, url, valid)

proc call*(call_594614: Call_GetModifyDBSubnetGroup_594598; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594615 = newJObject()
  if SubnetIds != nil:
    query_594615.add "SubnetIds", SubnetIds
  add(query_594615, "Action", newJString(Action))
  add(query_594615, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594615, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594615, "Version", newJString(Version))
  result = call_594614.call(nil, query_594615, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_594598(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_594599, base: "/",
    url: url_GetModifyDBSubnetGroup_594600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_594655 = ref object of OpenApiRestCall_592348
proc url_PostModifyEventSubscription_594657(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_594656(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594658 = query.getOrDefault("Action")
  valid_594658 = validateParameter(valid_594658, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594658 != nil:
    section.add "Action", valid_594658
  var valid_594659 = query.getOrDefault("Version")
  valid_594659 = validateParameter(valid_594659, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594659 != nil:
    section.add "Version", valid_594659
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
  var valid_594660 = header.getOrDefault("X-Amz-Signature")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Signature", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Content-Sha256", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Date")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Date", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-Credential")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Credential", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Security-Token")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Security-Token", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-SignedHeaders", valid_594666
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_594667 = formData.getOrDefault("SnsTopicArn")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "SnsTopicArn", valid_594667
  var valid_594668 = formData.getOrDefault("Enabled")
  valid_594668 = validateParameter(valid_594668, JBool, required = false, default = nil)
  if valid_594668 != nil:
    section.add "Enabled", valid_594668
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594669 = formData.getOrDefault("SubscriptionName")
  valid_594669 = validateParameter(valid_594669, JString, required = true,
                                 default = nil)
  if valid_594669 != nil:
    section.add "SubscriptionName", valid_594669
  var valid_594670 = formData.getOrDefault("SourceType")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "SourceType", valid_594670
  var valid_594671 = formData.getOrDefault("EventCategories")
  valid_594671 = validateParameter(valid_594671, JArray, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "EventCategories", valid_594671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594672: Call_PostModifyEventSubscription_594655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594672.validator(path, query, header, formData, body)
  let scheme = call_594672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594672.url(scheme.get, call_594672.host, call_594672.base,
                         call_594672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594672, url, valid)

proc call*(call_594673: Call_PostModifyEventSubscription_594655;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-09-09"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594674 = newJObject()
  var formData_594675 = newJObject()
  add(formData_594675, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_594675, "Enabled", newJBool(Enabled))
  add(formData_594675, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594675, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_594675.add "EventCategories", EventCategories
  add(query_594674, "Action", newJString(Action))
  add(query_594674, "Version", newJString(Version))
  result = call_594673.call(nil, query_594674, nil, formData_594675, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_594655(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_594656, base: "/",
    url: url_PostModifyEventSubscription_594657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_594635 = ref object of OpenApiRestCall_592348
proc url_GetModifyEventSubscription_594637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_594636(path: JsonNode; query: JsonNode;
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
  var valid_594638 = query.getOrDefault("SourceType")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "SourceType", valid_594638
  var valid_594639 = query.getOrDefault("Enabled")
  valid_594639 = validateParameter(valid_594639, JBool, required = false, default = nil)
  if valid_594639 != nil:
    section.add "Enabled", valid_594639
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_594640 = query.getOrDefault("SubscriptionName")
  valid_594640 = validateParameter(valid_594640, JString, required = true,
                                 default = nil)
  if valid_594640 != nil:
    section.add "SubscriptionName", valid_594640
  var valid_594641 = query.getOrDefault("EventCategories")
  valid_594641 = validateParameter(valid_594641, JArray, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "EventCategories", valid_594641
  var valid_594642 = query.getOrDefault("Action")
  valid_594642 = validateParameter(valid_594642, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_594642 != nil:
    section.add "Action", valid_594642
  var valid_594643 = query.getOrDefault("SnsTopicArn")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "SnsTopicArn", valid_594643
  var valid_594644 = query.getOrDefault("Version")
  valid_594644 = validateParameter(valid_594644, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594644 != nil:
    section.add "Version", valid_594644
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
  var valid_594645 = header.getOrDefault("X-Amz-Signature")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Signature", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Content-Sha256", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Date")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Date", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Credential")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Credential", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Security-Token")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Security-Token", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-SignedHeaders", valid_594651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594652: Call_GetModifyEventSubscription_594635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594652.validator(path, query, header, formData, body)
  let scheme = call_594652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594652.url(scheme.get, call_594652.host, call_594652.base,
                         call_594652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594652, url, valid)

proc call*(call_594653: Call_GetModifyEventSubscription_594635;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_594654 = newJObject()
  add(query_594654, "SourceType", newJString(SourceType))
  add(query_594654, "Enabled", newJBool(Enabled))
  add(query_594654, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_594654.add "EventCategories", EventCategories
  add(query_594654, "Action", newJString(Action))
  add(query_594654, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_594654, "Version", newJString(Version))
  result = call_594653.call(nil, query_594654, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_594635(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_594636, base: "/",
    url: url_GetModifyEventSubscription_594637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_594695 = ref object of OpenApiRestCall_592348
proc url_PostModifyOptionGroup_594697(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_594696(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594698 = query.getOrDefault("Action")
  valid_594698 = validateParameter(valid_594698, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594698 != nil:
    section.add "Action", valid_594698
  var valid_594699 = query.getOrDefault("Version")
  valid_594699 = validateParameter(valid_594699, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594699 != nil:
    section.add "Version", valid_594699
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
  var valid_594700 = header.getOrDefault("X-Amz-Signature")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "X-Amz-Signature", valid_594700
  var valid_594701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Content-Sha256", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Date")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Date", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Credential")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Credential", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Security-Token")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Security-Token", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Algorithm")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Algorithm", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-SignedHeaders", valid_594706
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_594707 = formData.getOrDefault("OptionsToRemove")
  valid_594707 = validateParameter(valid_594707, JArray, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "OptionsToRemove", valid_594707
  var valid_594708 = formData.getOrDefault("ApplyImmediately")
  valid_594708 = validateParameter(valid_594708, JBool, required = false, default = nil)
  if valid_594708 != nil:
    section.add "ApplyImmediately", valid_594708
  var valid_594709 = formData.getOrDefault("OptionsToInclude")
  valid_594709 = validateParameter(valid_594709, JArray, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "OptionsToInclude", valid_594709
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594710 = formData.getOrDefault("OptionGroupName")
  valid_594710 = validateParameter(valid_594710, JString, required = true,
                                 default = nil)
  if valid_594710 != nil:
    section.add "OptionGroupName", valid_594710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594711: Call_PostModifyOptionGroup_594695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594711.validator(path, query, header, formData, body)
  let scheme = call_594711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594711.url(scheme.get, call_594711.host, call_594711.base,
                         call_594711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594711, url, valid)

proc call*(call_594712: Call_PostModifyOptionGroup_594695; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594713 = newJObject()
  var formData_594714 = newJObject()
  if OptionsToRemove != nil:
    formData_594714.add "OptionsToRemove", OptionsToRemove
  add(formData_594714, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_594714.add "OptionsToInclude", OptionsToInclude
  add(query_594713, "Action", newJString(Action))
  add(formData_594714, "OptionGroupName", newJString(OptionGroupName))
  add(query_594713, "Version", newJString(Version))
  result = call_594712.call(nil, query_594713, nil, formData_594714, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_594695(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_594696, base: "/",
    url: url_PostModifyOptionGroup_594697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_594676 = ref object of OpenApiRestCall_592348
proc url_GetModifyOptionGroup_594678(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_594677(path: JsonNode; query: JsonNode;
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
  var valid_594679 = query.getOrDefault("Action")
  valid_594679 = validateParameter(valid_594679, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_594679 != nil:
    section.add "Action", valid_594679
  var valid_594680 = query.getOrDefault("ApplyImmediately")
  valid_594680 = validateParameter(valid_594680, JBool, required = false, default = nil)
  if valid_594680 != nil:
    section.add "ApplyImmediately", valid_594680
  var valid_594681 = query.getOrDefault("OptionsToRemove")
  valid_594681 = validateParameter(valid_594681, JArray, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "OptionsToRemove", valid_594681
  var valid_594682 = query.getOrDefault("OptionsToInclude")
  valid_594682 = validateParameter(valid_594682, JArray, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "OptionsToInclude", valid_594682
  var valid_594683 = query.getOrDefault("OptionGroupName")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = nil)
  if valid_594683 != nil:
    section.add "OptionGroupName", valid_594683
  var valid_594684 = query.getOrDefault("Version")
  valid_594684 = validateParameter(valid_594684, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594684 != nil:
    section.add "Version", valid_594684
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
  var valid_594685 = header.getOrDefault("X-Amz-Signature")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "X-Amz-Signature", valid_594685
  var valid_594686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "X-Amz-Content-Sha256", valid_594686
  var valid_594687 = header.getOrDefault("X-Amz-Date")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Date", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Credential")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Credential", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Security-Token")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Security-Token", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Algorithm")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Algorithm", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-SignedHeaders", valid_594691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594692: Call_GetModifyOptionGroup_594676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594692.validator(path, query, header, formData, body)
  let scheme = call_594692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594692.url(scheme.get, call_594692.host, call_594692.base,
                         call_594692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594692, url, valid)

proc call*(call_594693: Call_GetModifyOptionGroup_594676; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_594694 = newJObject()
  add(query_594694, "Action", newJString(Action))
  add(query_594694, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_594694.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_594694.add "OptionsToInclude", OptionsToInclude
  add(query_594694, "OptionGroupName", newJString(OptionGroupName))
  add(query_594694, "Version", newJString(Version))
  result = call_594693.call(nil, query_594694, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_594676(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_594677, base: "/",
    url: url_GetModifyOptionGroup_594678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_594733 = ref object of OpenApiRestCall_592348
proc url_PostPromoteReadReplica_594735(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_594734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594736 = query.getOrDefault("Action")
  valid_594736 = validateParameter(valid_594736, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594736 != nil:
    section.add "Action", valid_594736
  var valid_594737 = query.getOrDefault("Version")
  valid_594737 = validateParameter(valid_594737, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594737 != nil:
    section.add "Version", valid_594737
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
  var valid_594738 = header.getOrDefault("X-Amz-Signature")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Signature", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Content-Sha256", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Date")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Date", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Credential")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Credential", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Security-Token")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Security-Token", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Algorithm")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Algorithm", valid_594743
  var valid_594744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "X-Amz-SignedHeaders", valid_594744
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594745 = formData.getOrDefault("PreferredBackupWindow")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "PreferredBackupWindow", valid_594745
  var valid_594746 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594746 = validateParameter(valid_594746, JInt, required = false, default = nil)
  if valid_594746 != nil:
    section.add "BackupRetentionPeriod", valid_594746
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594747 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594747 = validateParameter(valid_594747, JString, required = true,
                                 default = nil)
  if valid_594747 != nil:
    section.add "DBInstanceIdentifier", valid_594747
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594748: Call_PostPromoteReadReplica_594733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594748.validator(path, query, header, formData, body)
  let scheme = call_594748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594748.url(scheme.get, call_594748.host, call_594748.base,
                         call_594748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594748, url, valid)

proc call*(call_594749: Call_PostPromoteReadReplica_594733;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594750 = newJObject()
  var formData_594751 = newJObject()
  add(formData_594751, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594751, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594751, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594750, "Action", newJString(Action))
  add(query_594750, "Version", newJString(Version))
  result = call_594749.call(nil, query_594750, nil, formData_594751, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_594733(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_594734, base: "/",
    url: url_PostPromoteReadReplica_594735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_594715 = ref object of OpenApiRestCall_592348
proc url_GetPromoteReadReplica_594717(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_594716(path: JsonNode; query: JsonNode;
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
  var valid_594718 = query.getOrDefault("DBInstanceIdentifier")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = nil)
  if valid_594718 != nil:
    section.add "DBInstanceIdentifier", valid_594718
  var valid_594719 = query.getOrDefault("BackupRetentionPeriod")
  valid_594719 = validateParameter(valid_594719, JInt, required = false, default = nil)
  if valid_594719 != nil:
    section.add "BackupRetentionPeriod", valid_594719
  var valid_594720 = query.getOrDefault("Action")
  valid_594720 = validateParameter(valid_594720, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_594720 != nil:
    section.add "Action", valid_594720
  var valid_594721 = query.getOrDefault("Version")
  valid_594721 = validateParameter(valid_594721, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594721 != nil:
    section.add "Version", valid_594721
  var valid_594722 = query.getOrDefault("PreferredBackupWindow")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "PreferredBackupWindow", valid_594722
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
  var valid_594723 = header.getOrDefault("X-Amz-Signature")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Signature", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Content-Sha256", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Date")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Date", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Credential")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Credential", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-Security-Token")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Security-Token", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Algorithm")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Algorithm", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-SignedHeaders", valid_594729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594730: Call_GetPromoteReadReplica_594715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594730.validator(path, query, header, formData, body)
  let scheme = call_594730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594730.url(scheme.get, call_594730.host, call_594730.base,
                         call_594730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594730, url, valid)

proc call*(call_594731: Call_GetPromoteReadReplica_594715;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-09-09";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_594732 = newJObject()
  add(query_594732, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594732, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594732, "Action", newJString(Action))
  add(query_594732, "Version", newJString(Version))
  add(query_594732, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_594731.call(nil, query_594732, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_594715(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_594716, base: "/",
    url: url_GetPromoteReadReplica_594717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_594771 = ref object of OpenApiRestCall_592348
proc url_PostPurchaseReservedDBInstancesOffering_594773(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_594772(path: JsonNode;
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
  var valid_594774 = query.getOrDefault("Action")
  valid_594774 = validateParameter(valid_594774, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594774 != nil:
    section.add "Action", valid_594774
  var valid_594775 = query.getOrDefault("Version")
  valid_594775 = validateParameter(valid_594775, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594775 != nil:
    section.add "Version", valid_594775
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
  var valid_594776 = header.getOrDefault("X-Amz-Signature")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Signature", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Content-Sha256", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Date")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Date", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Credential")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Credential", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Security-Token")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Security-Token", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Algorithm")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Algorithm", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-SignedHeaders", valid_594782
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_594783 = formData.getOrDefault("ReservedDBInstanceId")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "ReservedDBInstanceId", valid_594783
  var valid_594784 = formData.getOrDefault("Tags")
  valid_594784 = validateParameter(valid_594784, JArray, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "Tags", valid_594784
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_594785 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594785 = validateParameter(valid_594785, JString, required = true,
                                 default = nil)
  if valid_594785 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594785
  var valid_594786 = formData.getOrDefault("DBInstanceCount")
  valid_594786 = validateParameter(valid_594786, JInt, required = false, default = nil)
  if valid_594786 != nil:
    section.add "DBInstanceCount", valid_594786
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594787: Call_PostPurchaseReservedDBInstancesOffering_594771;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594787.validator(path, query, header, formData, body)
  let scheme = call_594787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594787.url(scheme.get, call_594787.host, call_594787.base,
                         call_594787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594787, url, valid)

proc call*(call_594788: Call_PostPurchaseReservedDBInstancesOffering_594771;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2013-09-09"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_594789 = newJObject()
  var formData_594790 = newJObject()
  add(formData_594790, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594789, "Action", newJString(Action))
  if Tags != nil:
    formData_594790.add "Tags", Tags
  add(formData_594790, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594789, "Version", newJString(Version))
  add(formData_594790, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_594788.call(nil, query_594789, nil, formData_594790, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_594771(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_594772, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_594773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_594752 = ref object of OpenApiRestCall_592348
proc url_GetPurchaseReservedDBInstancesOffering_594754(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_594753(path: JsonNode;
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
  var valid_594755 = query.getOrDefault("Tags")
  valid_594755 = validateParameter(valid_594755, JArray, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "Tags", valid_594755
  var valid_594756 = query.getOrDefault("DBInstanceCount")
  valid_594756 = validateParameter(valid_594756, JInt, required = false, default = nil)
  if valid_594756 != nil:
    section.add "DBInstanceCount", valid_594756
  var valid_594757 = query.getOrDefault("ReservedDBInstanceId")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "ReservedDBInstanceId", valid_594757
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594758 = query.getOrDefault("Action")
  valid_594758 = validateParameter(valid_594758, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_594758 != nil:
    section.add "Action", valid_594758
  var valid_594759 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = nil)
  if valid_594759 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_594759
  var valid_594760 = query.getOrDefault("Version")
  valid_594760 = validateParameter(valid_594760, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594760 != nil:
    section.add "Version", valid_594760
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
  var valid_594761 = header.getOrDefault("X-Amz-Signature")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Signature", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Content-Sha256", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Date")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Date", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Credential")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Credential", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Security-Token")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Security-Token", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Algorithm")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Algorithm", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-SignedHeaders", valid_594767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594768: Call_GetPurchaseReservedDBInstancesOffering_594752;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594768.validator(path, query, header, formData, body)
  let scheme = call_594768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594768.url(scheme.get, call_594768.host, call_594768.base,
                         call_594768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594768, url, valid)

proc call*(call_594769: Call_GetPurchaseReservedDBInstancesOffering_594752;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_594770 = newJObject()
  if Tags != nil:
    query_594770.add "Tags", Tags
  add(query_594770, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_594770, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_594770, "Action", newJString(Action))
  add(query_594770, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_594770, "Version", newJString(Version))
  result = call_594769.call(nil, query_594770, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_594752(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_594753, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_594754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_594808 = ref object of OpenApiRestCall_592348
proc url_PostRebootDBInstance_594810(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_594809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594811 = query.getOrDefault("Action")
  valid_594811 = validateParameter(valid_594811, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594811 != nil:
    section.add "Action", valid_594811
  var valid_594812 = query.getOrDefault("Version")
  valid_594812 = validateParameter(valid_594812, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594812 != nil:
    section.add "Version", valid_594812
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
  var valid_594813 = header.getOrDefault("X-Amz-Signature")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Signature", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Content-Sha256", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Date")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Date", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Credential")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Credential", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Security-Token")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Security-Token", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Algorithm")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Algorithm", valid_594818
  var valid_594819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-SignedHeaders", valid_594819
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_594820 = formData.getOrDefault("ForceFailover")
  valid_594820 = validateParameter(valid_594820, JBool, required = false, default = nil)
  if valid_594820 != nil:
    section.add "ForceFailover", valid_594820
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594821 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594821 = validateParameter(valid_594821, JString, required = true,
                                 default = nil)
  if valid_594821 != nil:
    section.add "DBInstanceIdentifier", valid_594821
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594822: Call_PostRebootDBInstance_594808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594822.validator(path, query, header, formData, body)
  let scheme = call_594822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594822.url(scheme.get, call_594822.host, call_594822.base,
                         call_594822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594822, url, valid)

proc call*(call_594823: Call_PostRebootDBInstance_594808;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594824 = newJObject()
  var formData_594825 = newJObject()
  add(formData_594825, "ForceFailover", newJBool(ForceFailover))
  add(formData_594825, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594824, "Action", newJString(Action))
  add(query_594824, "Version", newJString(Version))
  result = call_594823.call(nil, query_594824, nil, formData_594825, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_594808(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_594809, base: "/",
    url: url_PostRebootDBInstance_594810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_594791 = ref object of OpenApiRestCall_592348
proc url_GetRebootDBInstance_594793(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_594792(path: JsonNode; query: JsonNode;
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
  var valid_594794 = query.getOrDefault("ForceFailover")
  valid_594794 = validateParameter(valid_594794, JBool, required = false, default = nil)
  if valid_594794 != nil:
    section.add "ForceFailover", valid_594794
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594795 = query.getOrDefault("DBInstanceIdentifier")
  valid_594795 = validateParameter(valid_594795, JString, required = true,
                                 default = nil)
  if valid_594795 != nil:
    section.add "DBInstanceIdentifier", valid_594795
  var valid_594796 = query.getOrDefault("Action")
  valid_594796 = validateParameter(valid_594796, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_594796 != nil:
    section.add "Action", valid_594796
  var valid_594797 = query.getOrDefault("Version")
  valid_594797 = validateParameter(valid_594797, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594797 != nil:
    section.add "Version", valid_594797
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
  var valid_594798 = header.getOrDefault("X-Amz-Signature")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Signature", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Content-Sha256", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Date")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Date", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Credential")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Credential", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Security-Token")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Security-Token", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Algorithm")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Algorithm", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-SignedHeaders", valid_594804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594805: Call_GetRebootDBInstance_594791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594805.validator(path, query, header, formData, body)
  let scheme = call_594805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594805.url(scheme.get, call_594805.host, call_594805.base,
                         call_594805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594805, url, valid)

proc call*(call_594806: Call_GetRebootDBInstance_594791;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594807 = newJObject()
  add(query_594807, "ForceFailover", newJBool(ForceFailover))
  add(query_594807, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594807, "Action", newJString(Action))
  add(query_594807, "Version", newJString(Version))
  result = call_594806.call(nil, query_594807, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_594791(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_594792, base: "/",
    url: url_GetRebootDBInstance_594793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_594843 = ref object of OpenApiRestCall_592348
proc url_PostRemoveSourceIdentifierFromSubscription_594845(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_594844(path: JsonNode;
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
  var valid_594846 = query.getOrDefault("Action")
  valid_594846 = validateParameter(valid_594846, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594846 != nil:
    section.add "Action", valid_594846
  var valid_594847 = query.getOrDefault("Version")
  valid_594847 = validateParameter(valid_594847, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594847 != nil:
    section.add "Version", valid_594847
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
  var valid_594848 = header.getOrDefault("X-Amz-Signature")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Signature", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Content-Sha256", valid_594849
  var valid_594850 = header.getOrDefault("X-Amz-Date")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "X-Amz-Date", valid_594850
  var valid_594851 = header.getOrDefault("X-Amz-Credential")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "X-Amz-Credential", valid_594851
  var valid_594852 = header.getOrDefault("X-Amz-Security-Token")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Security-Token", valid_594852
  var valid_594853 = header.getOrDefault("X-Amz-Algorithm")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Algorithm", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-SignedHeaders", valid_594854
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594855 = formData.getOrDefault("SubscriptionName")
  valid_594855 = validateParameter(valid_594855, JString, required = true,
                                 default = nil)
  if valid_594855 != nil:
    section.add "SubscriptionName", valid_594855
  var valid_594856 = formData.getOrDefault("SourceIdentifier")
  valid_594856 = validateParameter(valid_594856, JString, required = true,
                                 default = nil)
  if valid_594856 != nil:
    section.add "SourceIdentifier", valid_594856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594857: Call_PostRemoveSourceIdentifierFromSubscription_594843;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594857.validator(path, query, header, formData, body)
  let scheme = call_594857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594857.url(scheme.get, call_594857.host, call_594857.base,
                         call_594857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594857, url, valid)

proc call*(call_594858: Call_PostRemoveSourceIdentifierFromSubscription_594843;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594859 = newJObject()
  var formData_594860 = newJObject()
  add(formData_594860, "SubscriptionName", newJString(SubscriptionName))
  add(formData_594860, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594859, "Action", newJString(Action))
  add(query_594859, "Version", newJString(Version))
  result = call_594858.call(nil, query_594859, nil, formData_594860, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_594843(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_594844,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_594845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_594826 = ref object of OpenApiRestCall_592348
proc url_GetRemoveSourceIdentifierFromSubscription_594828(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_594827(path: JsonNode;
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
  var valid_594829 = query.getOrDefault("SourceIdentifier")
  valid_594829 = validateParameter(valid_594829, JString, required = true,
                                 default = nil)
  if valid_594829 != nil:
    section.add "SourceIdentifier", valid_594829
  var valid_594830 = query.getOrDefault("SubscriptionName")
  valid_594830 = validateParameter(valid_594830, JString, required = true,
                                 default = nil)
  if valid_594830 != nil:
    section.add "SubscriptionName", valid_594830
  var valid_594831 = query.getOrDefault("Action")
  valid_594831 = validateParameter(valid_594831, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_594831 != nil:
    section.add "Action", valid_594831
  var valid_594832 = query.getOrDefault("Version")
  valid_594832 = validateParameter(valid_594832, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594832 != nil:
    section.add "Version", valid_594832
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
  var valid_594833 = header.getOrDefault("X-Amz-Signature")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Signature", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Content-Sha256", valid_594834
  var valid_594835 = header.getOrDefault("X-Amz-Date")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "X-Amz-Date", valid_594835
  var valid_594836 = header.getOrDefault("X-Amz-Credential")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "X-Amz-Credential", valid_594836
  var valid_594837 = header.getOrDefault("X-Amz-Security-Token")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Security-Token", valid_594837
  var valid_594838 = header.getOrDefault("X-Amz-Algorithm")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Algorithm", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-SignedHeaders", valid_594839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594840: Call_GetRemoveSourceIdentifierFromSubscription_594826;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594840.validator(path, query, header, formData, body)
  let scheme = call_594840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594840.url(scheme.get, call_594840.host, call_594840.base,
                         call_594840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594840, url, valid)

proc call*(call_594841: Call_GetRemoveSourceIdentifierFromSubscription_594826;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594842 = newJObject()
  add(query_594842, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594842, "SubscriptionName", newJString(SubscriptionName))
  add(query_594842, "Action", newJString(Action))
  add(query_594842, "Version", newJString(Version))
  result = call_594841.call(nil, query_594842, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_594826(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_594827,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_594828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_594878 = ref object of OpenApiRestCall_592348
proc url_PostRemoveTagsFromResource_594880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_594879(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594881 = query.getOrDefault("Action")
  valid_594881 = validateParameter(valid_594881, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594881 != nil:
    section.add "Action", valid_594881
  var valid_594882 = query.getOrDefault("Version")
  valid_594882 = validateParameter(valid_594882, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594882 != nil:
    section.add "Version", valid_594882
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
  var valid_594883 = header.getOrDefault("X-Amz-Signature")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Signature", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Content-Sha256", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Date")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Date", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Credential")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Credential", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Security-Token")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Security-Token", valid_594887
  var valid_594888 = header.getOrDefault("X-Amz-Algorithm")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "X-Amz-Algorithm", valid_594888
  var valid_594889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-SignedHeaders", valid_594889
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594890 = formData.getOrDefault("TagKeys")
  valid_594890 = validateParameter(valid_594890, JArray, required = true, default = nil)
  if valid_594890 != nil:
    section.add "TagKeys", valid_594890
  var valid_594891 = formData.getOrDefault("ResourceName")
  valid_594891 = validateParameter(valid_594891, JString, required = true,
                                 default = nil)
  if valid_594891 != nil:
    section.add "ResourceName", valid_594891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594892: Call_PostRemoveTagsFromResource_594878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594892.validator(path, query, header, formData, body)
  let scheme = call_594892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594892.url(scheme.get, call_594892.host, call_594892.base,
                         call_594892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594892, url, valid)

proc call*(call_594893: Call_PostRemoveTagsFromResource_594878; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_594894 = newJObject()
  var formData_594895 = newJObject()
  if TagKeys != nil:
    formData_594895.add "TagKeys", TagKeys
  add(query_594894, "Action", newJString(Action))
  add(query_594894, "Version", newJString(Version))
  add(formData_594895, "ResourceName", newJString(ResourceName))
  result = call_594893.call(nil, query_594894, nil, formData_594895, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_594878(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_594879, base: "/",
    url: url_PostRemoveTagsFromResource_594880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_594861 = ref object of OpenApiRestCall_592348
proc url_GetRemoveTagsFromResource_594863(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_594862(path: JsonNode; query: JsonNode;
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
  var valid_594864 = query.getOrDefault("ResourceName")
  valid_594864 = validateParameter(valid_594864, JString, required = true,
                                 default = nil)
  if valid_594864 != nil:
    section.add "ResourceName", valid_594864
  var valid_594865 = query.getOrDefault("TagKeys")
  valid_594865 = validateParameter(valid_594865, JArray, required = true, default = nil)
  if valid_594865 != nil:
    section.add "TagKeys", valid_594865
  var valid_594866 = query.getOrDefault("Action")
  valid_594866 = validateParameter(valid_594866, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_594866 != nil:
    section.add "Action", valid_594866
  var valid_594867 = query.getOrDefault("Version")
  valid_594867 = validateParameter(valid_594867, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594875: Call_GetRemoveTagsFromResource_594861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594875.validator(path, query, header, formData, body)
  let scheme = call_594875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594875.url(scheme.get, call_594875.host, call_594875.base,
                         call_594875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594875, url, valid)

proc call*(call_594876: Call_GetRemoveTagsFromResource_594861;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594877 = newJObject()
  add(query_594877, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_594877.add "TagKeys", TagKeys
  add(query_594877, "Action", newJString(Action))
  add(query_594877, "Version", newJString(Version))
  result = call_594876.call(nil, query_594877, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_594861(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_594862, base: "/",
    url: url_GetRemoveTagsFromResource_594863,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_594914 = ref object of OpenApiRestCall_592348
proc url_PostResetDBParameterGroup_594916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_594915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594917 = query.getOrDefault("Action")
  valid_594917 = validateParameter(valid_594917, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594917 != nil:
    section.add "Action", valid_594917
  var valid_594918 = query.getOrDefault("Version")
  valid_594918 = validateParameter(valid_594918, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594918 != nil:
    section.add "Version", valid_594918
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
  var valid_594919 = header.getOrDefault("X-Amz-Signature")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Signature", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Content-Sha256", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Date")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Date", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Credential")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Credential", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Security-Token")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Security-Token", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-Algorithm")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-Algorithm", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-SignedHeaders", valid_594925
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_594926 = formData.getOrDefault("ResetAllParameters")
  valid_594926 = validateParameter(valid_594926, JBool, required = false, default = nil)
  if valid_594926 != nil:
    section.add "ResetAllParameters", valid_594926
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594927 = formData.getOrDefault("DBParameterGroupName")
  valid_594927 = validateParameter(valid_594927, JString, required = true,
                                 default = nil)
  if valid_594927 != nil:
    section.add "DBParameterGroupName", valid_594927
  var valid_594928 = formData.getOrDefault("Parameters")
  valid_594928 = validateParameter(valid_594928, JArray, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "Parameters", valid_594928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594929: Call_PostResetDBParameterGroup_594914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594929.validator(path, query, header, formData, body)
  let scheme = call_594929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594929.url(scheme.get, call_594929.host, call_594929.base,
                         call_594929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594929, url, valid)

proc call*(call_594930: Call_PostResetDBParameterGroup_594914;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_594931 = newJObject()
  var formData_594932 = newJObject()
  add(formData_594932, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_594932, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594931, "Action", newJString(Action))
  if Parameters != nil:
    formData_594932.add "Parameters", Parameters
  add(query_594931, "Version", newJString(Version))
  result = call_594930.call(nil, query_594931, nil, formData_594932, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_594914(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_594915, base: "/",
    url: url_PostResetDBParameterGroup_594916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_594896 = ref object of OpenApiRestCall_592348
proc url_GetResetDBParameterGroup_594898(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_594897(path: JsonNode; query: JsonNode;
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
  var valid_594899 = query.getOrDefault("DBParameterGroupName")
  valid_594899 = validateParameter(valid_594899, JString, required = true,
                                 default = nil)
  if valid_594899 != nil:
    section.add "DBParameterGroupName", valid_594899
  var valid_594900 = query.getOrDefault("Parameters")
  valid_594900 = validateParameter(valid_594900, JArray, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "Parameters", valid_594900
  var valid_594901 = query.getOrDefault("ResetAllParameters")
  valid_594901 = validateParameter(valid_594901, JBool, required = false, default = nil)
  if valid_594901 != nil:
    section.add "ResetAllParameters", valid_594901
  var valid_594902 = query.getOrDefault("Action")
  valid_594902 = validateParameter(valid_594902, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_594902 != nil:
    section.add "Action", valid_594902
  var valid_594903 = query.getOrDefault("Version")
  valid_594903 = validateParameter(valid_594903, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594903 != nil:
    section.add "Version", valid_594903
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
  var valid_594904 = header.getOrDefault("X-Amz-Signature")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Signature", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Content-Sha256", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Date")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Date", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Credential")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Credential", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Security-Token")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Security-Token", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-Algorithm")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-Algorithm", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-SignedHeaders", valid_594910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594911: Call_GetResetDBParameterGroup_594896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594911.validator(path, query, header, formData, body)
  let scheme = call_594911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594911.url(scheme.get, call_594911.host, call_594911.base,
                         call_594911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594911, url, valid)

proc call*(call_594912: Call_GetResetDBParameterGroup_594896;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594913 = newJObject()
  add(query_594913, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_594913.add "Parameters", Parameters
  add(query_594913, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_594913, "Action", newJString(Action))
  add(query_594913, "Version", newJString(Version))
  result = call_594912.call(nil, query_594913, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_594896(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_594897, base: "/",
    url: url_GetResetDBParameterGroup_594898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_594963 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceFromDBSnapshot_594965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_594964(path: JsonNode;
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
  var valid_594966 = query.getOrDefault("Action")
  valid_594966 = validateParameter(valid_594966, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594966 != nil:
    section.add "Action", valid_594966
  var valid_594967 = query.getOrDefault("Version")
  valid_594967 = validateParameter(valid_594967, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594967 != nil:
    section.add "Version", valid_594967
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
  var valid_594968 = header.getOrDefault("X-Amz-Signature")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-Signature", valid_594968
  var valid_594969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594969 = validateParameter(valid_594969, JString, required = false,
                                 default = nil)
  if valid_594969 != nil:
    section.add "X-Amz-Content-Sha256", valid_594969
  var valid_594970 = header.getOrDefault("X-Amz-Date")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "X-Amz-Date", valid_594970
  var valid_594971 = header.getOrDefault("X-Amz-Credential")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Credential", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Security-Token")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Security-Token", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Algorithm")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Algorithm", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-SignedHeaders", valid_594974
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_594975 = formData.getOrDefault("Port")
  valid_594975 = validateParameter(valid_594975, JInt, required = false, default = nil)
  if valid_594975 != nil:
    section.add "Port", valid_594975
  var valid_594976 = formData.getOrDefault("DBInstanceClass")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "DBInstanceClass", valid_594976
  var valid_594977 = formData.getOrDefault("MultiAZ")
  valid_594977 = validateParameter(valid_594977, JBool, required = false, default = nil)
  if valid_594977 != nil:
    section.add "MultiAZ", valid_594977
  var valid_594978 = formData.getOrDefault("AvailabilityZone")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "AvailabilityZone", valid_594978
  var valid_594979 = formData.getOrDefault("Engine")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "Engine", valid_594979
  var valid_594980 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594980 = validateParameter(valid_594980, JBool, required = false, default = nil)
  if valid_594980 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594980
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594981 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594981 = validateParameter(valid_594981, JString, required = true,
                                 default = nil)
  if valid_594981 != nil:
    section.add "DBInstanceIdentifier", valid_594981
  var valid_594982 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594982 = validateParameter(valid_594982, JString, required = true,
                                 default = nil)
  if valid_594982 != nil:
    section.add "DBSnapshotIdentifier", valid_594982
  var valid_594983 = formData.getOrDefault("DBName")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "DBName", valid_594983
  var valid_594984 = formData.getOrDefault("Iops")
  valid_594984 = validateParameter(valid_594984, JInt, required = false, default = nil)
  if valid_594984 != nil:
    section.add "Iops", valid_594984
  var valid_594985 = formData.getOrDefault("PubliclyAccessible")
  valid_594985 = validateParameter(valid_594985, JBool, required = false, default = nil)
  if valid_594985 != nil:
    section.add "PubliclyAccessible", valid_594985
  var valid_594986 = formData.getOrDefault("LicenseModel")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "LicenseModel", valid_594986
  var valid_594987 = formData.getOrDefault("Tags")
  valid_594987 = validateParameter(valid_594987, JArray, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "Tags", valid_594987
  var valid_594988 = formData.getOrDefault("DBSubnetGroupName")
  valid_594988 = validateParameter(valid_594988, JString, required = false,
                                 default = nil)
  if valid_594988 != nil:
    section.add "DBSubnetGroupName", valid_594988
  var valid_594989 = formData.getOrDefault("OptionGroupName")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "OptionGroupName", valid_594989
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594990: Call_PostRestoreDBInstanceFromDBSnapshot_594963;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594990.validator(path, query, header, formData, body)
  let scheme = call_594990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594990.url(scheme.get, call_594990.host, call_594990.base,
                         call_594990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594990, url, valid)

proc call*(call_594991: Call_PostRestoreDBInstanceFromDBSnapshot_594963;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_594992 = newJObject()
  var formData_594993 = newJObject()
  add(formData_594993, "Port", newJInt(Port))
  add(formData_594993, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594993, "MultiAZ", newJBool(MultiAZ))
  add(formData_594993, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594993, "Engine", newJString(Engine))
  add(formData_594993, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594993, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594993, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_594993, "DBName", newJString(DBName))
  add(formData_594993, "Iops", newJInt(Iops))
  add(formData_594993, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594992, "Action", newJString(Action))
  add(formData_594993, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_594993.add "Tags", Tags
  add(formData_594993, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594993, "OptionGroupName", newJString(OptionGroupName))
  add(query_594992, "Version", newJString(Version))
  result = call_594991.call(nil, query_594992, nil, formData_594993, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_594963(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_594964, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_594965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_594933 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceFromDBSnapshot_594935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_594934(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   Tags: JArray
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
  var valid_594936 = query.getOrDefault("DBName")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "DBName", valid_594936
  var valid_594937 = query.getOrDefault("Engine")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "Engine", valid_594937
  var valid_594938 = query.getOrDefault("Tags")
  valid_594938 = validateParameter(valid_594938, JArray, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "Tags", valid_594938
  var valid_594939 = query.getOrDefault("LicenseModel")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "LicenseModel", valid_594939
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594940 = query.getOrDefault("DBInstanceIdentifier")
  valid_594940 = validateParameter(valid_594940, JString, required = true,
                                 default = nil)
  if valid_594940 != nil:
    section.add "DBInstanceIdentifier", valid_594940
  var valid_594941 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594941 = validateParameter(valid_594941, JString, required = true,
                                 default = nil)
  if valid_594941 != nil:
    section.add "DBSnapshotIdentifier", valid_594941
  var valid_594942 = query.getOrDefault("Action")
  valid_594942 = validateParameter(valid_594942, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_594942 != nil:
    section.add "Action", valid_594942
  var valid_594943 = query.getOrDefault("MultiAZ")
  valid_594943 = validateParameter(valid_594943, JBool, required = false, default = nil)
  if valid_594943 != nil:
    section.add "MultiAZ", valid_594943
  var valid_594944 = query.getOrDefault("Port")
  valid_594944 = validateParameter(valid_594944, JInt, required = false, default = nil)
  if valid_594944 != nil:
    section.add "Port", valid_594944
  var valid_594945 = query.getOrDefault("AvailabilityZone")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "AvailabilityZone", valid_594945
  var valid_594946 = query.getOrDefault("OptionGroupName")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "OptionGroupName", valid_594946
  var valid_594947 = query.getOrDefault("DBSubnetGroupName")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "DBSubnetGroupName", valid_594947
  var valid_594948 = query.getOrDefault("Version")
  valid_594948 = validateParameter(valid_594948, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_594948 != nil:
    section.add "Version", valid_594948
  var valid_594949 = query.getOrDefault("DBInstanceClass")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "DBInstanceClass", valid_594949
  var valid_594950 = query.getOrDefault("PubliclyAccessible")
  valid_594950 = validateParameter(valid_594950, JBool, required = false, default = nil)
  if valid_594950 != nil:
    section.add "PubliclyAccessible", valid_594950
  var valid_594951 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594951 = validateParameter(valid_594951, JBool, required = false, default = nil)
  if valid_594951 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594951
  var valid_594952 = query.getOrDefault("Iops")
  valid_594952 = validateParameter(valid_594952, JInt, required = false, default = nil)
  if valid_594952 != nil:
    section.add "Iops", valid_594952
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
  var valid_594953 = header.getOrDefault("X-Amz-Signature")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Signature", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Content-Sha256", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Date")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Date", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Credential")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Credential", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Security-Token")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Security-Token", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Algorithm")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Algorithm", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-SignedHeaders", valid_594959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594960: Call_GetRestoreDBInstanceFromDBSnapshot_594933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594960.validator(path, query, header, formData, body)
  let scheme = call_594960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594960.url(scheme.get, call_594960.host, call_594960.base,
                         call_594960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594960, url, valid)

proc call*(call_594961: Call_GetRestoreDBInstanceFromDBSnapshot_594933;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
  ##   Tags: JArray
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
  var query_594962 = newJObject()
  add(query_594962, "DBName", newJString(DBName))
  add(query_594962, "Engine", newJString(Engine))
  if Tags != nil:
    query_594962.add "Tags", Tags
  add(query_594962, "LicenseModel", newJString(LicenseModel))
  add(query_594962, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594962, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594962, "Action", newJString(Action))
  add(query_594962, "MultiAZ", newJBool(MultiAZ))
  add(query_594962, "Port", newJInt(Port))
  add(query_594962, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594962, "OptionGroupName", newJString(OptionGroupName))
  add(query_594962, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594962, "Version", newJString(Version))
  add(query_594962, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594962, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594962, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594962, "Iops", newJInt(Iops))
  result = call_594961.call(nil, query_594962, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_594933(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_594934, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_594935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_595026 = ref object of OpenApiRestCall_592348
proc url_PostRestoreDBInstanceToPointInTime_595028(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_595027(path: JsonNode;
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
  var valid_595029 = query.getOrDefault("Action")
  valid_595029 = validateParameter(valid_595029, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595029 != nil:
    section.add "Action", valid_595029
  var valid_595030 = query.getOrDefault("Version")
  valid_595030 = validateParameter(valid_595030, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595030 != nil:
    section.add "Version", valid_595030
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
  var valid_595031 = header.getOrDefault("X-Amz-Signature")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Signature", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Content-Sha256", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Date")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Date", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Credential")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Credential", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Security-Token")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Security-Token", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Algorithm")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Algorithm", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-SignedHeaders", valid_595037
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_595038 = formData.getOrDefault("Port")
  valid_595038 = validateParameter(valid_595038, JInt, required = false, default = nil)
  if valid_595038 != nil:
    section.add "Port", valid_595038
  var valid_595039 = formData.getOrDefault("DBInstanceClass")
  valid_595039 = validateParameter(valid_595039, JString, required = false,
                                 default = nil)
  if valid_595039 != nil:
    section.add "DBInstanceClass", valid_595039
  var valid_595040 = formData.getOrDefault("MultiAZ")
  valid_595040 = validateParameter(valid_595040, JBool, required = false, default = nil)
  if valid_595040 != nil:
    section.add "MultiAZ", valid_595040
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_595041 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_595041 = validateParameter(valid_595041, JString, required = true,
                                 default = nil)
  if valid_595041 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595041
  var valid_595042 = formData.getOrDefault("AvailabilityZone")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "AvailabilityZone", valid_595042
  var valid_595043 = formData.getOrDefault("Engine")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "Engine", valid_595043
  var valid_595044 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595044 = validateParameter(valid_595044, JBool, required = false, default = nil)
  if valid_595044 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595044
  var valid_595045 = formData.getOrDefault("UseLatestRestorableTime")
  valid_595045 = validateParameter(valid_595045, JBool, required = false, default = nil)
  if valid_595045 != nil:
    section.add "UseLatestRestorableTime", valid_595045
  var valid_595046 = formData.getOrDefault("DBName")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "DBName", valid_595046
  var valid_595047 = formData.getOrDefault("Iops")
  valid_595047 = validateParameter(valid_595047, JInt, required = false, default = nil)
  if valid_595047 != nil:
    section.add "Iops", valid_595047
  var valid_595048 = formData.getOrDefault("PubliclyAccessible")
  valid_595048 = validateParameter(valid_595048, JBool, required = false, default = nil)
  if valid_595048 != nil:
    section.add "PubliclyAccessible", valid_595048
  var valid_595049 = formData.getOrDefault("LicenseModel")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "LicenseModel", valid_595049
  var valid_595050 = formData.getOrDefault("Tags")
  valid_595050 = validateParameter(valid_595050, JArray, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "Tags", valid_595050
  var valid_595051 = formData.getOrDefault("DBSubnetGroupName")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "DBSubnetGroupName", valid_595051
  var valid_595052 = formData.getOrDefault("OptionGroupName")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "OptionGroupName", valid_595052
  var valid_595053 = formData.getOrDefault("RestoreTime")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "RestoreTime", valid_595053
  var valid_595054 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_595054 = validateParameter(valid_595054, JString, required = true,
                                 default = nil)
  if valid_595054 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595055: Call_PostRestoreDBInstanceToPointInTime_595026;
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

proc call*(call_595056: Call_PostRestoreDBInstanceToPointInTime_595026;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2013-09-09"): Recallable =
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
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_595057 = newJObject()
  var formData_595058 = newJObject()
  add(formData_595058, "Port", newJInt(Port))
  add(formData_595058, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595058, "MultiAZ", newJBool(MultiAZ))
  add(formData_595058, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_595058, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_595058, "Engine", newJString(Engine))
  add(formData_595058, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595058, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_595058, "DBName", newJString(DBName))
  add(formData_595058, "Iops", newJInt(Iops))
  add(formData_595058, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595057, "Action", newJString(Action))
  add(formData_595058, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_595058.add "Tags", Tags
  add(formData_595058, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595058, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595058, "RestoreTime", newJString(RestoreTime))
  add(formData_595058, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595057, "Version", newJString(Version))
  result = call_595056.call(nil, query_595057, nil, formData_595058, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_595026(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_595027, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_595028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_594994 = ref object of OpenApiRestCall_592348
proc url_GetRestoreDBInstanceToPointInTime_594996(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_594995(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
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
  var valid_594997 = query.getOrDefault("DBName")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "DBName", valid_594997
  var valid_594998 = query.getOrDefault("Engine")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "Engine", valid_594998
  var valid_594999 = query.getOrDefault("UseLatestRestorableTime")
  valid_594999 = validateParameter(valid_594999, JBool, required = false, default = nil)
  if valid_594999 != nil:
    section.add "UseLatestRestorableTime", valid_594999
  var valid_595000 = query.getOrDefault("Tags")
  valid_595000 = validateParameter(valid_595000, JArray, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "Tags", valid_595000
  var valid_595001 = query.getOrDefault("LicenseModel")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "LicenseModel", valid_595001
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_595002 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_595002 = validateParameter(valid_595002, JString, required = true,
                                 default = nil)
  if valid_595002 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595002
  var valid_595003 = query.getOrDefault("Action")
  valid_595003 = validateParameter(valid_595003, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595003 != nil:
    section.add "Action", valid_595003
  var valid_595004 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_595004 = validateParameter(valid_595004, JString, required = true,
                                 default = nil)
  if valid_595004 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595004
  var valid_595005 = query.getOrDefault("MultiAZ")
  valid_595005 = validateParameter(valid_595005, JBool, required = false, default = nil)
  if valid_595005 != nil:
    section.add "MultiAZ", valid_595005
  var valid_595006 = query.getOrDefault("Port")
  valid_595006 = validateParameter(valid_595006, JInt, required = false, default = nil)
  if valid_595006 != nil:
    section.add "Port", valid_595006
  var valid_595007 = query.getOrDefault("AvailabilityZone")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "AvailabilityZone", valid_595007
  var valid_595008 = query.getOrDefault("OptionGroupName")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "OptionGroupName", valid_595008
  var valid_595009 = query.getOrDefault("DBSubnetGroupName")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "DBSubnetGroupName", valid_595009
  var valid_595010 = query.getOrDefault("RestoreTime")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "RestoreTime", valid_595010
  var valid_595011 = query.getOrDefault("DBInstanceClass")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "DBInstanceClass", valid_595011
  var valid_595012 = query.getOrDefault("PubliclyAccessible")
  valid_595012 = validateParameter(valid_595012, JBool, required = false, default = nil)
  if valid_595012 != nil:
    section.add "PubliclyAccessible", valid_595012
  var valid_595013 = query.getOrDefault("Version")
  valid_595013 = validateParameter(valid_595013, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595013 != nil:
    section.add "Version", valid_595013
  var valid_595014 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595014 = validateParameter(valid_595014, JBool, required = false, default = nil)
  if valid_595014 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595014
  var valid_595015 = query.getOrDefault("Iops")
  valid_595015 = validateParameter(valid_595015, JInt, required = false, default = nil)
  if valid_595015 != nil:
    section.add "Iops", valid_595015
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
  var valid_595016 = header.getOrDefault("X-Amz-Signature")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Signature", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Content-Sha256", valid_595017
  var valid_595018 = header.getOrDefault("X-Amz-Date")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "X-Amz-Date", valid_595018
  var valid_595019 = header.getOrDefault("X-Amz-Credential")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "X-Amz-Credential", valid_595019
  var valid_595020 = header.getOrDefault("X-Amz-Security-Token")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "X-Amz-Security-Token", valid_595020
  var valid_595021 = header.getOrDefault("X-Amz-Algorithm")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Algorithm", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-SignedHeaders", valid_595022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595023: Call_GetRestoreDBInstanceToPointInTime_594994;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595023.validator(path, query, header, formData, body)
  let scheme = call_595023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595023.url(scheme.get, call_595023.host, call_595023.base,
                         call_595023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595023, url, valid)

proc call*(call_595024: Call_GetRestoreDBInstanceToPointInTime_594994;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-09-09"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
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
  var query_595025 = newJObject()
  add(query_595025, "DBName", newJString(DBName))
  add(query_595025, "Engine", newJString(Engine))
  add(query_595025, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_595025.add "Tags", Tags
  add(query_595025, "LicenseModel", newJString(LicenseModel))
  add(query_595025, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595025, "Action", newJString(Action))
  add(query_595025, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_595025, "MultiAZ", newJBool(MultiAZ))
  add(query_595025, "Port", newJInt(Port))
  add(query_595025, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595025, "OptionGroupName", newJString(OptionGroupName))
  add(query_595025, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595025, "RestoreTime", newJString(RestoreTime))
  add(query_595025, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595025, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595025, "Version", newJString(Version))
  add(query_595025, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595025, "Iops", newJInt(Iops))
  result = call_595024.call(nil, query_595025, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_594994(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_594995, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_594996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_595079 = ref object of OpenApiRestCall_592348
proc url_PostRevokeDBSecurityGroupIngress_595081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_595080(path: JsonNode;
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
  var valid_595082 = query.getOrDefault("Action")
  valid_595082 = validateParameter(valid_595082, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595082 != nil:
    section.add "Action", valid_595082
  var valid_595083 = query.getOrDefault("Version")
  valid_595083 = validateParameter(valid_595083, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595083 != nil:
    section.add "Version", valid_595083
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
  var valid_595084 = header.getOrDefault("X-Amz-Signature")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Signature", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Content-Sha256", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-Date")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Date", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-Credential")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Credential", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Security-Token")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Security-Token", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Algorithm")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Algorithm", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-SignedHeaders", valid_595090
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595091 = formData.getOrDefault("DBSecurityGroupName")
  valid_595091 = validateParameter(valid_595091, JString, required = true,
                                 default = nil)
  if valid_595091 != nil:
    section.add "DBSecurityGroupName", valid_595091
  var valid_595092 = formData.getOrDefault("EC2SecurityGroupName")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "EC2SecurityGroupName", valid_595092
  var valid_595093 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595093
  var valid_595094 = formData.getOrDefault("EC2SecurityGroupId")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "EC2SecurityGroupId", valid_595094
  var valid_595095 = formData.getOrDefault("CIDRIP")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "CIDRIP", valid_595095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595096: Call_PostRevokeDBSecurityGroupIngress_595079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595096.validator(path, query, header, formData, body)
  let scheme = call_595096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595096.url(scheme.get, call_595096.host, call_595096.base,
                         call_595096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595096, url, valid)

proc call*(call_595097: Call_PostRevokeDBSecurityGroupIngress_595079;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595098 = newJObject()
  var formData_595099 = newJObject()
  add(formData_595099, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_595099, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_595099, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_595099, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_595099, "CIDRIP", newJString(CIDRIP))
  add(query_595098, "Action", newJString(Action))
  add(query_595098, "Version", newJString(Version))
  result = call_595097.call(nil, query_595098, nil, formData_595099, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_595079(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_595080, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_595081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_595059 = ref object of OpenApiRestCall_592348
proc url_GetRevokeDBSecurityGroupIngress_595061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_595060(path: JsonNode;
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
  var valid_595062 = query.getOrDefault("EC2SecurityGroupName")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "EC2SecurityGroupName", valid_595062
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595063 = query.getOrDefault("DBSecurityGroupName")
  valid_595063 = validateParameter(valid_595063, JString, required = true,
                                 default = nil)
  if valid_595063 != nil:
    section.add "DBSecurityGroupName", valid_595063
  var valid_595064 = query.getOrDefault("EC2SecurityGroupId")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "EC2SecurityGroupId", valid_595064
  var valid_595065 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595065
  var valid_595066 = query.getOrDefault("Action")
  valid_595066 = validateParameter(valid_595066, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595066 != nil:
    section.add "Action", valid_595066
  var valid_595067 = query.getOrDefault("Version")
  valid_595067 = validateParameter(valid_595067, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_595067 != nil:
    section.add "Version", valid_595067
  var valid_595068 = query.getOrDefault("CIDRIP")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "CIDRIP", valid_595068
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
  var valid_595069 = header.getOrDefault("X-Amz-Signature")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Signature", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Content-Sha256", valid_595070
  var valid_595071 = header.getOrDefault("X-Amz-Date")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "X-Amz-Date", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-Credential")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-Credential", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Security-Token")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Security-Token", valid_595073
  var valid_595074 = header.getOrDefault("X-Amz-Algorithm")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Algorithm", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-SignedHeaders", valid_595075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595076: Call_GetRevokeDBSecurityGroupIngress_595059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595076.validator(path, query, header, formData, body)
  let scheme = call_595076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595076.url(scheme.get, call_595076.host, call_595076.base,
                         call_595076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595076, url, valid)

proc call*(call_595077: Call_GetRevokeDBSecurityGroupIngress_595059;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_595078 = newJObject()
  add(query_595078, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_595078, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_595078, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_595078, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_595078, "Action", newJString(Action))
  add(query_595078, "Version", newJString(Version))
  add(query_595078, "CIDRIP", newJString(CIDRIP))
  result = call_595077.call(nil, query_595078, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_595059(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_595060, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_595061,
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

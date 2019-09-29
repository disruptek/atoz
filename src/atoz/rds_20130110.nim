
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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
  Call_PostAddSourceIdentifierToSubscription_594030 = ref object of OpenApiRestCall_593421
proc url_PostAddSourceIdentifierToSubscription_594032(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_594031(path: JsonNode;
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
  var valid_594033 = query.getOrDefault("Action")
  valid_594033 = validateParameter(valid_594033, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_594033 != nil:
    section.add "Action", valid_594033
  var valid_594034 = query.getOrDefault("Version")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594034 != nil:
    section.add "Version", valid_594034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-SignedHeaders", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_594042 = formData.getOrDefault("SourceIdentifier")
  valid_594042 = validateParameter(valid_594042, JString, required = true,
                                 default = nil)
  if valid_594042 != nil:
    section.add "SourceIdentifier", valid_594042
  var valid_594043 = formData.getOrDefault("SubscriptionName")
  valid_594043 = validateParameter(valid_594043, JString, required = true,
                                 default = nil)
  if valid_594043 != nil:
    section.add "SubscriptionName", valid_594043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_PostAddSourceIdentifierToSubscription_594030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_PostAddSourceIdentifierToSubscription_594030;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594046 = newJObject()
  var formData_594047 = newJObject()
  add(formData_594047, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_594047, "SubscriptionName", newJString(SubscriptionName))
  add(query_594046, "Action", newJString(Action))
  add(query_594046, "Version", newJString(Version))
  result = call_594045.call(nil, query_594046, nil, formData_594047, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_594030(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_594031, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_594032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_593758 = ref object of OpenApiRestCall_593421
proc url_GetAddSourceIdentifierToSubscription_593760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_593759(path: JsonNode;
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
  var valid_593885 = query.getOrDefault("Action")
  valid_593885 = validateParameter(valid_593885, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_593885 != nil:
    section.add "Action", valid_593885
  var valid_593886 = query.getOrDefault("SourceIdentifier")
  valid_593886 = validateParameter(valid_593886, JString, required = true,
                                 default = nil)
  if valid_593886 != nil:
    section.add "SourceIdentifier", valid_593886
  var valid_593887 = query.getOrDefault("SubscriptionName")
  valid_593887 = validateParameter(valid_593887, JString, required = true,
                                 default = nil)
  if valid_593887 != nil:
    section.add "SubscriptionName", valid_593887
  var valid_593888 = query.getOrDefault("Version")
  valid_593888 = validateParameter(valid_593888, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_593888 != nil:
    section.add "Version", valid_593888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593889 = header.getOrDefault("X-Amz-Date")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Date", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Content-Sha256", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Algorithm")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Algorithm", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Signature")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Signature", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-SignedHeaders", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Credential")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Credential", valid_593895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_GetAddSourceIdentifierToSubscription_593758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593989: Call_GetAddSourceIdentifierToSubscription_593758;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_593990 = newJObject()
  add(query_593990, "Action", newJString(Action))
  add(query_593990, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_593990, "SubscriptionName", newJString(SubscriptionName))
  add(query_593990, "Version", newJString(Version))
  result = call_593989.call(nil, query_593990, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_593758(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_593759, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_593760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_594065 = ref object of OpenApiRestCall_593421
proc url_PostAddTagsToResource_594067(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_594066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594068 = query.getOrDefault("Action")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_594068 != nil:
    section.add "Action", valid_594068
  var valid_594069 = query.getOrDefault("Version")
  valid_594069 = validateParameter(valid_594069, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594069 != nil:
    section.add "Version", valid_594069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594070 = header.getOrDefault("X-Amz-Date")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Date", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Security-Token")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Security-Token", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Content-Sha256", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Algorithm")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Algorithm", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Signature")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Signature", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Credential")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Credential", valid_594076
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_594077 = formData.getOrDefault("Tags")
  valid_594077 = validateParameter(valid_594077, JArray, required = true, default = nil)
  if valid_594077 != nil:
    section.add "Tags", valid_594077
  var valid_594078 = formData.getOrDefault("ResourceName")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "ResourceName", valid_594078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594079: Call_PostAddTagsToResource_594065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594079.validator(path, query, header, formData, body)
  let scheme = call_594079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594079.url(scheme.get, call_594079.host, call_594079.base,
                         call_594079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594079, url, valid)

proc call*(call_594080: Call_PostAddTagsToResource_594065; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_594081 = newJObject()
  var formData_594082 = newJObject()
  if Tags != nil:
    formData_594082.add "Tags", Tags
  add(query_594081, "Action", newJString(Action))
  add(formData_594082, "ResourceName", newJString(ResourceName))
  add(query_594081, "Version", newJString(Version))
  result = call_594080.call(nil, query_594081, nil, formData_594082, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_594065(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_594066, base: "/",
    url: url_PostAddTagsToResource_594067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_594048 = ref object of OpenApiRestCall_593421
proc url_GetAddTagsToResource_594050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = query.getOrDefault("Tags")
  valid_594051 = validateParameter(valid_594051, JArray, required = true, default = nil)
  if valid_594051 != nil:
    section.add "Tags", valid_594051
  var valid_594052 = query.getOrDefault("ResourceName")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "ResourceName", valid_594052
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("Version")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594054 != nil:
    section.add "Version", valid_594054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594055 = header.getOrDefault("X-Amz-Date")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Date", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Security-Token")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Security-Token", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Content-Sha256", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Algorithm")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Algorithm", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-SignedHeaders", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Credential")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Credential", valid_594061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594062: Call_GetAddTagsToResource_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594062.validator(path, query, header, formData, body)
  let scheme = call_594062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594062.url(scheme.get, call_594062.host, call_594062.base,
                         call_594062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594062, url, valid)

proc call*(call_594063: Call_GetAddTagsToResource_594048; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594064 = newJObject()
  if Tags != nil:
    query_594064.add "Tags", Tags
  add(query_594064, "ResourceName", newJString(ResourceName))
  add(query_594064, "Action", newJString(Action))
  add(query_594064, "Version", newJString(Version))
  result = call_594063.call(nil, query_594064, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_594048(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_594049, base: "/",
    url: url_GetAddTagsToResource_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_594103 = ref object of OpenApiRestCall_593421
proc url_PostAuthorizeDBSecurityGroupIngress_594105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_594104(path: JsonNode;
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
  var valid_594106 = query.getOrDefault("Action")
  valid_594106 = validateParameter(valid_594106, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_594106 != nil:
    section.add "Action", valid_594106
  var valid_594107 = query.getOrDefault("Version")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594107 != nil:
    section.add "Version", valid_594107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594108 = header.getOrDefault("X-Amz-Date")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Date", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Algorithm")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Algorithm", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-SignedHeaders", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594115 = formData.getOrDefault("DBSecurityGroupName")
  valid_594115 = validateParameter(valid_594115, JString, required = true,
                                 default = nil)
  if valid_594115 != nil:
    section.add "DBSecurityGroupName", valid_594115
  var valid_594116 = formData.getOrDefault("EC2SecurityGroupName")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "EC2SecurityGroupName", valid_594116
  var valid_594117 = formData.getOrDefault("EC2SecurityGroupId")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "EC2SecurityGroupId", valid_594117
  var valid_594118 = formData.getOrDefault("CIDRIP")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "CIDRIP", valid_594118
  var valid_594119 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594120: Call_PostAuthorizeDBSecurityGroupIngress_594103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594120.validator(path, query, header, formData, body)
  let scheme = call_594120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594120.url(scheme.get, call_594120.host, call_594120.base,
                         call_594120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594120, url, valid)

proc call*(call_594121: Call_PostAuthorizeDBSecurityGroupIngress_594103;
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
  var query_594122 = newJObject()
  var formData_594123 = newJObject()
  add(formData_594123, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594122, "Action", newJString(Action))
  add(formData_594123, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_594123, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_594123, "CIDRIP", newJString(CIDRIP))
  add(query_594122, "Version", newJString(Version))
  add(formData_594123, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_594121.call(nil, query_594122, nil, formData_594123, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_594103(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_594104, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_594105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_594083 = ref object of OpenApiRestCall_593421
proc url_GetAuthorizeDBSecurityGroupIngress_594085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_594084(path: JsonNode;
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
  var valid_594086 = query.getOrDefault("EC2SecurityGroupId")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "EC2SecurityGroupId", valid_594086
  var valid_594087 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_594087
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594088 = query.getOrDefault("DBSecurityGroupName")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = nil)
  if valid_594088 != nil:
    section.add "DBSecurityGroupName", valid_594088
  var valid_594089 = query.getOrDefault("Action")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_594089 != nil:
    section.add "Action", valid_594089
  var valid_594090 = query.getOrDefault("CIDRIP")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "CIDRIP", valid_594090
  var valid_594091 = query.getOrDefault("EC2SecurityGroupName")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "EC2SecurityGroupName", valid_594091
  var valid_594092 = query.getOrDefault("Version")
  valid_594092 = validateParameter(valid_594092, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594092 != nil:
    section.add "Version", valid_594092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Content-Sha256", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Credential")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Credential", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_GetAuthorizeDBSecurityGroupIngress_594083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_GetAuthorizeDBSecurityGroupIngress_594083;
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
  var query_594102 = newJObject()
  add(query_594102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_594102, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_594102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594102, "Action", newJString(Action))
  add(query_594102, "CIDRIP", newJString(CIDRIP))
  add(query_594102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_594102, "Version", newJString(Version))
  result = call_594101.call(nil, query_594102, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_594083(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_594084, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_594085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_594141 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBSnapshot_594143(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_594142(path: JsonNode; query: JsonNode;
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
  var valid_594144 = query.getOrDefault("Action")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594144 != nil:
    section.add "Action", valid_594144
  var valid_594145 = query.getOrDefault("Version")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594145 != nil:
    section.add "Version", valid_594145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Security-Token")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Security-Token", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Content-Sha256", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-SignedHeaders", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Credential")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Credential", valid_594152
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_594153 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594153 = validateParameter(valid_594153, JString, required = true,
                                 default = nil)
  if valid_594153 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594153
  var valid_594154 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594154 = validateParameter(valid_594154, JString, required = true,
                                 default = nil)
  if valid_594154 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594155: Call_PostCopyDBSnapshot_594141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594155.validator(path, query, header, formData, body)
  let scheme = call_594155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594155.url(scheme.get, call_594155.host, call_594155.base,
                         call_594155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594155, url, valid)

proc call*(call_594156: Call_PostCopyDBSnapshot_594141;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594157 = newJObject()
  var formData_594158 = newJObject()
  add(formData_594158, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_594157, "Action", newJString(Action))
  add(formData_594158, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594157, "Version", newJString(Version))
  result = call_594156.call(nil, query_594157, nil, formData_594158, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_594141(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_594142, base: "/",
    url: url_PostCopyDBSnapshot_594143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_594124 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBSnapshot_594126(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_594125(path: JsonNode; query: JsonNode;
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
  var valid_594127 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_594127 = validateParameter(valid_594127, JString, required = true,
                                 default = nil)
  if valid_594127 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_594127
  var valid_594128 = query.getOrDefault("Action")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_594128 != nil:
    section.add "Action", valid_594128
  var valid_594129 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_594129
  var valid_594130 = query.getOrDefault("Version")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594130 != nil:
    section.add "Version", valid_594130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594131 = header.getOrDefault("X-Amz-Date")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Date", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Security-Token")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Security-Token", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Content-Sha256", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Algorithm")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Algorithm", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Signature")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Signature", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-SignedHeaders", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Credential")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Credential", valid_594137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_GetCopyDBSnapshot_594124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_GetCopyDBSnapshot_594124;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_594140 = newJObject()
  add(query_594140, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_594140, "Action", newJString(Action))
  add(query_594140, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_594124(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_594125,
    base: "/", url: url_GetCopyDBSnapshot_594126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_594198 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstance_594200(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_594199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594201 = query.getOrDefault("Action")
  valid_594201 = validateParameter(valid_594201, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594201 != nil:
    section.add "Action", valid_594201
  var valid_594202 = query.getOrDefault("Version")
  valid_594202 = validateParameter(valid_594202, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594202 != nil:
    section.add "Version", valid_594202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594203 = header.getOrDefault("X-Amz-Date")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Date", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Security-Token")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Security-Token", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Content-Sha256", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Algorithm")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Algorithm", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Signature")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Signature", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-SignedHeaders", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Credential")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Credential", valid_594209
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
  var valid_594210 = formData.getOrDefault("DBSecurityGroups")
  valid_594210 = validateParameter(valid_594210, JArray, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "DBSecurityGroups", valid_594210
  var valid_594211 = formData.getOrDefault("Port")
  valid_594211 = validateParameter(valid_594211, JInt, required = false, default = nil)
  if valid_594211 != nil:
    section.add "Port", valid_594211
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594212 = formData.getOrDefault("Engine")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = nil)
  if valid_594212 != nil:
    section.add "Engine", valid_594212
  var valid_594213 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594213 = validateParameter(valid_594213, JArray, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "VpcSecurityGroupIds", valid_594213
  var valid_594214 = formData.getOrDefault("Iops")
  valid_594214 = validateParameter(valid_594214, JInt, required = false, default = nil)
  if valid_594214 != nil:
    section.add "Iops", valid_594214
  var valid_594215 = formData.getOrDefault("DBName")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "DBName", valid_594215
  var valid_594216 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594216 = validateParameter(valid_594216, JString, required = true,
                                 default = nil)
  if valid_594216 != nil:
    section.add "DBInstanceIdentifier", valid_594216
  var valid_594217 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594217 = validateParameter(valid_594217, JInt, required = false, default = nil)
  if valid_594217 != nil:
    section.add "BackupRetentionPeriod", valid_594217
  var valid_594218 = formData.getOrDefault("DBParameterGroupName")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "DBParameterGroupName", valid_594218
  var valid_594219 = formData.getOrDefault("OptionGroupName")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "OptionGroupName", valid_594219
  var valid_594220 = formData.getOrDefault("MasterUserPassword")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "MasterUserPassword", valid_594220
  var valid_594221 = formData.getOrDefault("DBSubnetGroupName")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "DBSubnetGroupName", valid_594221
  var valid_594222 = formData.getOrDefault("AvailabilityZone")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "AvailabilityZone", valid_594222
  var valid_594223 = formData.getOrDefault("MultiAZ")
  valid_594223 = validateParameter(valid_594223, JBool, required = false, default = nil)
  if valid_594223 != nil:
    section.add "MultiAZ", valid_594223
  var valid_594224 = formData.getOrDefault("AllocatedStorage")
  valid_594224 = validateParameter(valid_594224, JInt, required = true, default = nil)
  if valid_594224 != nil:
    section.add "AllocatedStorage", valid_594224
  var valid_594225 = formData.getOrDefault("PubliclyAccessible")
  valid_594225 = validateParameter(valid_594225, JBool, required = false, default = nil)
  if valid_594225 != nil:
    section.add "PubliclyAccessible", valid_594225
  var valid_594226 = formData.getOrDefault("MasterUsername")
  valid_594226 = validateParameter(valid_594226, JString, required = true,
                                 default = nil)
  if valid_594226 != nil:
    section.add "MasterUsername", valid_594226
  var valid_594227 = formData.getOrDefault("DBInstanceClass")
  valid_594227 = validateParameter(valid_594227, JString, required = true,
                                 default = nil)
  if valid_594227 != nil:
    section.add "DBInstanceClass", valid_594227
  var valid_594228 = formData.getOrDefault("CharacterSetName")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "CharacterSetName", valid_594228
  var valid_594229 = formData.getOrDefault("PreferredBackupWindow")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "PreferredBackupWindow", valid_594229
  var valid_594230 = formData.getOrDefault("LicenseModel")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "LicenseModel", valid_594230
  var valid_594231 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594231 = validateParameter(valid_594231, JBool, required = false, default = nil)
  if valid_594231 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594231
  var valid_594232 = formData.getOrDefault("EngineVersion")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "EngineVersion", valid_594232
  var valid_594233 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "PreferredMaintenanceWindow", valid_594233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594234: Call_PostCreateDBInstance_594198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594234.validator(path, query, header, formData, body)
  let scheme = call_594234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594234.url(scheme.get, call_594234.host, call_594234.base,
                         call_594234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594234, url, valid)

proc call*(call_594235: Call_PostCreateDBInstance_594198; Engine: string;
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
  var query_594236 = newJObject()
  var formData_594237 = newJObject()
  if DBSecurityGroups != nil:
    formData_594237.add "DBSecurityGroups", DBSecurityGroups
  add(formData_594237, "Port", newJInt(Port))
  add(formData_594237, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_594237.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594237, "Iops", newJInt(Iops))
  add(formData_594237, "DBName", newJString(DBName))
  add(formData_594237, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594237, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_594237, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594237, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594237, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594237, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594237, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_594237, "MultiAZ", newJBool(MultiAZ))
  add(query_594236, "Action", newJString(Action))
  add(formData_594237, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_594237, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594237, "MasterUsername", newJString(MasterUsername))
  add(formData_594237, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594237, "CharacterSetName", newJString(CharacterSetName))
  add(formData_594237, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594237, "LicenseModel", newJString(LicenseModel))
  add(formData_594237, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594237, "EngineVersion", newJString(EngineVersion))
  add(query_594236, "Version", newJString(Version))
  add(formData_594237, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594235.call(nil, query_594236, nil, formData_594237, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_594198(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_594199, base: "/",
    url: url_PostCreateDBInstance_594200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_594159 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstance_594161(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_594160(path: JsonNode; query: JsonNode;
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
  var valid_594162 = query.getOrDefault("Engine")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "Engine", valid_594162
  var valid_594163 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "PreferredMaintenanceWindow", valid_594163
  var valid_594164 = query.getOrDefault("AllocatedStorage")
  valid_594164 = validateParameter(valid_594164, JInt, required = true, default = nil)
  if valid_594164 != nil:
    section.add "AllocatedStorage", valid_594164
  var valid_594165 = query.getOrDefault("OptionGroupName")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "OptionGroupName", valid_594165
  var valid_594166 = query.getOrDefault("DBSecurityGroups")
  valid_594166 = validateParameter(valid_594166, JArray, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "DBSecurityGroups", valid_594166
  var valid_594167 = query.getOrDefault("MasterUserPassword")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = nil)
  if valid_594167 != nil:
    section.add "MasterUserPassword", valid_594167
  var valid_594168 = query.getOrDefault("AvailabilityZone")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "AvailabilityZone", valid_594168
  var valid_594169 = query.getOrDefault("Iops")
  valid_594169 = validateParameter(valid_594169, JInt, required = false, default = nil)
  if valid_594169 != nil:
    section.add "Iops", valid_594169
  var valid_594170 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594170 = validateParameter(valid_594170, JArray, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "VpcSecurityGroupIds", valid_594170
  var valid_594171 = query.getOrDefault("MultiAZ")
  valid_594171 = validateParameter(valid_594171, JBool, required = false, default = nil)
  if valid_594171 != nil:
    section.add "MultiAZ", valid_594171
  var valid_594172 = query.getOrDefault("LicenseModel")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "LicenseModel", valid_594172
  var valid_594173 = query.getOrDefault("BackupRetentionPeriod")
  valid_594173 = validateParameter(valid_594173, JInt, required = false, default = nil)
  if valid_594173 != nil:
    section.add "BackupRetentionPeriod", valid_594173
  var valid_594174 = query.getOrDefault("DBName")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "DBName", valid_594174
  var valid_594175 = query.getOrDefault("DBParameterGroupName")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "DBParameterGroupName", valid_594175
  var valid_594176 = query.getOrDefault("DBInstanceClass")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "DBInstanceClass", valid_594176
  var valid_594177 = query.getOrDefault("Action")
  valid_594177 = validateParameter(valid_594177, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594177 != nil:
    section.add "Action", valid_594177
  var valid_594178 = query.getOrDefault("DBSubnetGroupName")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "DBSubnetGroupName", valid_594178
  var valid_594179 = query.getOrDefault("CharacterSetName")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "CharacterSetName", valid_594179
  var valid_594180 = query.getOrDefault("PubliclyAccessible")
  valid_594180 = validateParameter(valid_594180, JBool, required = false, default = nil)
  if valid_594180 != nil:
    section.add "PubliclyAccessible", valid_594180
  var valid_594181 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594181 = validateParameter(valid_594181, JBool, required = false, default = nil)
  if valid_594181 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594181
  var valid_594182 = query.getOrDefault("EngineVersion")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "EngineVersion", valid_594182
  var valid_594183 = query.getOrDefault("Port")
  valid_594183 = validateParameter(valid_594183, JInt, required = false, default = nil)
  if valid_594183 != nil:
    section.add "Port", valid_594183
  var valid_594184 = query.getOrDefault("PreferredBackupWindow")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "PreferredBackupWindow", valid_594184
  var valid_594185 = query.getOrDefault("Version")
  valid_594185 = validateParameter(valid_594185, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594185 != nil:
    section.add "Version", valid_594185
  var valid_594186 = query.getOrDefault("DBInstanceIdentifier")
  valid_594186 = validateParameter(valid_594186, JString, required = true,
                                 default = nil)
  if valid_594186 != nil:
    section.add "DBInstanceIdentifier", valid_594186
  var valid_594187 = query.getOrDefault("MasterUsername")
  valid_594187 = validateParameter(valid_594187, JString, required = true,
                                 default = nil)
  if valid_594187 != nil:
    section.add "MasterUsername", valid_594187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594188 = header.getOrDefault("X-Amz-Date")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Date", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Security-Token")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Security-Token", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Content-Sha256", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Algorithm")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Algorithm", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Signature")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Signature", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-SignedHeaders", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Credential")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Credential", valid_594194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594195: Call_GetCreateDBInstance_594159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594195.validator(path, query, header, formData, body)
  let scheme = call_594195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594195.url(scheme.get, call_594195.host, call_594195.base,
                         call_594195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594195, url, valid)

proc call*(call_594196: Call_GetCreateDBInstance_594159; Engine: string;
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
  var query_594197 = newJObject()
  add(query_594197, "Engine", newJString(Engine))
  add(query_594197, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594197, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_594197, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_594197.add "DBSecurityGroups", DBSecurityGroups
  add(query_594197, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_594197, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594197, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_594197.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_594197, "MultiAZ", newJBool(MultiAZ))
  add(query_594197, "LicenseModel", newJString(LicenseModel))
  add(query_594197, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594197, "DBName", newJString(DBName))
  add(query_594197, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594197, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594197, "Action", newJString(Action))
  add(query_594197, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594197, "CharacterSetName", newJString(CharacterSetName))
  add(query_594197, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594197, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594197, "EngineVersion", newJString(EngineVersion))
  add(query_594197, "Port", newJInt(Port))
  add(query_594197, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594197, "Version", newJString(Version))
  add(query_594197, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594197, "MasterUsername", newJString(MasterUsername))
  result = call_594196.call(nil, query_594197, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_594159(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_594160, base: "/",
    url: url_GetCreateDBInstance_594161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_594262 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstanceReadReplica_594264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_594263(path: JsonNode;
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
  var valid_594265 = query.getOrDefault("Action")
  valid_594265 = validateParameter(valid_594265, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594265 != nil:
    section.add "Action", valid_594265
  var valid_594266 = query.getOrDefault("Version")
  valid_594266 = validateParameter(valid_594266, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594266 != nil:
    section.add "Version", valid_594266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594267 = header.getOrDefault("X-Amz-Date")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Date", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Security-Token")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Security-Token", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Content-Sha256", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Algorithm")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Algorithm", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Signature")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Signature", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-SignedHeaders", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Credential")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Credential", valid_594273
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
  var valid_594274 = formData.getOrDefault("Port")
  valid_594274 = validateParameter(valid_594274, JInt, required = false, default = nil)
  if valid_594274 != nil:
    section.add "Port", valid_594274
  var valid_594275 = formData.getOrDefault("Iops")
  valid_594275 = validateParameter(valid_594275, JInt, required = false, default = nil)
  if valid_594275 != nil:
    section.add "Iops", valid_594275
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = nil)
  if valid_594276 != nil:
    section.add "DBInstanceIdentifier", valid_594276
  var valid_594277 = formData.getOrDefault("OptionGroupName")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "OptionGroupName", valid_594277
  var valid_594278 = formData.getOrDefault("AvailabilityZone")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "AvailabilityZone", valid_594278
  var valid_594279 = formData.getOrDefault("PubliclyAccessible")
  valid_594279 = validateParameter(valid_594279, JBool, required = false, default = nil)
  if valid_594279 != nil:
    section.add "PubliclyAccessible", valid_594279
  var valid_594280 = formData.getOrDefault("DBInstanceClass")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "DBInstanceClass", valid_594280
  var valid_594281 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_594281 = validateParameter(valid_594281, JString, required = true,
                                 default = nil)
  if valid_594281 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594281
  var valid_594282 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594282 = validateParameter(valid_594282, JBool, required = false, default = nil)
  if valid_594282 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594283: Call_PostCreateDBInstanceReadReplica_594262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594283.validator(path, query, header, formData, body)
  let scheme = call_594283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594283.url(scheme.get, call_594283.host, call_594283.base,
                         call_594283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594283, url, valid)

proc call*(call_594284: Call_PostCreateDBInstanceReadReplica_594262;
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
  var query_594285 = newJObject()
  var formData_594286 = newJObject()
  add(formData_594286, "Port", newJInt(Port))
  add(formData_594286, "Iops", newJInt(Iops))
  add(formData_594286, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594286, "OptionGroupName", newJString(OptionGroupName))
  add(formData_594286, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594285, "Action", newJString(Action))
  add(formData_594286, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_594286, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594286, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_594286, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_594285, "Version", newJString(Version))
  result = call_594284.call(nil, query_594285, nil, formData_594286, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_594262(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_594263, base: "/",
    url: url_PostCreateDBInstanceReadReplica_594264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_594238 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstanceReadReplica_594240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_594239(path: JsonNode;
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
  var valid_594241 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_594241 = validateParameter(valid_594241, JString, required = true,
                                 default = nil)
  if valid_594241 != nil:
    section.add "SourceDBInstanceIdentifier", valid_594241
  var valid_594242 = query.getOrDefault("OptionGroupName")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "OptionGroupName", valid_594242
  var valid_594243 = query.getOrDefault("AvailabilityZone")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "AvailabilityZone", valid_594243
  var valid_594244 = query.getOrDefault("Iops")
  valid_594244 = validateParameter(valid_594244, JInt, required = false, default = nil)
  if valid_594244 != nil:
    section.add "Iops", valid_594244
  var valid_594245 = query.getOrDefault("DBInstanceClass")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "DBInstanceClass", valid_594245
  var valid_594246 = query.getOrDefault("Action")
  valid_594246 = validateParameter(valid_594246, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_594246 != nil:
    section.add "Action", valid_594246
  var valid_594247 = query.getOrDefault("PubliclyAccessible")
  valid_594247 = validateParameter(valid_594247, JBool, required = false, default = nil)
  if valid_594247 != nil:
    section.add "PubliclyAccessible", valid_594247
  var valid_594248 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594248 = validateParameter(valid_594248, JBool, required = false, default = nil)
  if valid_594248 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594248
  var valid_594249 = query.getOrDefault("Port")
  valid_594249 = validateParameter(valid_594249, JInt, required = false, default = nil)
  if valid_594249 != nil:
    section.add "Port", valid_594249
  var valid_594250 = query.getOrDefault("Version")
  valid_594250 = validateParameter(valid_594250, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594250 != nil:
    section.add "Version", valid_594250
  var valid_594251 = query.getOrDefault("DBInstanceIdentifier")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = nil)
  if valid_594251 != nil:
    section.add "DBInstanceIdentifier", valid_594251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594252 = header.getOrDefault("X-Amz-Date")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Date", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Security-Token")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Security-Token", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Content-Sha256", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Algorithm")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Algorithm", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Signature")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Signature", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-SignedHeaders", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594259: Call_GetCreateDBInstanceReadReplica_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594259.validator(path, query, header, formData, body)
  let scheme = call_594259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594259.url(scheme.get, call_594259.host, call_594259.base,
                         call_594259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594259, url, valid)

proc call*(call_594260: Call_GetCreateDBInstanceReadReplica_594238;
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
  var query_594261 = newJObject()
  add(query_594261, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_594261, "OptionGroupName", newJString(OptionGroupName))
  add(query_594261, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594261, "Iops", newJInt(Iops))
  add(query_594261, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594261, "Action", newJString(Action))
  add(query_594261, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_594261, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594261, "Port", newJInt(Port))
  add(query_594261, "Version", newJString(Version))
  add(query_594261, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594260.call(nil, query_594261, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_594238(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_594239, base: "/",
    url: url_GetCreateDBInstanceReadReplica_594240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_594305 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBParameterGroup_594307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_594306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594308 = query.getOrDefault("Action")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594308 != nil:
    section.add "Action", valid_594308
  var valid_594309 = query.getOrDefault("Version")
  valid_594309 = validateParameter(valid_594309, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594309 != nil:
    section.add "Version", valid_594309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594310 = header.getOrDefault("X-Amz-Date")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Date", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Security-Token")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Security-Token", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Content-Sha256", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Algorithm")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Algorithm", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Signature")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Signature", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-SignedHeaders", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Credential")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Credential", valid_594316
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594317 = formData.getOrDefault("DBParameterGroupName")
  valid_594317 = validateParameter(valid_594317, JString, required = true,
                                 default = nil)
  if valid_594317 != nil:
    section.add "DBParameterGroupName", valid_594317
  var valid_594318 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = nil)
  if valid_594318 != nil:
    section.add "DBParameterGroupFamily", valid_594318
  var valid_594319 = formData.getOrDefault("Description")
  valid_594319 = validateParameter(valid_594319, JString, required = true,
                                 default = nil)
  if valid_594319 != nil:
    section.add "Description", valid_594319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594320: Call_PostCreateDBParameterGroup_594305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594320.validator(path, query, header, formData, body)
  let scheme = call_594320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594320.url(scheme.get, call_594320.host, call_594320.base,
                         call_594320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594320, url, valid)

proc call*(call_594321: Call_PostCreateDBParameterGroup_594305;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_594322 = newJObject()
  var formData_594323 = newJObject()
  add(formData_594323, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594322, "Action", newJString(Action))
  add(formData_594323, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_594322, "Version", newJString(Version))
  add(formData_594323, "Description", newJString(Description))
  result = call_594321.call(nil, query_594322, nil, formData_594323, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_594305(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_594306, base: "/",
    url: url_PostCreateDBParameterGroup_594307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_594287 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBParameterGroup_594289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_594288(path: JsonNode; query: JsonNode;
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
  var valid_594290 = query.getOrDefault("Description")
  valid_594290 = validateParameter(valid_594290, JString, required = true,
                                 default = nil)
  if valid_594290 != nil:
    section.add "Description", valid_594290
  var valid_594291 = query.getOrDefault("DBParameterGroupFamily")
  valid_594291 = validateParameter(valid_594291, JString, required = true,
                                 default = nil)
  if valid_594291 != nil:
    section.add "DBParameterGroupFamily", valid_594291
  var valid_594292 = query.getOrDefault("DBParameterGroupName")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = nil)
  if valid_594292 != nil:
    section.add "DBParameterGroupName", valid_594292
  var valid_594293 = query.getOrDefault("Action")
  valid_594293 = validateParameter(valid_594293, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_594293 != nil:
    section.add "Action", valid_594293
  var valid_594294 = query.getOrDefault("Version")
  valid_594294 = validateParameter(valid_594294, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594294 != nil:
    section.add "Version", valid_594294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594295 = header.getOrDefault("X-Amz-Date")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Date", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Security-Token")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Security-Token", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Content-Sha256", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Algorithm")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Algorithm", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Signature")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Signature", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-SignedHeaders", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Credential")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Credential", valid_594301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594302: Call_GetCreateDBParameterGroup_594287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594302.validator(path, query, header, formData, body)
  let scheme = call_594302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594302.url(scheme.get, call_594302.host, call_594302.base,
                         call_594302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594302, url, valid)

proc call*(call_594303: Call_GetCreateDBParameterGroup_594287; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594304 = newJObject()
  add(query_594304, "Description", newJString(Description))
  add(query_594304, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_594304, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594304, "Action", newJString(Action))
  add(query_594304, "Version", newJString(Version))
  result = call_594303.call(nil, query_594304, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_594287(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_594288, base: "/",
    url: url_GetCreateDBParameterGroup_594289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_594341 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSecurityGroup_594343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_594342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594344 != nil:
    section.add "Action", valid_594344
  var valid_594345 = query.getOrDefault("Version")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594345 != nil:
    section.add "Version", valid_594345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Content-Sha256", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Algorithm")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Algorithm", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Signature")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Signature", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-SignedHeaders", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Credential")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Credential", valid_594352
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594353 = formData.getOrDefault("DBSecurityGroupName")
  valid_594353 = validateParameter(valid_594353, JString, required = true,
                                 default = nil)
  if valid_594353 != nil:
    section.add "DBSecurityGroupName", valid_594353
  var valid_594354 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_594354 = validateParameter(valid_594354, JString, required = true,
                                 default = nil)
  if valid_594354 != nil:
    section.add "DBSecurityGroupDescription", valid_594354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_PostCreateDBSecurityGroup_594341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_PostCreateDBSecurityGroup_594341;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_594357 = newJObject()
  var formData_594358 = newJObject()
  add(formData_594358, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594357, "Action", newJString(Action))
  add(formData_594358, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_594357, "Version", newJString(Version))
  result = call_594356.call(nil, query_594357, nil, formData_594358, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_594341(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_594342, base: "/",
    url: url_PostCreateDBSecurityGroup_594343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_594324 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSecurityGroup_594326(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_594325(path: JsonNode; query: JsonNode;
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
  var valid_594327 = query.getOrDefault("DBSecurityGroupName")
  valid_594327 = validateParameter(valid_594327, JString, required = true,
                                 default = nil)
  if valid_594327 != nil:
    section.add "DBSecurityGroupName", valid_594327
  var valid_594328 = query.getOrDefault("DBSecurityGroupDescription")
  valid_594328 = validateParameter(valid_594328, JString, required = true,
                                 default = nil)
  if valid_594328 != nil:
    section.add "DBSecurityGroupDescription", valid_594328
  var valid_594329 = query.getOrDefault("Action")
  valid_594329 = validateParameter(valid_594329, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_594329 != nil:
    section.add "Action", valid_594329
  var valid_594330 = query.getOrDefault("Version")
  valid_594330 = validateParameter(valid_594330, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594330 != nil:
    section.add "Version", valid_594330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Content-Sha256", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Algorithm")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Algorithm", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Signature")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Signature", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-SignedHeaders", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Credential")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Credential", valid_594337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_GetCreateDBSecurityGroup_594324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_GetCreateDBSecurityGroup_594324;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594340 = newJObject()
  add(query_594340, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594340, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_594340, "Action", newJString(Action))
  add(query_594340, "Version", newJString(Version))
  result = call_594339.call(nil, query_594340, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_594324(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_594325, base: "/",
    url: url_GetCreateDBSecurityGroup_594326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_594376 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSnapshot_594378(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_594377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594379 = query.getOrDefault("Action")
  valid_594379 = validateParameter(valid_594379, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594379 != nil:
    section.add "Action", valid_594379
  var valid_594380 = query.getOrDefault("Version")
  valid_594380 = validateParameter(valid_594380, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594380 != nil:
    section.add "Version", valid_594380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594381 = header.getOrDefault("X-Amz-Date")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Date", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Security-Token")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Security-Token", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Content-Sha256", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Algorithm")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Algorithm", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Signature")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Signature", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-SignedHeaders", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Credential")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Credential", valid_594387
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594388 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594388 = validateParameter(valid_594388, JString, required = true,
                                 default = nil)
  if valid_594388 != nil:
    section.add "DBInstanceIdentifier", valid_594388
  var valid_594389 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594389 = validateParameter(valid_594389, JString, required = true,
                                 default = nil)
  if valid_594389 != nil:
    section.add "DBSnapshotIdentifier", valid_594389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594390: Call_PostCreateDBSnapshot_594376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594390.validator(path, query, header, formData, body)
  let scheme = call_594390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594390.url(scheme.get, call_594390.host, call_594390.base,
                         call_594390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594390, url, valid)

proc call*(call_594391: Call_PostCreateDBSnapshot_594376;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594392 = newJObject()
  var formData_594393 = newJObject()
  add(formData_594393, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594393, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594392, "Action", newJString(Action))
  add(query_594392, "Version", newJString(Version))
  result = call_594391.call(nil, query_594392, nil, formData_594393, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_594376(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_594377, base: "/",
    url: url_PostCreateDBSnapshot_594378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_594359 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSnapshot_594361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_594360(path: JsonNode; query: JsonNode;
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
  var valid_594362 = query.getOrDefault("Action")
  valid_594362 = validateParameter(valid_594362, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_594362 != nil:
    section.add "Action", valid_594362
  var valid_594363 = query.getOrDefault("Version")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594363 != nil:
    section.add "Version", valid_594363
  var valid_594364 = query.getOrDefault("DBInstanceIdentifier")
  valid_594364 = validateParameter(valid_594364, JString, required = true,
                                 default = nil)
  if valid_594364 != nil:
    section.add "DBInstanceIdentifier", valid_594364
  var valid_594365 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594365 = validateParameter(valid_594365, JString, required = true,
                                 default = nil)
  if valid_594365 != nil:
    section.add "DBSnapshotIdentifier", valid_594365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594366 = header.getOrDefault("X-Amz-Date")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Date", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Security-Token")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Security-Token", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Content-Sha256", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Algorithm")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Algorithm", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Signature")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Signature", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-SignedHeaders", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Credential")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Credential", valid_594372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594373: Call_GetCreateDBSnapshot_594359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594373.validator(path, query, header, formData, body)
  let scheme = call_594373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594373.url(scheme.get, call_594373.host, call_594373.base,
                         call_594373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594373, url, valid)

proc call*(call_594374: Call_GetCreateDBSnapshot_594359;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594375 = newJObject()
  add(query_594375, "Action", newJString(Action))
  add(query_594375, "Version", newJString(Version))
  add(query_594375, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594375, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594374.call(nil, query_594375, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_594359(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_594360, base: "/",
    url: url_GetCreateDBSnapshot_594361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_594412 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSubnetGroup_594414(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_594413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594415 = query.getOrDefault("Action")
  valid_594415 = validateParameter(valid_594415, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594415 != nil:
    section.add "Action", valid_594415
  var valid_594416 = query.getOrDefault("Version")
  valid_594416 = validateParameter(valid_594416, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594416 != nil:
    section.add "Version", valid_594416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594417 = header.getOrDefault("X-Amz-Date")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Date", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Security-Token")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Security-Token", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Content-Sha256", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Algorithm")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Algorithm", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Signature")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Signature", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-SignedHeaders", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Credential")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Credential", valid_594423
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594424 = formData.getOrDefault("DBSubnetGroupName")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = nil)
  if valid_594424 != nil:
    section.add "DBSubnetGroupName", valid_594424
  var valid_594425 = formData.getOrDefault("SubnetIds")
  valid_594425 = validateParameter(valid_594425, JArray, required = true, default = nil)
  if valid_594425 != nil:
    section.add "SubnetIds", valid_594425
  var valid_594426 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594426 = validateParameter(valid_594426, JString, required = true,
                                 default = nil)
  if valid_594426 != nil:
    section.add "DBSubnetGroupDescription", valid_594426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594427: Call_PostCreateDBSubnetGroup_594412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594427.validator(path, query, header, formData, body)
  let scheme = call_594427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594427.url(scheme.get, call_594427.host, call_594427.base,
                         call_594427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594427, url, valid)

proc call*(call_594428: Call_PostCreateDBSubnetGroup_594412;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594429 = newJObject()
  var formData_594430 = newJObject()
  add(formData_594430, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_594430.add "SubnetIds", SubnetIds
  add(query_594429, "Action", newJString(Action))
  add(formData_594430, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594429, "Version", newJString(Version))
  result = call_594428.call(nil, query_594429, nil, formData_594430, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_594412(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_594413, base: "/",
    url: url_PostCreateDBSubnetGroup_594414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_594394 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSubnetGroup_594396(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_594395(path: JsonNode; query: JsonNode;
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
  var valid_594397 = query.getOrDefault("Action")
  valid_594397 = validateParameter(valid_594397, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594397 != nil:
    section.add "Action", valid_594397
  var valid_594398 = query.getOrDefault("DBSubnetGroupName")
  valid_594398 = validateParameter(valid_594398, JString, required = true,
                                 default = nil)
  if valid_594398 != nil:
    section.add "DBSubnetGroupName", valid_594398
  var valid_594399 = query.getOrDefault("SubnetIds")
  valid_594399 = validateParameter(valid_594399, JArray, required = true, default = nil)
  if valid_594399 != nil:
    section.add "SubnetIds", valid_594399
  var valid_594400 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = nil)
  if valid_594400 != nil:
    section.add "DBSubnetGroupDescription", valid_594400
  var valid_594401 = query.getOrDefault("Version")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594401 != nil:
    section.add "Version", valid_594401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594402 = header.getOrDefault("X-Amz-Date")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Date", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Security-Token")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Security-Token", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Content-Sha256", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Algorithm")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Algorithm", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Signature")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Signature", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-SignedHeaders", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Credential")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Credential", valid_594408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594409: Call_GetCreateDBSubnetGroup_594394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594409.validator(path, query, header, formData, body)
  let scheme = call_594409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594409.url(scheme.get, call_594409.host, call_594409.base,
                         call_594409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594409, url, valid)

proc call*(call_594410: Call_GetCreateDBSubnetGroup_594394;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_594411 = newJObject()
  add(query_594411, "Action", newJString(Action))
  add(query_594411, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_594411.add "SubnetIds", SubnetIds
  add(query_594411, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594411, "Version", newJString(Version))
  result = call_594410.call(nil, query_594411, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_594394(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_594395, base: "/",
    url: url_GetCreateDBSubnetGroup_594396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_594452 = ref object of OpenApiRestCall_593421
proc url_PostCreateEventSubscription_594454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_594453(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594455 = query.getOrDefault("Action")
  valid_594455 = validateParameter(valid_594455, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594455 != nil:
    section.add "Action", valid_594455
  var valid_594456 = query.getOrDefault("Version")
  valid_594456 = validateParameter(valid_594456, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594456 != nil:
    section.add "Version", valid_594456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594457 = header.getOrDefault("X-Amz-Date")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Date", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Security-Token")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Security-Token", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Content-Sha256", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Algorithm")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Algorithm", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Signature")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Signature", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-SignedHeaders", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Credential")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Credential", valid_594463
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_594464 = formData.getOrDefault("Enabled")
  valid_594464 = validateParameter(valid_594464, JBool, required = false, default = nil)
  if valid_594464 != nil:
    section.add "Enabled", valid_594464
  var valid_594465 = formData.getOrDefault("EventCategories")
  valid_594465 = validateParameter(valid_594465, JArray, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "EventCategories", valid_594465
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_594466 = formData.getOrDefault("SnsTopicArn")
  valid_594466 = validateParameter(valid_594466, JString, required = true,
                                 default = nil)
  if valid_594466 != nil:
    section.add "SnsTopicArn", valid_594466
  var valid_594467 = formData.getOrDefault("SourceIds")
  valid_594467 = validateParameter(valid_594467, JArray, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "SourceIds", valid_594467
  var valid_594468 = formData.getOrDefault("SubscriptionName")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = nil)
  if valid_594468 != nil:
    section.add "SubscriptionName", valid_594468
  var valid_594469 = formData.getOrDefault("SourceType")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "SourceType", valid_594469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594470: Call_PostCreateEventSubscription_594452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594470.validator(path, query, header, formData, body)
  let scheme = call_594470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594470.url(scheme.get, call_594470.host, call_594470.base,
                         call_594470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594470, url, valid)

proc call*(call_594471: Call_PostCreateEventSubscription_594452;
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
  var query_594472 = newJObject()
  var formData_594473 = newJObject()
  add(formData_594473, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_594473.add "EventCategories", EventCategories
  add(formData_594473, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_594473.add "SourceIds", SourceIds
  add(formData_594473, "SubscriptionName", newJString(SubscriptionName))
  add(query_594472, "Action", newJString(Action))
  add(query_594472, "Version", newJString(Version))
  add(formData_594473, "SourceType", newJString(SourceType))
  result = call_594471.call(nil, query_594472, nil, formData_594473, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_594452(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_594453, base: "/",
    url: url_PostCreateEventSubscription_594454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_594431 = ref object of OpenApiRestCall_593421
proc url_GetCreateEventSubscription_594433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_594432(path: JsonNode; query: JsonNode;
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
  var valid_594434 = query.getOrDefault("SourceType")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "SourceType", valid_594434
  var valid_594435 = query.getOrDefault("SourceIds")
  valid_594435 = validateParameter(valid_594435, JArray, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "SourceIds", valid_594435
  var valid_594436 = query.getOrDefault("Enabled")
  valid_594436 = validateParameter(valid_594436, JBool, required = false, default = nil)
  if valid_594436 != nil:
    section.add "Enabled", valid_594436
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594437 = query.getOrDefault("Action")
  valid_594437 = validateParameter(valid_594437, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_594437 != nil:
    section.add "Action", valid_594437
  var valid_594438 = query.getOrDefault("SnsTopicArn")
  valid_594438 = validateParameter(valid_594438, JString, required = true,
                                 default = nil)
  if valid_594438 != nil:
    section.add "SnsTopicArn", valid_594438
  var valid_594439 = query.getOrDefault("EventCategories")
  valid_594439 = validateParameter(valid_594439, JArray, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "EventCategories", valid_594439
  var valid_594440 = query.getOrDefault("SubscriptionName")
  valid_594440 = validateParameter(valid_594440, JString, required = true,
                                 default = nil)
  if valid_594440 != nil:
    section.add "SubscriptionName", valid_594440
  var valid_594441 = query.getOrDefault("Version")
  valid_594441 = validateParameter(valid_594441, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594441 != nil:
    section.add "Version", valid_594441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594442 = header.getOrDefault("X-Amz-Date")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Date", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Security-Token")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Security-Token", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Content-Sha256", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Algorithm")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Algorithm", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Signature")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Signature", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-SignedHeaders", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Credential")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Credential", valid_594448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_GetCreateEventSubscription_594431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_GetCreateEventSubscription_594431;
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
  var query_594451 = newJObject()
  add(query_594451, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_594451.add "SourceIds", SourceIds
  add(query_594451, "Enabled", newJBool(Enabled))
  add(query_594451, "Action", newJString(Action))
  add(query_594451, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_594451.add "EventCategories", EventCategories
  add(query_594451, "SubscriptionName", newJString(SubscriptionName))
  add(query_594451, "Version", newJString(Version))
  result = call_594450.call(nil, query_594451, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_594431(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_594432, base: "/",
    url: url_GetCreateEventSubscription_594433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_594493 = ref object of OpenApiRestCall_593421
proc url_PostCreateOptionGroup_594495(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_594494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594496 = query.getOrDefault("Action")
  valid_594496 = validateParameter(valid_594496, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594496 != nil:
    section.add "Action", valid_594496
  var valid_594497 = query.getOrDefault("Version")
  valid_594497 = validateParameter(valid_594497, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594497 != nil:
    section.add "Version", valid_594497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594498 = header.getOrDefault("X-Amz-Date")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Date", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Security-Token")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Security-Token", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Content-Sha256", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Algorithm")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Algorithm", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-Signature")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Signature", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-SignedHeaders", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Credential")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Credential", valid_594504
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_594505 = formData.getOrDefault("MajorEngineVersion")
  valid_594505 = validateParameter(valid_594505, JString, required = true,
                                 default = nil)
  if valid_594505 != nil:
    section.add "MajorEngineVersion", valid_594505
  var valid_594506 = formData.getOrDefault("OptionGroupName")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = nil)
  if valid_594506 != nil:
    section.add "OptionGroupName", valid_594506
  var valid_594507 = formData.getOrDefault("EngineName")
  valid_594507 = validateParameter(valid_594507, JString, required = true,
                                 default = nil)
  if valid_594507 != nil:
    section.add "EngineName", valid_594507
  var valid_594508 = formData.getOrDefault("OptionGroupDescription")
  valid_594508 = validateParameter(valid_594508, JString, required = true,
                                 default = nil)
  if valid_594508 != nil:
    section.add "OptionGroupDescription", valid_594508
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594509: Call_PostCreateOptionGroup_594493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594509.validator(path, query, header, formData, body)
  let scheme = call_594509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594509.url(scheme.get, call_594509.host, call_594509.base,
                         call_594509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594509, url, valid)

proc call*(call_594510: Call_PostCreateOptionGroup_594493;
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
  var query_594511 = newJObject()
  var formData_594512 = newJObject()
  add(formData_594512, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_594512, "OptionGroupName", newJString(OptionGroupName))
  add(query_594511, "Action", newJString(Action))
  add(formData_594512, "EngineName", newJString(EngineName))
  add(formData_594512, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_594511, "Version", newJString(Version))
  result = call_594510.call(nil, query_594511, nil, formData_594512, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_594493(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_594494, base: "/",
    url: url_PostCreateOptionGroup_594495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_594474 = ref object of OpenApiRestCall_593421
proc url_GetCreateOptionGroup_594476(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_594475(path: JsonNode; query: JsonNode;
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
  var valid_594477 = query.getOrDefault("OptionGroupName")
  valid_594477 = validateParameter(valid_594477, JString, required = true,
                                 default = nil)
  if valid_594477 != nil:
    section.add "OptionGroupName", valid_594477
  var valid_594478 = query.getOrDefault("OptionGroupDescription")
  valid_594478 = validateParameter(valid_594478, JString, required = true,
                                 default = nil)
  if valid_594478 != nil:
    section.add "OptionGroupDescription", valid_594478
  var valid_594479 = query.getOrDefault("Action")
  valid_594479 = validateParameter(valid_594479, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_594479 != nil:
    section.add "Action", valid_594479
  var valid_594480 = query.getOrDefault("Version")
  valid_594480 = validateParameter(valid_594480, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594480 != nil:
    section.add "Version", valid_594480
  var valid_594481 = query.getOrDefault("EngineName")
  valid_594481 = validateParameter(valid_594481, JString, required = true,
                                 default = nil)
  if valid_594481 != nil:
    section.add "EngineName", valid_594481
  var valid_594482 = query.getOrDefault("MajorEngineVersion")
  valid_594482 = validateParameter(valid_594482, JString, required = true,
                                 default = nil)
  if valid_594482 != nil:
    section.add "MajorEngineVersion", valid_594482
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594483 = header.getOrDefault("X-Amz-Date")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Date", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Security-Token")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Security-Token", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Content-Sha256", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Algorithm")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Algorithm", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Signature")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Signature", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-SignedHeaders", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Credential")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Credential", valid_594489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_GetCreateOptionGroup_594474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_GetCreateOptionGroup_594474; OptionGroupName: string;
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
  var query_594492 = newJObject()
  add(query_594492, "OptionGroupName", newJString(OptionGroupName))
  add(query_594492, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_594492, "Action", newJString(Action))
  add(query_594492, "Version", newJString(Version))
  add(query_594492, "EngineName", newJString(EngineName))
  add(query_594492, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_594491.call(nil, query_594492, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_594474(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_594475, base: "/",
    url: url_GetCreateOptionGroup_594476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_594531 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBInstance_594533(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_594532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594534 = query.getOrDefault("Action")
  valid_594534 = validateParameter(valid_594534, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594534 != nil:
    section.add "Action", valid_594534
  var valid_594535 = query.getOrDefault("Version")
  valid_594535 = validateParameter(valid_594535, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594535 != nil:
    section.add "Version", valid_594535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594536 = header.getOrDefault("X-Amz-Date")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Date", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Security-Token")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Security-Token", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Content-Sha256", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-Algorithm")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-Algorithm", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Signature")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Signature", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-SignedHeaders", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Credential")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Credential", valid_594542
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594543 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594543 = validateParameter(valid_594543, JString, required = true,
                                 default = nil)
  if valid_594543 != nil:
    section.add "DBInstanceIdentifier", valid_594543
  var valid_594544 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594544
  var valid_594545 = formData.getOrDefault("SkipFinalSnapshot")
  valid_594545 = validateParameter(valid_594545, JBool, required = false, default = nil)
  if valid_594545 != nil:
    section.add "SkipFinalSnapshot", valid_594545
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594546: Call_PostDeleteDBInstance_594531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594546.validator(path, query, header, formData, body)
  let scheme = call_594546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594546.url(scheme.get, call_594546.host, call_594546.base,
                         call_594546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594546, url, valid)

proc call*(call_594547: Call_PostDeleteDBInstance_594531;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_594548 = newJObject()
  var formData_594549 = newJObject()
  add(formData_594549, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594549, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594548, "Action", newJString(Action))
  add(query_594548, "Version", newJString(Version))
  add(formData_594549, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_594547.call(nil, query_594548, nil, formData_594549, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_594531(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_594532, base: "/",
    url: url_PostDeleteDBInstance_594533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_594513 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBInstance_594515(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_594514(path: JsonNode; query: JsonNode;
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
  var valid_594516 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594516
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594517 = query.getOrDefault("Action")
  valid_594517 = validateParameter(valid_594517, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594517 != nil:
    section.add "Action", valid_594517
  var valid_594518 = query.getOrDefault("SkipFinalSnapshot")
  valid_594518 = validateParameter(valid_594518, JBool, required = false, default = nil)
  if valid_594518 != nil:
    section.add "SkipFinalSnapshot", valid_594518
  var valid_594519 = query.getOrDefault("Version")
  valid_594519 = validateParameter(valid_594519, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594519 != nil:
    section.add "Version", valid_594519
  var valid_594520 = query.getOrDefault("DBInstanceIdentifier")
  valid_594520 = validateParameter(valid_594520, JString, required = true,
                                 default = nil)
  if valid_594520 != nil:
    section.add "DBInstanceIdentifier", valid_594520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594521 = header.getOrDefault("X-Amz-Date")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Date", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Security-Token")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Security-Token", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Content-Sha256", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Algorithm")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Algorithm", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Signature")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Signature", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-SignedHeaders", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Credential")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Credential", valid_594527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594528: Call_GetDeleteDBInstance_594513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594528.validator(path, query, header, formData, body)
  let scheme = call_594528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594528.url(scheme.get, call_594528.host, call_594528.base,
                         call_594528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594528, url, valid)

proc call*(call_594529: Call_GetDeleteDBInstance_594513;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_594530 = newJObject()
  add(query_594530, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594530, "Action", newJString(Action))
  add(query_594530, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_594530, "Version", newJString(Version))
  add(query_594530, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594529.call(nil, query_594530, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_594513(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_594514, base: "/",
    url: url_GetDeleteDBInstance_594515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_594566 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBParameterGroup_594568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_594567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594569 = query.getOrDefault("Action")
  valid_594569 = validateParameter(valid_594569, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594569 != nil:
    section.add "Action", valid_594569
  var valid_594570 = query.getOrDefault("Version")
  valid_594570 = validateParameter(valid_594570, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594570 != nil:
    section.add "Version", valid_594570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Content-Sha256", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Algorithm")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Algorithm", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Signature")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Signature", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-SignedHeaders", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Credential")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Credential", valid_594577
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594578 = formData.getOrDefault("DBParameterGroupName")
  valid_594578 = validateParameter(valid_594578, JString, required = true,
                                 default = nil)
  if valid_594578 != nil:
    section.add "DBParameterGroupName", valid_594578
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594579: Call_PostDeleteDBParameterGroup_594566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594579.validator(path, query, header, formData, body)
  let scheme = call_594579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594579.url(scheme.get, call_594579.host, call_594579.base,
                         call_594579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594579, url, valid)

proc call*(call_594580: Call_PostDeleteDBParameterGroup_594566;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594581 = newJObject()
  var formData_594582 = newJObject()
  add(formData_594582, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594581, "Action", newJString(Action))
  add(query_594581, "Version", newJString(Version))
  result = call_594580.call(nil, query_594581, nil, formData_594582, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_594566(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_594567, base: "/",
    url: url_PostDeleteDBParameterGroup_594568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_594550 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBParameterGroup_594552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_594551(path: JsonNode; query: JsonNode;
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
  var valid_594553 = query.getOrDefault("DBParameterGroupName")
  valid_594553 = validateParameter(valid_594553, JString, required = true,
                                 default = nil)
  if valid_594553 != nil:
    section.add "DBParameterGroupName", valid_594553
  var valid_594554 = query.getOrDefault("Action")
  valid_594554 = validateParameter(valid_594554, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_594554 != nil:
    section.add "Action", valid_594554
  var valid_594555 = query.getOrDefault("Version")
  valid_594555 = validateParameter(valid_594555, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594555 != nil:
    section.add "Version", valid_594555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Content-Sha256", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Algorithm")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Algorithm", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Signature")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Signature", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-SignedHeaders", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Credential")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Credential", valid_594562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594563: Call_GetDeleteDBParameterGroup_594550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594563.validator(path, query, header, formData, body)
  let scheme = call_594563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594563.url(scheme.get, call_594563.host, call_594563.base,
                         call_594563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594563, url, valid)

proc call*(call_594564: Call_GetDeleteDBParameterGroup_594550;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594565 = newJObject()
  add(query_594565, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594565, "Action", newJString(Action))
  add(query_594565, "Version", newJString(Version))
  result = call_594564.call(nil, query_594565, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_594550(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_594551, base: "/",
    url: url_GetDeleteDBParameterGroup_594552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_594599 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSecurityGroup_594601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_594600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594602 = query.getOrDefault("Action")
  valid_594602 = validateParameter(valid_594602, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594602 != nil:
    section.add "Action", valid_594602
  var valid_594603 = query.getOrDefault("Version")
  valid_594603 = validateParameter(valid_594603, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594603 != nil:
    section.add "Version", valid_594603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594604 = header.getOrDefault("X-Amz-Date")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Date", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Security-Token")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Security-Token", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Content-Sha256", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-Algorithm")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-Algorithm", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Signature")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Signature", valid_594608
  var valid_594609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-SignedHeaders", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Credential")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Credential", valid_594610
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_594611 = formData.getOrDefault("DBSecurityGroupName")
  valid_594611 = validateParameter(valid_594611, JString, required = true,
                                 default = nil)
  if valid_594611 != nil:
    section.add "DBSecurityGroupName", valid_594611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594612: Call_PostDeleteDBSecurityGroup_594599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594612.validator(path, query, header, formData, body)
  let scheme = call_594612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594612.url(scheme.get, call_594612.host, call_594612.base,
                         call_594612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594612, url, valid)

proc call*(call_594613: Call_PostDeleteDBSecurityGroup_594599;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594614 = newJObject()
  var formData_594615 = newJObject()
  add(formData_594615, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594614, "Action", newJString(Action))
  add(query_594614, "Version", newJString(Version))
  result = call_594613.call(nil, query_594614, nil, formData_594615, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_594599(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_594600, base: "/",
    url: url_PostDeleteDBSecurityGroup_594601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_594583 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSecurityGroup_594585(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_594584(path: JsonNode; query: JsonNode;
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
  var valid_594586 = query.getOrDefault("DBSecurityGroupName")
  valid_594586 = validateParameter(valid_594586, JString, required = true,
                                 default = nil)
  if valid_594586 != nil:
    section.add "DBSecurityGroupName", valid_594586
  var valid_594587 = query.getOrDefault("Action")
  valid_594587 = validateParameter(valid_594587, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_594587 != nil:
    section.add "Action", valid_594587
  var valid_594588 = query.getOrDefault("Version")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594588 != nil:
    section.add "Version", valid_594588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594589 = header.getOrDefault("X-Amz-Date")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Date", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Security-Token")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Security-Token", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Content-Sha256", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Algorithm")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Algorithm", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Signature")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Signature", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-SignedHeaders", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Credential")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Credential", valid_594595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594596: Call_GetDeleteDBSecurityGroup_594583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594596.validator(path, query, header, formData, body)
  let scheme = call_594596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594596.url(scheme.get, call_594596.host, call_594596.base,
                         call_594596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594596, url, valid)

proc call*(call_594597: Call_GetDeleteDBSecurityGroup_594583;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594598 = newJObject()
  add(query_594598, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594598, "Action", newJString(Action))
  add(query_594598, "Version", newJString(Version))
  result = call_594597.call(nil, query_594598, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_594583(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_594584, base: "/",
    url: url_GetDeleteDBSecurityGroup_594585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_594632 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSnapshot_594634(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_594633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_594635 = validateParameter(valid_594635, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594635 != nil:
    section.add "Action", valid_594635
  var valid_594636 = query.getOrDefault("Version")
  valid_594636 = validateParameter(valid_594636, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594636 != nil:
    section.add "Version", valid_594636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594637 = header.getOrDefault("X-Amz-Date")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Date", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Security-Token")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Security-Token", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Content-Sha256", valid_594639
  var valid_594640 = header.getOrDefault("X-Amz-Algorithm")
  valid_594640 = validateParameter(valid_594640, JString, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "X-Amz-Algorithm", valid_594640
  var valid_594641 = header.getOrDefault("X-Amz-Signature")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "X-Amz-Signature", valid_594641
  var valid_594642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-SignedHeaders", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Credential")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Credential", valid_594643
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_594644 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594644 = validateParameter(valid_594644, JString, required = true,
                                 default = nil)
  if valid_594644 != nil:
    section.add "DBSnapshotIdentifier", valid_594644
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594645: Call_PostDeleteDBSnapshot_594632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594645.validator(path, query, header, formData, body)
  let scheme = call_594645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594645.url(scheme.get, call_594645.host, call_594645.base,
                         call_594645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594645, url, valid)

proc call*(call_594646: Call_PostDeleteDBSnapshot_594632;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594647 = newJObject()
  var formData_594648 = newJObject()
  add(formData_594648, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594647, "Action", newJString(Action))
  add(query_594647, "Version", newJString(Version))
  result = call_594646.call(nil, query_594647, nil, formData_594648, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_594632(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_594633, base: "/",
    url: url_PostDeleteDBSnapshot_594634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_594616 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSnapshot_594618(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_594617(path: JsonNode; query: JsonNode;
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
  var valid_594619 = query.getOrDefault("Action")
  valid_594619 = validateParameter(valid_594619, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_594619 != nil:
    section.add "Action", valid_594619
  var valid_594620 = query.getOrDefault("Version")
  valid_594620 = validateParameter(valid_594620, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594620 != nil:
    section.add "Version", valid_594620
  var valid_594621 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594621 = validateParameter(valid_594621, JString, required = true,
                                 default = nil)
  if valid_594621 != nil:
    section.add "DBSnapshotIdentifier", valid_594621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594622 = header.getOrDefault("X-Amz-Date")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Date", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Security-Token")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Security-Token", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Content-Sha256", valid_594624
  var valid_594625 = header.getOrDefault("X-Amz-Algorithm")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Algorithm", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Signature")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Signature", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-SignedHeaders", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Credential")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Credential", valid_594628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594629: Call_GetDeleteDBSnapshot_594616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594629.validator(path, query, header, formData, body)
  let scheme = call_594629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594629.url(scheme.get, call_594629.host, call_594629.base,
                         call_594629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594629, url, valid)

proc call*(call_594630: Call_GetDeleteDBSnapshot_594616;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_594631 = newJObject()
  add(query_594631, "Action", newJString(Action))
  add(query_594631, "Version", newJString(Version))
  add(query_594631, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594630.call(nil, query_594631, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_594616(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_594617, base: "/",
    url: url_GetDeleteDBSnapshot_594618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_594665 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSubnetGroup_594667(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_594666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594668 = query.getOrDefault("Action")
  valid_594668 = validateParameter(valid_594668, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594668 != nil:
    section.add "Action", valid_594668
  var valid_594669 = query.getOrDefault("Version")
  valid_594669 = validateParameter(valid_594669, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594669 != nil:
    section.add "Version", valid_594669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594670 = header.getOrDefault("X-Amz-Date")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Date", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Security-Token")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Security-Token", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Content-Sha256", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Algorithm")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Algorithm", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Signature")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Signature", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-SignedHeaders", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Credential")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Credential", valid_594676
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594677 = formData.getOrDefault("DBSubnetGroupName")
  valid_594677 = validateParameter(valid_594677, JString, required = true,
                                 default = nil)
  if valid_594677 != nil:
    section.add "DBSubnetGroupName", valid_594677
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594678: Call_PostDeleteDBSubnetGroup_594665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594678.validator(path, query, header, formData, body)
  let scheme = call_594678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594678.url(scheme.get, call_594678.host, call_594678.base,
                         call_594678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594678, url, valid)

proc call*(call_594679: Call_PostDeleteDBSubnetGroup_594665;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594680 = newJObject()
  var formData_594681 = newJObject()
  add(formData_594681, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594680, "Action", newJString(Action))
  add(query_594680, "Version", newJString(Version))
  result = call_594679.call(nil, query_594680, nil, formData_594681, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_594665(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_594666, base: "/",
    url: url_PostDeleteDBSubnetGroup_594667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_594649 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSubnetGroup_594651(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_594650(path: JsonNode; query: JsonNode;
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
  var valid_594652 = query.getOrDefault("Action")
  valid_594652 = validateParameter(valid_594652, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594652 != nil:
    section.add "Action", valid_594652
  var valid_594653 = query.getOrDefault("DBSubnetGroupName")
  valid_594653 = validateParameter(valid_594653, JString, required = true,
                                 default = nil)
  if valid_594653 != nil:
    section.add "DBSubnetGroupName", valid_594653
  var valid_594654 = query.getOrDefault("Version")
  valid_594654 = validateParameter(valid_594654, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594654 != nil:
    section.add "Version", valid_594654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594655 = header.getOrDefault("X-Amz-Date")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Date", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Security-Token")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Security-Token", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Content-Sha256", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Algorithm")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Algorithm", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Signature")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Signature", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-SignedHeaders", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Credential")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Credential", valid_594661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594662: Call_GetDeleteDBSubnetGroup_594649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594662.validator(path, query, header, formData, body)
  let scheme = call_594662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594662.url(scheme.get, call_594662.host, call_594662.base,
                         call_594662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594662, url, valid)

proc call*(call_594663: Call_GetDeleteDBSubnetGroup_594649;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_594664 = newJObject()
  add(query_594664, "Action", newJString(Action))
  add(query_594664, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594664, "Version", newJString(Version))
  result = call_594663.call(nil, query_594664, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_594649(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_594650, base: "/",
    url: url_GetDeleteDBSubnetGroup_594651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_594698 = ref object of OpenApiRestCall_593421
proc url_PostDeleteEventSubscription_594700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_594699(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594701 = query.getOrDefault("Action")
  valid_594701 = validateParameter(valid_594701, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594701 != nil:
    section.add "Action", valid_594701
  var valid_594702 = query.getOrDefault("Version")
  valid_594702 = validateParameter(valid_594702, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594702 != nil:
    section.add "Version", valid_594702
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594703 = header.getOrDefault("X-Amz-Date")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Date", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Security-Token")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Security-Token", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Content-Sha256", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Algorithm")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Algorithm", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Signature")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Signature", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-SignedHeaders", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Credential")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Credential", valid_594709
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_594710 = formData.getOrDefault("SubscriptionName")
  valid_594710 = validateParameter(valid_594710, JString, required = true,
                                 default = nil)
  if valid_594710 != nil:
    section.add "SubscriptionName", valid_594710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594711: Call_PostDeleteEventSubscription_594698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594711.validator(path, query, header, formData, body)
  let scheme = call_594711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594711.url(scheme.get, call_594711.host, call_594711.base,
                         call_594711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594711, url, valid)

proc call*(call_594712: Call_PostDeleteEventSubscription_594698;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594713 = newJObject()
  var formData_594714 = newJObject()
  add(formData_594714, "SubscriptionName", newJString(SubscriptionName))
  add(query_594713, "Action", newJString(Action))
  add(query_594713, "Version", newJString(Version))
  result = call_594712.call(nil, query_594713, nil, formData_594714, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_594698(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_594699, base: "/",
    url: url_PostDeleteEventSubscription_594700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_594682 = ref object of OpenApiRestCall_593421
proc url_GetDeleteEventSubscription_594684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_594683(path: JsonNode; query: JsonNode;
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
  var valid_594685 = query.getOrDefault("Action")
  valid_594685 = validateParameter(valid_594685, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_594685 != nil:
    section.add "Action", valid_594685
  var valid_594686 = query.getOrDefault("SubscriptionName")
  valid_594686 = validateParameter(valid_594686, JString, required = true,
                                 default = nil)
  if valid_594686 != nil:
    section.add "SubscriptionName", valid_594686
  var valid_594687 = query.getOrDefault("Version")
  valid_594687 = validateParameter(valid_594687, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594687 != nil:
    section.add "Version", valid_594687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594688 = header.getOrDefault("X-Amz-Date")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Date", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Security-Token")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Security-Token", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Content-Sha256", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Algorithm")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Algorithm", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Signature")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Signature", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-SignedHeaders", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Credential")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Credential", valid_594694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594695: Call_GetDeleteEventSubscription_594682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594695.validator(path, query, header, formData, body)
  let scheme = call_594695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594695.url(scheme.get, call_594695.host, call_594695.base,
                         call_594695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594695, url, valid)

proc call*(call_594696: Call_GetDeleteEventSubscription_594682;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_594697 = newJObject()
  add(query_594697, "Action", newJString(Action))
  add(query_594697, "SubscriptionName", newJString(SubscriptionName))
  add(query_594697, "Version", newJString(Version))
  result = call_594696.call(nil, query_594697, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_594682(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_594683, base: "/",
    url: url_GetDeleteEventSubscription_594684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_594731 = ref object of OpenApiRestCall_593421
proc url_PostDeleteOptionGroup_594733(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_594732(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594734 = query.getOrDefault("Action")
  valid_594734 = validateParameter(valid_594734, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594734 != nil:
    section.add "Action", valid_594734
  var valid_594735 = query.getOrDefault("Version")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594735 != nil:
    section.add "Version", valid_594735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Content-Sha256", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Algorithm")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Algorithm", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Signature")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Signature", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-SignedHeaders", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Credential")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Credential", valid_594742
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_594743 = formData.getOrDefault("OptionGroupName")
  valid_594743 = validateParameter(valid_594743, JString, required = true,
                                 default = nil)
  if valid_594743 != nil:
    section.add "OptionGroupName", valid_594743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594744: Call_PostDeleteOptionGroup_594731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594744.validator(path, query, header, formData, body)
  let scheme = call_594744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594744.url(scheme.get, call_594744.host, call_594744.base,
                         call_594744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594744, url, valid)

proc call*(call_594745: Call_PostDeleteOptionGroup_594731; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594746 = newJObject()
  var formData_594747 = newJObject()
  add(formData_594747, "OptionGroupName", newJString(OptionGroupName))
  add(query_594746, "Action", newJString(Action))
  add(query_594746, "Version", newJString(Version))
  result = call_594745.call(nil, query_594746, nil, formData_594747, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_594731(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_594732, base: "/",
    url: url_PostDeleteOptionGroup_594733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_594715 = ref object of OpenApiRestCall_593421
proc url_GetDeleteOptionGroup_594717(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_594716(path: JsonNode; query: JsonNode;
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
  var valid_594718 = query.getOrDefault("OptionGroupName")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = nil)
  if valid_594718 != nil:
    section.add "OptionGroupName", valid_594718
  var valid_594719 = query.getOrDefault("Action")
  valid_594719 = validateParameter(valid_594719, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_594719 != nil:
    section.add "Action", valid_594719
  var valid_594720 = query.getOrDefault("Version")
  valid_594720 = validateParameter(valid_594720, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594720 != nil:
    section.add "Version", valid_594720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Security-Token")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Security-Token", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Content-Sha256", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Algorithm")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Algorithm", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Signature")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Signature", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-SignedHeaders", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-Credential")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-Credential", valid_594727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594728: Call_GetDeleteOptionGroup_594715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594728.validator(path, query, header, formData, body)
  let scheme = call_594728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594728.url(scheme.get, call_594728.host, call_594728.base,
                         call_594728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594728, url, valid)

proc call*(call_594729: Call_GetDeleteOptionGroup_594715; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594730 = newJObject()
  add(query_594730, "OptionGroupName", newJString(OptionGroupName))
  add(query_594730, "Action", newJString(Action))
  add(query_594730, "Version", newJString(Version))
  result = call_594729.call(nil, query_594730, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_594715(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_594716, base: "/",
    url: url_GetDeleteOptionGroup_594717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_594770 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBEngineVersions_594772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_594771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594773 = query.getOrDefault("Action")
  valid_594773 = validateParameter(valid_594773, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594773 != nil:
    section.add "Action", valid_594773
  var valid_594774 = query.getOrDefault("Version")
  valid_594774 = validateParameter(valid_594774, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594774 != nil:
    section.add "Version", valid_594774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594775 = header.getOrDefault("X-Amz-Date")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Date", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-Security-Token")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-Security-Token", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Content-Sha256", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Algorithm")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Algorithm", valid_594778
  var valid_594779 = header.getOrDefault("X-Amz-Signature")
  valid_594779 = validateParameter(valid_594779, JString, required = false,
                                 default = nil)
  if valid_594779 != nil:
    section.add "X-Amz-Signature", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-SignedHeaders", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Credential")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Credential", valid_594781
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
  var valid_594782 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_594782 = validateParameter(valid_594782, JBool, required = false, default = nil)
  if valid_594782 != nil:
    section.add "ListSupportedCharacterSets", valid_594782
  var valid_594783 = formData.getOrDefault("Engine")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "Engine", valid_594783
  var valid_594784 = formData.getOrDefault("Marker")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "Marker", valid_594784
  var valid_594785 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "DBParameterGroupFamily", valid_594785
  var valid_594786 = formData.getOrDefault("MaxRecords")
  valid_594786 = validateParameter(valid_594786, JInt, required = false, default = nil)
  if valid_594786 != nil:
    section.add "MaxRecords", valid_594786
  var valid_594787 = formData.getOrDefault("EngineVersion")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "EngineVersion", valid_594787
  var valid_594788 = formData.getOrDefault("DefaultOnly")
  valid_594788 = validateParameter(valid_594788, JBool, required = false, default = nil)
  if valid_594788 != nil:
    section.add "DefaultOnly", valid_594788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594789: Call_PostDescribeDBEngineVersions_594770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594789.validator(path, query, header, formData, body)
  let scheme = call_594789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594789.url(scheme.get, call_594789.host, call_594789.base,
                         call_594789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594789, url, valid)

proc call*(call_594790: Call_PostDescribeDBEngineVersions_594770;
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
  var query_594791 = newJObject()
  var formData_594792 = newJObject()
  add(formData_594792, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_594792, "Engine", newJString(Engine))
  add(formData_594792, "Marker", newJString(Marker))
  add(query_594791, "Action", newJString(Action))
  add(formData_594792, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_594792, "MaxRecords", newJInt(MaxRecords))
  add(formData_594792, "EngineVersion", newJString(EngineVersion))
  add(query_594791, "Version", newJString(Version))
  add(formData_594792, "DefaultOnly", newJBool(DefaultOnly))
  result = call_594790.call(nil, query_594791, nil, formData_594792, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_594770(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_594771, base: "/",
    url: url_PostDescribeDBEngineVersions_594772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_594748 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBEngineVersions_594750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_594749(path: JsonNode; query: JsonNode;
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
  var valid_594751 = query.getOrDefault("Engine")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "Engine", valid_594751
  var valid_594752 = query.getOrDefault("ListSupportedCharacterSets")
  valid_594752 = validateParameter(valid_594752, JBool, required = false, default = nil)
  if valid_594752 != nil:
    section.add "ListSupportedCharacterSets", valid_594752
  var valid_594753 = query.getOrDefault("MaxRecords")
  valid_594753 = validateParameter(valid_594753, JInt, required = false, default = nil)
  if valid_594753 != nil:
    section.add "MaxRecords", valid_594753
  var valid_594754 = query.getOrDefault("DBParameterGroupFamily")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "DBParameterGroupFamily", valid_594754
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594755 = query.getOrDefault("Action")
  valid_594755 = validateParameter(valid_594755, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594755 != nil:
    section.add "Action", valid_594755
  var valid_594756 = query.getOrDefault("Marker")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "Marker", valid_594756
  var valid_594757 = query.getOrDefault("EngineVersion")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "EngineVersion", valid_594757
  var valid_594758 = query.getOrDefault("DefaultOnly")
  valid_594758 = validateParameter(valid_594758, JBool, required = false, default = nil)
  if valid_594758 != nil:
    section.add "DefaultOnly", valid_594758
  var valid_594759 = query.getOrDefault("Version")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594759 != nil:
    section.add "Version", valid_594759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594760 = header.getOrDefault("X-Amz-Date")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Date", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-Security-Token")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-Security-Token", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Content-Sha256", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Algorithm")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Algorithm", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Signature")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Signature", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-SignedHeaders", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Credential")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Credential", valid_594766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594767: Call_GetDescribeDBEngineVersions_594748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594767.validator(path, query, header, formData, body)
  let scheme = call_594767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594767.url(scheme.get, call_594767.host, call_594767.base,
                         call_594767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594767, url, valid)

proc call*(call_594768: Call_GetDescribeDBEngineVersions_594748;
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
  var query_594769 = newJObject()
  add(query_594769, "Engine", newJString(Engine))
  add(query_594769, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_594769, "MaxRecords", newJInt(MaxRecords))
  add(query_594769, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_594769, "Action", newJString(Action))
  add(query_594769, "Marker", newJString(Marker))
  add(query_594769, "EngineVersion", newJString(EngineVersion))
  add(query_594769, "DefaultOnly", newJBool(DefaultOnly))
  add(query_594769, "Version", newJString(Version))
  result = call_594768.call(nil, query_594769, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_594748(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_594749, base: "/",
    url: url_GetDescribeDBEngineVersions_594750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_594811 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBInstances_594813(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_594812(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594814 = query.getOrDefault("Action")
  valid_594814 = validateParameter(valid_594814, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594814 != nil:
    section.add "Action", valid_594814
  var valid_594815 = query.getOrDefault("Version")
  valid_594815 = validateParameter(valid_594815, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594815 != nil:
    section.add "Version", valid_594815
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594816 = header.getOrDefault("X-Amz-Date")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Date", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-Security-Token")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-Security-Token", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Content-Sha256", valid_594818
  var valid_594819 = header.getOrDefault("X-Amz-Algorithm")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "X-Amz-Algorithm", valid_594819
  var valid_594820 = header.getOrDefault("X-Amz-Signature")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Signature", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-SignedHeaders", valid_594821
  var valid_594822 = header.getOrDefault("X-Amz-Credential")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Credential", valid_594822
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594823 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "DBInstanceIdentifier", valid_594823
  var valid_594824 = formData.getOrDefault("Marker")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "Marker", valid_594824
  var valid_594825 = formData.getOrDefault("MaxRecords")
  valid_594825 = validateParameter(valid_594825, JInt, required = false, default = nil)
  if valid_594825 != nil:
    section.add "MaxRecords", valid_594825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594826: Call_PostDescribeDBInstances_594811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594826.validator(path, query, header, formData, body)
  let scheme = call_594826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594826.url(scheme.get, call_594826.host, call_594826.base,
                         call_594826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594826, url, valid)

proc call*(call_594827: Call_PostDescribeDBInstances_594811;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594828 = newJObject()
  var formData_594829 = newJObject()
  add(formData_594829, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594829, "Marker", newJString(Marker))
  add(query_594828, "Action", newJString(Action))
  add(formData_594829, "MaxRecords", newJInt(MaxRecords))
  add(query_594828, "Version", newJString(Version))
  result = call_594827.call(nil, query_594828, nil, formData_594829, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_594811(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_594812, base: "/",
    url: url_PostDescribeDBInstances_594813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_594793 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBInstances_594795(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_594794(path: JsonNode; query: JsonNode;
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
  var valid_594796 = query.getOrDefault("MaxRecords")
  valid_594796 = validateParameter(valid_594796, JInt, required = false, default = nil)
  if valid_594796 != nil:
    section.add "MaxRecords", valid_594796
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594797 = query.getOrDefault("Action")
  valid_594797 = validateParameter(valid_594797, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594797 != nil:
    section.add "Action", valid_594797
  var valid_594798 = query.getOrDefault("Marker")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "Marker", valid_594798
  var valid_594799 = query.getOrDefault("Version")
  valid_594799 = validateParameter(valid_594799, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594799 != nil:
    section.add "Version", valid_594799
  var valid_594800 = query.getOrDefault("DBInstanceIdentifier")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "DBInstanceIdentifier", valid_594800
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594801 = header.getOrDefault("X-Amz-Date")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Date", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-Security-Token")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Security-Token", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Content-Sha256", valid_594803
  var valid_594804 = header.getOrDefault("X-Amz-Algorithm")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "X-Amz-Algorithm", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Signature")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Signature", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-SignedHeaders", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Credential")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Credential", valid_594807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594808: Call_GetDescribeDBInstances_594793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594808.validator(path, query, header, formData, body)
  let scheme = call_594808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594808.url(scheme.get, call_594808.host, call_594808.base,
                         call_594808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594808, url, valid)

proc call*(call_594809: Call_GetDescribeDBInstances_594793; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-01-10"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_594810 = newJObject()
  add(query_594810, "MaxRecords", newJInt(MaxRecords))
  add(query_594810, "Action", newJString(Action))
  add(query_594810, "Marker", newJString(Marker))
  add(query_594810, "Version", newJString(Version))
  add(query_594810, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594809.call(nil, query_594810, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_594793(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_594794, base: "/",
    url: url_GetDescribeDBInstances_594795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_594848 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameterGroups_594850(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_594849(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594851 = query.getOrDefault("Action")
  valid_594851 = validateParameter(valid_594851, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594851 != nil:
    section.add "Action", valid_594851
  var valid_594852 = query.getOrDefault("Version")
  valid_594852 = validateParameter(valid_594852, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594852 != nil:
    section.add "Version", valid_594852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594853 = header.getOrDefault("X-Amz-Date")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Date", valid_594853
  var valid_594854 = header.getOrDefault("X-Amz-Security-Token")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "X-Amz-Security-Token", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-Content-Sha256", valid_594855
  var valid_594856 = header.getOrDefault("X-Amz-Algorithm")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Algorithm", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Signature")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Signature", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-SignedHeaders", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Credential")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Credential", valid_594859
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594860 = formData.getOrDefault("DBParameterGroupName")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "DBParameterGroupName", valid_594860
  var valid_594861 = formData.getOrDefault("Marker")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "Marker", valid_594861
  var valid_594862 = formData.getOrDefault("MaxRecords")
  valid_594862 = validateParameter(valid_594862, JInt, required = false, default = nil)
  if valid_594862 != nil:
    section.add "MaxRecords", valid_594862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594863: Call_PostDescribeDBParameterGroups_594848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594863.validator(path, query, header, formData, body)
  let scheme = call_594863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594863.url(scheme.get, call_594863.host, call_594863.base,
                         call_594863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594863, url, valid)

proc call*(call_594864: Call_PostDescribeDBParameterGroups_594848;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594865 = newJObject()
  var formData_594866 = newJObject()
  add(formData_594866, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594866, "Marker", newJString(Marker))
  add(query_594865, "Action", newJString(Action))
  add(formData_594866, "MaxRecords", newJInt(MaxRecords))
  add(query_594865, "Version", newJString(Version))
  result = call_594864.call(nil, query_594865, nil, formData_594866, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_594848(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_594849, base: "/",
    url: url_PostDescribeDBParameterGroups_594850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_594830 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameterGroups_594832(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_594831(path: JsonNode; query: JsonNode;
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
  var valid_594833 = query.getOrDefault("MaxRecords")
  valid_594833 = validateParameter(valid_594833, JInt, required = false, default = nil)
  if valid_594833 != nil:
    section.add "MaxRecords", valid_594833
  var valid_594834 = query.getOrDefault("DBParameterGroupName")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "DBParameterGroupName", valid_594834
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594835 = query.getOrDefault("Action")
  valid_594835 = validateParameter(valid_594835, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594835 != nil:
    section.add "Action", valid_594835
  var valid_594836 = query.getOrDefault("Marker")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "Marker", valid_594836
  var valid_594837 = query.getOrDefault("Version")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594837 != nil:
    section.add "Version", valid_594837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594838 = header.getOrDefault("X-Amz-Date")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Date", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Security-Token")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Security-Token", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Content-Sha256", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Algorithm")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Algorithm", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Signature")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Signature", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-SignedHeaders", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Credential")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Credential", valid_594844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594845: Call_GetDescribeDBParameterGroups_594830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594845.validator(path, query, header, formData, body)
  let scheme = call_594845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594845.url(scheme.get, call_594845.host, call_594845.base,
                         call_594845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594845, url, valid)

proc call*(call_594846: Call_GetDescribeDBParameterGroups_594830;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594847 = newJObject()
  add(query_594847, "MaxRecords", newJInt(MaxRecords))
  add(query_594847, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594847, "Action", newJString(Action))
  add(query_594847, "Marker", newJString(Marker))
  add(query_594847, "Version", newJString(Version))
  result = call_594846.call(nil, query_594847, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_594830(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_594831, base: "/",
    url: url_GetDescribeDBParameterGroups_594832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_594886 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameters_594888(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_594887(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594889 = query.getOrDefault("Action")
  valid_594889 = validateParameter(valid_594889, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594889 != nil:
    section.add "Action", valid_594889
  var valid_594890 = query.getOrDefault("Version")
  valid_594890 = validateParameter(valid_594890, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594890 != nil:
    section.add "Version", valid_594890
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594891 = header.getOrDefault("X-Amz-Date")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Date", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Security-Token")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Security-Token", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Content-Sha256", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-Algorithm")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Algorithm", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-Signature")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-Signature", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-SignedHeaders", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Credential")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Credential", valid_594897
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594898 = formData.getOrDefault("DBParameterGroupName")
  valid_594898 = validateParameter(valid_594898, JString, required = true,
                                 default = nil)
  if valid_594898 != nil:
    section.add "DBParameterGroupName", valid_594898
  var valid_594899 = formData.getOrDefault("Marker")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "Marker", valid_594899
  var valid_594900 = formData.getOrDefault("MaxRecords")
  valid_594900 = validateParameter(valid_594900, JInt, required = false, default = nil)
  if valid_594900 != nil:
    section.add "MaxRecords", valid_594900
  var valid_594901 = formData.getOrDefault("Source")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "Source", valid_594901
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594902: Call_PostDescribeDBParameters_594886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594902.validator(path, query, header, formData, body)
  let scheme = call_594902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594902.url(scheme.get, call_594902.host, call_594902.base,
                         call_594902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594902, url, valid)

proc call*(call_594903: Call_PostDescribeDBParameters_594886;
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
  var query_594904 = newJObject()
  var formData_594905 = newJObject()
  add(formData_594905, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594905, "Marker", newJString(Marker))
  add(query_594904, "Action", newJString(Action))
  add(formData_594905, "MaxRecords", newJInt(MaxRecords))
  add(query_594904, "Version", newJString(Version))
  add(formData_594905, "Source", newJString(Source))
  result = call_594903.call(nil, query_594904, nil, formData_594905, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_594886(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_594887, base: "/",
    url: url_PostDescribeDBParameters_594888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_594867 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameters_594869(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_594868(path: JsonNode; query: JsonNode;
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
  var valid_594870 = query.getOrDefault("MaxRecords")
  valid_594870 = validateParameter(valid_594870, JInt, required = false, default = nil)
  if valid_594870 != nil:
    section.add "MaxRecords", valid_594870
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_594871 = query.getOrDefault("DBParameterGroupName")
  valid_594871 = validateParameter(valid_594871, JString, required = true,
                                 default = nil)
  if valid_594871 != nil:
    section.add "DBParameterGroupName", valid_594871
  var valid_594872 = query.getOrDefault("Action")
  valid_594872 = validateParameter(valid_594872, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594872 != nil:
    section.add "Action", valid_594872
  var valid_594873 = query.getOrDefault("Marker")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "Marker", valid_594873
  var valid_594874 = query.getOrDefault("Source")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "Source", valid_594874
  var valid_594875 = query.getOrDefault("Version")
  valid_594875 = validateParameter(valid_594875, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594875 != nil:
    section.add "Version", valid_594875
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594876 = header.getOrDefault("X-Amz-Date")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Date", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Security-Token")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Security-Token", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Content-Sha256", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Algorithm")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Algorithm", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-Signature")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-Signature", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-SignedHeaders", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Credential")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Credential", valid_594882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594883: Call_GetDescribeDBParameters_594867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594883.validator(path, query, header, formData, body)
  let scheme = call_594883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594883.url(scheme.get, call_594883.host, call_594883.base,
                         call_594883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594883, url, valid)

proc call*(call_594884: Call_GetDescribeDBParameters_594867;
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
  var query_594885 = newJObject()
  add(query_594885, "MaxRecords", newJInt(MaxRecords))
  add(query_594885, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594885, "Action", newJString(Action))
  add(query_594885, "Marker", newJString(Marker))
  add(query_594885, "Source", newJString(Source))
  add(query_594885, "Version", newJString(Version))
  result = call_594884.call(nil, query_594885, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_594867(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_594868, base: "/",
    url: url_GetDescribeDBParameters_594869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_594924 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSecurityGroups_594926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_594925(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594927 = query.getOrDefault("Action")
  valid_594927 = validateParameter(valid_594927, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594927 != nil:
    section.add "Action", valid_594927
  var valid_594928 = query.getOrDefault("Version")
  valid_594928 = validateParameter(valid_594928, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594928 != nil:
    section.add "Version", valid_594928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594929 = header.getOrDefault("X-Amz-Date")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Date", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Security-Token")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Security-Token", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Content-Sha256", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-Algorithm")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-Algorithm", valid_594932
  var valid_594933 = header.getOrDefault("X-Amz-Signature")
  valid_594933 = validateParameter(valid_594933, JString, required = false,
                                 default = nil)
  if valid_594933 != nil:
    section.add "X-Amz-Signature", valid_594933
  var valid_594934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594934 = validateParameter(valid_594934, JString, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "X-Amz-SignedHeaders", valid_594934
  var valid_594935 = header.getOrDefault("X-Amz-Credential")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "X-Amz-Credential", valid_594935
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594936 = formData.getOrDefault("DBSecurityGroupName")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "DBSecurityGroupName", valid_594936
  var valid_594937 = formData.getOrDefault("Marker")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "Marker", valid_594937
  var valid_594938 = formData.getOrDefault("MaxRecords")
  valid_594938 = validateParameter(valid_594938, JInt, required = false, default = nil)
  if valid_594938 != nil:
    section.add "MaxRecords", valid_594938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594939: Call_PostDescribeDBSecurityGroups_594924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594939.validator(path, query, header, formData, body)
  let scheme = call_594939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594939.url(scheme.get, call_594939.host, call_594939.base,
                         call_594939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594939, url, valid)

proc call*(call_594940: Call_PostDescribeDBSecurityGroups_594924;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594941 = newJObject()
  var formData_594942 = newJObject()
  add(formData_594942, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_594942, "Marker", newJString(Marker))
  add(query_594941, "Action", newJString(Action))
  add(formData_594942, "MaxRecords", newJInt(MaxRecords))
  add(query_594941, "Version", newJString(Version))
  result = call_594940.call(nil, query_594941, nil, formData_594942, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_594924(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_594925, base: "/",
    url: url_PostDescribeDBSecurityGroups_594926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_594906 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSecurityGroups_594908(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_594907(path: JsonNode; query: JsonNode;
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
  var valid_594909 = query.getOrDefault("MaxRecords")
  valid_594909 = validateParameter(valid_594909, JInt, required = false, default = nil)
  if valid_594909 != nil:
    section.add "MaxRecords", valid_594909
  var valid_594910 = query.getOrDefault("DBSecurityGroupName")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "DBSecurityGroupName", valid_594910
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594911 = query.getOrDefault("Action")
  valid_594911 = validateParameter(valid_594911, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594911 != nil:
    section.add "Action", valid_594911
  var valid_594912 = query.getOrDefault("Marker")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "Marker", valid_594912
  var valid_594913 = query.getOrDefault("Version")
  valid_594913 = validateParameter(valid_594913, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594913 != nil:
    section.add "Version", valid_594913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594914 = header.getOrDefault("X-Amz-Date")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Date", valid_594914
  var valid_594915 = header.getOrDefault("X-Amz-Security-Token")
  valid_594915 = validateParameter(valid_594915, JString, required = false,
                                 default = nil)
  if valid_594915 != nil:
    section.add "X-Amz-Security-Token", valid_594915
  var valid_594916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Content-Sha256", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-Algorithm")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-Algorithm", valid_594917
  var valid_594918 = header.getOrDefault("X-Amz-Signature")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "X-Amz-Signature", valid_594918
  var valid_594919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-SignedHeaders", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Credential")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Credential", valid_594920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594921: Call_GetDescribeDBSecurityGroups_594906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594921.validator(path, query, header, formData, body)
  let scheme = call_594921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594921.url(scheme.get, call_594921.host, call_594921.base,
                         call_594921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594921, url, valid)

proc call*(call_594922: Call_GetDescribeDBSecurityGroups_594906;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594923 = newJObject()
  add(query_594923, "MaxRecords", newJInt(MaxRecords))
  add(query_594923, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594923, "Action", newJString(Action))
  add(query_594923, "Marker", newJString(Marker))
  add(query_594923, "Version", newJString(Version))
  result = call_594922.call(nil, query_594923, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_594906(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_594907, base: "/",
    url: url_GetDescribeDBSecurityGroups_594908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_594963 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSnapshots_594965(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_594964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_594966 = validateParameter(valid_594966, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_594966 != nil:
    section.add "Action", valid_594966
  var valid_594967 = query.getOrDefault("Version")
  valid_594967 = validateParameter(valid_594967, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594967 != nil:
    section.add "Version", valid_594967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594968 = header.getOrDefault("X-Amz-Date")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-Date", valid_594968
  var valid_594969 = header.getOrDefault("X-Amz-Security-Token")
  valid_594969 = validateParameter(valid_594969, JString, required = false,
                                 default = nil)
  if valid_594969 != nil:
    section.add "X-Amz-Security-Token", valid_594969
  var valid_594970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = nil)
  if valid_594970 != nil:
    section.add "X-Amz-Content-Sha256", valid_594970
  var valid_594971 = header.getOrDefault("X-Amz-Algorithm")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "X-Amz-Algorithm", valid_594971
  var valid_594972 = header.getOrDefault("X-Amz-Signature")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Signature", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-SignedHeaders", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Credential")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Credential", valid_594974
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594975 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "DBInstanceIdentifier", valid_594975
  var valid_594976 = formData.getOrDefault("SnapshotType")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "SnapshotType", valid_594976
  var valid_594977 = formData.getOrDefault("Marker")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "Marker", valid_594977
  var valid_594978 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "DBSnapshotIdentifier", valid_594978
  var valid_594979 = formData.getOrDefault("MaxRecords")
  valid_594979 = validateParameter(valid_594979, JInt, required = false, default = nil)
  if valid_594979 != nil:
    section.add "MaxRecords", valid_594979
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594980: Call_PostDescribeDBSnapshots_594963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594980.validator(path, query, header, formData, body)
  let scheme = call_594980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594980.url(scheme.get, call_594980.host, call_594980.base,
                         call_594980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594980, url, valid)

proc call*(call_594981: Call_PostDescribeDBSnapshots_594963;
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
  var query_594982 = newJObject()
  var formData_594983 = newJObject()
  add(formData_594983, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594983, "SnapshotType", newJString(SnapshotType))
  add(formData_594983, "Marker", newJString(Marker))
  add(formData_594983, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_594982, "Action", newJString(Action))
  add(formData_594983, "MaxRecords", newJInt(MaxRecords))
  add(query_594982, "Version", newJString(Version))
  result = call_594981.call(nil, query_594982, nil, formData_594983, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_594963(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_594964, base: "/",
    url: url_PostDescribeDBSnapshots_594965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_594943 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSnapshots_594945(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_594944(path: JsonNode; query: JsonNode;
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
  var valid_594946 = query.getOrDefault("MaxRecords")
  valid_594946 = validateParameter(valid_594946, JInt, required = false, default = nil)
  if valid_594946 != nil:
    section.add "MaxRecords", valid_594946
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594947 = query.getOrDefault("Action")
  valid_594947 = validateParameter(valid_594947, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_594947 != nil:
    section.add "Action", valid_594947
  var valid_594948 = query.getOrDefault("Marker")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "Marker", valid_594948
  var valid_594949 = query.getOrDefault("SnapshotType")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "SnapshotType", valid_594949
  var valid_594950 = query.getOrDefault("Version")
  valid_594950 = validateParameter(valid_594950, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594950 != nil:
    section.add "Version", valid_594950
  var valid_594951 = query.getOrDefault("DBInstanceIdentifier")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "DBInstanceIdentifier", valid_594951
  var valid_594952 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "DBSnapshotIdentifier", valid_594952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594953 = header.getOrDefault("X-Amz-Date")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Date", valid_594953
  var valid_594954 = header.getOrDefault("X-Amz-Security-Token")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Security-Token", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Content-Sha256", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Algorithm")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Algorithm", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Signature")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Signature", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-SignedHeaders", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Credential")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Credential", valid_594959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594960: Call_GetDescribeDBSnapshots_594943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594960.validator(path, query, header, formData, body)
  let scheme = call_594960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594960.url(scheme.get, call_594960.host, call_594960.base,
                         call_594960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594960, url, valid)

proc call*(call_594961: Call_GetDescribeDBSnapshots_594943; MaxRecords: int = 0;
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
  var query_594962 = newJObject()
  add(query_594962, "MaxRecords", newJInt(MaxRecords))
  add(query_594962, "Action", newJString(Action))
  add(query_594962, "Marker", newJString(Marker))
  add(query_594962, "SnapshotType", newJString(SnapshotType))
  add(query_594962, "Version", newJString(Version))
  add(query_594962, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594962, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_594961.call(nil, query_594962, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_594943(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_594944, base: "/",
    url: url_GetDescribeDBSnapshots_594945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_595002 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSubnetGroups_595004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_595003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595005 = query.getOrDefault("Action")
  valid_595005 = validateParameter(valid_595005, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595005 != nil:
    section.add "Action", valid_595005
  var valid_595006 = query.getOrDefault("Version")
  valid_595006 = validateParameter(valid_595006, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595006 != nil:
    section.add "Version", valid_595006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595007 = header.getOrDefault("X-Amz-Date")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Date", valid_595007
  var valid_595008 = header.getOrDefault("X-Amz-Security-Token")
  valid_595008 = validateParameter(valid_595008, JString, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "X-Amz-Security-Token", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Content-Sha256", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Algorithm")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Algorithm", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Signature")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Signature", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-SignedHeaders", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Credential")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Credential", valid_595013
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595014 = formData.getOrDefault("DBSubnetGroupName")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = nil)
  if valid_595014 != nil:
    section.add "DBSubnetGroupName", valid_595014
  var valid_595015 = formData.getOrDefault("Marker")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "Marker", valid_595015
  var valid_595016 = formData.getOrDefault("MaxRecords")
  valid_595016 = validateParameter(valid_595016, JInt, required = false, default = nil)
  if valid_595016 != nil:
    section.add "MaxRecords", valid_595016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595017: Call_PostDescribeDBSubnetGroups_595002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595017.validator(path, query, header, formData, body)
  let scheme = call_595017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595017.url(scheme.get, call_595017.host, call_595017.base,
                         call_595017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595017, url, valid)

proc call*(call_595018: Call_PostDescribeDBSubnetGroups_595002;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595019 = newJObject()
  var formData_595020 = newJObject()
  add(formData_595020, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595020, "Marker", newJString(Marker))
  add(query_595019, "Action", newJString(Action))
  add(formData_595020, "MaxRecords", newJInt(MaxRecords))
  add(query_595019, "Version", newJString(Version))
  result = call_595018.call(nil, query_595019, nil, formData_595020, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_595002(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_595003, base: "/",
    url: url_PostDescribeDBSubnetGroups_595004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_594984 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSubnetGroups_594986(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_594985(path: JsonNode; query: JsonNode;
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
  var valid_594987 = query.getOrDefault("MaxRecords")
  valid_594987 = validateParameter(valid_594987, JInt, required = false, default = nil)
  if valid_594987 != nil:
    section.add "MaxRecords", valid_594987
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594988 = query.getOrDefault("Action")
  valid_594988 = validateParameter(valid_594988, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594988 != nil:
    section.add "Action", valid_594988
  var valid_594989 = query.getOrDefault("Marker")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "Marker", valid_594989
  var valid_594990 = query.getOrDefault("DBSubnetGroupName")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "DBSubnetGroupName", valid_594990
  var valid_594991 = query.getOrDefault("Version")
  valid_594991 = validateParameter(valid_594991, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_594991 != nil:
    section.add "Version", valid_594991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594992 = header.getOrDefault("X-Amz-Date")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Date", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Security-Token")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Security-Token", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Content-Sha256", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-Algorithm")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-Algorithm", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Signature")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Signature", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-SignedHeaders", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Credential")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Credential", valid_594998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594999: Call_GetDescribeDBSubnetGroups_594984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594999.validator(path, query, header, formData, body)
  let scheme = call_594999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594999.url(scheme.get, call_594999.host, call_594999.base,
                         call_594999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594999, url, valid)

proc call*(call_595000: Call_GetDescribeDBSubnetGroups_594984; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_595001 = newJObject()
  add(query_595001, "MaxRecords", newJInt(MaxRecords))
  add(query_595001, "Action", newJString(Action))
  add(query_595001, "Marker", newJString(Marker))
  add(query_595001, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595001, "Version", newJString(Version))
  result = call_595000.call(nil, query_595001, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_594984(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_594985, base: "/",
    url: url_GetDescribeDBSubnetGroups_594986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_595039 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEngineDefaultParameters_595041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_595040(path: JsonNode;
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
  var valid_595042 = query.getOrDefault("Action")
  valid_595042 = validateParameter(valid_595042, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595042 != nil:
    section.add "Action", valid_595042
  var valid_595043 = query.getOrDefault("Version")
  valid_595043 = validateParameter(valid_595043, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595043 != nil:
    section.add "Version", valid_595043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595044 = header.getOrDefault("X-Amz-Date")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Date", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Security-Token")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Security-Token", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Algorithm")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Algorithm", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Signature")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Signature", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-SignedHeaders", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Credential")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Credential", valid_595050
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595051 = formData.getOrDefault("Marker")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "Marker", valid_595051
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595052 = formData.getOrDefault("DBParameterGroupFamily")
  valid_595052 = validateParameter(valid_595052, JString, required = true,
                                 default = nil)
  if valid_595052 != nil:
    section.add "DBParameterGroupFamily", valid_595052
  var valid_595053 = formData.getOrDefault("MaxRecords")
  valid_595053 = validateParameter(valid_595053, JInt, required = false, default = nil)
  if valid_595053 != nil:
    section.add "MaxRecords", valid_595053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595054: Call_PostDescribeEngineDefaultParameters_595039;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595054.validator(path, query, header, formData, body)
  let scheme = call_595054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595054.url(scheme.get, call_595054.host, call_595054.base,
                         call_595054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595054, url, valid)

proc call*(call_595055: Call_PostDescribeEngineDefaultParameters_595039;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595056 = newJObject()
  var formData_595057 = newJObject()
  add(formData_595057, "Marker", newJString(Marker))
  add(query_595056, "Action", newJString(Action))
  add(formData_595057, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_595057, "MaxRecords", newJInt(MaxRecords))
  add(query_595056, "Version", newJString(Version))
  result = call_595055.call(nil, query_595056, nil, formData_595057, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_595039(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_595040, base: "/",
    url: url_PostDescribeEngineDefaultParameters_595041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_595021 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEngineDefaultParameters_595023(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_595022(path: JsonNode;
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
  var valid_595024 = query.getOrDefault("MaxRecords")
  valid_595024 = validateParameter(valid_595024, JInt, required = false, default = nil)
  if valid_595024 != nil:
    section.add "MaxRecords", valid_595024
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595025 = query.getOrDefault("DBParameterGroupFamily")
  valid_595025 = validateParameter(valid_595025, JString, required = true,
                                 default = nil)
  if valid_595025 != nil:
    section.add "DBParameterGroupFamily", valid_595025
  var valid_595026 = query.getOrDefault("Action")
  valid_595026 = validateParameter(valid_595026, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595026 != nil:
    section.add "Action", valid_595026
  var valid_595027 = query.getOrDefault("Marker")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "Marker", valid_595027
  var valid_595028 = query.getOrDefault("Version")
  valid_595028 = validateParameter(valid_595028, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595028 != nil:
    section.add "Version", valid_595028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595029 = header.getOrDefault("X-Amz-Date")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Date", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Security-Token")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Security-Token", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Content-Sha256", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Algorithm")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Algorithm", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Signature")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Signature", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-SignedHeaders", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Credential")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Credential", valid_595035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595036: Call_GetDescribeEngineDefaultParameters_595021;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595036.validator(path, query, header, formData, body)
  let scheme = call_595036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595036.url(scheme.get, call_595036.host, call_595036.base,
                         call_595036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595036, url, valid)

proc call*(call_595037: Call_GetDescribeEngineDefaultParameters_595021;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595038 = newJObject()
  add(query_595038, "MaxRecords", newJInt(MaxRecords))
  add(query_595038, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_595038, "Action", newJString(Action))
  add(query_595038, "Marker", newJString(Marker))
  add(query_595038, "Version", newJString(Version))
  result = call_595037.call(nil, query_595038, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_595021(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_595022, base: "/",
    url: url_GetDescribeEngineDefaultParameters_595023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_595074 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventCategories_595076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_595075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595077 = query.getOrDefault("Action")
  valid_595077 = validateParameter(valid_595077, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595077 != nil:
    section.add "Action", valid_595077
  var valid_595078 = query.getOrDefault("Version")
  valid_595078 = validateParameter(valid_595078, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595078 != nil:
    section.add "Version", valid_595078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595079 = header.getOrDefault("X-Amz-Date")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Date", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Security-Token")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Security-Token", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Content-Sha256", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Algorithm")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Algorithm", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-Signature")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-Signature", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-SignedHeaders", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Credential")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Credential", valid_595085
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_595086 = formData.getOrDefault("SourceType")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "SourceType", valid_595086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595087: Call_PostDescribeEventCategories_595074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595087.validator(path, query, header, formData, body)
  let scheme = call_595087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595087.url(scheme.get, call_595087.host, call_595087.base,
                         call_595087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595087, url, valid)

proc call*(call_595088: Call_PostDescribeEventCategories_595074;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_595089 = newJObject()
  var formData_595090 = newJObject()
  add(query_595089, "Action", newJString(Action))
  add(query_595089, "Version", newJString(Version))
  add(formData_595090, "SourceType", newJString(SourceType))
  result = call_595088.call(nil, query_595089, nil, formData_595090, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_595074(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_595075, base: "/",
    url: url_PostDescribeEventCategories_595076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_595058 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventCategories_595060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_595059(path: JsonNode; query: JsonNode;
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
  var valid_595061 = query.getOrDefault("SourceType")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "SourceType", valid_595061
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595062 = query.getOrDefault("Action")
  valid_595062 = validateParameter(valid_595062, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595062 != nil:
    section.add "Action", valid_595062
  var valid_595063 = query.getOrDefault("Version")
  valid_595063 = validateParameter(valid_595063, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595063 != nil:
    section.add "Version", valid_595063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595064 = header.getOrDefault("X-Amz-Date")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Date", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Security-Token")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Security-Token", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Content-Sha256", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Algorithm")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Algorithm", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-Signature")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-Signature", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-SignedHeaders", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Credential")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Credential", valid_595070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595071: Call_GetDescribeEventCategories_595058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595071.validator(path, query, header, formData, body)
  let scheme = call_595071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595071.url(scheme.get, call_595071.host, call_595071.base,
                         call_595071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595071, url, valid)

proc call*(call_595072: Call_GetDescribeEventCategories_595058;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595073 = newJObject()
  add(query_595073, "SourceType", newJString(SourceType))
  add(query_595073, "Action", newJString(Action))
  add(query_595073, "Version", newJString(Version))
  result = call_595072.call(nil, query_595073, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_595058(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_595059, base: "/",
    url: url_GetDescribeEventCategories_595060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_595109 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventSubscriptions_595111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_595110(path: JsonNode;
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
  var valid_595112 = query.getOrDefault("Action")
  valid_595112 = validateParameter(valid_595112, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595112 != nil:
    section.add "Action", valid_595112
  var valid_595113 = query.getOrDefault("Version")
  valid_595113 = validateParameter(valid_595113, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595113 != nil:
    section.add "Version", valid_595113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595114 = header.getOrDefault("X-Amz-Date")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Date", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Security-Token")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Security-Token", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Content-Sha256", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-Algorithm")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Algorithm", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Signature")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Signature", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-SignedHeaders", valid_595119
  var valid_595120 = header.getOrDefault("X-Amz-Credential")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "X-Amz-Credential", valid_595120
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595121 = formData.getOrDefault("Marker")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "Marker", valid_595121
  var valid_595122 = formData.getOrDefault("SubscriptionName")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "SubscriptionName", valid_595122
  var valid_595123 = formData.getOrDefault("MaxRecords")
  valid_595123 = validateParameter(valid_595123, JInt, required = false, default = nil)
  if valid_595123 != nil:
    section.add "MaxRecords", valid_595123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595124: Call_PostDescribeEventSubscriptions_595109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595124.validator(path, query, header, formData, body)
  let scheme = call_595124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595124.url(scheme.get, call_595124.host, call_595124.base,
                         call_595124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595124, url, valid)

proc call*(call_595125: Call_PostDescribeEventSubscriptions_595109;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595126 = newJObject()
  var formData_595127 = newJObject()
  add(formData_595127, "Marker", newJString(Marker))
  add(formData_595127, "SubscriptionName", newJString(SubscriptionName))
  add(query_595126, "Action", newJString(Action))
  add(formData_595127, "MaxRecords", newJInt(MaxRecords))
  add(query_595126, "Version", newJString(Version))
  result = call_595125.call(nil, query_595126, nil, formData_595127, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_595109(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_595110, base: "/",
    url: url_PostDescribeEventSubscriptions_595111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_595091 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventSubscriptions_595093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_595092(path: JsonNode; query: JsonNode;
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
  var valid_595094 = query.getOrDefault("MaxRecords")
  valid_595094 = validateParameter(valid_595094, JInt, required = false, default = nil)
  if valid_595094 != nil:
    section.add "MaxRecords", valid_595094
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595095 = query.getOrDefault("Action")
  valid_595095 = validateParameter(valid_595095, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595095 != nil:
    section.add "Action", valid_595095
  var valid_595096 = query.getOrDefault("Marker")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "Marker", valid_595096
  var valid_595097 = query.getOrDefault("SubscriptionName")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "SubscriptionName", valid_595097
  var valid_595098 = query.getOrDefault("Version")
  valid_595098 = validateParameter(valid_595098, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595098 != nil:
    section.add "Version", valid_595098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595099 = header.getOrDefault("X-Amz-Date")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Date", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Security-Token")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Security-Token", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Content-Sha256", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-Algorithm")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-Algorithm", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-Signature")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-Signature", valid_595103
  var valid_595104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595104 = validateParameter(valid_595104, JString, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "X-Amz-SignedHeaders", valid_595104
  var valid_595105 = header.getOrDefault("X-Amz-Credential")
  valid_595105 = validateParameter(valid_595105, JString, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "X-Amz-Credential", valid_595105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595106: Call_GetDescribeEventSubscriptions_595091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595106.validator(path, query, header, formData, body)
  let scheme = call_595106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595106.url(scheme.get, call_595106.host, call_595106.base,
                         call_595106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595106, url, valid)

proc call*(call_595107: Call_GetDescribeEventSubscriptions_595091;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_595108 = newJObject()
  add(query_595108, "MaxRecords", newJInt(MaxRecords))
  add(query_595108, "Action", newJString(Action))
  add(query_595108, "Marker", newJString(Marker))
  add(query_595108, "SubscriptionName", newJString(SubscriptionName))
  add(query_595108, "Version", newJString(Version))
  result = call_595107.call(nil, query_595108, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_595091(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_595092, base: "/",
    url: url_GetDescribeEventSubscriptions_595093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_595151 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEvents_595153(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_595152(path: JsonNode; query: JsonNode;
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
  var valid_595154 = query.getOrDefault("Action")
  valid_595154 = validateParameter(valid_595154, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595154 != nil:
    section.add "Action", valid_595154
  var valid_595155 = query.getOrDefault("Version")
  valid_595155 = validateParameter(valid_595155, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595155 != nil:
    section.add "Version", valid_595155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595156 = header.getOrDefault("X-Amz-Date")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Date", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Security-Token")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Security-Token", valid_595157
  var valid_595158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "X-Amz-Content-Sha256", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Algorithm")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Algorithm", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Signature")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Signature", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-SignedHeaders", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-Credential")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-Credential", valid_595162
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
  var valid_595163 = formData.getOrDefault("SourceIdentifier")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "SourceIdentifier", valid_595163
  var valid_595164 = formData.getOrDefault("EventCategories")
  valid_595164 = validateParameter(valid_595164, JArray, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "EventCategories", valid_595164
  var valid_595165 = formData.getOrDefault("Marker")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "Marker", valid_595165
  var valid_595166 = formData.getOrDefault("StartTime")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "StartTime", valid_595166
  var valid_595167 = formData.getOrDefault("Duration")
  valid_595167 = validateParameter(valid_595167, JInt, required = false, default = nil)
  if valid_595167 != nil:
    section.add "Duration", valid_595167
  var valid_595168 = formData.getOrDefault("EndTime")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "EndTime", valid_595168
  var valid_595169 = formData.getOrDefault("MaxRecords")
  valid_595169 = validateParameter(valid_595169, JInt, required = false, default = nil)
  if valid_595169 != nil:
    section.add "MaxRecords", valid_595169
  var valid_595170 = formData.getOrDefault("SourceType")
  valid_595170 = validateParameter(valid_595170, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595170 != nil:
    section.add "SourceType", valid_595170
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595171: Call_PostDescribeEvents_595151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595171.validator(path, query, header, formData, body)
  let scheme = call_595171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595171.url(scheme.get, call_595171.host, call_595171.base,
                         call_595171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595171, url, valid)

proc call*(call_595172: Call_PostDescribeEvents_595151;
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
  var query_595173 = newJObject()
  var formData_595174 = newJObject()
  add(formData_595174, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_595174.add "EventCategories", EventCategories
  add(formData_595174, "Marker", newJString(Marker))
  add(formData_595174, "StartTime", newJString(StartTime))
  add(query_595173, "Action", newJString(Action))
  add(formData_595174, "Duration", newJInt(Duration))
  add(formData_595174, "EndTime", newJString(EndTime))
  add(formData_595174, "MaxRecords", newJInt(MaxRecords))
  add(query_595173, "Version", newJString(Version))
  add(formData_595174, "SourceType", newJString(SourceType))
  result = call_595172.call(nil, query_595173, nil, formData_595174, nil)

var postDescribeEvents* = Call_PostDescribeEvents_595151(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_595152, base: "/",
    url: url_PostDescribeEvents_595153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_595128 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEvents_595130(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_595129(path: JsonNode; query: JsonNode;
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
  var valid_595131 = query.getOrDefault("SourceType")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595131 != nil:
    section.add "SourceType", valid_595131
  var valid_595132 = query.getOrDefault("MaxRecords")
  valid_595132 = validateParameter(valid_595132, JInt, required = false, default = nil)
  if valid_595132 != nil:
    section.add "MaxRecords", valid_595132
  var valid_595133 = query.getOrDefault("StartTime")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "StartTime", valid_595133
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595134 = query.getOrDefault("Action")
  valid_595134 = validateParameter(valid_595134, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595134 != nil:
    section.add "Action", valid_595134
  var valid_595135 = query.getOrDefault("SourceIdentifier")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "SourceIdentifier", valid_595135
  var valid_595136 = query.getOrDefault("Marker")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "Marker", valid_595136
  var valid_595137 = query.getOrDefault("EventCategories")
  valid_595137 = validateParameter(valid_595137, JArray, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "EventCategories", valid_595137
  var valid_595138 = query.getOrDefault("Duration")
  valid_595138 = validateParameter(valid_595138, JInt, required = false, default = nil)
  if valid_595138 != nil:
    section.add "Duration", valid_595138
  var valid_595139 = query.getOrDefault("EndTime")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "EndTime", valid_595139
  var valid_595140 = query.getOrDefault("Version")
  valid_595140 = validateParameter(valid_595140, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595140 != nil:
    section.add "Version", valid_595140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595141 = header.getOrDefault("X-Amz-Date")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Date", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Security-Token")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Security-Token", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Content-Sha256", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Algorithm")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Algorithm", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Signature")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Signature", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-SignedHeaders", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-Credential")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-Credential", valid_595147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595148: Call_GetDescribeEvents_595128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595148.validator(path, query, header, formData, body)
  let scheme = call_595148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595148.url(scheme.get, call_595148.host, call_595148.base,
                         call_595148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595148, url, valid)

proc call*(call_595149: Call_GetDescribeEvents_595128;
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
  var query_595150 = newJObject()
  add(query_595150, "SourceType", newJString(SourceType))
  add(query_595150, "MaxRecords", newJInt(MaxRecords))
  add(query_595150, "StartTime", newJString(StartTime))
  add(query_595150, "Action", newJString(Action))
  add(query_595150, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595150, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_595150.add "EventCategories", EventCategories
  add(query_595150, "Duration", newJInt(Duration))
  add(query_595150, "EndTime", newJString(EndTime))
  add(query_595150, "Version", newJString(Version))
  result = call_595149.call(nil, query_595150, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_595128(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_595129,
    base: "/", url: url_GetDescribeEvents_595130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_595194 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroupOptions_595196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_595195(path: JsonNode;
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
  var valid_595197 = query.getOrDefault("Action")
  valid_595197 = validateParameter(valid_595197, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595197 != nil:
    section.add "Action", valid_595197
  var valid_595198 = query.getOrDefault("Version")
  valid_595198 = validateParameter(valid_595198, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595198 != nil:
    section.add "Version", valid_595198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595199 = header.getOrDefault("X-Amz-Date")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Date", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-Security-Token")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-Security-Token", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Content-Sha256", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Algorithm")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Algorithm", valid_595202
  var valid_595203 = header.getOrDefault("X-Amz-Signature")
  valid_595203 = validateParameter(valid_595203, JString, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "X-Amz-Signature", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-SignedHeaders", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Credential")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Credential", valid_595205
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595206 = formData.getOrDefault("MajorEngineVersion")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "MajorEngineVersion", valid_595206
  var valid_595207 = formData.getOrDefault("Marker")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "Marker", valid_595207
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_595208 = formData.getOrDefault("EngineName")
  valid_595208 = validateParameter(valid_595208, JString, required = true,
                                 default = nil)
  if valid_595208 != nil:
    section.add "EngineName", valid_595208
  var valid_595209 = formData.getOrDefault("MaxRecords")
  valid_595209 = validateParameter(valid_595209, JInt, required = false, default = nil)
  if valid_595209 != nil:
    section.add "MaxRecords", valid_595209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595210: Call_PostDescribeOptionGroupOptions_595194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595210.validator(path, query, header, formData, body)
  let scheme = call_595210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595210.url(scheme.get, call_595210.host, call_595210.base,
                         call_595210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595210, url, valid)

proc call*(call_595211: Call_PostDescribeOptionGroupOptions_595194;
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
  var query_595212 = newJObject()
  var formData_595213 = newJObject()
  add(formData_595213, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595213, "Marker", newJString(Marker))
  add(query_595212, "Action", newJString(Action))
  add(formData_595213, "EngineName", newJString(EngineName))
  add(formData_595213, "MaxRecords", newJInt(MaxRecords))
  add(query_595212, "Version", newJString(Version))
  result = call_595211.call(nil, query_595212, nil, formData_595213, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_595194(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_595195, base: "/",
    url: url_PostDescribeOptionGroupOptions_595196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_595175 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroupOptions_595177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_595176(path: JsonNode; query: JsonNode;
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
  var valid_595178 = query.getOrDefault("MaxRecords")
  valid_595178 = validateParameter(valid_595178, JInt, required = false, default = nil)
  if valid_595178 != nil:
    section.add "MaxRecords", valid_595178
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595179 = query.getOrDefault("Action")
  valid_595179 = validateParameter(valid_595179, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595179 != nil:
    section.add "Action", valid_595179
  var valid_595180 = query.getOrDefault("Marker")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "Marker", valid_595180
  var valid_595181 = query.getOrDefault("Version")
  valid_595181 = validateParameter(valid_595181, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595181 != nil:
    section.add "Version", valid_595181
  var valid_595182 = query.getOrDefault("EngineName")
  valid_595182 = validateParameter(valid_595182, JString, required = true,
                                 default = nil)
  if valid_595182 != nil:
    section.add "EngineName", valid_595182
  var valid_595183 = query.getOrDefault("MajorEngineVersion")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "MajorEngineVersion", valid_595183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595184 = header.getOrDefault("X-Amz-Date")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Date", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-Security-Token")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-Security-Token", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Content-Sha256", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Algorithm")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Algorithm", valid_595187
  var valid_595188 = header.getOrDefault("X-Amz-Signature")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "X-Amz-Signature", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-SignedHeaders", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Credential")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Credential", valid_595190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595191: Call_GetDescribeOptionGroupOptions_595175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595191.validator(path, query, header, formData, body)
  let scheme = call_595191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595191.url(scheme.get, call_595191.host, call_595191.base,
                         call_595191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595191, url, valid)

proc call*(call_595192: Call_GetDescribeOptionGroupOptions_595175;
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
  var query_595193 = newJObject()
  add(query_595193, "MaxRecords", newJInt(MaxRecords))
  add(query_595193, "Action", newJString(Action))
  add(query_595193, "Marker", newJString(Marker))
  add(query_595193, "Version", newJString(Version))
  add(query_595193, "EngineName", newJString(EngineName))
  add(query_595193, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595192.call(nil, query_595193, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_595175(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_595176, base: "/",
    url: url_GetDescribeOptionGroupOptions_595177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_595234 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroups_595236(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_595235(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595237 = query.getOrDefault("Action")
  valid_595237 = validateParameter(valid_595237, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595237 != nil:
    section.add "Action", valid_595237
  var valid_595238 = query.getOrDefault("Version")
  valid_595238 = validateParameter(valid_595238, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595238 != nil:
    section.add "Version", valid_595238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595239 = header.getOrDefault("X-Amz-Date")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Date", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Security-Token")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Security-Token", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-Content-Sha256", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Algorithm")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Algorithm", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-Signature")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-Signature", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-SignedHeaders", valid_595244
  var valid_595245 = header.getOrDefault("X-Amz-Credential")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "X-Amz-Credential", valid_595245
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595246 = formData.getOrDefault("MajorEngineVersion")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "MajorEngineVersion", valid_595246
  var valid_595247 = formData.getOrDefault("OptionGroupName")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "OptionGroupName", valid_595247
  var valid_595248 = formData.getOrDefault("Marker")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "Marker", valid_595248
  var valid_595249 = formData.getOrDefault("EngineName")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "EngineName", valid_595249
  var valid_595250 = formData.getOrDefault("MaxRecords")
  valid_595250 = validateParameter(valid_595250, JInt, required = false, default = nil)
  if valid_595250 != nil:
    section.add "MaxRecords", valid_595250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595251: Call_PostDescribeOptionGroups_595234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595251.validator(path, query, header, formData, body)
  let scheme = call_595251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595251.url(scheme.get, call_595251.host, call_595251.base,
                         call_595251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595251, url, valid)

proc call*(call_595252: Call_PostDescribeOptionGroups_595234;
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
  var query_595253 = newJObject()
  var formData_595254 = newJObject()
  add(formData_595254, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595254, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595254, "Marker", newJString(Marker))
  add(query_595253, "Action", newJString(Action))
  add(formData_595254, "EngineName", newJString(EngineName))
  add(formData_595254, "MaxRecords", newJInt(MaxRecords))
  add(query_595253, "Version", newJString(Version))
  result = call_595252.call(nil, query_595253, nil, formData_595254, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_595234(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_595235, base: "/",
    url: url_PostDescribeOptionGroups_595236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_595214 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroups_595216(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_595215(path: JsonNode; query: JsonNode;
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
  var valid_595217 = query.getOrDefault("MaxRecords")
  valid_595217 = validateParameter(valid_595217, JInt, required = false, default = nil)
  if valid_595217 != nil:
    section.add "MaxRecords", valid_595217
  var valid_595218 = query.getOrDefault("OptionGroupName")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "OptionGroupName", valid_595218
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595219 = query.getOrDefault("Action")
  valid_595219 = validateParameter(valid_595219, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595219 != nil:
    section.add "Action", valid_595219
  var valid_595220 = query.getOrDefault("Marker")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "Marker", valid_595220
  var valid_595221 = query.getOrDefault("Version")
  valid_595221 = validateParameter(valid_595221, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595221 != nil:
    section.add "Version", valid_595221
  var valid_595222 = query.getOrDefault("EngineName")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "EngineName", valid_595222
  var valid_595223 = query.getOrDefault("MajorEngineVersion")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "MajorEngineVersion", valid_595223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595224 = header.getOrDefault("X-Amz-Date")
  valid_595224 = validateParameter(valid_595224, JString, required = false,
                                 default = nil)
  if valid_595224 != nil:
    section.add "X-Amz-Date", valid_595224
  var valid_595225 = header.getOrDefault("X-Amz-Security-Token")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "X-Amz-Security-Token", valid_595225
  var valid_595226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "X-Amz-Content-Sha256", valid_595226
  var valid_595227 = header.getOrDefault("X-Amz-Algorithm")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-Algorithm", valid_595227
  var valid_595228 = header.getOrDefault("X-Amz-Signature")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "X-Amz-Signature", valid_595228
  var valid_595229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-SignedHeaders", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Credential")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Credential", valid_595230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595231: Call_GetDescribeOptionGroups_595214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595231.validator(path, query, header, formData, body)
  let scheme = call_595231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595231.url(scheme.get, call_595231.host, call_595231.base,
                         call_595231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595231, url, valid)

proc call*(call_595232: Call_GetDescribeOptionGroups_595214; MaxRecords: int = 0;
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
  var query_595233 = newJObject()
  add(query_595233, "MaxRecords", newJInt(MaxRecords))
  add(query_595233, "OptionGroupName", newJString(OptionGroupName))
  add(query_595233, "Action", newJString(Action))
  add(query_595233, "Marker", newJString(Marker))
  add(query_595233, "Version", newJString(Version))
  add(query_595233, "EngineName", newJString(EngineName))
  add(query_595233, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595232.call(nil, query_595233, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_595214(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_595215, base: "/",
    url: url_GetDescribeOptionGroups_595216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_595277 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOrderableDBInstanceOptions_595279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_595278(path: JsonNode;
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
  var valid_595280 = query.getOrDefault("Action")
  valid_595280 = validateParameter(valid_595280, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595280 != nil:
    section.add "Action", valid_595280
  var valid_595281 = query.getOrDefault("Version")
  valid_595281 = validateParameter(valid_595281, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595281 != nil:
    section.add "Version", valid_595281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595282 = header.getOrDefault("X-Amz-Date")
  valid_595282 = validateParameter(valid_595282, JString, required = false,
                                 default = nil)
  if valid_595282 != nil:
    section.add "X-Amz-Date", valid_595282
  var valid_595283 = header.getOrDefault("X-Amz-Security-Token")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "X-Amz-Security-Token", valid_595283
  var valid_595284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "X-Amz-Content-Sha256", valid_595284
  var valid_595285 = header.getOrDefault("X-Amz-Algorithm")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Algorithm", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Signature")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Signature", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-SignedHeaders", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Credential")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Credential", valid_595288
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
  var valid_595289 = formData.getOrDefault("Engine")
  valid_595289 = validateParameter(valid_595289, JString, required = true,
                                 default = nil)
  if valid_595289 != nil:
    section.add "Engine", valid_595289
  var valid_595290 = formData.getOrDefault("Marker")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "Marker", valid_595290
  var valid_595291 = formData.getOrDefault("Vpc")
  valid_595291 = validateParameter(valid_595291, JBool, required = false, default = nil)
  if valid_595291 != nil:
    section.add "Vpc", valid_595291
  var valid_595292 = formData.getOrDefault("DBInstanceClass")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "DBInstanceClass", valid_595292
  var valid_595293 = formData.getOrDefault("LicenseModel")
  valid_595293 = validateParameter(valid_595293, JString, required = false,
                                 default = nil)
  if valid_595293 != nil:
    section.add "LicenseModel", valid_595293
  var valid_595294 = formData.getOrDefault("MaxRecords")
  valid_595294 = validateParameter(valid_595294, JInt, required = false, default = nil)
  if valid_595294 != nil:
    section.add "MaxRecords", valid_595294
  var valid_595295 = formData.getOrDefault("EngineVersion")
  valid_595295 = validateParameter(valid_595295, JString, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "EngineVersion", valid_595295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595296: Call_PostDescribeOrderableDBInstanceOptions_595277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595296.validator(path, query, header, formData, body)
  let scheme = call_595296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595296.url(scheme.get, call_595296.host, call_595296.base,
                         call_595296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595296, url, valid)

proc call*(call_595297: Call_PostDescribeOrderableDBInstanceOptions_595277;
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
  var query_595298 = newJObject()
  var formData_595299 = newJObject()
  add(formData_595299, "Engine", newJString(Engine))
  add(formData_595299, "Marker", newJString(Marker))
  add(query_595298, "Action", newJString(Action))
  add(formData_595299, "Vpc", newJBool(Vpc))
  add(formData_595299, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595299, "LicenseModel", newJString(LicenseModel))
  add(formData_595299, "MaxRecords", newJInt(MaxRecords))
  add(formData_595299, "EngineVersion", newJString(EngineVersion))
  add(query_595298, "Version", newJString(Version))
  result = call_595297.call(nil, query_595298, nil, formData_595299, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_595277(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_595278, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_595279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_595255 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOrderableDBInstanceOptions_595257(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_595256(path: JsonNode;
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
  var valid_595258 = query.getOrDefault("Engine")
  valid_595258 = validateParameter(valid_595258, JString, required = true,
                                 default = nil)
  if valid_595258 != nil:
    section.add "Engine", valid_595258
  var valid_595259 = query.getOrDefault("MaxRecords")
  valid_595259 = validateParameter(valid_595259, JInt, required = false, default = nil)
  if valid_595259 != nil:
    section.add "MaxRecords", valid_595259
  var valid_595260 = query.getOrDefault("LicenseModel")
  valid_595260 = validateParameter(valid_595260, JString, required = false,
                                 default = nil)
  if valid_595260 != nil:
    section.add "LicenseModel", valid_595260
  var valid_595261 = query.getOrDefault("Vpc")
  valid_595261 = validateParameter(valid_595261, JBool, required = false, default = nil)
  if valid_595261 != nil:
    section.add "Vpc", valid_595261
  var valid_595262 = query.getOrDefault("DBInstanceClass")
  valid_595262 = validateParameter(valid_595262, JString, required = false,
                                 default = nil)
  if valid_595262 != nil:
    section.add "DBInstanceClass", valid_595262
  var valid_595263 = query.getOrDefault("Action")
  valid_595263 = validateParameter(valid_595263, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595263 != nil:
    section.add "Action", valid_595263
  var valid_595264 = query.getOrDefault("Marker")
  valid_595264 = validateParameter(valid_595264, JString, required = false,
                                 default = nil)
  if valid_595264 != nil:
    section.add "Marker", valid_595264
  var valid_595265 = query.getOrDefault("EngineVersion")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "EngineVersion", valid_595265
  var valid_595266 = query.getOrDefault("Version")
  valid_595266 = validateParameter(valid_595266, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595266 != nil:
    section.add "Version", valid_595266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595267 = header.getOrDefault("X-Amz-Date")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "X-Amz-Date", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-Security-Token")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-Security-Token", valid_595268
  var valid_595269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Content-Sha256", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Algorithm")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Algorithm", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-Signature")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-Signature", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-SignedHeaders", valid_595272
  var valid_595273 = header.getOrDefault("X-Amz-Credential")
  valid_595273 = validateParameter(valid_595273, JString, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "X-Amz-Credential", valid_595273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595274: Call_GetDescribeOrderableDBInstanceOptions_595255;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595274.validator(path, query, header, formData, body)
  let scheme = call_595274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595274.url(scheme.get, call_595274.host, call_595274.base,
                         call_595274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595274, url, valid)

proc call*(call_595275: Call_GetDescribeOrderableDBInstanceOptions_595255;
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
  var query_595276 = newJObject()
  add(query_595276, "Engine", newJString(Engine))
  add(query_595276, "MaxRecords", newJInt(MaxRecords))
  add(query_595276, "LicenseModel", newJString(LicenseModel))
  add(query_595276, "Vpc", newJBool(Vpc))
  add(query_595276, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595276, "Action", newJString(Action))
  add(query_595276, "Marker", newJString(Marker))
  add(query_595276, "EngineVersion", newJString(EngineVersion))
  add(query_595276, "Version", newJString(Version))
  result = call_595275.call(nil, query_595276, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_595255(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_595256, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_595257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_595324 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstances_595326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_595325(path: JsonNode;
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
  var valid_595327 = query.getOrDefault("Action")
  valid_595327 = validateParameter(valid_595327, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595327 != nil:
    section.add "Action", valid_595327
  var valid_595328 = query.getOrDefault("Version")
  valid_595328 = validateParameter(valid_595328, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595328 != nil:
    section.add "Version", valid_595328
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595329 = header.getOrDefault("X-Amz-Date")
  valid_595329 = validateParameter(valid_595329, JString, required = false,
                                 default = nil)
  if valid_595329 != nil:
    section.add "X-Amz-Date", valid_595329
  var valid_595330 = header.getOrDefault("X-Amz-Security-Token")
  valid_595330 = validateParameter(valid_595330, JString, required = false,
                                 default = nil)
  if valid_595330 != nil:
    section.add "X-Amz-Security-Token", valid_595330
  var valid_595331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-Content-Sha256", valid_595331
  var valid_595332 = header.getOrDefault("X-Amz-Algorithm")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Algorithm", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-Signature")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-Signature", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-SignedHeaders", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Credential")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Credential", valid_595335
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
  var valid_595336 = formData.getOrDefault("OfferingType")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "OfferingType", valid_595336
  var valid_595337 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "ReservedDBInstanceId", valid_595337
  var valid_595338 = formData.getOrDefault("Marker")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "Marker", valid_595338
  var valid_595339 = formData.getOrDefault("MultiAZ")
  valid_595339 = validateParameter(valid_595339, JBool, required = false, default = nil)
  if valid_595339 != nil:
    section.add "MultiAZ", valid_595339
  var valid_595340 = formData.getOrDefault("Duration")
  valid_595340 = validateParameter(valid_595340, JString, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "Duration", valid_595340
  var valid_595341 = formData.getOrDefault("DBInstanceClass")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "DBInstanceClass", valid_595341
  var valid_595342 = formData.getOrDefault("ProductDescription")
  valid_595342 = validateParameter(valid_595342, JString, required = false,
                                 default = nil)
  if valid_595342 != nil:
    section.add "ProductDescription", valid_595342
  var valid_595343 = formData.getOrDefault("MaxRecords")
  valid_595343 = validateParameter(valid_595343, JInt, required = false, default = nil)
  if valid_595343 != nil:
    section.add "MaxRecords", valid_595343
  var valid_595344 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595344 = validateParameter(valid_595344, JString, required = false,
                                 default = nil)
  if valid_595344 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595345: Call_PostDescribeReservedDBInstances_595324;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595345.validator(path, query, header, formData, body)
  let scheme = call_595345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595345.url(scheme.get, call_595345.host, call_595345.base,
                         call_595345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595345, url, valid)

proc call*(call_595346: Call_PostDescribeReservedDBInstances_595324;
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
  var query_595347 = newJObject()
  var formData_595348 = newJObject()
  add(formData_595348, "OfferingType", newJString(OfferingType))
  add(formData_595348, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595348, "Marker", newJString(Marker))
  add(formData_595348, "MultiAZ", newJBool(MultiAZ))
  add(query_595347, "Action", newJString(Action))
  add(formData_595348, "Duration", newJString(Duration))
  add(formData_595348, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595348, "ProductDescription", newJString(ProductDescription))
  add(formData_595348, "MaxRecords", newJInt(MaxRecords))
  add(formData_595348, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595347, "Version", newJString(Version))
  result = call_595346.call(nil, query_595347, nil, formData_595348, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_595324(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_595325, base: "/",
    url: url_PostDescribeReservedDBInstances_595326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_595300 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstances_595302(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_595301(path: JsonNode;
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
  var valid_595303 = query.getOrDefault("ProductDescription")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "ProductDescription", valid_595303
  var valid_595304 = query.getOrDefault("MaxRecords")
  valid_595304 = validateParameter(valid_595304, JInt, required = false, default = nil)
  if valid_595304 != nil:
    section.add "MaxRecords", valid_595304
  var valid_595305 = query.getOrDefault("OfferingType")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "OfferingType", valid_595305
  var valid_595306 = query.getOrDefault("MultiAZ")
  valid_595306 = validateParameter(valid_595306, JBool, required = false, default = nil)
  if valid_595306 != nil:
    section.add "MultiAZ", valid_595306
  var valid_595307 = query.getOrDefault("ReservedDBInstanceId")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "ReservedDBInstanceId", valid_595307
  var valid_595308 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595308
  var valid_595309 = query.getOrDefault("DBInstanceClass")
  valid_595309 = validateParameter(valid_595309, JString, required = false,
                                 default = nil)
  if valid_595309 != nil:
    section.add "DBInstanceClass", valid_595309
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595310 = query.getOrDefault("Action")
  valid_595310 = validateParameter(valid_595310, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595310 != nil:
    section.add "Action", valid_595310
  var valid_595311 = query.getOrDefault("Marker")
  valid_595311 = validateParameter(valid_595311, JString, required = false,
                                 default = nil)
  if valid_595311 != nil:
    section.add "Marker", valid_595311
  var valid_595312 = query.getOrDefault("Duration")
  valid_595312 = validateParameter(valid_595312, JString, required = false,
                                 default = nil)
  if valid_595312 != nil:
    section.add "Duration", valid_595312
  var valid_595313 = query.getOrDefault("Version")
  valid_595313 = validateParameter(valid_595313, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595313 != nil:
    section.add "Version", valid_595313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595314 = header.getOrDefault("X-Amz-Date")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Date", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-Security-Token")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-Security-Token", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-Content-Sha256", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Algorithm")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Algorithm", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-Signature")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-Signature", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-SignedHeaders", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Credential")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Credential", valid_595320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595321: Call_GetDescribeReservedDBInstances_595300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595321.validator(path, query, header, formData, body)
  let scheme = call_595321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595321.url(scheme.get, call_595321.host, call_595321.base,
                         call_595321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595321, url, valid)

proc call*(call_595322: Call_GetDescribeReservedDBInstances_595300;
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
  var query_595323 = newJObject()
  add(query_595323, "ProductDescription", newJString(ProductDescription))
  add(query_595323, "MaxRecords", newJInt(MaxRecords))
  add(query_595323, "OfferingType", newJString(OfferingType))
  add(query_595323, "MultiAZ", newJBool(MultiAZ))
  add(query_595323, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595323, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595323, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595323, "Action", newJString(Action))
  add(query_595323, "Marker", newJString(Marker))
  add(query_595323, "Duration", newJString(Duration))
  add(query_595323, "Version", newJString(Version))
  result = call_595322.call(nil, query_595323, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_595300(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_595301, base: "/",
    url: url_GetDescribeReservedDBInstances_595302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_595372 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstancesOfferings_595374(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_595373(path: JsonNode;
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
  var valid_595375 = query.getOrDefault("Action")
  valid_595375 = validateParameter(valid_595375, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595375 != nil:
    section.add "Action", valid_595375
  var valid_595376 = query.getOrDefault("Version")
  valid_595376 = validateParameter(valid_595376, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595376 != nil:
    section.add "Version", valid_595376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595377 = header.getOrDefault("X-Amz-Date")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-Date", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Security-Token")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Security-Token", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Content-Sha256", valid_595379
  var valid_595380 = header.getOrDefault("X-Amz-Algorithm")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "X-Amz-Algorithm", valid_595380
  var valid_595381 = header.getOrDefault("X-Amz-Signature")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "X-Amz-Signature", valid_595381
  var valid_595382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "X-Amz-SignedHeaders", valid_595382
  var valid_595383 = header.getOrDefault("X-Amz-Credential")
  valid_595383 = validateParameter(valid_595383, JString, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "X-Amz-Credential", valid_595383
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
  var valid_595384 = formData.getOrDefault("OfferingType")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "OfferingType", valid_595384
  var valid_595385 = formData.getOrDefault("Marker")
  valid_595385 = validateParameter(valid_595385, JString, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "Marker", valid_595385
  var valid_595386 = formData.getOrDefault("MultiAZ")
  valid_595386 = validateParameter(valid_595386, JBool, required = false, default = nil)
  if valid_595386 != nil:
    section.add "MultiAZ", valid_595386
  var valid_595387 = formData.getOrDefault("Duration")
  valid_595387 = validateParameter(valid_595387, JString, required = false,
                                 default = nil)
  if valid_595387 != nil:
    section.add "Duration", valid_595387
  var valid_595388 = formData.getOrDefault("DBInstanceClass")
  valid_595388 = validateParameter(valid_595388, JString, required = false,
                                 default = nil)
  if valid_595388 != nil:
    section.add "DBInstanceClass", valid_595388
  var valid_595389 = formData.getOrDefault("ProductDescription")
  valid_595389 = validateParameter(valid_595389, JString, required = false,
                                 default = nil)
  if valid_595389 != nil:
    section.add "ProductDescription", valid_595389
  var valid_595390 = formData.getOrDefault("MaxRecords")
  valid_595390 = validateParameter(valid_595390, JInt, required = false, default = nil)
  if valid_595390 != nil:
    section.add "MaxRecords", valid_595390
  var valid_595391 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595391 = validateParameter(valid_595391, JString, required = false,
                                 default = nil)
  if valid_595391 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595391
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595392: Call_PostDescribeReservedDBInstancesOfferings_595372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595392.validator(path, query, header, formData, body)
  let scheme = call_595392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595392.url(scheme.get, call_595392.host, call_595392.base,
                         call_595392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595392, url, valid)

proc call*(call_595393: Call_PostDescribeReservedDBInstancesOfferings_595372;
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
  var query_595394 = newJObject()
  var formData_595395 = newJObject()
  add(formData_595395, "OfferingType", newJString(OfferingType))
  add(formData_595395, "Marker", newJString(Marker))
  add(formData_595395, "MultiAZ", newJBool(MultiAZ))
  add(query_595394, "Action", newJString(Action))
  add(formData_595395, "Duration", newJString(Duration))
  add(formData_595395, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595395, "ProductDescription", newJString(ProductDescription))
  add(formData_595395, "MaxRecords", newJInt(MaxRecords))
  add(formData_595395, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595394, "Version", newJString(Version))
  result = call_595393.call(nil, query_595394, nil, formData_595395, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_595372(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_595373,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_595374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_595349 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstancesOfferings_595351(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_595350(path: JsonNode;
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
  var valid_595352 = query.getOrDefault("ProductDescription")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "ProductDescription", valid_595352
  var valid_595353 = query.getOrDefault("MaxRecords")
  valid_595353 = validateParameter(valid_595353, JInt, required = false, default = nil)
  if valid_595353 != nil:
    section.add "MaxRecords", valid_595353
  var valid_595354 = query.getOrDefault("OfferingType")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "OfferingType", valid_595354
  var valid_595355 = query.getOrDefault("MultiAZ")
  valid_595355 = validateParameter(valid_595355, JBool, required = false, default = nil)
  if valid_595355 != nil:
    section.add "MultiAZ", valid_595355
  var valid_595356 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595356 = validateParameter(valid_595356, JString, required = false,
                                 default = nil)
  if valid_595356 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595356
  var valid_595357 = query.getOrDefault("DBInstanceClass")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "DBInstanceClass", valid_595357
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595358 = query.getOrDefault("Action")
  valid_595358 = validateParameter(valid_595358, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595358 != nil:
    section.add "Action", valid_595358
  var valid_595359 = query.getOrDefault("Marker")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "Marker", valid_595359
  var valid_595360 = query.getOrDefault("Duration")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "Duration", valid_595360
  var valid_595361 = query.getOrDefault("Version")
  valid_595361 = validateParameter(valid_595361, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595361 != nil:
    section.add "Version", valid_595361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595362 = header.getOrDefault("X-Amz-Date")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-Date", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Security-Token")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Security-Token", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-Content-Sha256", valid_595364
  var valid_595365 = header.getOrDefault("X-Amz-Algorithm")
  valid_595365 = validateParameter(valid_595365, JString, required = false,
                                 default = nil)
  if valid_595365 != nil:
    section.add "X-Amz-Algorithm", valid_595365
  var valid_595366 = header.getOrDefault("X-Amz-Signature")
  valid_595366 = validateParameter(valid_595366, JString, required = false,
                                 default = nil)
  if valid_595366 != nil:
    section.add "X-Amz-Signature", valid_595366
  var valid_595367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595367 = validateParameter(valid_595367, JString, required = false,
                                 default = nil)
  if valid_595367 != nil:
    section.add "X-Amz-SignedHeaders", valid_595367
  var valid_595368 = header.getOrDefault("X-Amz-Credential")
  valid_595368 = validateParameter(valid_595368, JString, required = false,
                                 default = nil)
  if valid_595368 != nil:
    section.add "X-Amz-Credential", valid_595368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595369: Call_GetDescribeReservedDBInstancesOfferings_595349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595369.validator(path, query, header, formData, body)
  let scheme = call_595369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595369.url(scheme.get, call_595369.host, call_595369.base,
                         call_595369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595369, url, valid)

proc call*(call_595370: Call_GetDescribeReservedDBInstancesOfferings_595349;
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
  var query_595371 = newJObject()
  add(query_595371, "ProductDescription", newJString(ProductDescription))
  add(query_595371, "MaxRecords", newJInt(MaxRecords))
  add(query_595371, "OfferingType", newJString(OfferingType))
  add(query_595371, "MultiAZ", newJBool(MultiAZ))
  add(query_595371, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595371, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595371, "Action", newJString(Action))
  add(query_595371, "Marker", newJString(Marker))
  add(query_595371, "Duration", newJString(Duration))
  add(query_595371, "Version", newJString(Version))
  result = call_595370.call(nil, query_595371, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_595349(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_595350, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_595351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595412 = ref object of OpenApiRestCall_593421
proc url_PostListTagsForResource_595414(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595415 = query.getOrDefault("Action")
  valid_595415 = validateParameter(valid_595415, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595415 != nil:
    section.add "Action", valid_595415
  var valid_595416 = query.getOrDefault("Version")
  valid_595416 = validateParameter(valid_595416, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595416 != nil:
    section.add "Version", valid_595416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595417 = header.getOrDefault("X-Amz-Date")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "X-Amz-Date", valid_595417
  var valid_595418 = header.getOrDefault("X-Amz-Security-Token")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "X-Amz-Security-Token", valid_595418
  var valid_595419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595419 = validateParameter(valid_595419, JString, required = false,
                                 default = nil)
  if valid_595419 != nil:
    section.add "X-Amz-Content-Sha256", valid_595419
  var valid_595420 = header.getOrDefault("X-Amz-Algorithm")
  valid_595420 = validateParameter(valid_595420, JString, required = false,
                                 default = nil)
  if valid_595420 != nil:
    section.add "X-Amz-Algorithm", valid_595420
  var valid_595421 = header.getOrDefault("X-Amz-Signature")
  valid_595421 = validateParameter(valid_595421, JString, required = false,
                                 default = nil)
  if valid_595421 != nil:
    section.add "X-Amz-Signature", valid_595421
  var valid_595422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595422 = validateParameter(valid_595422, JString, required = false,
                                 default = nil)
  if valid_595422 != nil:
    section.add "X-Amz-SignedHeaders", valid_595422
  var valid_595423 = header.getOrDefault("X-Amz-Credential")
  valid_595423 = validateParameter(valid_595423, JString, required = false,
                                 default = nil)
  if valid_595423 != nil:
    section.add "X-Amz-Credential", valid_595423
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_595424 = formData.getOrDefault("ResourceName")
  valid_595424 = validateParameter(valid_595424, JString, required = true,
                                 default = nil)
  if valid_595424 != nil:
    section.add "ResourceName", valid_595424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595425: Call_PostListTagsForResource_595412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595425.validator(path, query, header, formData, body)
  let scheme = call_595425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595425.url(scheme.get, call_595425.host, call_595425.base,
                         call_595425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595425, url, valid)

proc call*(call_595426: Call_PostListTagsForResource_595412; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595427 = newJObject()
  var formData_595428 = newJObject()
  add(query_595427, "Action", newJString(Action))
  add(formData_595428, "ResourceName", newJString(ResourceName))
  add(query_595427, "Version", newJString(Version))
  result = call_595426.call(nil, query_595427, nil, formData_595428, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595412(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595413, base: "/",
    url: url_PostListTagsForResource_595414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595396 = ref object of OpenApiRestCall_593421
proc url_GetListTagsForResource_595398(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595397(path: JsonNode; query: JsonNode;
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
  var valid_595399 = query.getOrDefault("ResourceName")
  valid_595399 = validateParameter(valid_595399, JString, required = true,
                                 default = nil)
  if valid_595399 != nil:
    section.add "ResourceName", valid_595399
  var valid_595400 = query.getOrDefault("Action")
  valid_595400 = validateParameter(valid_595400, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595400 != nil:
    section.add "Action", valid_595400
  var valid_595401 = query.getOrDefault("Version")
  valid_595401 = validateParameter(valid_595401, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595401 != nil:
    section.add "Version", valid_595401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595402 = header.getOrDefault("X-Amz-Date")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "X-Amz-Date", valid_595402
  var valid_595403 = header.getOrDefault("X-Amz-Security-Token")
  valid_595403 = validateParameter(valid_595403, JString, required = false,
                                 default = nil)
  if valid_595403 != nil:
    section.add "X-Amz-Security-Token", valid_595403
  var valid_595404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595404 = validateParameter(valid_595404, JString, required = false,
                                 default = nil)
  if valid_595404 != nil:
    section.add "X-Amz-Content-Sha256", valid_595404
  var valid_595405 = header.getOrDefault("X-Amz-Algorithm")
  valid_595405 = validateParameter(valid_595405, JString, required = false,
                                 default = nil)
  if valid_595405 != nil:
    section.add "X-Amz-Algorithm", valid_595405
  var valid_595406 = header.getOrDefault("X-Amz-Signature")
  valid_595406 = validateParameter(valid_595406, JString, required = false,
                                 default = nil)
  if valid_595406 != nil:
    section.add "X-Amz-Signature", valid_595406
  var valid_595407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595407 = validateParameter(valid_595407, JString, required = false,
                                 default = nil)
  if valid_595407 != nil:
    section.add "X-Amz-SignedHeaders", valid_595407
  var valid_595408 = header.getOrDefault("X-Amz-Credential")
  valid_595408 = validateParameter(valid_595408, JString, required = false,
                                 default = nil)
  if valid_595408 != nil:
    section.add "X-Amz-Credential", valid_595408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595409: Call_GetListTagsForResource_595396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595409.validator(path, query, header, formData, body)
  let scheme = call_595409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595409.url(scheme.get, call_595409.host, call_595409.base,
                         call_595409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595409, url, valid)

proc call*(call_595410: Call_GetListTagsForResource_595396; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595411 = newJObject()
  add(query_595411, "ResourceName", newJString(ResourceName))
  add(query_595411, "Action", newJString(Action))
  add(query_595411, "Version", newJString(Version))
  result = call_595410.call(nil, query_595411, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595396(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595397, base: "/",
    url: url_GetListTagsForResource_595398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_595462 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBInstance_595464(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_595463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595465 = query.getOrDefault("Action")
  valid_595465 = validateParameter(valid_595465, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595465 != nil:
    section.add "Action", valid_595465
  var valid_595466 = query.getOrDefault("Version")
  valid_595466 = validateParameter(valid_595466, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595466 != nil:
    section.add "Version", valid_595466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595467 = header.getOrDefault("X-Amz-Date")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Date", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Security-Token")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Security-Token", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Content-Sha256", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-Algorithm")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-Algorithm", valid_595470
  var valid_595471 = header.getOrDefault("X-Amz-Signature")
  valid_595471 = validateParameter(valid_595471, JString, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "X-Amz-Signature", valid_595471
  var valid_595472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "X-Amz-SignedHeaders", valid_595472
  var valid_595473 = header.getOrDefault("X-Amz-Credential")
  valid_595473 = validateParameter(valid_595473, JString, required = false,
                                 default = nil)
  if valid_595473 != nil:
    section.add "X-Amz-Credential", valid_595473
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
  var valid_595474 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "PreferredMaintenanceWindow", valid_595474
  var valid_595475 = formData.getOrDefault("DBSecurityGroups")
  valid_595475 = validateParameter(valid_595475, JArray, required = false,
                                 default = nil)
  if valid_595475 != nil:
    section.add "DBSecurityGroups", valid_595475
  var valid_595476 = formData.getOrDefault("ApplyImmediately")
  valid_595476 = validateParameter(valid_595476, JBool, required = false, default = nil)
  if valid_595476 != nil:
    section.add "ApplyImmediately", valid_595476
  var valid_595477 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595477 = validateParameter(valid_595477, JArray, required = false,
                                 default = nil)
  if valid_595477 != nil:
    section.add "VpcSecurityGroupIds", valid_595477
  var valid_595478 = formData.getOrDefault("Iops")
  valid_595478 = validateParameter(valid_595478, JInt, required = false, default = nil)
  if valid_595478 != nil:
    section.add "Iops", valid_595478
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595479 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595479 = validateParameter(valid_595479, JString, required = true,
                                 default = nil)
  if valid_595479 != nil:
    section.add "DBInstanceIdentifier", valid_595479
  var valid_595480 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595480 = validateParameter(valid_595480, JInt, required = false, default = nil)
  if valid_595480 != nil:
    section.add "BackupRetentionPeriod", valid_595480
  var valid_595481 = formData.getOrDefault("DBParameterGroupName")
  valid_595481 = validateParameter(valid_595481, JString, required = false,
                                 default = nil)
  if valid_595481 != nil:
    section.add "DBParameterGroupName", valid_595481
  var valid_595482 = formData.getOrDefault("OptionGroupName")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "OptionGroupName", valid_595482
  var valid_595483 = formData.getOrDefault("MasterUserPassword")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "MasterUserPassword", valid_595483
  var valid_595484 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "NewDBInstanceIdentifier", valid_595484
  var valid_595485 = formData.getOrDefault("MultiAZ")
  valid_595485 = validateParameter(valid_595485, JBool, required = false, default = nil)
  if valid_595485 != nil:
    section.add "MultiAZ", valid_595485
  var valid_595486 = formData.getOrDefault("AllocatedStorage")
  valid_595486 = validateParameter(valid_595486, JInt, required = false, default = nil)
  if valid_595486 != nil:
    section.add "AllocatedStorage", valid_595486
  var valid_595487 = formData.getOrDefault("DBInstanceClass")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "DBInstanceClass", valid_595487
  var valid_595488 = formData.getOrDefault("PreferredBackupWindow")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "PreferredBackupWindow", valid_595488
  var valid_595489 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595489 = validateParameter(valid_595489, JBool, required = false, default = nil)
  if valid_595489 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595489
  var valid_595490 = formData.getOrDefault("EngineVersion")
  valid_595490 = validateParameter(valid_595490, JString, required = false,
                                 default = nil)
  if valid_595490 != nil:
    section.add "EngineVersion", valid_595490
  var valid_595491 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_595491 = validateParameter(valid_595491, JBool, required = false, default = nil)
  if valid_595491 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595492: Call_PostModifyDBInstance_595462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595492.validator(path, query, header, formData, body)
  let scheme = call_595492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595492.url(scheme.get, call_595492.host, call_595492.base,
                         call_595492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595492, url, valid)

proc call*(call_595493: Call_PostModifyDBInstance_595462;
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
  var query_595494 = newJObject()
  var formData_595495 = newJObject()
  add(formData_595495, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_595495.add "DBSecurityGroups", DBSecurityGroups
  add(formData_595495, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_595495.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595495, "Iops", newJInt(Iops))
  add(formData_595495, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595495, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_595495, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595495, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595495, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_595495, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_595495, "MultiAZ", newJBool(MultiAZ))
  add(query_595494, "Action", newJString(Action))
  add(formData_595495, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_595495, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595495, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_595495, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595495, "EngineVersion", newJString(EngineVersion))
  add(query_595494, "Version", newJString(Version))
  add(formData_595495, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_595493.call(nil, query_595494, nil, formData_595495, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_595462(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_595463, base: "/",
    url: url_PostModifyDBInstance_595464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_595429 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBInstance_595431(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_595430(path: JsonNode; query: JsonNode;
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
  var valid_595432 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "PreferredMaintenanceWindow", valid_595432
  var valid_595433 = query.getOrDefault("AllocatedStorage")
  valid_595433 = validateParameter(valid_595433, JInt, required = false, default = nil)
  if valid_595433 != nil:
    section.add "AllocatedStorage", valid_595433
  var valid_595434 = query.getOrDefault("OptionGroupName")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "OptionGroupName", valid_595434
  var valid_595435 = query.getOrDefault("DBSecurityGroups")
  valid_595435 = validateParameter(valid_595435, JArray, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "DBSecurityGroups", valid_595435
  var valid_595436 = query.getOrDefault("MasterUserPassword")
  valid_595436 = validateParameter(valid_595436, JString, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "MasterUserPassword", valid_595436
  var valid_595437 = query.getOrDefault("Iops")
  valid_595437 = validateParameter(valid_595437, JInt, required = false, default = nil)
  if valid_595437 != nil:
    section.add "Iops", valid_595437
  var valid_595438 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595438 = validateParameter(valid_595438, JArray, required = false,
                                 default = nil)
  if valid_595438 != nil:
    section.add "VpcSecurityGroupIds", valid_595438
  var valid_595439 = query.getOrDefault("MultiAZ")
  valid_595439 = validateParameter(valid_595439, JBool, required = false, default = nil)
  if valid_595439 != nil:
    section.add "MultiAZ", valid_595439
  var valid_595440 = query.getOrDefault("BackupRetentionPeriod")
  valid_595440 = validateParameter(valid_595440, JInt, required = false, default = nil)
  if valid_595440 != nil:
    section.add "BackupRetentionPeriod", valid_595440
  var valid_595441 = query.getOrDefault("DBParameterGroupName")
  valid_595441 = validateParameter(valid_595441, JString, required = false,
                                 default = nil)
  if valid_595441 != nil:
    section.add "DBParameterGroupName", valid_595441
  var valid_595442 = query.getOrDefault("DBInstanceClass")
  valid_595442 = validateParameter(valid_595442, JString, required = false,
                                 default = nil)
  if valid_595442 != nil:
    section.add "DBInstanceClass", valid_595442
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595443 = query.getOrDefault("Action")
  valid_595443 = validateParameter(valid_595443, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595443 != nil:
    section.add "Action", valid_595443
  var valid_595444 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_595444 = validateParameter(valid_595444, JBool, required = false, default = nil)
  if valid_595444 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595444
  var valid_595445 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "NewDBInstanceIdentifier", valid_595445
  var valid_595446 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595446 = validateParameter(valid_595446, JBool, required = false, default = nil)
  if valid_595446 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595446
  var valid_595447 = query.getOrDefault("EngineVersion")
  valid_595447 = validateParameter(valid_595447, JString, required = false,
                                 default = nil)
  if valid_595447 != nil:
    section.add "EngineVersion", valid_595447
  var valid_595448 = query.getOrDefault("PreferredBackupWindow")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "PreferredBackupWindow", valid_595448
  var valid_595449 = query.getOrDefault("Version")
  valid_595449 = validateParameter(valid_595449, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595449 != nil:
    section.add "Version", valid_595449
  var valid_595450 = query.getOrDefault("DBInstanceIdentifier")
  valid_595450 = validateParameter(valid_595450, JString, required = true,
                                 default = nil)
  if valid_595450 != nil:
    section.add "DBInstanceIdentifier", valid_595450
  var valid_595451 = query.getOrDefault("ApplyImmediately")
  valid_595451 = validateParameter(valid_595451, JBool, required = false, default = nil)
  if valid_595451 != nil:
    section.add "ApplyImmediately", valid_595451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595452 = header.getOrDefault("X-Amz-Date")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Date", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-Security-Token")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-Security-Token", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Content-Sha256", valid_595454
  var valid_595455 = header.getOrDefault("X-Amz-Algorithm")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "X-Amz-Algorithm", valid_595455
  var valid_595456 = header.getOrDefault("X-Amz-Signature")
  valid_595456 = validateParameter(valid_595456, JString, required = false,
                                 default = nil)
  if valid_595456 != nil:
    section.add "X-Amz-Signature", valid_595456
  var valid_595457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595457 = validateParameter(valid_595457, JString, required = false,
                                 default = nil)
  if valid_595457 != nil:
    section.add "X-Amz-SignedHeaders", valid_595457
  var valid_595458 = header.getOrDefault("X-Amz-Credential")
  valid_595458 = validateParameter(valid_595458, JString, required = false,
                                 default = nil)
  if valid_595458 != nil:
    section.add "X-Amz-Credential", valid_595458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595459: Call_GetModifyDBInstance_595429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595459.validator(path, query, header, formData, body)
  let scheme = call_595459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595459.url(scheme.get, call_595459.host, call_595459.base,
                         call_595459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595459, url, valid)

proc call*(call_595460: Call_GetModifyDBInstance_595429;
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
  var query_595461 = newJObject()
  add(query_595461, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595461, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_595461, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_595461.add "DBSecurityGroups", DBSecurityGroups
  add(query_595461, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_595461, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_595461.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_595461, "MultiAZ", newJBool(MultiAZ))
  add(query_595461, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595461, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595461, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595461, "Action", newJString(Action))
  add(query_595461, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_595461, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_595461, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595461, "EngineVersion", newJString(EngineVersion))
  add(query_595461, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595461, "Version", newJString(Version))
  add(query_595461, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595461, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595460.call(nil, query_595461, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_595429(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_595430, base: "/",
    url: url_GetModifyDBInstance_595431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_595513 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBParameterGroup_595515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_595514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595516 = query.getOrDefault("Action")
  valid_595516 = validateParameter(valid_595516, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595516 != nil:
    section.add "Action", valid_595516
  var valid_595517 = query.getOrDefault("Version")
  valid_595517 = validateParameter(valid_595517, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595517 != nil:
    section.add "Version", valid_595517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595518 = header.getOrDefault("X-Amz-Date")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "X-Amz-Date", valid_595518
  var valid_595519 = header.getOrDefault("X-Amz-Security-Token")
  valid_595519 = validateParameter(valid_595519, JString, required = false,
                                 default = nil)
  if valid_595519 != nil:
    section.add "X-Amz-Security-Token", valid_595519
  var valid_595520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595520 = validateParameter(valid_595520, JString, required = false,
                                 default = nil)
  if valid_595520 != nil:
    section.add "X-Amz-Content-Sha256", valid_595520
  var valid_595521 = header.getOrDefault("X-Amz-Algorithm")
  valid_595521 = validateParameter(valid_595521, JString, required = false,
                                 default = nil)
  if valid_595521 != nil:
    section.add "X-Amz-Algorithm", valid_595521
  var valid_595522 = header.getOrDefault("X-Amz-Signature")
  valid_595522 = validateParameter(valid_595522, JString, required = false,
                                 default = nil)
  if valid_595522 != nil:
    section.add "X-Amz-Signature", valid_595522
  var valid_595523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "X-Amz-SignedHeaders", valid_595523
  var valid_595524 = header.getOrDefault("X-Amz-Credential")
  valid_595524 = validateParameter(valid_595524, JString, required = false,
                                 default = nil)
  if valid_595524 != nil:
    section.add "X-Amz-Credential", valid_595524
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595525 = formData.getOrDefault("DBParameterGroupName")
  valid_595525 = validateParameter(valid_595525, JString, required = true,
                                 default = nil)
  if valid_595525 != nil:
    section.add "DBParameterGroupName", valid_595525
  var valid_595526 = formData.getOrDefault("Parameters")
  valid_595526 = validateParameter(valid_595526, JArray, required = true, default = nil)
  if valid_595526 != nil:
    section.add "Parameters", valid_595526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595527: Call_PostModifyDBParameterGroup_595513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595527.validator(path, query, header, formData, body)
  let scheme = call_595527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595527.url(scheme.get, call_595527.host, call_595527.base,
                         call_595527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595527, url, valid)

proc call*(call_595528: Call_PostModifyDBParameterGroup_595513;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595529 = newJObject()
  var formData_595530 = newJObject()
  add(formData_595530, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595530.add "Parameters", Parameters
  add(query_595529, "Action", newJString(Action))
  add(query_595529, "Version", newJString(Version))
  result = call_595528.call(nil, query_595529, nil, formData_595530, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_595513(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_595514, base: "/",
    url: url_PostModifyDBParameterGroup_595515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_595496 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBParameterGroup_595498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_595497(path: JsonNode; query: JsonNode;
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
  var valid_595499 = query.getOrDefault("DBParameterGroupName")
  valid_595499 = validateParameter(valid_595499, JString, required = true,
                                 default = nil)
  if valid_595499 != nil:
    section.add "DBParameterGroupName", valid_595499
  var valid_595500 = query.getOrDefault("Parameters")
  valid_595500 = validateParameter(valid_595500, JArray, required = true, default = nil)
  if valid_595500 != nil:
    section.add "Parameters", valid_595500
  var valid_595501 = query.getOrDefault("Action")
  valid_595501 = validateParameter(valid_595501, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595501 != nil:
    section.add "Action", valid_595501
  var valid_595502 = query.getOrDefault("Version")
  valid_595502 = validateParameter(valid_595502, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595502 != nil:
    section.add "Version", valid_595502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595503 = header.getOrDefault("X-Amz-Date")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Date", valid_595503
  var valid_595504 = header.getOrDefault("X-Amz-Security-Token")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "X-Amz-Security-Token", valid_595504
  var valid_595505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595505 = validateParameter(valid_595505, JString, required = false,
                                 default = nil)
  if valid_595505 != nil:
    section.add "X-Amz-Content-Sha256", valid_595505
  var valid_595506 = header.getOrDefault("X-Amz-Algorithm")
  valid_595506 = validateParameter(valid_595506, JString, required = false,
                                 default = nil)
  if valid_595506 != nil:
    section.add "X-Amz-Algorithm", valid_595506
  var valid_595507 = header.getOrDefault("X-Amz-Signature")
  valid_595507 = validateParameter(valid_595507, JString, required = false,
                                 default = nil)
  if valid_595507 != nil:
    section.add "X-Amz-Signature", valid_595507
  var valid_595508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595508 = validateParameter(valid_595508, JString, required = false,
                                 default = nil)
  if valid_595508 != nil:
    section.add "X-Amz-SignedHeaders", valid_595508
  var valid_595509 = header.getOrDefault("X-Amz-Credential")
  valid_595509 = validateParameter(valid_595509, JString, required = false,
                                 default = nil)
  if valid_595509 != nil:
    section.add "X-Amz-Credential", valid_595509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595510: Call_GetModifyDBParameterGroup_595496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595510.validator(path, query, header, formData, body)
  let scheme = call_595510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595510.url(scheme.get, call_595510.host, call_595510.base,
                         call_595510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595510, url, valid)

proc call*(call_595511: Call_GetModifyDBParameterGroup_595496;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595512 = newJObject()
  add(query_595512, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595512.add "Parameters", Parameters
  add(query_595512, "Action", newJString(Action))
  add(query_595512, "Version", newJString(Version))
  result = call_595511.call(nil, query_595512, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_595496(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_595497, base: "/",
    url: url_GetModifyDBParameterGroup_595498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_595549 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBSubnetGroup_595551(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_595550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595552 = query.getOrDefault("Action")
  valid_595552 = validateParameter(valid_595552, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595552 != nil:
    section.add "Action", valid_595552
  var valid_595553 = query.getOrDefault("Version")
  valid_595553 = validateParameter(valid_595553, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595553 != nil:
    section.add "Version", valid_595553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595554 = header.getOrDefault("X-Amz-Date")
  valid_595554 = validateParameter(valid_595554, JString, required = false,
                                 default = nil)
  if valid_595554 != nil:
    section.add "X-Amz-Date", valid_595554
  var valid_595555 = header.getOrDefault("X-Amz-Security-Token")
  valid_595555 = validateParameter(valid_595555, JString, required = false,
                                 default = nil)
  if valid_595555 != nil:
    section.add "X-Amz-Security-Token", valid_595555
  var valid_595556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595556 = validateParameter(valid_595556, JString, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "X-Amz-Content-Sha256", valid_595556
  var valid_595557 = header.getOrDefault("X-Amz-Algorithm")
  valid_595557 = validateParameter(valid_595557, JString, required = false,
                                 default = nil)
  if valid_595557 != nil:
    section.add "X-Amz-Algorithm", valid_595557
  var valid_595558 = header.getOrDefault("X-Amz-Signature")
  valid_595558 = validateParameter(valid_595558, JString, required = false,
                                 default = nil)
  if valid_595558 != nil:
    section.add "X-Amz-Signature", valid_595558
  var valid_595559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-SignedHeaders", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Credential")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Credential", valid_595560
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_595561 = formData.getOrDefault("DBSubnetGroupName")
  valid_595561 = validateParameter(valid_595561, JString, required = true,
                                 default = nil)
  if valid_595561 != nil:
    section.add "DBSubnetGroupName", valid_595561
  var valid_595562 = formData.getOrDefault("SubnetIds")
  valid_595562 = validateParameter(valid_595562, JArray, required = true, default = nil)
  if valid_595562 != nil:
    section.add "SubnetIds", valid_595562
  var valid_595563 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "DBSubnetGroupDescription", valid_595563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595564: Call_PostModifyDBSubnetGroup_595549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595564.validator(path, query, header, formData, body)
  let scheme = call_595564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595564.url(scheme.get, call_595564.host, call_595564.base,
                         call_595564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595564, url, valid)

proc call*(call_595565: Call_PostModifyDBSubnetGroup_595549;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595566 = newJObject()
  var formData_595567 = newJObject()
  add(formData_595567, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_595567.add "SubnetIds", SubnetIds
  add(query_595566, "Action", newJString(Action))
  add(formData_595567, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595566, "Version", newJString(Version))
  result = call_595565.call(nil, query_595566, nil, formData_595567, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_595549(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_595550, base: "/",
    url: url_PostModifyDBSubnetGroup_595551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_595531 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBSubnetGroup_595533(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_595532(path: JsonNode; query: JsonNode;
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
  var valid_595534 = query.getOrDefault("Action")
  valid_595534 = validateParameter(valid_595534, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595534 != nil:
    section.add "Action", valid_595534
  var valid_595535 = query.getOrDefault("DBSubnetGroupName")
  valid_595535 = validateParameter(valid_595535, JString, required = true,
                                 default = nil)
  if valid_595535 != nil:
    section.add "DBSubnetGroupName", valid_595535
  var valid_595536 = query.getOrDefault("SubnetIds")
  valid_595536 = validateParameter(valid_595536, JArray, required = true, default = nil)
  if valid_595536 != nil:
    section.add "SubnetIds", valid_595536
  var valid_595537 = query.getOrDefault("DBSubnetGroupDescription")
  valid_595537 = validateParameter(valid_595537, JString, required = false,
                                 default = nil)
  if valid_595537 != nil:
    section.add "DBSubnetGroupDescription", valid_595537
  var valid_595538 = query.getOrDefault("Version")
  valid_595538 = validateParameter(valid_595538, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595538 != nil:
    section.add "Version", valid_595538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595539 = header.getOrDefault("X-Amz-Date")
  valid_595539 = validateParameter(valid_595539, JString, required = false,
                                 default = nil)
  if valid_595539 != nil:
    section.add "X-Amz-Date", valid_595539
  var valid_595540 = header.getOrDefault("X-Amz-Security-Token")
  valid_595540 = validateParameter(valid_595540, JString, required = false,
                                 default = nil)
  if valid_595540 != nil:
    section.add "X-Amz-Security-Token", valid_595540
  var valid_595541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "X-Amz-Content-Sha256", valid_595541
  var valid_595542 = header.getOrDefault("X-Amz-Algorithm")
  valid_595542 = validateParameter(valid_595542, JString, required = false,
                                 default = nil)
  if valid_595542 != nil:
    section.add "X-Amz-Algorithm", valid_595542
  var valid_595543 = header.getOrDefault("X-Amz-Signature")
  valid_595543 = validateParameter(valid_595543, JString, required = false,
                                 default = nil)
  if valid_595543 != nil:
    section.add "X-Amz-Signature", valid_595543
  var valid_595544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-SignedHeaders", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Credential")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Credential", valid_595545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595546: Call_GetModifyDBSubnetGroup_595531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595546.validator(path, query, header, formData, body)
  let scheme = call_595546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595546.url(scheme.get, call_595546.host, call_595546.base,
                         call_595546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595546, url, valid)

proc call*(call_595547: Call_GetModifyDBSubnetGroup_595531;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595548 = newJObject()
  add(query_595548, "Action", newJString(Action))
  add(query_595548, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_595548.add "SubnetIds", SubnetIds
  add(query_595548, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595548, "Version", newJString(Version))
  result = call_595547.call(nil, query_595548, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_595531(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_595532, base: "/",
    url: url_GetModifyDBSubnetGroup_595533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_595588 = ref object of OpenApiRestCall_593421
proc url_PostModifyEventSubscription_595590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_595589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595591 = query.getOrDefault("Action")
  valid_595591 = validateParameter(valid_595591, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595591 != nil:
    section.add "Action", valid_595591
  var valid_595592 = query.getOrDefault("Version")
  valid_595592 = validateParameter(valid_595592, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595592 != nil:
    section.add "Version", valid_595592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595593 = header.getOrDefault("X-Amz-Date")
  valid_595593 = validateParameter(valid_595593, JString, required = false,
                                 default = nil)
  if valid_595593 != nil:
    section.add "X-Amz-Date", valid_595593
  var valid_595594 = header.getOrDefault("X-Amz-Security-Token")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "X-Amz-Security-Token", valid_595594
  var valid_595595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595595 = validateParameter(valid_595595, JString, required = false,
                                 default = nil)
  if valid_595595 != nil:
    section.add "X-Amz-Content-Sha256", valid_595595
  var valid_595596 = header.getOrDefault("X-Amz-Algorithm")
  valid_595596 = validateParameter(valid_595596, JString, required = false,
                                 default = nil)
  if valid_595596 != nil:
    section.add "X-Amz-Algorithm", valid_595596
  var valid_595597 = header.getOrDefault("X-Amz-Signature")
  valid_595597 = validateParameter(valid_595597, JString, required = false,
                                 default = nil)
  if valid_595597 != nil:
    section.add "X-Amz-Signature", valid_595597
  var valid_595598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595598 = validateParameter(valid_595598, JString, required = false,
                                 default = nil)
  if valid_595598 != nil:
    section.add "X-Amz-SignedHeaders", valid_595598
  var valid_595599 = header.getOrDefault("X-Amz-Credential")
  valid_595599 = validateParameter(valid_595599, JString, required = false,
                                 default = nil)
  if valid_595599 != nil:
    section.add "X-Amz-Credential", valid_595599
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_595600 = formData.getOrDefault("Enabled")
  valid_595600 = validateParameter(valid_595600, JBool, required = false, default = nil)
  if valid_595600 != nil:
    section.add "Enabled", valid_595600
  var valid_595601 = formData.getOrDefault("EventCategories")
  valid_595601 = validateParameter(valid_595601, JArray, required = false,
                                 default = nil)
  if valid_595601 != nil:
    section.add "EventCategories", valid_595601
  var valid_595602 = formData.getOrDefault("SnsTopicArn")
  valid_595602 = validateParameter(valid_595602, JString, required = false,
                                 default = nil)
  if valid_595602 != nil:
    section.add "SnsTopicArn", valid_595602
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_595603 = formData.getOrDefault("SubscriptionName")
  valid_595603 = validateParameter(valid_595603, JString, required = true,
                                 default = nil)
  if valid_595603 != nil:
    section.add "SubscriptionName", valid_595603
  var valid_595604 = formData.getOrDefault("SourceType")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "SourceType", valid_595604
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595605: Call_PostModifyEventSubscription_595588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595605.validator(path, query, header, formData, body)
  let scheme = call_595605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595605.url(scheme.get, call_595605.host, call_595605.base,
                         call_595605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595605, url, valid)

proc call*(call_595606: Call_PostModifyEventSubscription_595588;
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
  var query_595607 = newJObject()
  var formData_595608 = newJObject()
  add(formData_595608, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_595608.add "EventCategories", EventCategories
  add(formData_595608, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_595608, "SubscriptionName", newJString(SubscriptionName))
  add(query_595607, "Action", newJString(Action))
  add(query_595607, "Version", newJString(Version))
  add(formData_595608, "SourceType", newJString(SourceType))
  result = call_595606.call(nil, query_595607, nil, formData_595608, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_595588(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_595589, base: "/",
    url: url_PostModifyEventSubscription_595590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_595568 = ref object of OpenApiRestCall_593421
proc url_GetModifyEventSubscription_595570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_595569(path: JsonNode; query: JsonNode;
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
  var valid_595571 = query.getOrDefault("SourceType")
  valid_595571 = validateParameter(valid_595571, JString, required = false,
                                 default = nil)
  if valid_595571 != nil:
    section.add "SourceType", valid_595571
  var valid_595572 = query.getOrDefault("Enabled")
  valid_595572 = validateParameter(valid_595572, JBool, required = false, default = nil)
  if valid_595572 != nil:
    section.add "Enabled", valid_595572
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595573 = query.getOrDefault("Action")
  valid_595573 = validateParameter(valid_595573, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595573 != nil:
    section.add "Action", valid_595573
  var valid_595574 = query.getOrDefault("SnsTopicArn")
  valid_595574 = validateParameter(valid_595574, JString, required = false,
                                 default = nil)
  if valid_595574 != nil:
    section.add "SnsTopicArn", valid_595574
  var valid_595575 = query.getOrDefault("EventCategories")
  valid_595575 = validateParameter(valid_595575, JArray, required = false,
                                 default = nil)
  if valid_595575 != nil:
    section.add "EventCategories", valid_595575
  var valid_595576 = query.getOrDefault("SubscriptionName")
  valid_595576 = validateParameter(valid_595576, JString, required = true,
                                 default = nil)
  if valid_595576 != nil:
    section.add "SubscriptionName", valid_595576
  var valid_595577 = query.getOrDefault("Version")
  valid_595577 = validateParameter(valid_595577, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595577 != nil:
    section.add "Version", valid_595577
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595578 = header.getOrDefault("X-Amz-Date")
  valid_595578 = validateParameter(valid_595578, JString, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "X-Amz-Date", valid_595578
  var valid_595579 = header.getOrDefault("X-Amz-Security-Token")
  valid_595579 = validateParameter(valid_595579, JString, required = false,
                                 default = nil)
  if valid_595579 != nil:
    section.add "X-Amz-Security-Token", valid_595579
  var valid_595580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595580 = validateParameter(valid_595580, JString, required = false,
                                 default = nil)
  if valid_595580 != nil:
    section.add "X-Amz-Content-Sha256", valid_595580
  var valid_595581 = header.getOrDefault("X-Amz-Algorithm")
  valid_595581 = validateParameter(valid_595581, JString, required = false,
                                 default = nil)
  if valid_595581 != nil:
    section.add "X-Amz-Algorithm", valid_595581
  var valid_595582 = header.getOrDefault("X-Amz-Signature")
  valid_595582 = validateParameter(valid_595582, JString, required = false,
                                 default = nil)
  if valid_595582 != nil:
    section.add "X-Amz-Signature", valid_595582
  var valid_595583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595583 = validateParameter(valid_595583, JString, required = false,
                                 default = nil)
  if valid_595583 != nil:
    section.add "X-Amz-SignedHeaders", valid_595583
  var valid_595584 = header.getOrDefault("X-Amz-Credential")
  valid_595584 = validateParameter(valid_595584, JString, required = false,
                                 default = nil)
  if valid_595584 != nil:
    section.add "X-Amz-Credential", valid_595584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595585: Call_GetModifyEventSubscription_595568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595585.validator(path, query, header, formData, body)
  let scheme = call_595585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595585.url(scheme.get, call_595585.host, call_595585.base,
                         call_595585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595585, url, valid)

proc call*(call_595586: Call_GetModifyEventSubscription_595568;
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
  var query_595587 = newJObject()
  add(query_595587, "SourceType", newJString(SourceType))
  add(query_595587, "Enabled", newJBool(Enabled))
  add(query_595587, "Action", newJString(Action))
  add(query_595587, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_595587.add "EventCategories", EventCategories
  add(query_595587, "SubscriptionName", newJString(SubscriptionName))
  add(query_595587, "Version", newJString(Version))
  result = call_595586.call(nil, query_595587, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_595568(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_595569, base: "/",
    url: url_GetModifyEventSubscription_595570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_595628 = ref object of OpenApiRestCall_593421
proc url_PostModifyOptionGroup_595630(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_595629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595631 = query.getOrDefault("Action")
  valid_595631 = validateParameter(valid_595631, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595631 != nil:
    section.add "Action", valid_595631
  var valid_595632 = query.getOrDefault("Version")
  valid_595632 = validateParameter(valid_595632, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595632 != nil:
    section.add "Version", valid_595632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595633 = header.getOrDefault("X-Amz-Date")
  valid_595633 = validateParameter(valid_595633, JString, required = false,
                                 default = nil)
  if valid_595633 != nil:
    section.add "X-Amz-Date", valid_595633
  var valid_595634 = header.getOrDefault("X-Amz-Security-Token")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Security-Token", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-Content-Sha256", valid_595635
  var valid_595636 = header.getOrDefault("X-Amz-Algorithm")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Algorithm", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-Signature")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-Signature", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-SignedHeaders", valid_595638
  var valid_595639 = header.getOrDefault("X-Amz-Credential")
  valid_595639 = validateParameter(valid_595639, JString, required = false,
                                 default = nil)
  if valid_595639 != nil:
    section.add "X-Amz-Credential", valid_595639
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_595640 = formData.getOrDefault("OptionsToRemove")
  valid_595640 = validateParameter(valid_595640, JArray, required = false,
                                 default = nil)
  if valid_595640 != nil:
    section.add "OptionsToRemove", valid_595640
  var valid_595641 = formData.getOrDefault("ApplyImmediately")
  valid_595641 = validateParameter(valid_595641, JBool, required = false, default = nil)
  if valid_595641 != nil:
    section.add "ApplyImmediately", valid_595641
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_595642 = formData.getOrDefault("OptionGroupName")
  valid_595642 = validateParameter(valid_595642, JString, required = true,
                                 default = nil)
  if valid_595642 != nil:
    section.add "OptionGroupName", valid_595642
  var valid_595643 = formData.getOrDefault("OptionsToInclude")
  valid_595643 = validateParameter(valid_595643, JArray, required = false,
                                 default = nil)
  if valid_595643 != nil:
    section.add "OptionsToInclude", valid_595643
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595644: Call_PostModifyOptionGroup_595628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595644.validator(path, query, header, formData, body)
  let scheme = call_595644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595644.url(scheme.get, call_595644.host, call_595644.base,
                         call_595644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595644, url, valid)

proc call*(call_595645: Call_PostModifyOptionGroup_595628; OptionGroupName: string;
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
  var query_595646 = newJObject()
  var formData_595647 = newJObject()
  if OptionsToRemove != nil:
    formData_595647.add "OptionsToRemove", OptionsToRemove
  add(formData_595647, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595647, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_595647.add "OptionsToInclude", OptionsToInclude
  add(query_595646, "Action", newJString(Action))
  add(query_595646, "Version", newJString(Version))
  result = call_595645.call(nil, query_595646, nil, formData_595647, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_595628(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_595629, base: "/",
    url: url_PostModifyOptionGroup_595630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_595609 = ref object of OpenApiRestCall_593421
proc url_GetModifyOptionGroup_595611(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_595610(path: JsonNode; query: JsonNode;
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
  var valid_595612 = query.getOrDefault("OptionGroupName")
  valid_595612 = validateParameter(valid_595612, JString, required = true,
                                 default = nil)
  if valid_595612 != nil:
    section.add "OptionGroupName", valid_595612
  var valid_595613 = query.getOrDefault("OptionsToRemove")
  valid_595613 = validateParameter(valid_595613, JArray, required = false,
                                 default = nil)
  if valid_595613 != nil:
    section.add "OptionsToRemove", valid_595613
  var valid_595614 = query.getOrDefault("Action")
  valid_595614 = validateParameter(valid_595614, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595614 != nil:
    section.add "Action", valid_595614
  var valid_595615 = query.getOrDefault("Version")
  valid_595615 = validateParameter(valid_595615, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595615 != nil:
    section.add "Version", valid_595615
  var valid_595616 = query.getOrDefault("ApplyImmediately")
  valid_595616 = validateParameter(valid_595616, JBool, required = false, default = nil)
  if valid_595616 != nil:
    section.add "ApplyImmediately", valid_595616
  var valid_595617 = query.getOrDefault("OptionsToInclude")
  valid_595617 = validateParameter(valid_595617, JArray, required = false,
                                 default = nil)
  if valid_595617 != nil:
    section.add "OptionsToInclude", valid_595617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595618 = header.getOrDefault("X-Amz-Date")
  valid_595618 = validateParameter(valid_595618, JString, required = false,
                                 default = nil)
  if valid_595618 != nil:
    section.add "X-Amz-Date", valid_595618
  var valid_595619 = header.getOrDefault("X-Amz-Security-Token")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "X-Amz-Security-Token", valid_595619
  var valid_595620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "X-Amz-Content-Sha256", valid_595620
  var valid_595621 = header.getOrDefault("X-Amz-Algorithm")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "X-Amz-Algorithm", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-Signature")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-Signature", valid_595622
  var valid_595623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-SignedHeaders", valid_595623
  var valid_595624 = header.getOrDefault("X-Amz-Credential")
  valid_595624 = validateParameter(valid_595624, JString, required = false,
                                 default = nil)
  if valid_595624 != nil:
    section.add "X-Amz-Credential", valid_595624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595625: Call_GetModifyOptionGroup_595609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595625.validator(path, query, header, formData, body)
  let scheme = call_595625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595625.url(scheme.get, call_595625.host, call_595625.base,
                         call_595625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595625, url, valid)

proc call*(call_595626: Call_GetModifyOptionGroup_595609; OptionGroupName: string;
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
  var query_595627 = newJObject()
  add(query_595627, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_595627.add "OptionsToRemove", OptionsToRemove
  add(query_595627, "Action", newJString(Action))
  add(query_595627, "Version", newJString(Version))
  add(query_595627, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_595627.add "OptionsToInclude", OptionsToInclude
  result = call_595626.call(nil, query_595627, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_595609(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_595610, base: "/",
    url: url_GetModifyOptionGroup_595611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_595666 = ref object of OpenApiRestCall_593421
proc url_PostPromoteReadReplica_595668(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_595667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595669 = query.getOrDefault("Action")
  valid_595669 = validateParameter(valid_595669, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595669 != nil:
    section.add "Action", valid_595669
  var valid_595670 = query.getOrDefault("Version")
  valid_595670 = validateParameter(valid_595670, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595670 != nil:
    section.add "Version", valid_595670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595671 = header.getOrDefault("X-Amz-Date")
  valid_595671 = validateParameter(valid_595671, JString, required = false,
                                 default = nil)
  if valid_595671 != nil:
    section.add "X-Amz-Date", valid_595671
  var valid_595672 = header.getOrDefault("X-Amz-Security-Token")
  valid_595672 = validateParameter(valid_595672, JString, required = false,
                                 default = nil)
  if valid_595672 != nil:
    section.add "X-Amz-Security-Token", valid_595672
  var valid_595673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595673 = validateParameter(valid_595673, JString, required = false,
                                 default = nil)
  if valid_595673 != nil:
    section.add "X-Amz-Content-Sha256", valid_595673
  var valid_595674 = header.getOrDefault("X-Amz-Algorithm")
  valid_595674 = validateParameter(valid_595674, JString, required = false,
                                 default = nil)
  if valid_595674 != nil:
    section.add "X-Amz-Algorithm", valid_595674
  var valid_595675 = header.getOrDefault("X-Amz-Signature")
  valid_595675 = validateParameter(valid_595675, JString, required = false,
                                 default = nil)
  if valid_595675 != nil:
    section.add "X-Amz-Signature", valid_595675
  var valid_595676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595676 = validateParameter(valid_595676, JString, required = false,
                                 default = nil)
  if valid_595676 != nil:
    section.add "X-Amz-SignedHeaders", valid_595676
  var valid_595677 = header.getOrDefault("X-Amz-Credential")
  valid_595677 = validateParameter(valid_595677, JString, required = false,
                                 default = nil)
  if valid_595677 != nil:
    section.add "X-Amz-Credential", valid_595677
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595678 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595678 = validateParameter(valid_595678, JString, required = true,
                                 default = nil)
  if valid_595678 != nil:
    section.add "DBInstanceIdentifier", valid_595678
  var valid_595679 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595679 = validateParameter(valid_595679, JInt, required = false, default = nil)
  if valid_595679 != nil:
    section.add "BackupRetentionPeriod", valid_595679
  var valid_595680 = formData.getOrDefault("PreferredBackupWindow")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "PreferredBackupWindow", valid_595680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595681: Call_PostPromoteReadReplica_595666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595681.validator(path, query, header, formData, body)
  let scheme = call_595681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595681.url(scheme.get, call_595681.host, call_595681.base,
                         call_595681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595681, url, valid)

proc call*(call_595682: Call_PostPromoteReadReplica_595666;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_595683 = newJObject()
  var formData_595684 = newJObject()
  add(formData_595684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595684, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595683, "Action", newJString(Action))
  add(formData_595684, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595683, "Version", newJString(Version))
  result = call_595682.call(nil, query_595683, nil, formData_595684, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_595666(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_595667, base: "/",
    url: url_PostPromoteReadReplica_595668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_595648 = ref object of OpenApiRestCall_593421
proc url_GetPromoteReadReplica_595650(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_595649(path: JsonNode; query: JsonNode;
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
  var valid_595651 = query.getOrDefault("BackupRetentionPeriod")
  valid_595651 = validateParameter(valid_595651, JInt, required = false, default = nil)
  if valid_595651 != nil:
    section.add "BackupRetentionPeriod", valid_595651
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595652 = query.getOrDefault("Action")
  valid_595652 = validateParameter(valid_595652, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595652 != nil:
    section.add "Action", valid_595652
  var valid_595653 = query.getOrDefault("PreferredBackupWindow")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "PreferredBackupWindow", valid_595653
  var valid_595654 = query.getOrDefault("Version")
  valid_595654 = validateParameter(valid_595654, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595654 != nil:
    section.add "Version", valid_595654
  var valid_595655 = query.getOrDefault("DBInstanceIdentifier")
  valid_595655 = validateParameter(valid_595655, JString, required = true,
                                 default = nil)
  if valid_595655 != nil:
    section.add "DBInstanceIdentifier", valid_595655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595656 = header.getOrDefault("X-Amz-Date")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "X-Amz-Date", valid_595656
  var valid_595657 = header.getOrDefault("X-Amz-Security-Token")
  valid_595657 = validateParameter(valid_595657, JString, required = false,
                                 default = nil)
  if valid_595657 != nil:
    section.add "X-Amz-Security-Token", valid_595657
  var valid_595658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595658 = validateParameter(valid_595658, JString, required = false,
                                 default = nil)
  if valid_595658 != nil:
    section.add "X-Amz-Content-Sha256", valid_595658
  var valid_595659 = header.getOrDefault("X-Amz-Algorithm")
  valid_595659 = validateParameter(valid_595659, JString, required = false,
                                 default = nil)
  if valid_595659 != nil:
    section.add "X-Amz-Algorithm", valid_595659
  var valid_595660 = header.getOrDefault("X-Amz-Signature")
  valid_595660 = validateParameter(valid_595660, JString, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "X-Amz-Signature", valid_595660
  var valid_595661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "X-Amz-SignedHeaders", valid_595661
  var valid_595662 = header.getOrDefault("X-Amz-Credential")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Credential", valid_595662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595663: Call_GetPromoteReadReplica_595648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595663.validator(path, query, header, formData, body)
  let scheme = call_595663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595663.url(scheme.get, call_595663.host, call_595663.base,
                         call_595663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595663, url, valid)

proc call*(call_595664: Call_GetPromoteReadReplica_595648;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595665 = newJObject()
  add(query_595665, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595665, "Action", newJString(Action))
  add(query_595665, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595665, "Version", newJString(Version))
  add(query_595665, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595664.call(nil, query_595665, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_595648(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_595649, base: "/",
    url: url_GetPromoteReadReplica_595650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_595703 = ref object of OpenApiRestCall_593421
proc url_PostPurchaseReservedDBInstancesOffering_595705(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_595704(path: JsonNode;
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
  var valid_595706 = query.getOrDefault("Action")
  valid_595706 = validateParameter(valid_595706, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595706 != nil:
    section.add "Action", valid_595706
  var valid_595707 = query.getOrDefault("Version")
  valid_595707 = validateParameter(valid_595707, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595707 != nil:
    section.add "Version", valid_595707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595708 = header.getOrDefault("X-Amz-Date")
  valid_595708 = validateParameter(valid_595708, JString, required = false,
                                 default = nil)
  if valid_595708 != nil:
    section.add "X-Amz-Date", valid_595708
  var valid_595709 = header.getOrDefault("X-Amz-Security-Token")
  valid_595709 = validateParameter(valid_595709, JString, required = false,
                                 default = nil)
  if valid_595709 != nil:
    section.add "X-Amz-Security-Token", valid_595709
  var valid_595710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595710 = validateParameter(valid_595710, JString, required = false,
                                 default = nil)
  if valid_595710 != nil:
    section.add "X-Amz-Content-Sha256", valid_595710
  var valid_595711 = header.getOrDefault("X-Amz-Algorithm")
  valid_595711 = validateParameter(valid_595711, JString, required = false,
                                 default = nil)
  if valid_595711 != nil:
    section.add "X-Amz-Algorithm", valid_595711
  var valid_595712 = header.getOrDefault("X-Amz-Signature")
  valid_595712 = validateParameter(valid_595712, JString, required = false,
                                 default = nil)
  if valid_595712 != nil:
    section.add "X-Amz-Signature", valid_595712
  var valid_595713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595713 = validateParameter(valid_595713, JString, required = false,
                                 default = nil)
  if valid_595713 != nil:
    section.add "X-Amz-SignedHeaders", valid_595713
  var valid_595714 = header.getOrDefault("X-Amz-Credential")
  valid_595714 = validateParameter(valid_595714, JString, required = false,
                                 default = nil)
  if valid_595714 != nil:
    section.add "X-Amz-Credential", valid_595714
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_595715 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595715 = validateParameter(valid_595715, JString, required = false,
                                 default = nil)
  if valid_595715 != nil:
    section.add "ReservedDBInstanceId", valid_595715
  var valid_595716 = formData.getOrDefault("DBInstanceCount")
  valid_595716 = validateParameter(valid_595716, JInt, required = false, default = nil)
  if valid_595716 != nil:
    section.add "DBInstanceCount", valid_595716
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595717 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595717 = validateParameter(valid_595717, JString, required = true,
                                 default = nil)
  if valid_595717 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595718: Call_PostPurchaseReservedDBInstancesOffering_595703;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595718.validator(path, query, header, formData, body)
  let scheme = call_595718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595718.url(scheme.get, call_595718.host, call_595718.base,
                         call_595718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595718, url, valid)

proc call*(call_595719: Call_PostPurchaseReservedDBInstancesOffering_595703;
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
  var query_595720 = newJObject()
  var formData_595721 = newJObject()
  add(formData_595721, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595721, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595720, "Action", newJString(Action))
  add(formData_595721, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595720, "Version", newJString(Version))
  result = call_595719.call(nil, query_595720, nil, formData_595721, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_595703(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_595704, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_595705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_595685 = ref object of OpenApiRestCall_593421
proc url_GetPurchaseReservedDBInstancesOffering_595687(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_595686(path: JsonNode;
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
  var valid_595688 = query.getOrDefault("DBInstanceCount")
  valid_595688 = validateParameter(valid_595688, JInt, required = false, default = nil)
  if valid_595688 != nil:
    section.add "DBInstanceCount", valid_595688
  var valid_595689 = query.getOrDefault("ReservedDBInstanceId")
  valid_595689 = validateParameter(valid_595689, JString, required = false,
                                 default = nil)
  if valid_595689 != nil:
    section.add "ReservedDBInstanceId", valid_595689
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595690 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595690 = validateParameter(valid_595690, JString, required = true,
                                 default = nil)
  if valid_595690 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595690
  var valid_595691 = query.getOrDefault("Action")
  valid_595691 = validateParameter(valid_595691, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595691 != nil:
    section.add "Action", valid_595691
  var valid_595692 = query.getOrDefault("Version")
  valid_595692 = validateParameter(valid_595692, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595692 != nil:
    section.add "Version", valid_595692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595693 = header.getOrDefault("X-Amz-Date")
  valid_595693 = validateParameter(valid_595693, JString, required = false,
                                 default = nil)
  if valid_595693 != nil:
    section.add "X-Amz-Date", valid_595693
  var valid_595694 = header.getOrDefault("X-Amz-Security-Token")
  valid_595694 = validateParameter(valid_595694, JString, required = false,
                                 default = nil)
  if valid_595694 != nil:
    section.add "X-Amz-Security-Token", valid_595694
  var valid_595695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595695 = validateParameter(valid_595695, JString, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "X-Amz-Content-Sha256", valid_595695
  var valid_595696 = header.getOrDefault("X-Amz-Algorithm")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Algorithm", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-Signature")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-Signature", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-SignedHeaders", valid_595698
  var valid_595699 = header.getOrDefault("X-Amz-Credential")
  valid_595699 = validateParameter(valid_595699, JString, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "X-Amz-Credential", valid_595699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595700: Call_GetPurchaseReservedDBInstancesOffering_595685;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595700.validator(path, query, header, formData, body)
  let scheme = call_595700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595700.url(scheme.get, call_595700.host, call_595700.base,
                         call_595700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595700, url, valid)

proc call*(call_595701: Call_GetPurchaseReservedDBInstancesOffering_595685;
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
  var query_595702 = newJObject()
  add(query_595702, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595702, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595702, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595702, "Action", newJString(Action))
  add(query_595702, "Version", newJString(Version))
  result = call_595701.call(nil, query_595702, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_595685(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_595686, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_595687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_595739 = ref object of OpenApiRestCall_593421
proc url_PostRebootDBInstance_595741(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_595740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595742 = query.getOrDefault("Action")
  valid_595742 = validateParameter(valid_595742, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595742 != nil:
    section.add "Action", valid_595742
  var valid_595743 = query.getOrDefault("Version")
  valid_595743 = validateParameter(valid_595743, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595743 != nil:
    section.add "Version", valid_595743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595744 = header.getOrDefault("X-Amz-Date")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "X-Amz-Date", valid_595744
  var valid_595745 = header.getOrDefault("X-Amz-Security-Token")
  valid_595745 = validateParameter(valid_595745, JString, required = false,
                                 default = nil)
  if valid_595745 != nil:
    section.add "X-Amz-Security-Token", valid_595745
  var valid_595746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595746 = validateParameter(valid_595746, JString, required = false,
                                 default = nil)
  if valid_595746 != nil:
    section.add "X-Amz-Content-Sha256", valid_595746
  var valid_595747 = header.getOrDefault("X-Amz-Algorithm")
  valid_595747 = validateParameter(valid_595747, JString, required = false,
                                 default = nil)
  if valid_595747 != nil:
    section.add "X-Amz-Algorithm", valid_595747
  var valid_595748 = header.getOrDefault("X-Amz-Signature")
  valid_595748 = validateParameter(valid_595748, JString, required = false,
                                 default = nil)
  if valid_595748 != nil:
    section.add "X-Amz-Signature", valid_595748
  var valid_595749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595749 = validateParameter(valid_595749, JString, required = false,
                                 default = nil)
  if valid_595749 != nil:
    section.add "X-Amz-SignedHeaders", valid_595749
  var valid_595750 = header.getOrDefault("X-Amz-Credential")
  valid_595750 = validateParameter(valid_595750, JString, required = false,
                                 default = nil)
  if valid_595750 != nil:
    section.add "X-Amz-Credential", valid_595750
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595751 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595751 = validateParameter(valid_595751, JString, required = true,
                                 default = nil)
  if valid_595751 != nil:
    section.add "DBInstanceIdentifier", valid_595751
  var valid_595752 = formData.getOrDefault("ForceFailover")
  valid_595752 = validateParameter(valid_595752, JBool, required = false, default = nil)
  if valid_595752 != nil:
    section.add "ForceFailover", valid_595752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595753: Call_PostRebootDBInstance_595739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595753.validator(path, query, header, formData, body)
  let scheme = call_595753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595753.url(scheme.get, call_595753.host, call_595753.base,
                         call_595753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595753, url, valid)

proc call*(call_595754: Call_PostRebootDBInstance_595739;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_595755 = newJObject()
  var formData_595756 = newJObject()
  add(formData_595756, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595755, "Action", newJString(Action))
  add(formData_595756, "ForceFailover", newJBool(ForceFailover))
  add(query_595755, "Version", newJString(Version))
  result = call_595754.call(nil, query_595755, nil, formData_595756, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_595739(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_595740, base: "/",
    url: url_PostRebootDBInstance_595741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_595722 = ref object of OpenApiRestCall_593421
proc url_GetRebootDBInstance_595724(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_595723(path: JsonNode; query: JsonNode;
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
  var valid_595725 = query.getOrDefault("Action")
  valid_595725 = validateParameter(valid_595725, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595725 != nil:
    section.add "Action", valid_595725
  var valid_595726 = query.getOrDefault("ForceFailover")
  valid_595726 = validateParameter(valid_595726, JBool, required = false, default = nil)
  if valid_595726 != nil:
    section.add "ForceFailover", valid_595726
  var valid_595727 = query.getOrDefault("Version")
  valid_595727 = validateParameter(valid_595727, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595727 != nil:
    section.add "Version", valid_595727
  var valid_595728 = query.getOrDefault("DBInstanceIdentifier")
  valid_595728 = validateParameter(valid_595728, JString, required = true,
                                 default = nil)
  if valid_595728 != nil:
    section.add "DBInstanceIdentifier", valid_595728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595729 = header.getOrDefault("X-Amz-Date")
  valid_595729 = validateParameter(valid_595729, JString, required = false,
                                 default = nil)
  if valid_595729 != nil:
    section.add "X-Amz-Date", valid_595729
  var valid_595730 = header.getOrDefault("X-Amz-Security-Token")
  valid_595730 = validateParameter(valid_595730, JString, required = false,
                                 default = nil)
  if valid_595730 != nil:
    section.add "X-Amz-Security-Token", valid_595730
  var valid_595731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595731 = validateParameter(valid_595731, JString, required = false,
                                 default = nil)
  if valid_595731 != nil:
    section.add "X-Amz-Content-Sha256", valid_595731
  var valid_595732 = header.getOrDefault("X-Amz-Algorithm")
  valid_595732 = validateParameter(valid_595732, JString, required = false,
                                 default = nil)
  if valid_595732 != nil:
    section.add "X-Amz-Algorithm", valid_595732
  var valid_595733 = header.getOrDefault("X-Amz-Signature")
  valid_595733 = validateParameter(valid_595733, JString, required = false,
                                 default = nil)
  if valid_595733 != nil:
    section.add "X-Amz-Signature", valid_595733
  var valid_595734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595734 = validateParameter(valid_595734, JString, required = false,
                                 default = nil)
  if valid_595734 != nil:
    section.add "X-Amz-SignedHeaders", valid_595734
  var valid_595735 = header.getOrDefault("X-Amz-Credential")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "X-Amz-Credential", valid_595735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595736: Call_GetRebootDBInstance_595722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595736.validator(path, query, header, formData, body)
  let scheme = call_595736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595736.url(scheme.get, call_595736.host, call_595736.base,
                         call_595736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595736, url, valid)

proc call*(call_595737: Call_GetRebootDBInstance_595722;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595738 = newJObject()
  add(query_595738, "Action", newJString(Action))
  add(query_595738, "ForceFailover", newJBool(ForceFailover))
  add(query_595738, "Version", newJString(Version))
  add(query_595738, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595737.call(nil, query_595738, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_595722(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_595723, base: "/",
    url: url_GetRebootDBInstance_595724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_595774 = ref object of OpenApiRestCall_593421
proc url_PostRemoveSourceIdentifierFromSubscription_595776(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_595775(path: JsonNode;
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
  var valid_595777 = query.getOrDefault("Action")
  valid_595777 = validateParameter(valid_595777, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595777 != nil:
    section.add "Action", valid_595777
  var valid_595778 = query.getOrDefault("Version")
  valid_595778 = validateParameter(valid_595778, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595778 != nil:
    section.add "Version", valid_595778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595779 = header.getOrDefault("X-Amz-Date")
  valid_595779 = validateParameter(valid_595779, JString, required = false,
                                 default = nil)
  if valid_595779 != nil:
    section.add "X-Amz-Date", valid_595779
  var valid_595780 = header.getOrDefault("X-Amz-Security-Token")
  valid_595780 = validateParameter(valid_595780, JString, required = false,
                                 default = nil)
  if valid_595780 != nil:
    section.add "X-Amz-Security-Token", valid_595780
  var valid_595781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595781 = validateParameter(valid_595781, JString, required = false,
                                 default = nil)
  if valid_595781 != nil:
    section.add "X-Amz-Content-Sha256", valid_595781
  var valid_595782 = header.getOrDefault("X-Amz-Algorithm")
  valid_595782 = validateParameter(valid_595782, JString, required = false,
                                 default = nil)
  if valid_595782 != nil:
    section.add "X-Amz-Algorithm", valid_595782
  var valid_595783 = header.getOrDefault("X-Amz-Signature")
  valid_595783 = validateParameter(valid_595783, JString, required = false,
                                 default = nil)
  if valid_595783 != nil:
    section.add "X-Amz-Signature", valid_595783
  var valid_595784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595784 = validateParameter(valid_595784, JString, required = false,
                                 default = nil)
  if valid_595784 != nil:
    section.add "X-Amz-SignedHeaders", valid_595784
  var valid_595785 = header.getOrDefault("X-Amz-Credential")
  valid_595785 = validateParameter(valid_595785, JString, required = false,
                                 default = nil)
  if valid_595785 != nil:
    section.add "X-Amz-Credential", valid_595785
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_595786 = formData.getOrDefault("SourceIdentifier")
  valid_595786 = validateParameter(valid_595786, JString, required = true,
                                 default = nil)
  if valid_595786 != nil:
    section.add "SourceIdentifier", valid_595786
  var valid_595787 = formData.getOrDefault("SubscriptionName")
  valid_595787 = validateParameter(valid_595787, JString, required = true,
                                 default = nil)
  if valid_595787 != nil:
    section.add "SubscriptionName", valid_595787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595788: Call_PostRemoveSourceIdentifierFromSubscription_595774;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595788.validator(path, query, header, formData, body)
  let scheme = call_595788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595788.url(scheme.get, call_595788.host, call_595788.base,
                         call_595788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595788, url, valid)

proc call*(call_595789: Call_PostRemoveSourceIdentifierFromSubscription_595774;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595790 = newJObject()
  var formData_595791 = newJObject()
  add(formData_595791, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_595791, "SubscriptionName", newJString(SubscriptionName))
  add(query_595790, "Action", newJString(Action))
  add(query_595790, "Version", newJString(Version))
  result = call_595789.call(nil, query_595790, nil, formData_595791, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_595774(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_595775,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_595776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_595757 = ref object of OpenApiRestCall_593421
proc url_GetRemoveSourceIdentifierFromSubscription_595759(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_595758(path: JsonNode;
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
  var valid_595760 = query.getOrDefault("Action")
  valid_595760 = validateParameter(valid_595760, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595760 != nil:
    section.add "Action", valid_595760
  var valid_595761 = query.getOrDefault("SourceIdentifier")
  valid_595761 = validateParameter(valid_595761, JString, required = true,
                                 default = nil)
  if valid_595761 != nil:
    section.add "SourceIdentifier", valid_595761
  var valid_595762 = query.getOrDefault("SubscriptionName")
  valid_595762 = validateParameter(valid_595762, JString, required = true,
                                 default = nil)
  if valid_595762 != nil:
    section.add "SubscriptionName", valid_595762
  var valid_595763 = query.getOrDefault("Version")
  valid_595763 = validateParameter(valid_595763, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595763 != nil:
    section.add "Version", valid_595763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595764 = header.getOrDefault("X-Amz-Date")
  valid_595764 = validateParameter(valid_595764, JString, required = false,
                                 default = nil)
  if valid_595764 != nil:
    section.add "X-Amz-Date", valid_595764
  var valid_595765 = header.getOrDefault("X-Amz-Security-Token")
  valid_595765 = validateParameter(valid_595765, JString, required = false,
                                 default = nil)
  if valid_595765 != nil:
    section.add "X-Amz-Security-Token", valid_595765
  var valid_595766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595766 = validateParameter(valid_595766, JString, required = false,
                                 default = nil)
  if valid_595766 != nil:
    section.add "X-Amz-Content-Sha256", valid_595766
  var valid_595767 = header.getOrDefault("X-Amz-Algorithm")
  valid_595767 = validateParameter(valid_595767, JString, required = false,
                                 default = nil)
  if valid_595767 != nil:
    section.add "X-Amz-Algorithm", valid_595767
  var valid_595768 = header.getOrDefault("X-Amz-Signature")
  valid_595768 = validateParameter(valid_595768, JString, required = false,
                                 default = nil)
  if valid_595768 != nil:
    section.add "X-Amz-Signature", valid_595768
  var valid_595769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595769 = validateParameter(valid_595769, JString, required = false,
                                 default = nil)
  if valid_595769 != nil:
    section.add "X-Amz-SignedHeaders", valid_595769
  var valid_595770 = header.getOrDefault("X-Amz-Credential")
  valid_595770 = validateParameter(valid_595770, JString, required = false,
                                 default = nil)
  if valid_595770 != nil:
    section.add "X-Amz-Credential", valid_595770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595771: Call_GetRemoveSourceIdentifierFromSubscription_595757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595771.validator(path, query, header, formData, body)
  let scheme = call_595771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595771.url(scheme.get, call_595771.host, call_595771.base,
                         call_595771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595771, url, valid)

proc call*(call_595772: Call_GetRemoveSourceIdentifierFromSubscription_595757;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_595773 = newJObject()
  add(query_595773, "Action", newJString(Action))
  add(query_595773, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595773, "SubscriptionName", newJString(SubscriptionName))
  add(query_595773, "Version", newJString(Version))
  result = call_595772.call(nil, query_595773, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_595757(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_595758,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_595759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_595809 = ref object of OpenApiRestCall_593421
proc url_PostRemoveTagsFromResource_595811(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_595810(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595812 = query.getOrDefault("Action")
  valid_595812 = validateParameter(valid_595812, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595812 != nil:
    section.add "Action", valid_595812
  var valid_595813 = query.getOrDefault("Version")
  valid_595813 = validateParameter(valid_595813, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595813 != nil:
    section.add "Version", valid_595813
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595814 = header.getOrDefault("X-Amz-Date")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Date", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Security-Token")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Security-Token", valid_595815
  var valid_595816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595816 = validateParameter(valid_595816, JString, required = false,
                                 default = nil)
  if valid_595816 != nil:
    section.add "X-Amz-Content-Sha256", valid_595816
  var valid_595817 = header.getOrDefault("X-Amz-Algorithm")
  valid_595817 = validateParameter(valid_595817, JString, required = false,
                                 default = nil)
  if valid_595817 != nil:
    section.add "X-Amz-Algorithm", valid_595817
  var valid_595818 = header.getOrDefault("X-Amz-Signature")
  valid_595818 = validateParameter(valid_595818, JString, required = false,
                                 default = nil)
  if valid_595818 != nil:
    section.add "X-Amz-Signature", valid_595818
  var valid_595819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595819 = validateParameter(valid_595819, JString, required = false,
                                 default = nil)
  if valid_595819 != nil:
    section.add "X-Amz-SignedHeaders", valid_595819
  var valid_595820 = header.getOrDefault("X-Amz-Credential")
  valid_595820 = validateParameter(valid_595820, JString, required = false,
                                 default = nil)
  if valid_595820 != nil:
    section.add "X-Amz-Credential", valid_595820
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595821 = formData.getOrDefault("TagKeys")
  valid_595821 = validateParameter(valid_595821, JArray, required = true, default = nil)
  if valid_595821 != nil:
    section.add "TagKeys", valid_595821
  var valid_595822 = formData.getOrDefault("ResourceName")
  valid_595822 = validateParameter(valid_595822, JString, required = true,
                                 default = nil)
  if valid_595822 != nil:
    section.add "ResourceName", valid_595822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595823: Call_PostRemoveTagsFromResource_595809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595823.validator(path, query, header, formData, body)
  let scheme = call_595823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595823.url(scheme.get, call_595823.host, call_595823.base,
                         call_595823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595823, url, valid)

proc call*(call_595824: Call_PostRemoveTagsFromResource_595809; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595825 = newJObject()
  var formData_595826 = newJObject()
  add(query_595825, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595826.add "TagKeys", TagKeys
  add(formData_595826, "ResourceName", newJString(ResourceName))
  add(query_595825, "Version", newJString(Version))
  result = call_595824.call(nil, query_595825, nil, formData_595826, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_595809(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_595810, base: "/",
    url: url_PostRemoveTagsFromResource_595811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_595792 = ref object of OpenApiRestCall_593421
proc url_GetRemoveTagsFromResource_595794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_595793(path: JsonNode; query: JsonNode;
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
  var valid_595795 = query.getOrDefault("ResourceName")
  valid_595795 = validateParameter(valid_595795, JString, required = true,
                                 default = nil)
  if valid_595795 != nil:
    section.add "ResourceName", valid_595795
  var valid_595796 = query.getOrDefault("Action")
  valid_595796 = validateParameter(valid_595796, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595796 != nil:
    section.add "Action", valid_595796
  var valid_595797 = query.getOrDefault("TagKeys")
  valid_595797 = validateParameter(valid_595797, JArray, required = true, default = nil)
  if valid_595797 != nil:
    section.add "TagKeys", valid_595797
  var valid_595798 = query.getOrDefault("Version")
  valid_595798 = validateParameter(valid_595798, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595798 != nil:
    section.add "Version", valid_595798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595799 = header.getOrDefault("X-Amz-Date")
  valid_595799 = validateParameter(valid_595799, JString, required = false,
                                 default = nil)
  if valid_595799 != nil:
    section.add "X-Amz-Date", valid_595799
  var valid_595800 = header.getOrDefault("X-Amz-Security-Token")
  valid_595800 = validateParameter(valid_595800, JString, required = false,
                                 default = nil)
  if valid_595800 != nil:
    section.add "X-Amz-Security-Token", valid_595800
  var valid_595801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595801 = validateParameter(valid_595801, JString, required = false,
                                 default = nil)
  if valid_595801 != nil:
    section.add "X-Amz-Content-Sha256", valid_595801
  var valid_595802 = header.getOrDefault("X-Amz-Algorithm")
  valid_595802 = validateParameter(valid_595802, JString, required = false,
                                 default = nil)
  if valid_595802 != nil:
    section.add "X-Amz-Algorithm", valid_595802
  var valid_595803 = header.getOrDefault("X-Amz-Signature")
  valid_595803 = validateParameter(valid_595803, JString, required = false,
                                 default = nil)
  if valid_595803 != nil:
    section.add "X-Amz-Signature", valid_595803
  var valid_595804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595804 = validateParameter(valid_595804, JString, required = false,
                                 default = nil)
  if valid_595804 != nil:
    section.add "X-Amz-SignedHeaders", valid_595804
  var valid_595805 = header.getOrDefault("X-Amz-Credential")
  valid_595805 = validateParameter(valid_595805, JString, required = false,
                                 default = nil)
  if valid_595805 != nil:
    section.add "X-Amz-Credential", valid_595805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595806: Call_GetRemoveTagsFromResource_595792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595806.validator(path, query, header, formData, body)
  let scheme = call_595806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595806.url(scheme.get, call_595806.host, call_595806.base,
                         call_595806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595806, url, valid)

proc call*(call_595807: Call_GetRemoveTagsFromResource_595792;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_595808 = newJObject()
  add(query_595808, "ResourceName", newJString(ResourceName))
  add(query_595808, "Action", newJString(Action))
  if TagKeys != nil:
    query_595808.add "TagKeys", TagKeys
  add(query_595808, "Version", newJString(Version))
  result = call_595807.call(nil, query_595808, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_595792(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_595793, base: "/",
    url: url_GetRemoveTagsFromResource_595794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_595845 = ref object of OpenApiRestCall_593421
proc url_PostResetDBParameterGroup_595847(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_595846(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595848 = query.getOrDefault("Action")
  valid_595848 = validateParameter(valid_595848, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595848 != nil:
    section.add "Action", valid_595848
  var valid_595849 = query.getOrDefault("Version")
  valid_595849 = validateParameter(valid_595849, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595849 != nil:
    section.add "Version", valid_595849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595850 = header.getOrDefault("X-Amz-Date")
  valid_595850 = validateParameter(valid_595850, JString, required = false,
                                 default = nil)
  if valid_595850 != nil:
    section.add "X-Amz-Date", valid_595850
  var valid_595851 = header.getOrDefault("X-Amz-Security-Token")
  valid_595851 = validateParameter(valid_595851, JString, required = false,
                                 default = nil)
  if valid_595851 != nil:
    section.add "X-Amz-Security-Token", valid_595851
  var valid_595852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595852 = validateParameter(valid_595852, JString, required = false,
                                 default = nil)
  if valid_595852 != nil:
    section.add "X-Amz-Content-Sha256", valid_595852
  var valid_595853 = header.getOrDefault("X-Amz-Algorithm")
  valid_595853 = validateParameter(valid_595853, JString, required = false,
                                 default = nil)
  if valid_595853 != nil:
    section.add "X-Amz-Algorithm", valid_595853
  var valid_595854 = header.getOrDefault("X-Amz-Signature")
  valid_595854 = validateParameter(valid_595854, JString, required = false,
                                 default = nil)
  if valid_595854 != nil:
    section.add "X-Amz-Signature", valid_595854
  var valid_595855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595855 = validateParameter(valid_595855, JString, required = false,
                                 default = nil)
  if valid_595855 != nil:
    section.add "X-Amz-SignedHeaders", valid_595855
  var valid_595856 = header.getOrDefault("X-Amz-Credential")
  valid_595856 = validateParameter(valid_595856, JString, required = false,
                                 default = nil)
  if valid_595856 != nil:
    section.add "X-Amz-Credential", valid_595856
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595857 = formData.getOrDefault("DBParameterGroupName")
  valid_595857 = validateParameter(valid_595857, JString, required = true,
                                 default = nil)
  if valid_595857 != nil:
    section.add "DBParameterGroupName", valid_595857
  var valid_595858 = formData.getOrDefault("Parameters")
  valid_595858 = validateParameter(valid_595858, JArray, required = false,
                                 default = nil)
  if valid_595858 != nil:
    section.add "Parameters", valid_595858
  var valid_595859 = formData.getOrDefault("ResetAllParameters")
  valid_595859 = validateParameter(valid_595859, JBool, required = false, default = nil)
  if valid_595859 != nil:
    section.add "ResetAllParameters", valid_595859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595860: Call_PostResetDBParameterGroup_595845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595860.validator(path, query, header, formData, body)
  let scheme = call_595860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595860.url(scheme.get, call_595860.host, call_595860.base,
                         call_595860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595860, url, valid)

proc call*(call_595861: Call_PostResetDBParameterGroup_595845;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_595862 = newJObject()
  var formData_595863 = newJObject()
  add(formData_595863, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595863.add "Parameters", Parameters
  add(query_595862, "Action", newJString(Action))
  add(formData_595863, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595862, "Version", newJString(Version))
  result = call_595861.call(nil, query_595862, nil, formData_595863, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_595845(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_595846, base: "/",
    url: url_PostResetDBParameterGroup_595847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_595827 = ref object of OpenApiRestCall_593421
proc url_GetResetDBParameterGroup_595829(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_595828(path: JsonNode; query: JsonNode;
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
  var valid_595830 = query.getOrDefault("DBParameterGroupName")
  valid_595830 = validateParameter(valid_595830, JString, required = true,
                                 default = nil)
  if valid_595830 != nil:
    section.add "DBParameterGroupName", valid_595830
  var valid_595831 = query.getOrDefault("Parameters")
  valid_595831 = validateParameter(valid_595831, JArray, required = false,
                                 default = nil)
  if valid_595831 != nil:
    section.add "Parameters", valid_595831
  var valid_595832 = query.getOrDefault("Action")
  valid_595832 = validateParameter(valid_595832, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595832 != nil:
    section.add "Action", valid_595832
  var valid_595833 = query.getOrDefault("ResetAllParameters")
  valid_595833 = validateParameter(valid_595833, JBool, required = false, default = nil)
  if valid_595833 != nil:
    section.add "ResetAllParameters", valid_595833
  var valid_595834 = query.getOrDefault("Version")
  valid_595834 = validateParameter(valid_595834, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595834 != nil:
    section.add "Version", valid_595834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595835 = header.getOrDefault("X-Amz-Date")
  valid_595835 = validateParameter(valid_595835, JString, required = false,
                                 default = nil)
  if valid_595835 != nil:
    section.add "X-Amz-Date", valid_595835
  var valid_595836 = header.getOrDefault("X-Amz-Security-Token")
  valid_595836 = validateParameter(valid_595836, JString, required = false,
                                 default = nil)
  if valid_595836 != nil:
    section.add "X-Amz-Security-Token", valid_595836
  var valid_595837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595837 = validateParameter(valid_595837, JString, required = false,
                                 default = nil)
  if valid_595837 != nil:
    section.add "X-Amz-Content-Sha256", valid_595837
  var valid_595838 = header.getOrDefault("X-Amz-Algorithm")
  valid_595838 = validateParameter(valid_595838, JString, required = false,
                                 default = nil)
  if valid_595838 != nil:
    section.add "X-Amz-Algorithm", valid_595838
  var valid_595839 = header.getOrDefault("X-Amz-Signature")
  valid_595839 = validateParameter(valid_595839, JString, required = false,
                                 default = nil)
  if valid_595839 != nil:
    section.add "X-Amz-Signature", valid_595839
  var valid_595840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595840 = validateParameter(valid_595840, JString, required = false,
                                 default = nil)
  if valid_595840 != nil:
    section.add "X-Amz-SignedHeaders", valid_595840
  var valid_595841 = header.getOrDefault("X-Amz-Credential")
  valid_595841 = validateParameter(valid_595841, JString, required = false,
                                 default = nil)
  if valid_595841 != nil:
    section.add "X-Amz-Credential", valid_595841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595842: Call_GetResetDBParameterGroup_595827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595842.validator(path, query, header, formData, body)
  let scheme = call_595842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595842.url(scheme.get, call_595842.host, call_595842.base,
                         call_595842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595842, url, valid)

proc call*(call_595843: Call_GetResetDBParameterGroup_595827;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_595844 = newJObject()
  add(query_595844, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595844.add "Parameters", Parameters
  add(query_595844, "Action", newJString(Action))
  add(query_595844, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595844, "Version", newJString(Version))
  result = call_595843.call(nil, query_595844, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_595827(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_595828, base: "/",
    url: url_GetResetDBParameterGroup_595829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_595893 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceFromDBSnapshot_595895(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_595894(path: JsonNode;
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
  var valid_595896 = query.getOrDefault("Action")
  valid_595896 = validateParameter(valid_595896, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595896 != nil:
    section.add "Action", valid_595896
  var valid_595897 = query.getOrDefault("Version")
  valid_595897 = validateParameter(valid_595897, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595897 != nil:
    section.add "Version", valid_595897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595898 = header.getOrDefault("X-Amz-Date")
  valid_595898 = validateParameter(valid_595898, JString, required = false,
                                 default = nil)
  if valid_595898 != nil:
    section.add "X-Amz-Date", valid_595898
  var valid_595899 = header.getOrDefault("X-Amz-Security-Token")
  valid_595899 = validateParameter(valid_595899, JString, required = false,
                                 default = nil)
  if valid_595899 != nil:
    section.add "X-Amz-Security-Token", valid_595899
  var valid_595900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595900 = validateParameter(valid_595900, JString, required = false,
                                 default = nil)
  if valid_595900 != nil:
    section.add "X-Amz-Content-Sha256", valid_595900
  var valid_595901 = header.getOrDefault("X-Amz-Algorithm")
  valid_595901 = validateParameter(valid_595901, JString, required = false,
                                 default = nil)
  if valid_595901 != nil:
    section.add "X-Amz-Algorithm", valid_595901
  var valid_595902 = header.getOrDefault("X-Amz-Signature")
  valid_595902 = validateParameter(valid_595902, JString, required = false,
                                 default = nil)
  if valid_595902 != nil:
    section.add "X-Amz-Signature", valid_595902
  var valid_595903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595903 = validateParameter(valid_595903, JString, required = false,
                                 default = nil)
  if valid_595903 != nil:
    section.add "X-Amz-SignedHeaders", valid_595903
  var valid_595904 = header.getOrDefault("X-Amz-Credential")
  valid_595904 = validateParameter(valid_595904, JString, required = false,
                                 default = nil)
  if valid_595904 != nil:
    section.add "X-Amz-Credential", valid_595904
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
  var valid_595905 = formData.getOrDefault("Port")
  valid_595905 = validateParameter(valid_595905, JInt, required = false, default = nil)
  if valid_595905 != nil:
    section.add "Port", valid_595905
  var valid_595906 = formData.getOrDefault("Engine")
  valid_595906 = validateParameter(valid_595906, JString, required = false,
                                 default = nil)
  if valid_595906 != nil:
    section.add "Engine", valid_595906
  var valid_595907 = formData.getOrDefault("Iops")
  valid_595907 = validateParameter(valid_595907, JInt, required = false, default = nil)
  if valid_595907 != nil:
    section.add "Iops", valid_595907
  var valid_595908 = formData.getOrDefault("DBName")
  valid_595908 = validateParameter(valid_595908, JString, required = false,
                                 default = nil)
  if valid_595908 != nil:
    section.add "DBName", valid_595908
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595909 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595909 = validateParameter(valid_595909, JString, required = true,
                                 default = nil)
  if valid_595909 != nil:
    section.add "DBInstanceIdentifier", valid_595909
  var valid_595910 = formData.getOrDefault("OptionGroupName")
  valid_595910 = validateParameter(valid_595910, JString, required = false,
                                 default = nil)
  if valid_595910 != nil:
    section.add "OptionGroupName", valid_595910
  var valid_595911 = formData.getOrDefault("DBSubnetGroupName")
  valid_595911 = validateParameter(valid_595911, JString, required = false,
                                 default = nil)
  if valid_595911 != nil:
    section.add "DBSubnetGroupName", valid_595911
  var valid_595912 = formData.getOrDefault("AvailabilityZone")
  valid_595912 = validateParameter(valid_595912, JString, required = false,
                                 default = nil)
  if valid_595912 != nil:
    section.add "AvailabilityZone", valid_595912
  var valid_595913 = formData.getOrDefault("MultiAZ")
  valid_595913 = validateParameter(valid_595913, JBool, required = false, default = nil)
  if valid_595913 != nil:
    section.add "MultiAZ", valid_595913
  var valid_595914 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595914 = validateParameter(valid_595914, JString, required = true,
                                 default = nil)
  if valid_595914 != nil:
    section.add "DBSnapshotIdentifier", valid_595914
  var valid_595915 = formData.getOrDefault("PubliclyAccessible")
  valid_595915 = validateParameter(valid_595915, JBool, required = false, default = nil)
  if valid_595915 != nil:
    section.add "PubliclyAccessible", valid_595915
  var valid_595916 = formData.getOrDefault("DBInstanceClass")
  valid_595916 = validateParameter(valid_595916, JString, required = false,
                                 default = nil)
  if valid_595916 != nil:
    section.add "DBInstanceClass", valid_595916
  var valid_595917 = formData.getOrDefault("LicenseModel")
  valid_595917 = validateParameter(valid_595917, JString, required = false,
                                 default = nil)
  if valid_595917 != nil:
    section.add "LicenseModel", valid_595917
  var valid_595918 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595918 = validateParameter(valid_595918, JBool, required = false, default = nil)
  if valid_595918 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595918
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595919: Call_PostRestoreDBInstanceFromDBSnapshot_595893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595919.validator(path, query, header, formData, body)
  let scheme = call_595919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595919.url(scheme.get, call_595919.host, call_595919.base,
                         call_595919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595919, url, valid)

proc call*(call_595920: Call_PostRestoreDBInstanceFromDBSnapshot_595893;
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
  var query_595921 = newJObject()
  var formData_595922 = newJObject()
  add(formData_595922, "Port", newJInt(Port))
  add(formData_595922, "Engine", newJString(Engine))
  add(formData_595922, "Iops", newJInt(Iops))
  add(formData_595922, "DBName", newJString(DBName))
  add(formData_595922, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595922, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595922, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595922, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_595922, "MultiAZ", newJBool(MultiAZ))
  add(formData_595922, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_595921, "Action", newJString(Action))
  add(formData_595922, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_595922, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595922, "LicenseModel", newJString(LicenseModel))
  add(formData_595922, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_595921, "Version", newJString(Version))
  result = call_595920.call(nil, query_595921, nil, formData_595922, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_595893(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_595894, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_595895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_595864 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceFromDBSnapshot_595866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_595865(path: JsonNode;
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
  var valid_595867 = query.getOrDefault("Engine")
  valid_595867 = validateParameter(valid_595867, JString, required = false,
                                 default = nil)
  if valid_595867 != nil:
    section.add "Engine", valid_595867
  var valid_595868 = query.getOrDefault("OptionGroupName")
  valid_595868 = validateParameter(valid_595868, JString, required = false,
                                 default = nil)
  if valid_595868 != nil:
    section.add "OptionGroupName", valid_595868
  var valid_595869 = query.getOrDefault("AvailabilityZone")
  valid_595869 = validateParameter(valid_595869, JString, required = false,
                                 default = nil)
  if valid_595869 != nil:
    section.add "AvailabilityZone", valid_595869
  var valid_595870 = query.getOrDefault("Iops")
  valid_595870 = validateParameter(valid_595870, JInt, required = false, default = nil)
  if valid_595870 != nil:
    section.add "Iops", valid_595870
  var valid_595871 = query.getOrDefault("MultiAZ")
  valid_595871 = validateParameter(valid_595871, JBool, required = false, default = nil)
  if valid_595871 != nil:
    section.add "MultiAZ", valid_595871
  var valid_595872 = query.getOrDefault("LicenseModel")
  valid_595872 = validateParameter(valid_595872, JString, required = false,
                                 default = nil)
  if valid_595872 != nil:
    section.add "LicenseModel", valid_595872
  var valid_595873 = query.getOrDefault("DBName")
  valid_595873 = validateParameter(valid_595873, JString, required = false,
                                 default = nil)
  if valid_595873 != nil:
    section.add "DBName", valid_595873
  var valid_595874 = query.getOrDefault("DBInstanceClass")
  valid_595874 = validateParameter(valid_595874, JString, required = false,
                                 default = nil)
  if valid_595874 != nil:
    section.add "DBInstanceClass", valid_595874
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595875 = query.getOrDefault("Action")
  valid_595875 = validateParameter(valid_595875, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595875 != nil:
    section.add "Action", valid_595875
  var valid_595876 = query.getOrDefault("DBSubnetGroupName")
  valid_595876 = validateParameter(valid_595876, JString, required = false,
                                 default = nil)
  if valid_595876 != nil:
    section.add "DBSubnetGroupName", valid_595876
  var valid_595877 = query.getOrDefault("PubliclyAccessible")
  valid_595877 = validateParameter(valid_595877, JBool, required = false, default = nil)
  if valid_595877 != nil:
    section.add "PubliclyAccessible", valid_595877
  var valid_595878 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595878 = validateParameter(valid_595878, JBool, required = false, default = nil)
  if valid_595878 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595878
  var valid_595879 = query.getOrDefault("Port")
  valid_595879 = validateParameter(valid_595879, JInt, required = false, default = nil)
  if valid_595879 != nil:
    section.add "Port", valid_595879
  var valid_595880 = query.getOrDefault("Version")
  valid_595880 = validateParameter(valid_595880, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595880 != nil:
    section.add "Version", valid_595880
  var valid_595881 = query.getOrDefault("DBInstanceIdentifier")
  valid_595881 = validateParameter(valid_595881, JString, required = true,
                                 default = nil)
  if valid_595881 != nil:
    section.add "DBInstanceIdentifier", valid_595881
  var valid_595882 = query.getOrDefault("DBSnapshotIdentifier")
  valid_595882 = validateParameter(valid_595882, JString, required = true,
                                 default = nil)
  if valid_595882 != nil:
    section.add "DBSnapshotIdentifier", valid_595882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595883 = header.getOrDefault("X-Amz-Date")
  valid_595883 = validateParameter(valid_595883, JString, required = false,
                                 default = nil)
  if valid_595883 != nil:
    section.add "X-Amz-Date", valid_595883
  var valid_595884 = header.getOrDefault("X-Amz-Security-Token")
  valid_595884 = validateParameter(valid_595884, JString, required = false,
                                 default = nil)
  if valid_595884 != nil:
    section.add "X-Amz-Security-Token", valid_595884
  var valid_595885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595885 = validateParameter(valid_595885, JString, required = false,
                                 default = nil)
  if valid_595885 != nil:
    section.add "X-Amz-Content-Sha256", valid_595885
  var valid_595886 = header.getOrDefault("X-Amz-Algorithm")
  valid_595886 = validateParameter(valid_595886, JString, required = false,
                                 default = nil)
  if valid_595886 != nil:
    section.add "X-Amz-Algorithm", valid_595886
  var valid_595887 = header.getOrDefault("X-Amz-Signature")
  valid_595887 = validateParameter(valid_595887, JString, required = false,
                                 default = nil)
  if valid_595887 != nil:
    section.add "X-Amz-Signature", valid_595887
  var valid_595888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595888 = validateParameter(valid_595888, JString, required = false,
                                 default = nil)
  if valid_595888 != nil:
    section.add "X-Amz-SignedHeaders", valid_595888
  var valid_595889 = header.getOrDefault("X-Amz-Credential")
  valid_595889 = validateParameter(valid_595889, JString, required = false,
                                 default = nil)
  if valid_595889 != nil:
    section.add "X-Amz-Credential", valid_595889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595890: Call_GetRestoreDBInstanceFromDBSnapshot_595864;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595890.validator(path, query, header, formData, body)
  let scheme = call_595890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595890.url(scheme.get, call_595890.host, call_595890.base,
                         call_595890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595890, url, valid)

proc call*(call_595891: Call_GetRestoreDBInstanceFromDBSnapshot_595864;
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
  var query_595892 = newJObject()
  add(query_595892, "Engine", newJString(Engine))
  add(query_595892, "OptionGroupName", newJString(OptionGroupName))
  add(query_595892, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595892, "Iops", newJInt(Iops))
  add(query_595892, "MultiAZ", newJBool(MultiAZ))
  add(query_595892, "LicenseModel", newJString(LicenseModel))
  add(query_595892, "DBName", newJString(DBName))
  add(query_595892, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595892, "Action", newJString(Action))
  add(query_595892, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595892, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595892, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595892, "Port", newJInt(Port))
  add(query_595892, "Version", newJString(Version))
  add(query_595892, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595892, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_595891.call(nil, query_595892, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_595864(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_595865, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_595866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_595954 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceToPointInTime_595956(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_595955(path: JsonNode;
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
  var valid_595957 = query.getOrDefault("Action")
  valid_595957 = validateParameter(valid_595957, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595957 != nil:
    section.add "Action", valid_595957
  var valid_595958 = query.getOrDefault("Version")
  valid_595958 = validateParameter(valid_595958, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595958 != nil:
    section.add "Version", valid_595958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595959 = header.getOrDefault("X-Amz-Date")
  valid_595959 = validateParameter(valid_595959, JString, required = false,
                                 default = nil)
  if valid_595959 != nil:
    section.add "X-Amz-Date", valid_595959
  var valid_595960 = header.getOrDefault("X-Amz-Security-Token")
  valid_595960 = validateParameter(valid_595960, JString, required = false,
                                 default = nil)
  if valid_595960 != nil:
    section.add "X-Amz-Security-Token", valid_595960
  var valid_595961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595961 = validateParameter(valid_595961, JString, required = false,
                                 default = nil)
  if valid_595961 != nil:
    section.add "X-Amz-Content-Sha256", valid_595961
  var valid_595962 = header.getOrDefault("X-Amz-Algorithm")
  valid_595962 = validateParameter(valid_595962, JString, required = false,
                                 default = nil)
  if valid_595962 != nil:
    section.add "X-Amz-Algorithm", valid_595962
  var valid_595963 = header.getOrDefault("X-Amz-Signature")
  valid_595963 = validateParameter(valid_595963, JString, required = false,
                                 default = nil)
  if valid_595963 != nil:
    section.add "X-Amz-Signature", valid_595963
  var valid_595964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595964 = validateParameter(valid_595964, JString, required = false,
                                 default = nil)
  if valid_595964 != nil:
    section.add "X-Amz-SignedHeaders", valid_595964
  var valid_595965 = header.getOrDefault("X-Amz-Credential")
  valid_595965 = validateParameter(valid_595965, JString, required = false,
                                 default = nil)
  if valid_595965 != nil:
    section.add "X-Amz-Credential", valid_595965
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
  var valid_595966 = formData.getOrDefault("UseLatestRestorableTime")
  valid_595966 = validateParameter(valid_595966, JBool, required = false, default = nil)
  if valid_595966 != nil:
    section.add "UseLatestRestorableTime", valid_595966
  var valid_595967 = formData.getOrDefault("Port")
  valid_595967 = validateParameter(valid_595967, JInt, required = false, default = nil)
  if valid_595967 != nil:
    section.add "Port", valid_595967
  var valid_595968 = formData.getOrDefault("Engine")
  valid_595968 = validateParameter(valid_595968, JString, required = false,
                                 default = nil)
  if valid_595968 != nil:
    section.add "Engine", valid_595968
  var valid_595969 = formData.getOrDefault("Iops")
  valid_595969 = validateParameter(valid_595969, JInt, required = false, default = nil)
  if valid_595969 != nil:
    section.add "Iops", valid_595969
  var valid_595970 = formData.getOrDefault("DBName")
  valid_595970 = validateParameter(valid_595970, JString, required = false,
                                 default = nil)
  if valid_595970 != nil:
    section.add "DBName", valid_595970
  var valid_595971 = formData.getOrDefault("OptionGroupName")
  valid_595971 = validateParameter(valid_595971, JString, required = false,
                                 default = nil)
  if valid_595971 != nil:
    section.add "OptionGroupName", valid_595971
  var valid_595972 = formData.getOrDefault("DBSubnetGroupName")
  valid_595972 = validateParameter(valid_595972, JString, required = false,
                                 default = nil)
  if valid_595972 != nil:
    section.add "DBSubnetGroupName", valid_595972
  var valid_595973 = formData.getOrDefault("AvailabilityZone")
  valid_595973 = validateParameter(valid_595973, JString, required = false,
                                 default = nil)
  if valid_595973 != nil:
    section.add "AvailabilityZone", valid_595973
  var valid_595974 = formData.getOrDefault("MultiAZ")
  valid_595974 = validateParameter(valid_595974, JBool, required = false, default = nil)
  if valid_595974 != nil:
    section.add "MultiAZ", valid_595974
  var valid_595975 = formData.getOrDefault("RestoreTime")
  valid_595975 = validateParameter(valid_595975, JString, required = false,
                                 default = nil)
  if valid_595975 != nil:
    section.add "RestoreTime", valid_595975
  var valid_595976 = formData.getOrDefault("PubliclyAccessible")
  valid_595976 = validateParameter(valid_595976, JBool, required = false, default = nil)
  if valid_595976 != nil:
    section.add "PubliclyAccessible", valid_595976
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_595977 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_595977 = validateParameter(valid_595977, JString, required = true,
                                 default = nil)
  if valid_595977 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595977
  var valid_595978 = formData.getOrDefault("DBInstanceClass")
  valid_595978 = validateParameter(valid_595978, JString, required = false,
                                 default = nil)
  if valid_595978 != nil:
    section.add "DBInstanceClass", valid_595978
  var valid_595979 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_595979 = validateParameter(valid_595979, JString, required = true,
                                 default = nil)
  if valid_595979 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595979
  var valid_595980 = formData.getOrDefault("LicenseModel")
  valid_595980 = validateParameter(valid_595980, JString, required = false,
                                 default = nil)
  if valid_595980 != nil:
    section.add "LicenseModel", valid_595980
  var valid_595981 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595981 = validateParameter(valid_595981, JBool, required = false, default = nil)
  if valid_595981 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595981
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595982: Call_PostRestoreDBInstanceToPointInTime_595954;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595982.validator(path, query, header, formData, body)
  let scheme = call_595982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595982.url(scheme.get, call_595982.host, call_595982.base,
                         call_595982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595982, url, valid)

proc call*(call_595983: Call_PostRestoreDBInstanceToPointInTime_595954;
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
  var query_595984 = newJObject()
  var formData_595985 = newJObject()
  add(formData_595985, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_595985, "Port", newJInt(Port))
  add(formData_595985, "Engine", newJString(Engine))
  add(formData_595985, "Iops", newJInt(Iops))
  add(formData_595985, "DBName", newJString(DBName))
  add(formData_595985, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595985, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595985, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_595985, "MultiAZ", newJBool(MultiAZ))
  add(query_595984, "Action", newJString(Action))
  add(formData_595985, "RestoreTime", newJString(RestoreTime))
  add(formData_595985, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_595985, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_595985, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595985, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_595985, "LicenseModel", newJString(LicenseModel))
  add(formData_595985, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_595984, "Version", newJString(Version))
  result = call_595983.call(nil, query_595984, nil, formData_595985, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_595954(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_595955, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_595956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_595923 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceToPointInTime_595925(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_595924(path: JsonNode;
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
  var valid_595926 = query.getOrDefault("Engine")
  valid_595926 = validateParameter(valid_595926, JString, required = false,
                                 default = nil)
  if valid_595926 != nil:
    section.add "Engine", valid_595926
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_595927 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_595927 = validateParameter(valid_595927, JString, required = true,
                                 default = nil)
  if valid_595927 != nil:
    section.add "SourceDBInstanceIdentifier", valid_595927
  var valid_595928 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_595928 = validateParameter(valid_595928, JString, required = true,
                                 default = nil)
  if valid_595928 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595928
  var valid_595929 = query.getOrDefault("AvailabilityZone")
  valid_595929 = validateParameter(valid_595929, JString, required = false,
                                 default = nil)
  if valid_595929 != nil:
    section.add "AvailabilityZone", valid_595929
  var valid_595930 = query.getOrDefault("Iops")
  valid_595930 = validateParameter(valid_595930, JInt, required = false, default = nil)
  if valid_595930 != nil:
    section.add "Iops", valid_595930
  var valid_595931 = query.getOrDefault("OptionGroupName")
  valid_595931 = validateParameter(valid_595931, JString, required = false,
                                 default = nil)
  if valid_595931 != nil:
    section.add "OptionGroupName", valid_595931
  var valid_595932 = query.getOrDefault("RestoreTime")
  valid_595932 = validateParameter(valid_595932, JString, required = false,
                                 default = nil)
  if valid_595932 != nil:
    section.add "RestoreTime", valid_595932
  var valid_595933 = query.getOrDefault("MultiAZ")
  valid_595933 = validateParameter(valid_595933, JBool, required = false, default = nil)
  if valid_595933 != nil:
    section.add "MultiAZ", valid_595933
  var valid_595934 = query.getOrDefault("LicenseModel")
  valid_595934 = validateParameter(valid_595934, JString, required = false,
                                 default = nil)
  if valid_595934 != nil:
    section.add "LicenseModel", valid_595934
  var valid_595935 = query.getOrDefault("DBName")
  valid_595935 = validateParameter(valid_595935, JString, required = false,
                                 default = nil)
  if valid_595935 != nil:
    section.add "DBName", valid_595935
  var valid_595936 = query.getOrDefault("DBInstanceClass")
  valid_595936 = validateParameter(valid_595936, JString, required = false,
                                 default = nil)
  if valid_595936 != nil:
    section.add "DBInstanceClass", valid_595936
  var valid_595937 = query.getOrDefault("Action")
  valid_595937 = validateParameter(valid_595937, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_595937 != nil:
    section.add "Action", valid_595937
  var valid_595938 = query.getOrDefault("UseLatestRestorableTime")
  valid_595938 = validateParameter(valid_595938, JBool, required = false, default = nil)
  if valid_595938 != nil:
    section.add "UseLatestRestorableTime", valid_595938
  var valid_595939 = query.getOrDefault("DBSubnetGroupName")
  valid_595939 = validateParameter(valid_595939, JString, required = false,
                                 default = nil)
  if valid_595939 != nil:
    section.add "DBSubnetGroupName", valid_595939
  var valid_595940 = query.getOrDefault("PubliclyAccessible")
  valid_595940 = validateParameter(valid_595940, JBool, required = false, default = nil)
  if valid_595940 != nil:
    section.add "PubliclyAccessible", valid_595940
  var valid_595941 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595941 = validateParameter(valid_595941, JBool, required = false, default = nil)
  if valid_595941 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595941
  var valid_595942 = query.getOrDefault("Port")
  valid_595942 = validateParameter(valid_595942, JInt, required = false, default = nil)
  if valid_595942 != nil:
    section.add "Port", valid_595942
  var valid_595943 = query.getOrDefault("Version")
  valid_595943 = validateParameter(valid_595943, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595943 != nil:
    section.add "Version", valid_595943
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595944 = header.getOrDefault("X-Amz-Date")
  valid_595944 = validateParameter(valid_595944, JString, required = false,
                                 default = nil)
  if valid_595944 != nil:
    section.add "X-Amz-Date", valid_595944
  var valid_595945 = header.getOrDefault("X-Amz-Security-Token")
  valid_595945 = validateParameter(valid_595945, JString, required = false,
                                 default = nil)
  if valid_595945 != nil:
    section.add "X-Amz-Security-Token", valid_595945
  var valid_595946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595946 = validateParameter(valid_595946, JString, required = false,
                                 default = nil)
  if valid_595946 != nil:
    section.add "X-Amz-Content-Sha256", valid_595946
  var valid_595947 = header.getOrDefault("X-Amz-Algorithm")
  valid_595947 = validateParameter(valid_595947, JString, required = false,
                                 default = nil)
  if valid_595947 != nil:
    section.add "X-Amz-Algorithm", valid_595947
  var valid_595948 = header.getOrDefault("X-Amz-Signature")
  valid_595948 = validateParameter(valid_595948, JString, required = false,
                                 default = nil)
  if valid_595948 != nil:
    section.add "X-Amz-Signature", valid_595948
  var valid_595949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595949 = validateParameter(valid_595949, JString, required = false,
                                 default = nil)
  if valid_595949 != nil:
    section.add "X-Amz-SignedHeaders", valid_595949
  var valid_595950 = header.getOrDefault("X-Amz-Credential")
  valid_595950 = validateParameter(valid_595950, JString, required = false,
                                 default = nil)
  if valid_595950 != nil:
    section.add "X-Amz-Credential", valid_595950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595951: Call_GetRestoreDBInstanceToPointInTime_595923;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595951.validator(path, query, header, formData, body)
  let scheme = call_595951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595951.url(scheme.get, call_595951.host, call_595951.base,
                         call_595951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595951, url, valid)

proc call*(call_595952: Call_GetRestoreDBInstanceToPointInTime_595923;
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
  var query_595953 = newJObject()
  add(query_595953, "Engine", newJString(Engine))
  add(query_595953, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_595953, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595953, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595953, "Iops", newJInt(Iops))
  add(query_595953, "OptionGroupName", newJString(OptionGroupName))
  add(query_595953, "RestoreTime", newJString(RestoreTime))
  add(query_595953, "MultiAZ", newJBool(MultiAZ))
  add(query_595953, "LicenseModel", newJString(LicenseModel))
  add(query_595953, "DBName", newJString(DBName))
  add(query_595953, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595953, "Action", newJString(Action))
  add(query_595953, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_595953, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595953, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595953, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595953, "Port", newJInt(Port))
  add(query_595953, "Version", newJString(Version))
  result = call_595952.call(nil, query_595953, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_595923(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_595924, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_595925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_596006 = ref object of OpenApiRestCall_593421
proc url_PostRevokeDBSecurityGroupIngress_596008(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_596007(path: JsonNode;
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
  var valid_596009 = query.getOrDefault("Action")
  valid_596009 = validateParameter(valid_596009, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596009 != nil:
    section.add "Action", valid_596009
  var valid_596010 = query.getOrDefault("Version")
  valid_596010 = validateParameter(valid_596010, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_596010 != nil:
    section.add "Version", valid_596010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_596011 = header.getOrDefault("X-Amz-Date")
  valid_596011 = validateParameter(valid_596011, JString, required = false,
                                 default = nil)
  if valid_596011 != nil:
    section.add "X-Amz-Date", valid_596011
  var valid_596012 = header.getOrDefault("X-Amz-Security-Token")
  valid_596012 = validateParameter(valid_596012, JString, required = false,
                                 default = nil)
  if valid_596012 != nil:
    section.add "X-Amz-Security-Token", valid_596012
  var valid_596013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596013 = validateParameter(valid_596013, JString, required = false,
                                 default = nil)
  if valid_596013 != nil:
    section.add "X-Amz-Content-Sha256", valid_596013
  var valid_596014 = header.getOrDefault("X-Amz-Algorithm")
  valid_596014 = validateParameter(valid_596014, JString, required = false,
                                 default = nil)
  if valid_596014 != nil:
    section.add "X-Amz-Algorithm", valid_596014
  var valid_596015 = header.getOrDefault("X-Amz-Signature")
  valid_596015 = validateParameter(valid_596015, JString, required = false,
                                 default = nil)
  if valid_596015 != nil:
    section.add "X-Amz-Signature", valid_596015
  var valid_596016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596016 = validateParameter(valid_596016, JString, required = false,
                                 default = nil)
  if valid_596016 != nil:
    section.add "X-Amz-SignedHeaders", valid_596016
  var valid_596017 = header.getOrDefault("X-Amz-Credential")
  valid_596017 = validateParameter(valid_596017, JString, required = false,
                                 default = nil)
  if valid_596017 != nil:
    section.add "X-Amz-Credential", valid_596017
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596018 = formData.getOrDefault("DBSecurityGroupName")
  valid_596018 = validateParameter(valid_596018, JString, required = true,
                                 default = nil)
  if valid_596018 != nil:
    section.add "DBSecurityGroupName", valid_596018
  var valid_596019 = formData.getOrDefault("EC2SecurityGroupName")
  valid_596019 = validateParameter(valid_596019, JString, required = false,
                                 default = nil)
  if valid_596019 != nil:
    section.add "EC2SecurityGroupName", valid_596019
  var valid_596020 = formData.getOrDefault("EC2SecurityGroupId")
  valid_596020 = validateParameter(valid_596020, JString, required = false,
                                 default = nil)
  if valid_596020 != nil:
    section.add "EC2SecurityGroupId", valid_596020
  var valid_596021 = formData.getOrDefault("CIDRIP")
  valid_596021 = validateParameter(valid_596021, JString, required = false,
                                 default = nil)
  if valid_596021 != nil:
    section.add "CIDRIP", valid_596021
  var valid_596022 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596022 = validateParameter(valid_596022, JString, required = false,
                                 default = nil)
  if valid_596022 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596023: Call_PostRevokeDBSecurityGroupIngress_596006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596023.validator(path, query, header, formData, body)
  let scheme = call_596023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596023.url(scheme.get, call_596023.host, call_596023.base,
                         call_596023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596023, url, valid)

proc call*(call_596024: Call_PostRevokeDBSecurityGroupIngress_596006;
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
  var query_596025 = newJObject()
  var formData_596026 = newJObject()
  add(formData_596026, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596025, "Action", newJString(Action))
  add(formData_596026, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_596026, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_596026, "CIDRIP", newJString(CIDRIP))
  add(query_596025, "Version", newJString(Version))
  add(formData_596026, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_596024.call(nil, query_596025, nil, formData_596026, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_596006(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_596007, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_596008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_595986 = ref object of OpenApiRestCall_593421
proc url_GetRevokeDBSecurityGroupIngress_595988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_595987(path: JsonNode;
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
  var valid_595989 = query.getOrDefault("EC2SecurityGroupId")
  valid_595989 = validateParameter(valid_595989, JString, required = false,
                                 default = nil)
  if valid_595989 != nil:
    section.add "EC2SecurityGroupId", valid_595989
  var valid_595990 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_595990 = validateParameter(valid_595990, JString, required = false,
                                 default = nil)
  if valid_595990 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_595990
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_595991 = query.getOrDefault("DBSecurityGroupName")
  valid_595991 = validateParameter(valid_595991, JString, required = true,
                                 default = nil)
  if valid_595991 != nil:
    section.add "DBSecurityGroupName", valid_595991
  var valid_595992 = query.getOrDefault("Action")
  valid_595992 = validateParameter(valid_595992, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_595992 != nil:
    section.add "Action", valid_595992
  var valid_595993 = query.getOrDefault("CIDRIP")
  valid_595993 = validateParameter(valid_595993, JString, required = false,
                                 default = nil)
  if valid_595993 != nil:
    section.add "CIDRIP", valid_595993
  var valid_595994 = query.getOrDefault("EC2SecurityGroupName")
  valid_595994 = validateParameter(valid_595994, JString, required = false,
                                 default = nil)
  if valid_595994 != nil:
    section.add "EC2SecurityGroupName", valid_595994
  var valid_595995 = query.getOrDefault("Version")
  valid_595995 = validateParameter(valid_595995, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_595995 != nil:
    section.add "Version", valid_595995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595996 = header.getOrDefault("X-Amz-Date")
  valid_595996 = validateParameter(valid_595996, JString, required = false,
                                 default = nil)
  if valid_595996 != nil:
    section.add "X-Amz-Date", valid_595996
  var valid_595997 = header.getOrDefault("X-Amz-Security-Token")
  valid_595997 = validateParameter(valid_595997, JString, required = false,
                                 default = nil)
  if valid_595997 != nil:
    section.add "X-Amz-Security-Token", valid_595997
  var valid_595998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595998 = validateParameter(valid_595998, JString, required = false,
                                 default = nil)
  if valid_595998 != nil:
    section.add "X-Amz-Content-Sha256", valid_595998
  var valid_595999 = header.getOrDefault("X-Amz-Algorithm")
  valid_595999 = validateParameter(valid_595999, JString, required = false,
                                 default = nil)
  if valid_595999 != nil:
    section.add "X-Amz-Algorithm", valid_595999
  var valid_596000 = header.getOrDefault("X-Amz-Signature")
  valid_596000 = validateParameter(valid_596000, JString, required = false,
                                 default = nil)
  if valid_596000 != nil:
    section.add "X-Amz-Signature", valid_596000
  var valid_596001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596001 = validateParameter(valid_596001, JString, required = false,
                                 default = nil)
  if valid_596001 != nil:
    section.add "X-Amz-SignedHeaders", valid_596001
  var valid_596002 = header.getOrDefault("X-Amz-Credential")
  valid_596002 = validateParameter(valid_596002, JString, required = false,
                                 default = nil)
  if valid_596002 != nil:
    section.add "X-Amz-Credential", valid_596002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596003: Call_GetRevokeDBSecurityGroupIngress_595986;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596003.validator(path, query, header, formData, body)
  let scheme = call_596003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596003.url(scheme.get, call_596003.host, call_596003.base,
                         call_596003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596003, url, valid)

proc call*(call_596004: Call_GetRevokeDBSecurityGroupIngress_595986;
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
  var query_596005 = newJObject()
  add(query_596005, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_596005, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_596005, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596005, "Action", newJString(Action))
  add(query_596005, "CIDRIP", newJString(CIDRIP))
  add(query_596005, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_596005, "Version", newJString(Version))
  result = call_596004.call(nil, query_596005, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_595986(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_595987, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_595988,
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

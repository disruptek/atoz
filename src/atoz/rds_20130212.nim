
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
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
  Call_PostDescribeDBLogFiles_594851 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBLogFiles_594853(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_594852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594854 = query.getOrDefault("Action")
  valid_594854 = validateParameter(valid_594854, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594854 != nil:
    section.add "Action", valid_594854
  var valid_594855 = query.getOrDefault("Version")
  valid_594855 = validateParameter(valid_594855, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594855 != nil:
    section.add "Version", valid_594855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594856 = header.getOrDefault("X-Amz-Date")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Date", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Content-Sha256", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Algorithm")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Algorithm", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Signature")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Signature", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-SignedHeaders", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Credential")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Credential", valid_594862
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_594863 = formData.getOrDefault("FilenameContains")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "FilenameContains", valid_594863
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594864 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594864 = validateParameter(valid_594864, JString, required = true,
                                 default = nil)
  if valid_594864 != nil:
    section.add "DBInstanceIdentifier", valid_594864
  var valid_594865 = formData.getOrDefault("FileSize")
  valid_594865 = validateParameter(valid_594865, JInt, required = false, default = nil)
  if valid_594865 != nil:
    section.add "FileSize", valid_594865
  var valid_594866 = formData.getOrDefault("Marker")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "Marker", valid_594866
  var valid_594867 = formData.getOrDefault("MaxRecords")
  valid_594867 = validateParameter(valid_594867, JInt, required = false, default = nil)
  if valid_594867 != nil:
    section.add "MaxRecords", valid_594867
  var valid_594868 = formData.getOrDefault("FileLastWritten")
  valid_594868 = validateParameter(valid_594868, JInt, required = false, default = nil)
  if valid_594868 != nil:
    section.add "FileLastWritten", valid_594868
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594869: Call_PostDescribeDBLogFiles_594851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594869.validator(path, query, header, formData, body)
  let scheme = call_594869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594869.url(scheme.get, call_594869.host, call_594869.base,
                         call_594869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594869, url, valid)

proc call*(call_594870: Call_PostDescribeDBLogFiles_594851;
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
  var query_594871 = newJObject()
  var formData_594872 = newJObject()
  add(formData_594872, "FilenameContains", newJString(FilenameContains))
  add(formData_594872, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594872, "FileSize", newJInt(FileSize))
  add(formData_594872, "Marker", newJString(Marker))
  add(query_594871, "Action", newJString(Action))
  add(formData_594872, "MaxRecords", newJInt(MaxRecords))
  add(formData_594872, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594871, "Version", newJString(Version))
  result = call_594870.call(nil, query_594871, nil, formData_594872, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_594851(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_594852, base: "/",
    url: url_PostDescribeDBLogFiles_594853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_594830 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBLogFiles_594832(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_594831(path: JsonNode; query: JsonNode;
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
  var valid_594833 = query.getOrDefault("FileLastWritten")
  valid_594833 = validateParameter(valid_594833, JInt, required = false, default = nil)
  if valid_594833 != nil:
    section.add "FileLastWritten", valid_594833
  var valid_594834 = query.getOrDefault("MaxRecords")
  valid_594834 = validateParameter(valid_594834, JInt, required = false, default = nil)
  if valid_594834 != nil:
    section.add "MaxRecords", valid_594834
  var valid_594835 = query.getOrDefault("FilenameContains")
  valid_594835 = validateParameter(valid_594835, JString, required = false,
                                 default = nil)
  if valid_594835 != nil:
    section.add "FilenameContains", valid_594835
  var valid_594836 = query.getOrDefault("FileSize")
  valid_594836 = validateParameter(valid_594836, JInt, required = false, default = nil)
  if valid_594836 != nil:
    section.add "FileSize", valid_594836
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594837 = query.getOrDefault("Action")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_594837 != nil:
    section.add "Action", valid_594837
  var valid_594838 = query.getOrDefault("Marker")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "Marker", valid_594838
  var valid_594839 = query.getOrDefault("Version")
  valid_594839 = validateParameter(valid_594839, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594839 != nil:
    section.add "Version", valid_594839
  var valid_594840 = query.getOrDefault("DBInstanceIdentifier")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = nil)
  if valid_594840 != nil:
    section.add "DBInstanceIdentifier", valid_594840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594841 = header.getOrDefault("X-Amz-Date")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Date", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Security-Token")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Security-Token", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Content-Sha256", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Algorithm")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Algorithm", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Signature")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Signature", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-SignedHeaders", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Credential")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Credential", valid_594847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594848: Call_GetDescribeDBLogFiles_594830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594848.validator(path, query, header, formData, body)
  let scheme = call_594848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594848.url(scheme.get, call_594848.host, call_594848.base,
                         call_594848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594848, url, valid)

proc call*(call_594849: Call_GetDescribeDBLogFiles_594830;
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
  var query_594850 = newJObject()
  add(query_594850, "FileLastWritten", newJInt(FileLastWritten))
  add(query_594850, "MaxRecords", newJInt(MaxRecords))
  add(query_594850, "FilenameContains", newJString(FilenameContains))
  add(query_594850, "FileSize", newJInt(FileSize))
  add(query_594850, "Action", newJString(Action))
  add(query_594850, "Marker", newJString(Marker))
  add(query_594850, "Version", newJString(Version))
  add(query_594850, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594849.call(nil, query_594850, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_594830(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_594831, base: "/",
    url: url_GetDescribeDBLogFiles_594832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_594891 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameterGroups_594893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_594892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594894 = query.getOrDefault("Action")
  valid_594894 = validateParameter(valid_594894, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594894 != nil:
    section.add "Action", valid_594894
  var valid_594895 = query.getOrDefault("Version")
  valid_594895 = validateParameter(valid_594895, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594895 != nil:
    section.add "Version", valid_594895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594896 = header.getOrDefault("X-Amz-Date")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Date", valid_594896
  var valid_594897 = header.getOrDefault("X-Amz-Security-Token")
  valid_594897 = validateParameter(valid_594897, JString, required = false,
                                 default = nil)
  if valid_594897 != nil:
    section.add "X-Amz-Security-Token", valid_594897
  var valid_594898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594898 = validateParameter(valid_594898, JString, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "X-Amz-Content-Sha256", valid_594898
  var valid_594899 = header.getOrDefault("X-Amz-Algorithm")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = nil)
  if valid_594899 != nil:
    section.add "X-Amz-Algorithm", valid_594899
  var valid_594900 = header.getOrDefault("X-Amz-Signature")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "X-Amz-Signature", valid_594900
  var valid_594901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-SignedHeaders", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-Credential")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-Credential", valid_594902
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594903 = formData.getOrDefault("DBParameterGroupName")
  valid_594903 = validateParameter(valid_594903, JString, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "DBParameterGroupName", valid_594903
  var valid_594904 = formData.getOrDefault("Marker")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "Marker", valid_594904
  var valid_594905 = formData.getOrDefault("MaxRecords")
  valid_594905 = validateParameter(valid_594905, JInt, required = false, default = nil)
  if valid_594905 != nil:
    section.add "MaxRecords", valid_594905
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594906: Call_PostDescribeDBParameterGroups_594891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594906.validator(path, query, header, formData, body)
  let scheme = call_594906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594906.url(scheme.get, call_594906.host, call_594906.base,
                         call_594906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594906, url, valid)

proc call*(call_594907: Call_PostDescribeDBParameterGroups_594891;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594908 = newJObject()
  var formData_594909 = newJObject()
  add(formData_594909, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594909, "Marker", newJString(Marker))
  add(query_594908, "Action", newJString(Action))
  add(formData_594909, "MaxRecords", newJInt(MaxRecords))
  add(query_594908, "Version", newJString(Version))
  result = call_594907.call(nil, query_594908, nil, formData_594909, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_594891(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_594892, base: "/",
    url: url_PostDescribeDBParameterGroups_594893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_594873 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameterGroups_594875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_594874(path: JsonNode; query: JsonNode;
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
  var valid_594876 = query.getOrDefault("MaxRecords")
  valid_594876 = validateParameter(valid_594876, JInt, required = false, default = nil)
  if valid_594876 != nil:
    section.add "MaxRecords", valid_594876
  var valid_594877 = query.getOrDefault("DBParameterGroupName")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "DBParameterGroupName", valid_594877
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594878 = query.getOrDefault("Action")
  valid_594878 = validateParameter(valid_594878, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_594878 != nil:
    section.add "Action", valid_594878
  var valid_594879 = query.getOrDefault("Marker")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "Marker", valid_594879
  var valid_594880 = query.getOrDefault("Version")
  valid_594880 = validateParameter(valid_594880, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594880 != nil:
    section.add "Version", valid_594880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Security-Token")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Security-Token", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Content-Sha256", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Algorithm")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Algorithm", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Signature")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Signature", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-SignedHeaders", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Credential")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Credential", valid_594887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594888: Call_GetDescribeDBParameterGroups_594873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594888.validator(path, query, header, formData, body)
  let scheme = call_594888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594888.url(scheme.get, call_594888.host, call_594888.base,
                         call_594888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594888, url, valid)

proc call*(call_594889: Call_GetDescribeDBParameterGroups_594873;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594890 = newJObject()
  add(query_594890, "MaxRecords", newJInt(MaxRecords))
  add(query_594890, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594890, "Action", newJString(Action))
  add(query_594890, "Marker", newJString(Marker))
  add(query_594890, "Version", newJString(Version))
  result = call_594889.call(nil, query_594890, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_594873(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_594874, base: "/",
    url: url_GetDescribeDBParameterGroups_594875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_594929 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBParameters_594931(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_594930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594932 = query.getOrDefault("Action")
  valid_594932 = validateParameter(valid_594932, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594932 != nil:
    section.add "Action", valid_594932
  var valid_594933 = query.getOrDefault("Version")
  valid_594933 = validateParameter(valid_594933, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594933 != nil:
    section.add "Version", valid_594933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594934 = header.getOrDefault("X-Amz-Date")
  valid_594934 = validateParameter(valid_594934, JString, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "X-Amz-Date", valid_594934
  var valid_594935 = header.getOrDefault("X-Amz-Security-Token")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "X-Amz-Security-Token", valid_594935
  var valid_594936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "X-Amz-Content-Sha256", valid_594936
  var valid_594937 = header.getOrDefault("X-Amz-Algorithm")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "X-Amz-Algorithm", valid_594937
  var valid_594938 = header.getOrDefault("X-Amz-Signature")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Signature", valid_594938
  var valid_594939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "X-Amz-SignedHeaders", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Credential")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Credential", valid_594940
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_594941 = formData.getOrDefault("DBParameterGroupName")
  valid_594941 = validateParameter(valid_594941, JString, required = true,
                                 default = nil)
  if valid_594941 != nil:
    section.add "DBParameterGroupName", valid_594941
  var valid_594942 = formData.getOrDefault("Marker")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "Marker", valid_594942
  var valid_594943 = formData.getOrDefault("MaxRecords")
  valid_594943 = validateParameter(valid_594943, JInt, required = false, default = nil)
  if valid_594943 != nil:
    section.add "MaxRecords", valid_594943
  var valid_594944 = formData.getOrDefault("Source")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "Source", valid_594944
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594945: Call_PostDescribeDBParameters_594929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594945.validator(path, query, header, formData, body)
  let scheme = call_594945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594945.url(scheme.get, call_594945.host, call_594945.base,
                         call_594945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594945, url, valid)

proc call*(call_594946: Call_PostDescribeDBParameters_594929;
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
  var query_594947 = newJObject()
  var formData_594948 = newJObject()
  add(formData_594948, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_594948, "Marker", newJString(Marker))
  add(query_594947, "Action", newJString(Action))
  add(formData_594948, "MaxRecords", newJInt(MaxRecords))
  add(query_594947, "Version", newJString(Version))
  add(formData_594948, "Source", newJString(Source))
  result = call_594946.call(nil, query_594947, nil, formData_594948, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_594929(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_594930, base: "/",
    url: url_PostDescribeDBParameters_594931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_594910 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBParameters_594912(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_594911(path: JsonNode; query: JsonNode;
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
  var valid_594913 = query.getOrDefault("MaxRecords")
  valid_594913 = validateParameter(valid_594913, JInt, required = false, default = nil)
  if valid_594913 != nil:
    section.add "MaxRecords", valid_594913
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_594914 = query.getOrDefault("DBParameterGroupName")
  valid_594914 = validateParameter(valid_594914, JString, required = true,
                                 default = nil)
  if valid_594914 != nil:
    section.add "DBParameterGroupName", valid_594914
  var valid_594915 = query.getOrDefault("Action")
  valid_594915 = validateParameter(valid_594915, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_594915 != nil:
    section.add "Action", valid_594915
  var valid_594916 = query.getOrDefault("Marker")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "Marker", valid_594916
  var valid_594917 = query.getOrDefault("Source")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "Source", valid_594917
  var valid_594918 = query.getOrDefault("Version")
  valid_594918 = validateParameter(valid_594918, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594918 != nil:
    section.add "Version", valid_594918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594919 = header.getOrDefault("X-Amz-Date")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Date", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Security-Token")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Security-Token", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Content-Sha256", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Algorithm")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Algorithm", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Signature")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Signature", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-SignedHeaders", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Credential")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Credential", valid_594925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594926: Call_GetDescribeDBParameters_594910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594926.validator(path, query, header, formData, body)
  let scheme = call_594926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594926.url(scheme.get, call_594926.host, call_594926.base,
                         call_594926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594926, url, valid)

proc call*(call_594927: Call_GetDescribeDBParameters_594910;
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
  var query_594928 = newJObject()
  add(query_594928, "MaxRecords", newJInt(MaxRecords))
  add(query_594928, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_594928, "Action", newJString(Action))
  add(query_594928, "Marker", newJString(Marker))
  add(query_594928, "Source", newJString(Source))
  add(query_594928, "Version", newJString(Version))
  result = call_594927.call(nil, query_594928, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_594910(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_594911, base: "/",
    url: url_GetDescribeDBParameters_594912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_594967 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSecurityGroups_594969(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_594968(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594970 = query.getOrDefault("Action")
  valid_594970 = validateParameter(valid_594970, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594970 != nil:
    section.add "Action", valid_594970
  var valid_594971 = query.getOrDefault("Version")
  valid_594971 = validateParameter(valid_594971, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594971 != nil:
    section.add "Version", valid_594971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594972 = header.getOrDefault("X-Amz-Date")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "X-Amz-Date", valid_594972
  var valid_594973 = header.getOrDefault("X-Amz-Security-Token")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Security-Token", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Content-Sha256", valid_594974
  var valid_594975 = header.getOrDefault("X-Amz-Algorithm")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Algorithm", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Signature")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Signature", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-SignedHeaders", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Credential")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Credential", valid_594978
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_594979 = formData.getOrDefault("DBSecurityGroupName")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "DBSecurityGroupName", valid_594979
  var valid_594980 = formData.getOrDefault("Marker")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "Marker", valid_594980
  var valid_594981 = formData.getOrDefault("MaxRecords")
  valid_594981 = validateParameter(valid_594981, JInt, required = false, default = nil)
  if valid_594981 != nil:
    section.add "MaxRecords", valid_594981
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594982: Call_PostDescribeDBSecurityGroups_594967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594982.validator(path, query, header, formData, body)
  let scheme = call_594982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594982.url(scheme.get, call_594982.host, call_594982.base,
                         call_594982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594982, url, valid)

proc call*(call_594983: Call_PostDescribeDBSecurityGroups_594967;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_594984 = newJObject()
  var formData_594985 = newJObject()
  add(formData_594985, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_594985, "Marker", newJString(Marker))
  add(query_594984, "Action", newJString(Action))
  add(formData_594985, "MaxRecords", newJInt(MaxRecords))
  add(query_594984, "Version", newJString(Version))
  result = call_594983.call(nil, query_594984, nil, formData_594985, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_594967(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_594968, base: "/",
    url: url_PostDescribeDBSecurityGroups_594969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_594949 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSecurityGroups_594951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_594950(path: JsonNode; query: JsonNode;
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
  var valid_594952 = query.getOrDefault("MaxRecords")
  valid_594952 = validateParameter(valid_594952, JInt, required = false, default = nil)
  if valid_594952 != nil:
    section.add "MaxRecords", valid_594952
  var valid_594953 = query.getOrDefault("DBSecurityGroupName")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "DBSecurityGroupName", valid_594953
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594954 = query.getOrDefault("Action")
  valid_594954 = validateParameter(valid_594954, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_594954 != nil:
    section.add "Action", valid_594954
  var valid_594955 = query.getOrDefault("Marker")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "Marker", valid_594955
  var valid_594956 = query.getOrDefault("Version")
  valid_594956 = validateParameter(valid_594956, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594956 != nil:
    section.add "Version", valid_594956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594957 = header.getOrDefault("X-Amz-Date")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Date", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Security-Token")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Security-Token", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Content-Sha256", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Algorithm")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Algorithm", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Signature")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Signature", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-SignedHeaders", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-Credential")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Credential", valid_594963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594964: Call_GetDescribeDBSecurityGroups_594949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594964.validator(path, query, header, formData, body)
  let scheme = call_594964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594964.url(scheme.get, call_594964.host, call_594964.base,
                         call_594964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594964, url, valid)

proc call*(call_594965: Call_GetDescribeDBSecurityGroups_594949;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_594966 = newJObject()
  add(query_594966, "MaxRecords", newJInt(MaxRecords))
  add(query_594966, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_594966, "Action", newJString(Action))
  add(query_594966, "Marker", newJString(Marker))
  add(query_594966, "Version", newJString(Version))
  result = call_594965.call(nil, query_594966, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_594949(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_594950, base: "/",
    url: url_GetDescribeDBSecurityGroups_594951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_595006 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSnapshots_595008(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_595007(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DescribeDBSnapshots"))
  if valid_595009 != nil:
    section.add "Action", valid_595009
  var valid_595010 = query.getOrDefault("Version")
  valid_595010 = validateParameter(valid_595010, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595010 != nil:
    section.add "Version", valid_595010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595011 = header.getOrDefault("X-Amz-Date")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Date", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-Security-Token")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-Security-Token", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Content-Sha256", valid_595013
  var valid_595014 = header.getOrDefault("X-Amz-Algorithm")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = nil)
  if valid_595014 != nil:
    section.add "X-Amz-Algorithm", valid_595014
  var valid_595015 = header.getOrDefault("X-Amz-Signature")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "X-Amz-Signature", valid_595015
  var valid_595016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-SignedHeaders", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-Credential")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-Credential", valid_595017
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595018 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "DBInstanceIdentifier", valid_595018
  var valid_595019 = formData.getOrDefault("SnapshotType")
  valid_595019 = validateParameter(valid_595019, JString, required = false,
                                 default = nil)
  if valid_595019 != nil:
    section.add "SnapshotType", valid_595019
  var valid_595020 = formData.getOrDefault("Marker")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "Marker", valid_595020
  var valid_595021 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "DBSnapshotIdentifier", valid_595021
  var valid_595022 = formData.getOrDefault("MaxRecords")
  valid_595022 = validateParameter(valid_595022, JInt, required = false, default = nil)
  if valid_595022 != nil:
    section.add "MaxRecords", valid_595022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595023: Call_PostDescribeDBSnapshots_595006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595023.validator(path, query, header, formData, body)
  let scheme = call_595023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595023.url(scheme.get, call_595023.host, call_595023.base,
                         call_595023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595023, url, valid)

proc call*(call_595024: Call_PostDescribeDBSnapshots_595006;
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
  var query_595025 = newJObject()
  var formData_595026 = newJObject()
  add(formData_595026, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595026, "SnapshotType", newJString(SnapshotType))
  add(formData_595026, "Marker", newJString(Marker))
  add(formData_595026, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_595025, "Action", newJString(Action))
  add(formData_595026, "MaxRecords", newJInt(MaxRecords))
  add(query_595025, "Version", newJString(Version))
  result = call_595024.call(nil, query_595025, nil, formData_595026, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_595006(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_595007, base: "/",
    url: url_PostDescribeDBSnapshots_595008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_594986 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSnapshots_594988(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_594987(path: JsonNode; query: JsonNode;
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
  var valid_594989 = query.getOrDefault("MaxRecords")
  valid_594989 = validateParameter(valid_594989, JInt, required = false, default = nil)
  if valid_594989 != nil:
    section.add "MaxRecords", valid_594989
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594990 = query.getOrDefault("Action")
  valid_594990 = validateParameter(valid_594990, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_594990 != nil:
    section.add "Action", valid_594990
  var valid_594991 = query.getOrDefault("Marker")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "Marker", valid_594991
  var valid_594992 = query.getOrDefault("SnapshotType")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "SnapshotType", valid_594992
  var valid_594993 = query.getOrDefault("Version")
  valid_594993 = validateParameter(valid_594993, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_594993 != nil:
    section.add "Version", valid_594993
  var valid_594994 = query.getOrDefault("DBInstanceIdentifier")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "DBInstanceIdentifier", valid_594994
  var valid_594995 = query.getOrDefault("DBSnapshotIdentifier")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "DBSnapshotIdentifier", valid_594995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594996 = header.getOrDefault("X-Amz-Date")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Date", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Security-Token")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Security-Token", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Content-Sha256", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-Algorithm")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-Algorithm", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Signature")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Signature", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-SignedHeaders", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Credential")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Credential", valid_595002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595003: Call_GetDescribeDBSnapshots_594986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595003.validator(path, query, header, formData, body)
  let scheme = call_595003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595003.url(scheme.get, call_595003.host, call_595003.base,
                         call_595003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595003, url, valid)

proc call*(call_595004: Call_GetDescribeDBSnapshots_594986; MaxRecords: int = 0;
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
  var query_595005 = newJObject()
  add(query_595005, "MaxRecords", newJInt(MaxRecords))
  add(query_595005, "Action", newJString(Action))
  add(query_595005, "Marker", newJString(Marker))
  add(query_595005, "SnapshotType", newJString(SnapshotType))
  add(query_595005, "Version", newJString(Version))
  add(query_595005, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595005, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_595004.call(nil, query_595005, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_594986(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_594987, base: "/",
    url: url_GetDescribeDBSnapshots_594988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_595045 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSubnetGroups_595047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_595046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595048 = query.getOrDefault("Action")
  valid_595048 = validateParameter(valid_595048, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595048 != nil:
    section.add "Action", valid_595048
  var valid_595049 = query.getOrDefault("Version")
  valid_595049 = validateParameter(valid_595049, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595049 != nil:
    section.add "Version", valid_595049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595050 = header.getOrDefault("X-Amz-Date")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Date", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Security-Token")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Security-Token", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Content-Sha256", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Algorithm")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Algorithm", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-Signature")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-Signature", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-SignedHeaders", valid_595055
  var valid_595056 = header.getOrDefault("X-Amz-Credential")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "X-Amz-Credential", valid_595056
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595057 = formData.getOrDefault("DBSubnetGroupName")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "DBSubnetGroupName", valid_595057
  var valid_595058 = formData.getOrDefault("Marker")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "Marker", valid_595058
  var valid_595059 = formData.getOrDefault("MaxRecords")
  valid_595059 = validateParameter(valid_595059, JInt, required = false, default = nil)
  if valid_595059 != nil:
    section.add "MaxRecords", valid_595059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595060: Call_PostDescribeDBSubnetGroups_595045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595060.validator(path, query, header, formData, body)
  let scheme = call_595060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595060.url(scheme.get, call_595060.host, call_595060.base,
                         call_595060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595060, url, valid)

proc call*(call_595061: Call_PostDescribeDBSubnetGroups_595045;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595062 = newJObject()
  var formData_595063 = newJObject()
  add(formData_595063, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_595063, "Marker", newJString(Marker))
  add(query_595062, "Action", newJString(Action))
  add(formData_595063, "MaxRecords", newJInt(MaxRecords))
  add(query_595062, "Version", newJString(Version))
  result = call_595061.call(nil, query_595062, nil, formData_595063, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_595045(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_595046, base: "/",
    url: url_PostDescribeDBSubnetGroups_595047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_595027 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSubnetGroups_595029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_595028(path: JsonNode; query: JsonNode;
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
  var valid_595030 = query.getOrDefault("MaxRecords")
  valid_595030 = validateParameter(valid_595030, JInt, required = false, default = nil)
  if valid_595030 != nil:
    section.add "MaxRecords", valid_595030
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595031 = query.getOrDefault("Action")
  valid_595031 = validateParameter(valid_595031, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_595031 != nil:
    section.add "Action", valid_595031
  var valid_595032 = query.getOrDefault("Marker")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "Marker", valid_595032
  var valid_595033 = query.getOrDefault("DBSubnetGroupName")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "DBSubnetGroupName", valid_595033
  var valid_595034 = query.getOrDefault("Version")
  valid_595034 = validateParameter(valid_595034, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595034 != nil:
    section.add "Version", valid_595034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595035 = header.getOrDefault("X-Amz-Date")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Date", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Security-Token")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Security-Token", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-Content-Sha256", valid_595037
  var valid_595038 = header.getOrDefault("X-Amz-Algorithm")
  valid_595038 = validateParameter(valid_595038, JString, required = false,
                                 default = nil)
  if valid_595038 != nil:
    section.add "X-Amz-Algorithm", valid_595038
  var valid_595039 = header.getOrDefault("X-Amz-Signature")
  valid_595039 = validateParameter(valid_595039, JString, required = false,
                                 default = nil)
  if valid_595039 != nil:
    section.add "X-Amz-Signature", valid_595039
  var valid_595040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-SignedHeaders", valid_595040
  var valid_595041 = header.getOrDefault("X-Amz-Credential")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "X-Amz-Credential", valid_595041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595042: Call_GetDescribeDBSubnetGroups_595027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595042.validator(path, query, header, formData, body)
  let scheme = call_595042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595042.url(scheme.get, call_595042.host, call_595042.base,
                         call_595042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595042, url, valid)

proc call*(call_595043: Call_GetDescribeDBSubnetGroups_595027; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_595044 = newJObject()
  add(query_595044, "MaxRecords", newJInt(MaxRecords))
  add(query_595044, "Action", newJString(Action))
  add(query_595044, "Marker", newJString(Marker))
  add(query_595044, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595044, "Version", newJString(Version))
  result = call_595043.call(nil, query_595044, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_595027(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_595028, base: "/",
    url: url_GetDescribeDBSubnetGroups_595029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_595082 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEngineDefaultParameters_595084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_595083(path: JsonNode;
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
  var valid_595085 = query.getOrDefault("Action")
  valid_595085 = validateParameter(valid_595085, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595085 != nil:
    section.add "Action", valid_595085
  var valid_595086 = query.getOrDefault("Version")
  valid_595086 = validateParameter(valid_595086, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595086 != nil:
    section.add "Version", valid_595086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595087 = header.getOrDefault("X-Amz-Date")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Date", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Security-Token")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Security-Token", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Content-Sha256", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-Algorithm")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-Algorithm", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-Signature")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Signature", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-SignedHeaders", valid_595092
  var valid_595093 = header.getOrDefault("X-Amz-Credential")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "X-Amz-Credential", valid_595093
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595094 = formData.getOrDefault("Marker")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "Marker", valid_595094
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595095 = formData.getOrDefault("DBParameterGroupFamily")
  valid_595095 = validateParameter(valid_595095, JString, required = true,
                                 default = nil)
  if valid_595095 != nil:
    section.add "DBParameterGroupFamily", valid_595095
  var valid_595096 = formData.getOrDefault("MaxRecords")
  valid_595096 = validateParameter(valid_595096, JInt, required = false, default = nil)
  if valid_595096 != nil:
    section.add "MaxRecords", valid_595096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595097: Call_PostDescribeEngineDefaultParameters_595082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595097.validator(path, query, header, formData, body)
  let scheme = call_595097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595097.url(scheme.get, call_595097.host, call_595097.base,
                         call_595097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595097, url, valid)

proc call*(call_595098: Call_PostDescribeEngineDefaultParameters_595082;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595099 = newJObject()
  var formData_595100 = newJObject()
  add(formData_595100, "Marker", newJString(Marker))
  add(query_595099, "Action", newJString(Action))
  add(formData_595100, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_595100, "MaxRecords", newJInt(MaxRecords))
  add(query_595099, "Version", newJString(Version))
  result = call_595098.call(nil, query_595099, nil, formData_595100, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_595082(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_595083, base: "/",
    url: url_PostDescribeEngineDefaultParameters_595084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_595064 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEngineDefaultParameters_595066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_595065(path: JsonNode;
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
  var valid_595067 = query.getOrDefault("MaxRecords")
  valid_595067 = validateParameter(valid_595067, JInt, required = false, default = nil)
  if valid_595067 != nil:
    section.add "MaxRecords", valid_595067
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_595068 = query.getOrDefault("DBParameterGroupFamily")
  valid_595068 = validateParameter(valid_595068, JString, required = true,
                                 default = nil)
  if valid_595068 != nil:
    section.add "DBParameterGroupFamily", valid_595068
  var valid_595069 = query.getOrDefault("Action")
  valid_595069 = validateParameter(valid_595069, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_595069 != nil:
    section.add "Action", valid_595069
  var valid_595070 = query.getOrDefault("Marker")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "Marker", valid_595070
  var valid_595071 = query.getOrDefault("Version")
  valid_595071 = validateParameter(valid_595071, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595071 != nil:
    section.add "Version", valid_595071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595072 = header.getOrDefault("X-Amz-Date")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-Date", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Security-Token")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Security-Token", valid_595073
  var valid_595074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Content-Sha256", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-Algorithm")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-Algorithm", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Signature")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Signature", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-SignedHeaders", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Credential")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Credential", valid_595078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595079: Call_GetDescribeEngineDefaultParameters_595064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595079.validator(path, query, header, formData, body)
  let scheme = call_595079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595079.url(scheme.get, call_595079.host, call_595079.base,
                         call_595079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595079, url, valid)

proc call*(call_595080: Call_GetDescribeEngineDefaultParameters_595064;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_595081 = newJObject()
  add(query_595081, "MaxRecords", newJInt(MaxRecords))
  add(query_595081, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_595081, "Action", newJString(Action))
  add(query_595081, "Marker", newJString(Marker))
  add(query_595081, "Version", newJString(Version))
  result = call_595080.call(nil, query_595081, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_595064(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_595065, base: "/",
    url: url_GetDescribeEngineDefaultParameters_595066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_595117 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventCategories_595119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_595118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595120 = query.getOrDefault("Action")
  valid_595120 = validateParameter(valid_595120, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595120 != nil:
    section.add "Action", valid_595120
  var valid_595121 = query.getOrDefault("Version")
  valid_595121 = validateParameter(valid_595121, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595121 != nil:
    section.add "Version", valid_595121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595122 = header.getOrDefault("X-Amz-Date")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "X-Amz-Date", valid_595122
  var valid_595123 = header.getOrDefault("X-Amz-Security-Token")
  valid_595123 = validateParameter(valid_595123, JString, required = false,
                                 default = nil)
  if valid_595123 != nil:
    section.add "X-Amz-Security-Token", valid_595123
  var valid_595124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Content-Sha256", valid_595124
  var valid_595125 = header.getOrDefault("X-Amz-Algorithm")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Algorithm", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Signature")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Signature", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-SignedHeaders", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Credential")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Credential", valid_595128
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_595129 = formData.getOrDefault("SourceType")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "SourceType", valid_595129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595130: Call_PostDescribeEventCategories_595117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595130.validator(path, query, header, formData, body)
  let scheme = call_595130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595130.url(scheme.get, call_595130.host, call_595130.base,
                         call_595130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595130, url, valid)

proc call*(call_595131: Call_PostDescribeEventCategories_595117;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_595132 = newJObject()
  var formData_595133 = newJObject()
  add(query_595132, "Action", newJString(Action))
  add(query_595132, "Version", newJString(Version))
  add(formData_595133, "SourceType", newJString(SourceType))
  result = call_595131.call(nil, query_595132, nil, formData_595133, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_595117(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_595118, base: "/",
    url: url_PostDescribeEventCategories_595119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_595101 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventCategories_595103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_595102(path: JsonNode; query: JsonNode;
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
  var valid_595104 = query.getOrDefault("SourceType")
  valid_595104 = validateParameter(valid_595104, JString, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "SourceType", valid_595104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595105 = query.getOrDefault("Action")
  valid_595105 = validateParameter(valid_595105, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_595105 != nil:
    section.add "Action", valid_595105
  var valid_595106 = query.getOrDefault("Version")
  valid_595106 = validateParameter(valid_595106, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595106 != nil:
    section.add "Version", valid_595106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595107 = header.getOrDefault("X-Amz-Date")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "X-Amz-Date", valid_595107
  var valid_595108 = header.getOrDefault("X-Amz-Security-Token")
  valid_595108 = validateParameter(valid_595108, JString, required = false,
                                 default = nil)
  if valid_595108 != nil:
    section.add "X-Amz-Security-Token", valid_595108
  var valid_595109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Content-Sha256", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Algorithm")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Algorithm", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Signature")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Signature", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-SignedHeaders", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Credential")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Credential", valid_595113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595114: Call_GetDescribeEventCategories_595101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595114.validator(path, query, header, formData, body)
  let scheme = call_595114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595114.url(scheme.get, call_595114.host, call_595114.base,
                         call_595114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595114, url, valid)

proc call*(call_595115: Call_GetDescribeEventCategories_595101;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595116 = newJObject()
  add(query_595116, "SourceType", newJString(SourceType))
  add(query_595116, "Action", newJString(Action))
  add(query_595116, "Version", newJString(Version))
  result = call_595115.call(nil, query_595116, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_595101(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_595102, base: "/",
    url: url_GetDescribeEventCategories_595103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_595152 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventSubscriptions_595154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_595153(path: JsonNode;
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
  var valid_595155 = query.getOrDefault("Action")
  valid_595155 = validateParameter(valid_595155, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595155 != nil:
    section.add "Action", valid_595155
  var valid_595156 = query.getOrDefault("Version")
  valid_595156 = validateParameter(valid_595156, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595156 != nil:
    section.add "Version", valid_595156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595157 = header.getOrDefault("X-Amz-Date")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Date", valid_595157
  var valid_595158 = header.getOrDefault("X-Amz-Security-Token")
  valid_595158 = validateParameter(valid_595158, JString, required = false,
                                 default = nil)
  if valid_595158 != nil:
    section.add "X-Amz-Security-Token", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Content-Sha256", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Algorithm")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Algorithm", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Signature")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Signature", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-SignedHeaders", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Credential")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Credential", valid_595163
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595164 = formData.getOrDefault("Marker")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "Marker", valid_595164
  var valid_595165 = formData.getOrDefault("SubscriptionName")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "SubscriptionName", valid_595165
  var valid_595166 = formData.getOrDefault("MaxRecords")
  valid_595166 = validateParameter(valid_595166, JInt, required = false, default = nil)
  if valid_595166 != nil:
    section.add "MaxRecords", valid_595166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595167: Call_PostDescribeEventSubscriptions_595152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595167.validator(path, query, header, formData, body)
  let scheme = call_595167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595167.url(scheme.get, call_595167.host, call_595167.base,
                         call_595167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595167, url, valid)

proc call*(call_595168: Call_PostDescribeEventSubscriptions_595152;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_595169 = newJObject()
  var formData_595170 = newJObject()
  add(formData_595170, "Marker", newJString(Marker))
  add(formData_595170, "SubscriptionName", newJString(SubscriptionName))
  add(query_595169, "Action", newJString(Action))
  add(formData_595170, "MaxRecords", newJInt(MaxRecords))
  add(query_595169, "Version", newJString(Version))
  result = call_595168.call(nil, query_595169, nil, formData_595170, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_595152(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_595153, base: "/",
    url: url_PostDescribeEventSubscriptions_595154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_595134 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventSubscriptions_595136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_595135(path: JsonNode; query: JsonNode;
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
  var valid_595137 = query.getOrDefault("MaxRecords")
  valid_595137 = validateParameter(valid_595137, JInt, required = false, default = nil)
  if valid_595137 != nil:
    section.add "MaxRecords", valid_595137
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595138 = query.getOrDefault("Action")
  valid_595138 = validateParameter(valid_595138, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_595138 != nil:
    section.add "Action", valid_595138
  var valid_595139 = query.getOrDefault("Marker")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "Marker", valid_595139
  var valid_595140 = query.getOrDefault("SubscriptionName")
  valid_595140 = validateParameter(valid_595140, JString, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "SubscriptionName", valid_595140
  var valid_595141 = query.getOrDefault("Version")
  valid_595141 = validateParameter(valid_595141, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595141 != nil:
    section.add "Version", valid_595141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595142 = header.getOrDefault("X-Amz-Date")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Date", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Security-Token")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Security-Token", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Content-Sha256", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Algorithm")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Algorithm", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Signature")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Signature", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-SignedHeaders", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Credential")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Credential", valid_595148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595149: Call_GetDescribeEventSubscriptions_595134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595149.validator(path, query, header, formData, body)
  let scheme = call_595149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595149.url(scheme.get, call_595149.host, call_595149.base,
                         call_595149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595149, url, valid)

proc call*(call_595150: Call_GetDescribeEventSubscriptions_595134;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_595151 = newJObject()
  add(query_595151, "MaxRecords", newJInt(MaxRecords))
  add(query_595151, "Action", newJString(Action))
  add(query_595151, "Marker", newJString(Marker))
  add(query_595151, "SubscriptionName", newJString(SubscriptionName))
  add(query_595151, "Version", newJString(Version))
  result = call_595150.call(nil, query_595151, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_595134(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_595135, base: "/",
    url: url_GetDescribeEventSubscriptions_595136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_595194 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEvents_595196(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_595195(path: JsonNode; query: JsonNode;
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
  var valid_595197 = query.getOrDefault("Action")
  valid_595197 = validateParameter(valid_595197, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595197 != nil:
    section.add "Action", valid_595197
  var valid_595198 = query.getOrDefault("Version")
  valid_595198 = validateParameter(valid_595198, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_595206 = formData.getOrDefault("SourceIdentifier")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "SourceIdentifier", valid_595206
  var valid_595207 = formData.getOrDefault("EventCategories")
  valid_595207 = validateParameter(valid_595207, JArray, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "EventCategories", valid_595207
  var valid_595208 = formData.getOrDefault("Marker")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "Marker", valid_595208
  var valid_595209 = formData.getOrDefault("StartTime")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "StartTime", valid_595209
  var valid_595210 = formData.getOrDefault("Duration")
  valid_595210 = validateParameter(valid_595210, JInt, required = false, default = nil)
  if valid_595210 != nil:
    section.add "Duration", valid_595210
  var valid_595211 = formData.getOrDefault("EndTime")
  valid_595211 = validateParameter(valid_595211, JString, required = false,
                                 default = nil)
  if valid_595211 != nil:
    section.add "EndTime", valid_595211
  var valid_595212 = formData.getOrDefault("MaxRecords")
  valid_595212 = validateParameter(valid_595212, JInt, required = false, default = nil)
  if valid_595212 != nil:
    section.add "MaxRecords", valid_595212
  var valid_595213 = formData.getOrDefault("SourceType")
  valid_595213 = validateParameter(valid_595213, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595213 != nil:
    section.add "SourceType", valid_595213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595214: Call_PostDescribeEvents_595194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595214.validator(path, query, header, formData, body)
  let scheme = call_595214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595214.url(scheme.get, call_595214.host, call_595214.base,
                         call_595214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595214, url, valid)

proc call*(call_595215: Call_PostDescribeEvents_595194;
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
  var query_595216 = newJObject()
  var formData_595217 = newJObject()
  add(formData_595217, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_595217.add "EventCategories", EventCategories
  add(formData_595217, "Marker", newJString(Marker))
  add(formData_595217, "StartTime", newJString(StartTime))
  add(query_595216, "Action", newJString(Action))
  add(formData_595217, "Duration", newJInt(Duration))
  add(formData_595217, "EndTime", newJString(EndTime))
  add(formData_595217, "MaxRecords", newJInt(MaxRecords))
  add(query_595216, "Version", newJString(Version))
  add(formData_595217, "SourceType", newJString(SourceType))
  result = call_595215.call(nil, query_595216, nil, formData_595217, nil)

var postDescribeEvents* = Call_PostDescribeEvents_595194(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_595195, base: "/",
    url: url_PostDescribeEvents_595196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_595171 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEvents_595173(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_595172(path: JsonNode; query: JsonNode;
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
  var valid_595174 = query.getOrDefault("SourceType")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595174 != nil:
    section.add "SourceType", valid_595174
  var valid_595175 = query.getOrDefault("MaxRecords")
  valid_595175 = validateParameter(valid_595175, JInt, required = false, default = nil)
  if valid_595175 != nil:
    section.add "MaxRecords", valid_595175
  var valid_595176 = query.getOrDefault("StartTime")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "StartTime", valid_595176
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595177 = query.getOrDefault("Action")
  valid_595177 = validateParameter(valid_595177, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595177 != nil:
    section.add "Action", valid_595177
  var valid_595178 = query.getOrDefault("SourceIdentifier")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "SourceIdentifier", valid_595178
  var valid_595179 = query.getOrDefault("Marker")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "Marker", valid_595179
  var valid_595180 = query.getOrDefault("EventCategories")
  valid_595180 = validateParameter(valid_595180, JArray, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "EventCategories", valid_595180
  var valid_595181 = query.getOrDefault("Duration")
  valid_595181 = validateParameter(valid_595181, JInt, required = false, default = nil)
  if valid_595181 != nil:
    section.add "Duration", valid_595181
  var valid_595182 = query.getOrDefault("EndTime")
  valid_595182 = validateParameter(valid_595182, JString, required = false,
                                 default = nil)
  if valid_595182 != nil:
    section.add "EndTime", valid_595182
  var valid_595183 = query.getOrDefault("Version")
  valid_595183 = validateParameter(valid_595183, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595183 != nil:
    section.add "Version", valid_595183
  result.add "query", section
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

proc call*(call_595191: Call_GetDescribeEvents_595171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595191.validator(path, query, header, formData, body)
  let scheme = call_595191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595191.url(scheme.get, call_595191.host, call_595191.base,
                         call_595191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595191, url, valid)

proc call*(call_595192: Call_GetDescribeEvents_595171;
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
  var query_595193 = newJObject()
  add(query_595193, "SourceType", newJString(SourceType))
  add(query_595193, "MaxRecords", newJInt(MaxRecords))
  add(query_595193, "StartTime", newJString(StartTime))
  add(query_595193, "Action", newJString(Action))
  add(query_595193, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595193, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_595193.add "EventCategories", EventCategories
  add(query_595193, "Duration", newJInt(Duration))
  add(query_595193, "EndTime", newJString(EndTime))
  add(query_595193, "Version", newJString(Version))
  result = call_595192.call(nil, query_595193, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_595171(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_595172,
    base: "/", url: url_GetDescribeEvents_595173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_595237 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroupOptions_595239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_595238(path: JsonNode;
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
  var valid_595240 = query.getOrDefault("Action")
  valid_595240 = validateParameter(valid_595240, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595240 != nil:
    section.add "Action", valid_595240
  var valid_595241 = query.getOrDefault("Version")
  valid_595241 = validateParameter(valid_595241, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595241 != nil:
    section.add "Version", valid_595241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595242 = header.getOrDefault("X-Amz-Date")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Date", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-Security-Token")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-Security-Token", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-Content-Sha256", valid_595244
  var valid_595245 = header.getOrDefault("X-Amz-Algorithm")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "X-Amz-Algorithm", valid_595245
  var valid_595246 = header.getOrDefault("X-Amz-Signature")
  valid_595246 = validateParameter(valid_595246, JString, required = false,
                                 default = nil)
  if valid_595246 != nil:
    section.add "X-Amz-Signature", valid_595246
  var valid_595247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "X-Amz-SignedHeaders", valid_595247
  var valid_595248 = header.getOrDefault("X-Amz-Credential")
  valid_595248 = validateParameter(valid_595248, JString, required = false,
                                 default = nil)
  if valid_595248 != nil:
    section.add "X-Amz-Credential", valid_595248
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595249 = formData.getOrDefault("MajorEngineVersion")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "MajorEngineVersion", valid_595249
  var valid_595250 = formData.getOrDefault("Marker")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "Marker", valid_595250
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_595251 = formData.getOrDefault("EngineName")
  valid_595251 = validateParameter(valid_595251, JString, required = true,
                                 default = nil)
  if valid_595251 != nil:
    section.add "EngineName", valid_595251
  var valid_595252 = formData.getOrDefault("MaxRecords")
  valid_595252 = validateParameter(valid_595252, JInt, required = false, default = nil)
  if valid_595252 != nil:
    section.add "MaxRecords", valid_595252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595253: Call_PostDescribeOptionGroupOptions_595237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595253.validator(path, query, header, formData, body)
  let scheme = call_595253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595253.url(scheme.get, call_595253.host, call_595253.base,
                         call_595253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595253, url, valid)

proc call*(call_595254: Call_PostDescribeOptionGroupOptions_595237;
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
  var query_595255 = newJObject()
  var formData_595256 = newJObject()
  add(formData_595256, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595256, "Marker", newJString(Marker))
  add(query_595255, "Action", newJString(Action))
  add(formData_595256, "EngineName", newJString(EngineName))
  add(formData_595256, "MaxRecords", newJInt(MaxRecords))
  add(query_595255, "Version", newJString(Version))
  result = call_595254.call(nil, query_595255, nil, formData_595256, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_595237(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_595238, base: "/",
    url: url_PostDescribeOptionGroupOptions_595239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_595218 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroupOptions_595220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_595219(path: JsonNode; query: JsonNode;
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
  var valid_595221 = query.getOrDefault("MaxRecords")
  valid_595221 = validateParameter(valid_595221, JInt, required = false, default = nil)
  if valid_595221 != nil:
    section.add "MaxRecords", valid_595221
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595222 = query.getOrDefault("Action")
  valid_595222 = validateParameter(valid_595222, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_595222 != nil:
    section.add "Action", valid_595222
  var valid_595223 = query.getOrDefault("Marker")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "Marker", valid_595223
  var valid_595224 = query.getOrDefault("Version")
  valid_595224 = validateParameter(valid_595224, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595224 != nil:
    section.add "Version", valid_595224
  var valid_595225 = query.getOrDefault("EngineName")
  valid_595225 = validateParameter(valid_595225, JString, required = true,
                                 default = nil)
  if valid_595225 != nil:
    section.add "EngineName", valid_595225
  var valid_595226 = query.getOrDefault("MajorEngineVersion")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "MajorEngineVersion", valid_595226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595227 = header.getOrDefault("X-Amz-Date")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-Date", valid_595227
  var valid_595228 = header.getOrDefault("X-Amz-Security-Token")
  valid_595228 = validateParameter(valid_595228, JString, required = false,
                                 default = nil)
  if valid_595228 != nil:
    section.add "X-Amz-Security-Token", valid_595228
  var valid_595229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595229 = validateParameter(valid_595229, JString, required = false,
                                 default = nil)
  if valid_595229 != nil:
    section.add "X-Amz-Content-Sha256", valid_595229
  var valid_595230 = header.getOrDefault("X-Amz-Algorithm")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Algorithm", valid_595230
  var valid_595231 = header.getOrDefault("X-Amz-Signature")
  valid_595231 = validateParameter(valid_595231, JString, required = false,
                                 default = nil)
  if valid_595231 != nil:
    section.add "X-Amz-Signature", valid_595231
  var valid_595232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-SignedHeaders", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Credential")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Credential", valid_595233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595234: Call_GetDescribeOptionGroupOptions_595218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595234.validator(path, query, header, formData, body)
  let scheme = call_595234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595234.url(scheme.get, call_595234.host, call_595234.base,
                         call_595234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595234, url, valid)

proc call*(call_595235: Call_GetDescribeOptionGroupOptions_595218;
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
  var query_595236 = newJObject()
  add(query_595236, "MaxRecords", newJInt(MaxRecords))
  add(query_595236, "Action", newJString(Action))
  add(query_595236, "Marker", newJString(Marker))
  add(query_595236, "Version", newJString(Version))
  add(query_595236, "EngineName", newJString(EngineName))
  add(query_595236, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595235.call(nil, query_595236, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_595218(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_595219, base: "/",
    url: url_GetDescribeOptionGroupOptions_595220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_595277 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOptionGroups_595279(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_595278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_595280 = validateParameter(valid_595280, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595280 != nil:
    section.add "Action", valid_595280
  var valid_595281 = query.getOrDefault("Version")
  valid_595281 = validateParameter(valid_595281, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_595289 = formData.getOrDefault("MajorEngineVersion")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "MajorEngineVersion", valid_595289
  var valid_595290 = formData.getOrDefault("OptionGroupName")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "OptionGroupName", valid_595290
  var valid_595291 = formData.getOrDefault("Marker")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "Marker", valid_595291
  var valid_595292 = formData.getOrDefault("EngineName")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "EngineName", valid_595292
  var valid_595293 = formData.getOrDefault("MaxRecords")
  valid_595293 = validateParameter(valid_595293, JInt, required = false, default = nil)
  if valid_595293 != nil:
    section.add "MaxRecords", valid_595293
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595294: Call_PostDescribeOptionGroups_595277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595294.validator(path, query, header, formData, body)
  let scheme = call_595294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595294.url(scheme.get, call_595294.host, call_595294.base,
                         call_595294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595294, url, valid)

proc call*(call_595295: Call_PostDescribeOptionGroups_595277;
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
  var query_595296 = newJObject()
  var formData_595297 = newJObject()
  add(formData_595297, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_595297, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595297, "Marker", newJString(Marker))
  add(query_595296, "Action", newJString(Action))
  add(formData_595297, "EngineName", newJString(EngineName))
  add(formData_595297, "MaxRecords", newJInt(MaxRecords))
  add(query_595296, "Version", newJString(Version))
  result = call_595295.call(nil, query_595296, nil, formData_595297, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_595277(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_595278, base: "/",
    url: url_PostDescribeOptionGroups_595279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_595257 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOptionGroups_595259(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_595258(path: JsonNode; query: JsonNode;
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
  var valid_595260 = query.getOrDefault("MaxRecords")
  valid_595260 = validateParameter(valid_595260, JInt, required = false, default = nil)
  if valid_595260 != nil:
    section.add "MaxRecords", valid_595260
  var valid_595261 = query.getOrDefault("OptionGroupName")
  valid_595261 = validateParameter(valid_595261, JString, required = false,
                                 default = nil)
  if valid_595261 != nil:
    section.add "OptionGroupName", valid_595261
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595262 = query.getOrDefault("Action")
  valid_595262 = validateParameter(valid_595262, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_595262 != nil:
    section.add "Action", valid_595262
  var valid_595263 = query.getOrDefault("Marker")
  valid_595263 = validateParameter(valid_595263, JString, required = false,
                                 default = nil)
  if valid_595263 != nil:
    section.add "Marker", valid_595263
  var valid_595264 = query.getOrDefault("Version")
  valid_595264 = validateParameter(valid_595264, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595264 != nil:
    section.add "Version", valid_595264
  var valid_595265 = query.getOrDefault("EngineName")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "EngineName", valid_595265
  var valid_595266 = query.getOrDefault("MajorEngineVersion")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "MajorEngineVersion", valid_595266
  result.add "query", section
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

proc call*(call_595274: Call_GetDescribeOptionGroups_595257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595274.validator(path, query, header, formData, body)
  let scheme = call_595274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595274.url(scheme.get, call_595274.host, call_595274.base,
                         call_595274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595274, url, valid)

proc call*(call_595275: Call_GetDescribeOptionGroups_595257; MaxRecords: int = 0;
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
  var query_595276 = newJObject()
  add(query_595276, "MaxRecords", newJInt(MaxRecords))
  add(query_595276, "OptionGroupName", newJString(OptionGroupName))
  add(query_595276, "Action", newJString(Action))
  add(query_595276, "Marker", newJString(Marker))
  add(query_595276, "Version", newJString(Version))
  add(query_595276, "EngineName", newJString(EngineName))
  add(query_595276, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_595275.call(nil, query_595276, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_595257(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_595258, base: "/",
    url: url_GetDescribeOptionGroups_595259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_595320 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOrderableDBInstanceOptions_595322(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_595321(path: JsonNode;
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
  var valid_595323 = query.getOrDefault("Action")
  valid_595323 = validateParameter(valid_595323, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595323 != nil:
    section.add "Action", valid_595323
  var valid_595324 = query.getOrDefault("Version")
  valid_595324 = validateParameter(valid_595324, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595324 != nil:
    section.add "Version", valid_595324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595325 = header.getOrDefault("X-Amz-Date")
  valid_595325 = validateParameter(valid_595325, JString, required = false,
                                 default = nil)
  if valid_595325 != nil:
    section.add "X-Amz-Date", valid_595325
  var valid_595326 = header.getOrDefault("X-Amz-Security-Token")
  valid_595326 = validateParameter(valid_595326, JString, required = false,
                                 default = nil)
  if valid_595326 != nil:
    section.add "X-Amz-Security-Token", valid_595326
  var valid_595327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595327 = validateParameter(valid_595327, JString, required = false,
                                 default = nil)
  if valid_595327 != nil:
    section.add "X-Amz-Content-Sha256", valid_595327
  var valid_595328 = header.getOrDefault("X-Amz-Algorithm")
  valid_595328 = validateParameter(valid_595328, JString, required = false,
                                 default = nil)
  if valid_595328 != nil:
    section.add "X-Amz-Algorithm", valid_595328
  var valid_595329 = header.getOrDefault("X-Amz-Signature")
  valid_595329 = validateParameter(valid_595329, JString, required = false,
                                 default = nil)
  if valid_595329 != nil:
    section.add "X-Amz-Signature", valid_595329
  var valid_595330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595330 = validateParameter(valid_595330, JString, required = false,
                                 default = nil)
  if valid_595330 != nil:
    section.add "X-Amz-SignedHeaders", valid_595330
  var valid_595331 = header.getOrDefault("X-Amz-Credential")
  valid_595331 = validateParameter(valid_595331, JString, required = false,
                                 default = nil)
  if valid_595331 != nil:
    section.add "X-Amz-Credential", valid_595331
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
  var valid_595332 = formData.getOrDefault("Engine")
  valid_595332 = validateParameter(valid_595332, JString, required = true,
                                 default = nil)
  if valid_595332 != nil:
    section.add "Engine", valid_595332
  var valid_595333 = formData.getOrDefault("Marker")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "Marker", valid_595333
  var valid_595334 = formData.getOrDefault("Vpc")
  valid_595334 = validateParameter(valid_595334, JBool, required = false, default = nil)
  if valid_595334 != nil:
    section.add "Vpc", valid_595334
  var valid_595335 = formData.getOrDefault("DBInstanceClass")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "DBInstanceClass", valid_595335
  var valid_595336 = formData.getOrDefault("LicenseModel")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "LicenseModel", valid_595336
  var valid_595337 = formData.getOrDefault("MaxRecords")
  valid_595337 = validateParameter(valid_595337, JInt, required = false, default = nil)
  if valid_595337 != nil:
    section.add "MaxRecords", valid_595337
  var valid_595338 = formData.getOrDefault("EngineVersion")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "EngineVersion", valid_595338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595339: Call_PostDescribeOrderableDBInstanceOptions_595320;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595339.validator(path, query, header, formData, body)
  let scheme = call_595339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595339.url(scheme.get, call_595339.host, call_595339.base,
                         call_595339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595339, url, valid)

proc call*(call_595340: Call_PostDescribeOrderableDBInstanceOptions_595320;
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
  var query_595341 = newJObject()
  var formData_595342 = newJObject()
  add(formData_595342, "Engine", newJString(Engine))
  add(formData_595342, "Marker", newJString(Marker))
  add(query_595341, "Action", newJString(Action))
  add(formData_595342, "Vpc", newJBool(Vpc))
  add(formData_595342, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595342, "LicenseModel", newJString(LicenseModel))
  add(formData_595342, "MaxRecords", newJInt(MaxRecords))
  add(formData_595342, "EngineVersion", newJString(EngineVersion))
  add(query_595341, "Version", newJString(Version))
  result = call_595340.call(nil, query_595341, nil, formData_595342, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_595320(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_595321, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_595322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_595298 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOrderableDBInstanceOptions_595300(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_595299(path: JsonNode;
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
  var valid_595301 = query.getOrDefault("Engine")
  valid_595301 = validateParameter(valid_595301, JString, required = true,
                                 default = nil)
  if valid_595301 != nil:
    section.add "Engine", valid_595301
  var valid_595302 = query.getOrDefault("MaxRecords")
  valid_595302 = validateParameter(valid_595302, JInt, required = false, default = nil)
  if valid_595302 != nil:
    section.add "MaxRecords", valid_595302
  var valid_595303 = query.getOrDefault("LicenseModel")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "LicenseModel", valid_595303
  var valid_595304 = query.getOrDefault("Vpc")
  valid_595304 = validateParameter(valid_595304, JBool, required = false, default = nil)
  if valid_595304 != nil:
    section.add "Vpc", valid_595304
  var valid_595305 = query.getOrDefault("DBInstanceClass")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "DBInstanceClass", valid_595305
  var valid_595306 = query.getOrDefault("Action")
  valid_595306 = validateParameter(valid_595306, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595306 != nil:
    section.add "Action", valid_595306
  var valid_595307 = query.getOrDefault("Marker")
  valid_595307 = validateParameter(valid_595307, JString, required = false,
                                 default = nil)
  if valid_595307 != nil:
    section.add "Marker", valid_595307
  var valid_595308 = query.getOrDefault("EngineVersion")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "EngineVersion", valid_595308
  var valid_595309 = query.getOrDefault("Version")
  valid_595309 = validateParameter(valid_595309, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595309 != nil:
    section.add "Version", valid_595309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595310 = header.getOrDefault("X-Amz-Date")
  valid_595310 = validateParameter(valid_595310, JString, required = false,
                                 default = nil)
  if valid_595310 != nil:
    section.add "X-Amz-Date", valid_595310
  var valid_595311 = header.getOrDefault("X-Amz-Security-Token")
  valid_595311 = validateParameter(valid_595311, JString, required = false,
                                 default = nil)
  if valid_595311 != nil:
    section.add "X-Amz-Security-Token", valid_595311
  var valid_595312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595312 = validateParameter(valid_595312, JString, required = false,
                                 default = nil)
  if valid_595312 != nil:
    section.add "X-Amz-Content-Sha256", valid_595312
  var valid_595313 = header.getOrDefault("X-Amz-Algorithm")
  valid_595313 = validateParameter(valid_595313, JString, required = false,
                                 default = nil)
  if valid_595313 != nil:
    section.add "X-Amz-Algorithm", valid_595313
  var valid_595314 = header.getOrDefault("X-Amz-Signature")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Signature", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-SignedHeaders", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-Credential")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-Credential", valid_595316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595317: Call_GetDescribeOrderableDBInstanceOptions_595298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595317.validator(path, query, header, formData, body)
  let scheme = call_595317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595317.url(scheme.get, call_595317.host, call_595317.base,
                         call_595317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595317, url, valid)

proc call*(call_595318: Call_GetDescribeOrderableDBInstanceOptions_595298;
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
  var query_595319 = newJObject()
  add(query_595319, "Engine", newJString(Engine))
  add(query_595319, "MaxRecords", newJInt(MaxRecords))
  add(query_595319, "LicenseModel", newJString(LicenseModel))
  add(query_595319, "Vpc", newJBool(Vpc))
  add(query_595319, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595319, "Action", newJString(Action))
  add(query_595319, "Marker", newJString(Marker))
  add(query_595319, "EngineVersion", newJString(EngineVersion))
  add(query_595319, "Version", newJString(Version))
  result = call_595318.call(nil, query_595319, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_595298(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_595299, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_595300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_595367 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstances_595369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_595368(path: JsonNode;
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
  var valid_595370 = query.getOrDefault("Action")
  valid_595370 = validateParameter(valid_595370, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595370 != nil:
    section.add "Action", valid_595370
  var valid_595371 = query.getOrDefault("Version")
  valid_595371 = validateParameter(valid_595371, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595371 != nil:
    section.add "Version", valid_595371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595372 = header.getOrDefault("X-Amz-Date")
  valid_595372 = validateParameter(valid_595372, JString, required = false,
                                 default = nil)
  if valid_595372 != nil:
    section.add "X-Amz-Date", valid_595372
  var valid_595373 = header.getOrDefault("X-Amz-Security-Token")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "X-Amz-Security-Token", valid_595373
  var valid_595374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Content-Sha256", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Algorithm")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Algorithm", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Signature")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Signature", valid_595376
  var valid_595377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-SignedHeaders", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Credential")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Credential", valid_595378
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
  var valid_595379 = formData.getOrDefault("OfferingType")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "OfferingType", valid_595379
  var valid_595380 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "ReservedDBInstanceId", valid_595380
  var valid_595381 = formData.getOrDefault("Marker")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "Marker", valid_595381
  var valid_595382 = formData.getOrDefault("MultiAZ")
  valid_595382 = validateParameter(valid_595382, JBool, required = false, default = nil)
  if valid_595382 != nil:
    section.add "MultiAZ", valid_595382
  var valid_595383 = formData.getOrDefault("Duration")
  valid_595383 = validateParameter(valid_595383, JString, required = false,
                                 default = nil)
  if valid_595383 != nil:
    section.add "Duration", valid_595383
  var valid_595384 = formData.getOrDefault("DBInstanceClass")
  valid_595384 = validateParameter(valid_595384, JString, required = false,
                                 default = nil)
  if valid_595384 != nil:
    section.add "DBInstanceClass", valid_595384
  var valid_595385 = formData.getOrDefault("ProductDescription")
  valid_595385 = validateParameter(valid_595385, JString, required = false,
                                 default = nil)
  if valid_595385 != nil:
    section.add "ProductDescription", valid_595385
  var valid_595386 = formData.getOrDefault("MaxRecords")
  valid_595386 = validateParameter(valid_595386, JInt, required = false, default = nil)
  if valid_595386 != nil:
    section.add "MaxRecords", valid_595386
  var valid_595387 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595387 = validateParameter(valid_595387, JString, required = false,
                                 default = nil)
  if valid_595387 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595388: Call_PostDescribeReservedDBInstances_595367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595388.validator(path, query, header, formData, body)
  let scheme = call_595388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595388.url(scheme.get, call_595388.host, call_595388.base,
                         call_595388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595388, url, valid)

proc call*(call_595389: Call_PostDescribeReservedDBInstances_595367;
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
  var query_595390 = newJObject()
  var formData_595391 = newJObject()
  add(formData_595391, "OfferingType", newJString(OfferingType))
  add(formData_595391, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595391, "Marker", newJString(Marker))
  add(formData_595391, "MultiAZ", newJBool(MultiAZ))
  add(query_595390, "Action", newJString(Action))
  add(formData_595391, "Duration", newJString(Duration))
  add(formData_595391, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595391, "ProductDescription", newJString(ProductDescription))
  add(formData_595391, "MaxRecords", newJInt(MaxRecords))
  add(formData_595391, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595390, "Version", newJString(Version))
  result = call_595389.call(nil, query_595390, nil, formData_595391, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_595367(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_595368, base: "/",
    url: url_PostDescribeReservedDBInstances_595369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_595343 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstances_595345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_595344(path: JsonNode;
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
  var valid_595346 = query.getOrDefault("ProductDescription")
  valid_595346 = validateParameter(valid_595346, JString, required = false,
                                 default = nil)
  if valid_595346 != nil:
    section.add "ProductDescription", valid_595346
  var valid_595347 = query.getOrDefault("MaxRecords")
  valid_595347 = validateParameter(valid_595347, JInt, required = false, default = nil)
  if valid_595347 != nil:
    section.add "MaxRecords", valid_595347
  var valid_595348 = query.getOrDefault("OfferingType")
  valid_595348 = validateParameter(valid_595348, JString, required = false,
                                 default = nil)
  if valid_595348 != nil:
    section.add "OfferingType", valid_595348
  var valid_595349 = query.getOrDefault("MultiAZ")
  valid_595349 = validateParameter(valid_595349, JBool, required = false, default = nil)
  if valid_595349 != nil:
    section.add "MultiAZ", valid_595349
  var valid_595350 = query.getOrDefault("ReservedDBInstanceId")
  valid_595350 = validateParameter(valid_595350, JString, required = false,
                                 default = nil)
  if valid_595350 != nil:
    section.add "ReservedDBInstanceId", valid_595350
  var valid_595351 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595351 = validateParameter(valid_595351, JString, required = false,
                                 default = nil)
  if valid_595351 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595351
  var valid_595352 = query.getOrDefault("DBInstanceClass")
  valid_595352 = validateParameter(valid_595352, JString, required = false,
                                 default = nil)
  if valid_595352 != nil:
    section.add "DBInstanceClass", valid_595352
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595353 = query.getOrDefault("Action")
  valid_595353 = validateParameter(valid_595353, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_595353 != nil:
    section.add "Action", valid_595353
  var valid_595354 = query.getOrDefault("Marker")
  valid_595354 = validateParameter(valid_595354, JString, required = false,
                                 default = nil)
  if valid_595354 != nil:
    section.add "Marker", valid_595354
  var valid_595355 = query.getOrDefault("Duration")
  valid_595355 = validateParameter(valid_595355, JString, required = false,
                                 default = nil)
  if valid_595355 != nil:
    section.add "Duration", valid_595355
  var valid_595356 = query.getOrDefault("Version")
  valid_595356 = validateParameter(valid_595356, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595356 != nil:
    section.add "Version", valid_595356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595357 = header.getOrDefault("X-Amz-Date")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "X-Amz-Date", valid_595357
  var valid_595358 = header.getOrDefault("X-Amz-Security-Token")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Security-Token", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Content-Sha256", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Algorithm")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Algorithm", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Signature")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Signature", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-SignedHeaders", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Credential")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Credential", valid_595363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595364: Call_GetDescribeReservedDBInstances_595343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595364.validator(path, query, header, formData, body)
  let scheme = call_595364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595364.url(scheme.get, call_595364.host, call_595364.base,
                         call_595364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595364, url, valid)

proc call*(call_595365: Call_GetDescribeReservedDBInstances_595343;
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
  var query_595366 = newJObject()
  add(query_595366, "ProductDescription", newJString(ProductDescription))
  add(query_595366, "MaxRecords", newJInt(MaxRecords))
  add(query_595366, "OfferingType", newJString(OfferingType))
  add(query_595366, "MultiAZ", newJBool(MultiAZ))
  add(query_595366, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595366, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595366, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595366, "Action", newJString(Action))
  add(query_595366, "Marker", newJString(Marker))
  add(query_595366, "Duration", newJString(Duration))
  add(query_595366, "Version", newJString(Version))
  result = call_595365.call(nil, query_595366, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_595343(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_595344, base: "/",
    url: url_GetDescribeReservedDBInstances_595345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_595415 = ref object of OpenApiRestCall_593421
proc url_PostDescribeReservedDBInstancesOfferings_595417(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_595416(path: JsonNode;
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
  var valid_595418 = query.getOrDefault("Action")
  valid_595418 = validateParameter(valid_595418, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595418 != nil:
    section.add "Action", valid_595418
  var valid_595419 = query.getOrDefault("Version")
  valid_595419 = validateParameter(valid_595419, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595419 != nil:
    section.add "Version", valid_595419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595420 = header.getOrDefault("X-Amz-Date")
  valid_595420 = validateParameter(valid_595420, JString, required = false,
                                 default = nil)
  if valid_595420 != nil:
    section.add "X-Amz-Date", valid_595420
  var valid_595421 = header.getOrDefault("X-Amz-Security-Token")
  valid_595421 = validateParameter(valid_595421, JString, required = false,
                                 default = nil)
  if valid_595421 != nil:
    section.add "X-Amz-Security-Token", valid_595421
  var valid_595422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595422 = validateParameter(valid_595422, JString, required = false,
                                 default = nil)
  if valid_595422 != nil:
    section.add "X-Amz-Content-Sha256", valid_595422
  var valid_595423 = header.getOrDefault("X-Amz-Algorithm")
  valid_595423 = validateParameter(valid_595423, JString, required = false,
                                 default = nil)
  if valid_595423 != nil:
    section.add "X-Amz-Algorithm", valid_595423
  var valid_595424 = header.getOrDefault("X-Amz-Signature")
  valid_595424 = validateParameter(valid_595424, JString, required = false,
                                 default = nil)
  if valid_595424 != nil:
    section.add "X-Amz-Signature", valid_595424
  var valid_595425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595425 = validateParameter(valid_595425, JString, required = false,
                                 default = nil)
  if valid_595425 != nil:
    section.add "X-Amz-SignedHeaders", valid_595425
  var valid_595426 = header.getOrDefault("X-Amz-Credential")
  valid_595426 = validateParameter(valid_595426, JString, required = false,
                                 default = nil)
  if valid_595426 != nil:
    section.add "X-Amz-Credential", valid_595426
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
  var valid_595427 = formData.getOrDefault("OfferingType")
  valid_595427 = validateParameter(valid_595427, JString, required = false,
                                 default = nil)
  if valid_595427 != nil:
    section.add "OfferingType", valid_595427
  var valid_595428 = formData.getOrDefault("Marker")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "Marker", valid_595428
  var valid_595429 = formData.getOrDefault("MultiAZ")
  valid_595429 = validateParameter(valid_595429, JBool, required = false, default = nil)
  if valid_595429 != nil:
    section.add "MultiAZ", valid_595429
  var valid_595430 = formData.getOrDefault("Duration")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "Duration", valid_595430
  var valid_595431 = formData.getOrDefault("DBInstanceClass")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "DBInstanceClass", valid_595431
  var valid_595432 = formData.getOrDefault("ProductDescription")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "ProductDescription", valid_595432
  var valid_595433 = formData.getOrDefault("MaxRecords")
  valid_595433 = validateParameter(valid_595433, JInt, required = false, default = nil)
  if valid_595433 != nil:
    section.add "MaxRecords", valid_595433
  var valid_595434 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595434
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595435: Call_PostDescribeReservedDBInstancesOfferings_595415;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595435.validator(path, query, header, formData, body)
  let scheme = call_595435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595435.url(scheme.get, call_595435.host, call_595435.base,
                         call_595435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595435, url, valid)

proc call*(call_595436: Call_PostDescribeReservedDBInstancesOfferings_595415;
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
  var query_595437 = newJObject()
  var formData_595438 = newJObject()
  add(formData_595438, "OfferingType", newJString(OfferingType))
  add(formData_595438, "Marker", newJString(Marker))
  add(formData_595438, "MultiAZ", newJBool(MultiAZ))
  add(query_595437, "Action", newJString(Action))
  add(formData_595438, "Duration", newJString(Duration))
  add(formData_595438, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595438, "ProductDescription", newJString(ProductDescription))
  add(formData_595438, "MaxRecords", newJInt(MaxRecords))
  add(formData_595438, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595437, "Version", newJString(Version))
  result = call_595436.call(nil, query_595437, nil, formData_595438, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_595415(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_595416,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_595417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_595392 = ref object of OpenApiRestCall_593421
proc url_GetDescribeReservedDBInstancesOfferings_595394(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_595393(path: JsonNode;
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
  var valid_595395 = query.getOrDefault("ProductDescription")
  valid_595395 = validateParameter(valid_595395, JString, required = false,
                                 default = nil)
  if valid_595395 != nil:
    section.add "ProductDescription", valid_595395
  var valid_595396 = query.getOrDefault("MaxRecords")
  valid_595396 = validateParameter(valid_595396, JInt, required = false, default = nil)
  if valid_595396 != nil:
    section.add "MaxRecords", valid_595396
  var valid_595397 = query.getOrDefault("OfferingType")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "OfferingType", valid_595397
  var valid_595398 = query.getOrDefault("MultiAZ")
  valid_595398 = validateParameter(valid_595398, JBool, required = false, default = nil)
  if valid_595398 != nil:
    section.add "MultiAZ", valid_595398
  var valid_595399 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595399
  var valid_595400 = query.getOrDefault("DBInstanceClass")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "DBInstanceClass", valid_595400
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595401 = query.getOrDefault("Action")
  valid_595401 = validateParameter(valid_595401, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_595401 != nil:
    section.add "Action", valid_595401
  var valid_595402 = query.getOrDefault("Marker")
  valid_595402 = validateParameter(valid_595402, JString, required = false,
                                 default = nil)
  if valid_595402 != nil:
    section.add "Marker", valid_595402
  var valid_595403 = query.getOrDefault("Duration")
  valid_595403 = validateParameter(valid_595403, JString, required = false,
                                 default = nil)
  if valid_595403 != nil:
    section.add "Duration", valid_595403
  var valid_595404 = query.getOrDefault("Version")
  valid_595404 = validateParameter(valid_595404, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595404 != nil:
    section.add "Version", valid_595404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595405 = header.getOrDefault("X-Amz-Date")
  valid_595405 = validateParameter(valid_595405, JString, required = false,
                                 default = nil)
  if valid_595405 != nil:
    section.add "X-Amz-Date", valid_595405
  var valid_595406 = header.getOrDefault("X-Amz-Security-Token")
  valid_595406 = validateParameter(valid_595406, JString, required = false,
                                 default = nil)
  if valid_595406 != nil:
    section.add "X-Amz-Security-Token", valid_595406
  var valid_595407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595407 = validateParameter(valid_595407, JString, required = false,
                                 default = nil)
  if valid_595407 != nil:
    section.add "X-Amz-Content-Sha256", valid_595407
  var valid_595408 = header.getOrDefault("X-Amz-Algorithm")
  valid_595408 = validateParameter(valid_595408, JString, required = false,
                                 default = nil)
  if valid_595408 != nil:
    section.add "X-Amz-Algorithm", valid_595408
  var valid_595409 = header.getOrDefault("X-Amz-Signature")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-Signature", valid_595409
  var valid_595410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-SignedHeaders", valid_595410
  var valid_595411 = header.getOrDefault("X-Amz-Credential")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Credential", valid_595411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595412: Call_GetDescribeReservedDBInstancesOfferings_595392;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595412.validator(path, query, header, formData, body)
  let scheme = call_595412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595412.url(scheme.get, call_595412.host, call_595412.base,
                         call_595412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595412, url, valid)

proc call*(call_595413: Call_GetDescribeReservedDBInstancesOfferings_595392;
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
  var query_595414 = newJObject()
  add(query_595414, "ProductDescription", newJString(ProductDescription))
  add(query_595414, "MaxRecords", newJInt(MaxRecords))
  add(query_595414, "OfferingType", newJString(OfferingType))
  add(query_595414, "MultiAZ", newJBool(MultiAZ))
  add(query_595414, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595414, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595414, "Action", newJString(Action))
  add(query_595414, "Marker", newJString(Marker))
  add(query_595414, "Duration", newJString(Duration))
  add(query_595414, "Version", newJString(Version))
  result = call_595413.call(nil, query_595414, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_595392(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_595393, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_595394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_595458 = ref object of OpenApiRestCall_593421
proc url_PostDownloadDBLogFilePortion_595460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_595459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595461 = query.getOrDefault("Action")
  valid_595461 = validateParameter(valid_595461, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595461 != nil:
    section.add "Action", valid_595461
  var valid_595462 = query.getOrDefault("Version")
  valid_595462 = validateParameter(valid_595462, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595462 != nil:
    section.add "Version", valid_595462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595463 = header.getOrDefault("X-Amz-Date")
  valid_595463 = validateParameter(valid_595463, JString, required = false,
                                 default = nil)
  if valid_595463 != nil:
    section.add "X-Amz-Date", valid_595463
  var valid_595464 = header.getOrDefault("X-Amz-Security-Token")
  valid_595464 = validateParameter(valid_595464, JString, required = false,
                                 default = nil)
  if valid_595464 != nil:
    section.add "X-Amz-Security-Token", valid_595464
  var valid_595465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595465 = validateParameter(valid_595465, JString, required = false,
                                 default = nil)
  if valid_595465 != nil:
    section.add "X-Amz-Content-Sha256", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Algorithm")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Algorithm", valid_595466
  var valid_595467 = header.getOrDefault("X-Amz-Signature")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Signature", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-SignedHeaders", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Credential")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Credential", valid_595469
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_595470 = formData.getOrDefault("NumberOfLines")
  valid_595470 = validateParameter(valid_595470, JInt, required = false, default = nil)
  if valid_595470 != nil:
    section.add "NumberOfLines", valid_595470
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595471 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595471 = validateParameter(valid_595471, JString, required = true,
                                 default = nil)
  if valid_595471 != nil:
    section.add "DBInstanceIdentifier", valid_595471
  var valid_595472 = formData.getOrDefault("Marker")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "Marker", valid_595472
  var valid_595473 = formData.getOrDefault("LogFileName")
  valid_595473 = validateParameter(valid_595473, JString, required = true,
                                 default = nil)
  if valid_595473 != nil:
    section.add "LogFileName", valid_595473
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595474: Call_PostDownloadDBLogFilePortion_595458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595474.validator(path, query, header, formData, body)
  let scheme = call_595474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595474.url(scheme.get, call_595474.host, call_595474.base,
                         call_595474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595474, url, valid)

proc call*(call_595475: Call_PostDownloadDBLogFilePortion_595458;
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
  var query_595476 = newJObject()
  var formData_595477 = newJObject()
  add(formData_595477, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_595477, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595477, "Marker", newJString(Marker))
  add(query_595476, "Action", newJString(Action))
  add(formData_595477, "LogFileName", newJString(LogFileName))
  add(query_595476, "Version", newJString(Version))
  result = call_595475.call(nil, query_595476, nil, formData_595477, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_595458(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_595459, base: "/",
    url: url_PostDownloadDBLogFilePortion_595460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_595439 = ref object of OpenApiRestCall_593421
proc url_GetDownloadDBLogFilePortion_595441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_595440(path: JsonNode; query: JsonNode;
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
  var valid_595442 = query.getOrDefault("NumberOfLines")
  valid_595442 = validateParameter(valid_595442, JInt, required = false, default = nil)
  if valid_595442 != nil:
    section.add "NumberOfLines", valid_595442
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_595443 = query.getOrDefault("LogFileName")
  valid_595443 = validateParameter(valid_595443, JString, required = true,
                                 default = nil)
  if valid_595443 != nil:
    section.add "LogFileName", valid_595443
  var valid_595444 = query.getOrDefault("Action")
  valid_595444 = validateParameter(valid_595444, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_595444 != nil:
    section.add "Action", valid_595444
  var valid_595445 = query.getOrDefault("Marker")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "Marker", valid_595445
  var valid_595446 = query.getOrDefault("Version")
  valid_595446 = validateParameter(valid_595446, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595446 != nil:
    section.add "Version", valid_595446
  var valid_595447 = query.getOrDefault("DBInstanceIdentifier")
  valid_595447 = validateParameter(valid_595447, JString, required = true,
                                 default = nil)
  if valid_595447 != nil:
    section.add "DBInstanceIdentifier", valid_595447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595448 = header.getOrDefault("X-Amz-Date")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "X-Amz-Date", valid_595448
  var valid_595449 = header.getOrDefault("X-Amz-Security-Token")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "X-Amz-Security-Token", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-Content-Sha256", valid_595450
  var valid_595451 = header.getOrDefault("X-Amz-Algorithm")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Algorithm", valid_595451
  var valid_595452 = header.getOrDefault("X-Amz-Signature")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Signature", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-SignedHeaders", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-Credential")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-Credential", valid_595454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595455: Call_GetDownloadDBLogFilePortion_595439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595455.validator(path, query, header, formData, body)
  let scheme = call_595455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595455.url(scheme.get, call_595455.host, call_595455.base,
                         call_595455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595455, url, valid)

proc call*(call_595456: Call_GetDownloadDBLogFilePortion_595439;
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
  var query_595457 = newJObject()
  add(query_595457, "NumberOfLines", newJInt(NumberOfLines))
  add(query_595457, "LogFileName", newJString(LogFileName))
  add(query_595457, "Action", newJString(Action))
  add(query_595457, "Marker", newJString(Marker))
  add(query_595457, "Version", newJString(Version))
  add(query_595457, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595456.call(nil, query_595457, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_595439(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_595440, base: "/",
    url: url_GetDownloadDBLogFilePortion_595441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595494 = ref object of OpenApiRestCall_593421
proc url_PostListTagsForResource_595496(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595497 = query.getOrDefault("Action")
  valid_595497 = validateParameter(valid_595497, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595497 != nil:
    section.add "Action", valid_595497
  var valid_595498 = query.getOrDefault("Version")
  valid_595498 = validateParameter(valid_595498, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595498 != nil:
    section.add "Version", valid_595498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595499 = header.getOrDefault("X-Amz-Date")
  valid_595499 = validateParameter(valid_595499, JString, required = false,
                                 default = nil)
  if valid_595499 != nil:
    section.add "X-Amz-Date", valid_595499
  var valid_595500 = header.getOrDefault("X-Amz-Security-Token")
  valid_595500 = validateParameter(valid_595500, JString, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "X-Amz-Security-Token", valid_595500
  var valid_595501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595501 = validateParameter(valid_595501, JString, required = false,
                                 default = nil)
  if valid_595501 != nil:
    section.add "X-Amz-Content-Sha256", valid_595501
  var valid_595502 = header.getOrDefault("X-Amz-Algorithm")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "X-Amz-Algorithm", valid_595502
  var valid_595503 = header.getOrDefault("X-Amz-Signature")
  valid_595503 = validateParameter(valid_595503, JString, required = false,
                                 default = nil)
  if valid_595503 != nil:
    section.add "X-Amz-Signature", valid_595503
  var valid_595504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "X-Amz-SignedHeaders", valid_595504
  var valid_595505 = header.getOrDefault("X-Amz-Credential")
  valid_595505 = validateParameter(valid_595505, JString, required = false,
                                 default = nil)
  if valid_595505 != nil:
    section.add "X-Amz-Credential", valid_595505
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_595506 = formData.getOrDefault("ResourceName")
  valid_595506 = validateParameter(valid_595506, JString, required = true,
                                 default = nil)
  if valid_595506 != nil:
    section.add "ResourceName", valid_595506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595507: Call_PostListTagsForResource_595494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595507.validator(path, query, header, formData, body)
  let scheme = call_595507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595507.url(scheme.get, call_595507.host, call_595507.base,
                         call_595507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595507, url, valid)

proc call*(call_595508: Call_PostListTagsForResource_595494; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595509 = newJObject()
  var formData_595510 = newJObject()
  add(query_595509, "Action", newJString(Action))
  add(formData_595510, "ResourceName", newJString(ResourceName))
  add(query_595509, "Version", newJString(Version))
  result = call_595508.call(nil, query_595509, nil, formData_595510, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595494(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595495, base: "/",
    url: url_PostListTagsForResource_595496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595478 = ref object of OpenApiRestCall_593421
proc url_GetListTagsForResource_595480(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595479(path: JsonNode; query: JsonNode;
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
  var valid_595481 = query.getOrDefault("ResourceName")
  valid_595481 = validateParameter(valid_595481, JString, required = true,
                                 default = nil)
  if valid_595481 != nil:
    section.add "ResourceName", valid_595481
  var valid_595482 = query.getOrDefault("Action")
  valid_595482 = validateParameter(valid_595482, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595482 != nil:
    section.add "Action", valid_595482
  var valid_595483 = query.getOrDefault("Version")
  valid_595483 = validateParameter(valid_595483, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595483 != nil:
    section.add "Version", valid_595483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595484 = header.getOrDefault("X-Amz-Date")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Date", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-Security-Token")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-Security-Token", valid_595485
  var valid_595486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-Content-Sha256", valid_595486
  var valid_595487 = header.getOrDefault("X-Amz-Algorithm")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "X-Amz-Algorithm", valid_595487
  var valid_595488 = header.getOrDefault("X-Amz-Signature")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "X-Amz-Signature", valid_595488
  var valid_595489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595489 = validateParameter(valid_595489, JString, required = false,
                                 default = nil)
  if valid_595489 != nil:
    section.add "X-Amz-SignedHeaders", valid_595489
  var valid_595490 = header.getOrDefault("X-Amz-Credential")
  valid_595490 = validateParameter(valid_595490, JString, required = false,
                                 default = nil)
  if valid_595490 != nil:
    section.add "X-Amz-Credential", valid_595490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595491: Call_GetListTagsForResource_595478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595491.validator(path, query, header, formData, body)
  let scheme = call_595491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595491.url(scheme.get, call_595491.host, call_595491.base,
                         call_595491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595491, url, valid)

proc call*(call_595492: Call_GetListTagsForResource_595478; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595493 = newJObject()
  add(query_595493, "ResourceName", newJString(ResourceName))
  add(query_595493, "Action", newJString(Action))
  add(query_595493, "Version", newJString(Version))
  result = call_595492.call(nil, query_595493, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595478(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595479, base: "/",
    url: url_GetListTagsForResource_595480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_595544 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBInstance_595546(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_595545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595547 = query.getOrDefault("Action")
  valid_595547 = validateParameter(valid_595547, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595547 != nil:
    section.add "Action", valid_595547
  var valid_595548 = query.getOrDefault("Version")
  valid_595548 = validateParameter(valid_595548, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595548 != nil:
    section.add "Version", valid_595548
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595549 = header.getOrDefault("X-Amz-Date")
  valid_595549 = validateParameter(valid_595549, JString, required = false,
                                 default = nil)
  if valid_595549 != nil:
    section.add "X-Amz-Date", valid_595549
  var valid_595550 = header.getOrDefault("X-Amz-Security-Token")
  valid_595550 = validateParameter(valid_595550, JString, required = false,
                                 default = nil)
  if valid_595550 != nil:
    section.add "X-Amz-Security-Token", valid_595550
  var valid_595551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595551 = validateParameter(valid_595551, JString, required = false,
                                 default = nil)
  if valid_595551 != nil:
    section.add "X-Amz-Content-Sha256", valid_595551
  var valid_595552 = header.getOrDefault("X-Amz-Algorithm")
  valid_595552 = validateParameter(valid_595552, JString, required = false,
                                 default = nil)
  if valid_595552 != nil:
    section.add "X-Amz-Algorithm", valid_595552
  var valid_595553 = header.getOrDefault("X-Amz-Signature")
  valid_595553 = validateParameter(valid_595553, JString, required = false,
                                 default = nil)
  if valid_595553 != nil:
    section.add "X-Amz-Signature", valid_595553
  var valid_595554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595554 = validateParameter(valid_595554, JString, required = false,
                                 default = nil)
  if valid_595554 != nil:
    section.add "X-Amz-SignedHeaders", valid_595554
  var valid_595555 = header.getOrDefault("X-Amz-Credential")
  valid_595555 = validateParameter(valid_595555, JString, required = false,
                                 default = nil)
  if valid_595555 != nil:
    section.add "X-Amz-Credential", valid_595555
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
  var valid_595556 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595556 = validateParameter(valid_595556, JString, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "PreferredMaintenanceWindow", valid_595556
  var valid_595557 = formData.getOrDefault("DBSecurityGroups")
  valid_595557 = validateParameter(valid_595557, JArray, required = false,
                                 default = nil)
  if valid_595557 != nil:
    section.add "DBSecurityGroups", valid_595557
  var valid_595558 = formData.getOrDefault("ApplyImmediately")
  valid_595558 = validateParameter(valid_595558, JBool, required = false, default = nil)
  if valid_595558 != nil:
    section.add "ApplyImmediately", valid_595558
  var valid_595559 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595559 = validateParameter(valid_595559, JArray, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "VpcSecurityGroupIds", valid_595559
  var valid_595560 = formData.getOrDefault("Iops")
  valid_595560 = validateParameter(valid_595560, JInt, required = false, default = nil)
  if valid_595560 != nil:
    section.add "Iops", valid_595560
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595561 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595561 = validateParameter(valid_595561, JString, required = true,
                                 default = nil)
  if valid_595561 != nil:
    section.add "DBInstanceIdentifier", valid_595561
  var valid_595562 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595562 = validateParameter(valid_595562, JInt, required = false, default = nil)
  if valid_595562 != nil:
    section.add "BackupRetentionPeriod", valid_595562
  var valid_595563 = formData.getOrDefault("DBParameterGroupName")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "DBParameterGroupName", valid_595563
  var valid_595564 = formData.getOrDefault("OptionGroupName")
  valid_595564 = validateParameter(valid_595564, JString, required = false,
                                 default = nil)
  if valid_595564 != nil:
    section.add "OptionGroupName", valid_595564
  var valid_595565 = formData.getOrDefault("MasterUserPassword")
  valid_595565 = validateParameter(valid_595565, JString, required = false,
                                 default = nil)
  if valid_595565 != nil:
    section.add "MasterUserPassword", valid_595565
  var valid_595566 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_595566 = validateParameter(valid_595566, JString, required = false,
                                 default = nil)
  if valid_595566 != nil:
    section.add "NewDBInstanceIdentifier", valid_595566
  var valid_595567 = formData.getOrDefault("MultiAZ")
  valid_595567 = validateParameter(valid_595567, JBool, required = false, default = nil)
  if valid_595567 != nil:
    section.add "MultiAZ", valid_595567
  var valid_595568 = formData.getOrDefault("AllocatedStorage")
  valid_595568 = validateParameter(valid_595568, JInt, required = false, default = nil)
  if valid_595568 != nil:
    section.add "AllocatedStorage", valid_595568
  var valid_595569 = formData.getOrDefault("DBInstanceClass")
  valid_595569 = validateParameter(valid_595569, JString, required = false,
                                 default = nil)
  if valid_595569 != nil:
    section.add "DBInstanceClass", valid_595569
  var valid_595570 = formData.getOrDefault("PreferredBackupWindow")
  valid_595570 = validateParameter(valid_595570, JString, required = false,
                                 default = nil)
  if valid_595570 != nil:
    section.add "PreferredBackupWindow", valid_595570
  var valid_595571 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595571 = validateParameter(valid_595571, JBool, required = false, default = nil)
  if valid_595571 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595571
  var valid_595572 = formData.getOrDefault("EngineVersion")
  valid_595572 = validateParameter(valid_595572, JString, required = false,
                                 default = nil)
  if valid_595572 != nil:
    section.add "EngineVersion", valid_595572
  var valid_595573 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_595573 = validateParameter(valid_595573, JBool, required = false, default = nil)
  if valid_595573 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595574: Call_PostModifyDBInstance_595544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595574.validator(path, query, header, formData, body)
  let scheme = call_595574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595574.url(scheme.get, call_595574.host, call_595574.base,
                         call_595574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595574, url, valid)

proc call*(call_595575: Call_PostModifyDBInstance_595544;
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
  var query_595576 = newJObject()
  var formData_595577 = newJObject()
  add(formData_595577, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_595577.add "DBSecurityGroups", DBSecurityGroups
  add(formData_595577, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_595577.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595577, "Iops", newJInt(Iops))
  add(formData_595577, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595577, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_595577, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_595577, "OptionGroupName", newJString(OptionGroupName))
  add(formData_595577, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_595577, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_595577, "MultiAZ", newJBool(MultiAZ))
  add(query_595576, "Action", newJString(Action))
  add(formData_595577, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_595577, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595577, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_595577, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_595577, "EngineVersion", newJString(EngineVersion))
  add(query_595576, "Version", newJString(Version))
  add(formData_595577, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_595575.call(nil, query_595576, nil, formData_595577, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_595544(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_595545, base: "/",
    url: url_PostModifyDBInstance_595546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_595511 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBInstance_595513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_595512(path: JsonNode; query: JsonNode;
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
  var valid_595514 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "PreferredMaintenanceWindow", valid_595514
  var valid_595515 = query.getOrDefault("AllocatedStorage")
  valid_595515 = validateParameter(valid_595515, JInt, required = false, default = nil)
  if valid_595515 != nil:
    section.add "AllocatedStorage", valid_595515
  var valid_595516 = query.getOrDefault("OptionGroupName")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "OptionGroupName", valid_595516
  var valid_595517 = query.getOrDefault("DBSecurityGroups")
  valid_595517 = validateParameter(valid_595517, JArray, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "DBSecurityGroups", valid_595517
  var valid_595518 = query.getOrDefault("MasterUserPassword")
  valid_595518 = validateParameter(valid_595518, JString, required = false,
                                 default = nil)
  if valid_595518 != nil:
    section.add "MasterUserPassword", valid_595518
  var valid_595519 = query.getOrDefault("Iops")
  valid_595519 = validateParameter(valid_595519, JInt, required = false, default = nil)
  if valid_595519 != nil:
    section.add "Iops", valid_595519
  var valid_595520 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595520 = validateParameter(valid_595520, JArray, required = false,
                                 default = nil)
  if valid_595520 != nil:
    section.add "VpcSecurityGroupIds", valid_595520
  var valid_595521 = query.getOrDefault("MultiAZ")
  valid_595521 = validateParameter(valid_595521, JBool, required = false, default = nil)
  if valid_595521 != nil:
    section.add "MultiAZ", valid_595521
  var valid_595522 = query.getOrDefault("BackupRetentionPeriod")
  valid_595522 = validateParameter(valid_595522, JInt, required = false, default = nil)
  if valid_595522 != nil:
    section.add "BackupRetentionPeriod", valid_595522
  var valid_595523 = query.getOrDefault("DBParameterGroupName")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "DBParameterGroupName", valid_595523
  var valid_595524 = query.getOrDefault("DBInstanceClass")
  valid_595524 = validateParameter(valid_595524, JString, required = false,
                                 default = nil)
  if valid_595524 != nil:
    section.add "DBInstanceClass", valid_595524
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595525 = query.getOrDefault("Action")
  valid_595525 = validateParameter(valid_595525, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595525 != nil:
    section.add "Action", valid_595525
  var valid_595526 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_595526 = validateParameter(valid_595526, JBool, required = false, default = nil)
  if valid_595526 != nil:
    section.add "AllowMajorVersionUpgrade", valid_595526
  var valid_595527 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_595527 = validateParameter(valid_595527, JString, required = false,
                                 default = nil)
  if valid_595527 != nil:
    section.add "NewDBInstanceIdentifier", valid_595527
  var valid_595528 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595528 = validateParameter(valid_595528, JBool, required = false, default = nil)
  if valid_595528 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595528
  var valid_595529 = query.getOrDefault("EngineVersion")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "EngineVersion", valid_595529
  var valid_595530 = query.getOrDefault("PreferredBackupWindow")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "PreferredBackupWindow", valid_595530
  var valid_595531 = query.getOrDefault("Version")
  valid_595531 = validateParameter(valid_595531, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595531 != nil:
    section.add "Version", valid_595531
  var valid_595532 = query.getOrDefault("DBInstanceIdentifier")
  valid_595532 = validateParameter(valid_595532, JString, required = true,
                                 default = nil)
  if valid_595532 != nil:
    section.add "DBInstanceIdentifier", valid_595532
  var valid_595533 = query.getOrDefault("ApplyImmediately")
  valid_595533 = validateParameter(valid_595533, JBool, required = false, default = nil)
  if valid_595533 != nil:
    section.add "ApplyImmediately", valid_595533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595534 = header.getOrDefault("X-Amz-Date")
  valid_595534 = validateParameter(valid_595534, JString, required = false,
                                 default = nil)
  if valid_595534 != nil:
    section.add "X-Amz-Date", valid_595534
  var valid_595535 = header.getOrDefault("X-Amz-Security-Token")
  valid_595535 = validateParameter(valid_595535, JString, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "X-Amz-Security-Token", valid_595535
  var valid_595536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595536 = validateParameter(valid_595536, JString, required = false,
                                 default = nil)
  if valid_595536 != nil:
    section.add "X-Amz-Content-Sha256", valid_595536
  var valid_595537 = header.getOrDefault("X-Amz-Algorithm")
  valid_595537 = validateParameter(valid_595537, JString, required = false,
                                 default = nil)
  if valid_595537 != nil:
    section.add "X-Amz-Algorithm", valid_595537
  var valid_595538 = header.getOrDefault("X-Amz-Signature")
  valid_595538 = validateParameter(valid_595538, JString, required = false,
                                 default = nil)
  if valid_595538 != nil:
    section.add "X-Amz-Signature", valid_595538
  var valid_595539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595539 = validateParameter(valid_595539, JString, required = false,
                                 default = nil)
  if valid_595539 != nil:
    section.add "X-Amz-SignedHeaders", valid_595539
  var valid_595540 = header.getOrDefault("X-Amz-Credential")
  valid_595540 = validateParameter(valid_595540, JString, required = false,
                                 default = nil)
  if valid_595540 != nil:
    section.add "X-Amz-Credential", valid_595540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595541: Call_GetModifyDBInstance_595511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595541.validator(path, query, header, formData, body)
  let scheme = call_595541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595541.url(scheme.get, call_595541.host, call_595541.base,
                         call_595541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595541, url, valid)

proc call*(call_595542: Call_GetModifyDBInstance_595511;
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
  var query_595543 = newJObject()
  add(query_595543, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595543, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_595543, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_595543.add "DBSecurityGroups", DBSecurityGroups
  add(query_595543, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_595543, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_595543.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_595543, "MultiAZ", newJBool(MultiAZ))
  add(query_595543, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595543, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_595543, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595543, "Action", newJString(Action))
  add(query_595543, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_595543, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_595543, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595543, "EngineVersion", newJString(EngineVersion))
  add(query_595543, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595543, "Version", newJString(Version))
  add(query_595543, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595543, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595542.call(nil, query_595543, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_595511(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_595512, base: "/",
    url: url_GetModifyDBInstance_595513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_595595 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBParameterGroup_595597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_595596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595598 = query.getOrDefault("Action")
  valid_595598 = validateParameter(valid_595598, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595598 != nil:
    section.add "Action", valid_595598
  var valid_595599 = query.getOrDefault("Version")
  valid_595599 = validateParameter(valid_595599, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595599 != nil:
    section.add "Version", valid_595599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595600 = header.getOrDefault("X-Amz-Date")
  valid_595600 = validateParameter(valid_595600, JString, required = false,
                                 default = nil)
  if valid_595600 != nil:
    section.add "X-Amz-Date", valid_595600
  var valid_595601 = header.getOrDefault("X-Amz-Security-Token")
  valid_595601 = validateParameter(valid_595601, JString, required = false,
                                 default = nil)
  if valid_595601 != nil:
    section.add "X-Amz-Security-Token", valid_595601
  var valid_595602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595602 = validateParameter(valid_595602, JString, required = false,
                                 default = nil)
  if valid_595602 != nil:
    section.add "X-Amz-Content-Sha256", valid_595602
  var valid_595603 = header.getOrDefault("X-Amz-Algorithm")
  valid_595603 = validateParameter(valid_595603, JString, required = false,
                                 default = nil)
  if valid_595603 != nil:
    section.add "X-Amz-Algorithm", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Signature")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Signature", valid_595604
  var valid_595605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595605 = validateParameter(valid_595605, JString, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "X-Amz-SignedHeaders", valid_595605
  var valid_595606 = header.getOrDefault("X-Amz-Credential")
  valid_595606 = validateParameter(valid_595606, JString, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "X-Amz-Credential", valid_595606
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595607 = formData.getOrDefault("DBParameterGroupName")
  valid_595607 = validateParameter(valid_595607, JString, required = true,
                                 default = nil)
  if valid_595607 != nil:
    section.add "DBParameterGroupName", valid_595607
  var valid_595608 = formData.getOrDefault("Parameters")
  valid_595608 = validateParameter(valid_595608, JArray, required = true, default = nil)
  if valid_595608 != nil:
    section.add "Parameters", valid_595608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595609: Call_PostModifyDBParameterGroup_595595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595609.validator(path, query, header, formData, body)
  let scheme = call_595609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595609.url(scheme.get, call_595609.host, call_595609.base,
                         call_595609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595609, url, valid)

proc call*(call_595610: Call_PostModifyDBParameterGroup_595595;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595611 = newJObject()
  var formData_595612 = newJObject()
  add(formData_595612, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595612.add "Parameters", Parameters
  add(query_595611, "Action", newJString(Action))
  add(query_595611, "Version", newJString(Version))
  result = call_595610.call(nil, query_595611, nil, formData_595612, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_595595(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_595596, base: "/",
    url: url_PostModifyDBParameterGroup_595597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_595578 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBParameterGroup_595580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_595579(path: JsonNode; query: JsonNode;
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
  var valid_595581 = query.getOrDefault("DBParameterGroupName")
  valid_595581 = validateParameter(valid_595581, JString, required = true,
                                 default = nil)
  if valid_595581 != nil:
    section.add "DBParameterGroupName", valid_595581
  var valid_595582 = query.getOrDefault("Parameters")
  valid_595582 = validateParameter(valid_595582, JArray, required = true, default = nil)
  if valid_595582 != nil:
    section.add "Parameters", valid_595582
  var valid_595583 = query.getOrDefault("Action")
  valid_595583 = validateParameter(valid_595583, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_595583 != nil:
    section.add "Action", valid_595583
  var valid_595584 = query.getOrDefault("Version")
  valid_595584 = validateParameter(valid_595584, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595584 != nil:
    section.add "Version", valid_595584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595585 = header.getOrDefault("X-Amz-Date")
  valid_595585 = validateParameter(valid_595585, JString, required = false,
                                 default = nil)
  if valid_595585 != nil:
    section.add "X-Amz-Date", valid_595585
  var valid_595586 = header.getOrDefault("X-Amz-Security-Token")
  valid_595586 = validateParameter(valid_595586, JString, required = false,
                                 default = nil)
  if valid_595586 != nil:
    section.add "X-Amz-Security-Token", valid_595586
  var valid_595587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595587 = validateParameter(valid_595587, JString, required = false,
                                 default = nil)
  if valid_595587 != nil:
    section.add "X-Amz-Content-Sha256", valid_595587
  var valid_595588 = header.getOrDefault("X-Amz-Algorithm")
  valid_595588 = validateParameter(valid_595588, JString, required = false,
                                 default = nil)
  if valid_595588 != nil:
    section.add "X-Amz-Algorithm", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Signature")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Signature", valid_595589
  var valid_595590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595590 = validateParameter(valid_595590, JString, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "X-Amz-SignedHeaders", valid_595590
  var valid_595591 = header.getOrDefault("X-Amz-Credential")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "X-Amz-Credential", valid_595591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595592: Call_GetModifyDBParameterGroup_595578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595592.validator(path, query, header, formData, body)
  let scheme = call_595592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595592.url(scheme.get, call_595592.host, call_595592.base,
                         call_595592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595592, url, valid)

proc call*(call_595593: Call_GetModifyDBParameterGroup_595578;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595594 = newJObject()
  add(query_595594, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595594.add "Parameters", Parameters
  add(query_595594, "Action", newJString(Action))
  add(query_595594, "Version", newJString(Version))
  result = call_595593.call(nil, query_595594, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_595578(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_595579, base: "/",
    url: url_GetModifyDBParameterGroup_595580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_595631 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBSubnetGroup_595633(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_595632(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595634 = query.getOrDefault("Action")
  valid_595634 = validateParameter(valid_595634, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595634 != nil:
    section.add "Action", valid_595634
  var valid_595635 = query.getOrDefault("Version")
  valid_595635 = validateParameter(valid_595635, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595635 != nil:
    section.add "Version", valid_595635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595636 = header.getOrDefault("X-Amz-Date")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Date", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-Security-Token")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-Security-Token", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-Content-Sha256", valid_595638
  var valid_595639 = header.getOrDefault("X-Amz-Algorithm")
  valid_595639 = validateParameter(valid_595639, JString, required = false,
                                 default = nil)
  if valid_595639 != nil:
    section.add "X-Amz-Algorithm", valid_595639
  var valid_595640 = header.getOrDefault("X-Amz-Signature")
  valid_595640 = validateParameter(valid_595640, JString, required = false,
                                 default = nil)
  if valid_595640 != nil:
    section.add "X-Amz-Signature", valid_595640
  var valid_595641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595641 = validateParameter(valid_595641, JString, required = false,
                                 default = nil)
  if valid_595641 != nil:
    section.add "X-Amz-SignedHeaders", valid_595641
  var valid_595642 = header.getOrDefault("X-Amz-Credential")
  valid_595642 = validateParameter(valid_595642, JString, required = false,
                                 default = nil)
  if valid_595642 != nil:
    section.add "X-Amz-Credential", valid_595642
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_595643 = formData.getOrDefault("DBSubnetGroupName")
  valid_595643 = validateParameter(valid_595643, JString, required = true,
                                 default = nil)
  if valid_595643 != nil:
    section.add "DBSubnetGroupName", valid_595643
  var valid_595644 = formData.getOrDefault("SubnetIds")
  valid_595644 = validateParameter(valid_595644, JArray, required = true, default = nil)
  if valid_595644 != nil:
    section.add "SubnetIds", valid_595644
  var valid_595645 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_595645 = validateParameter(valid_595645, JString, required = false,
                                 default = nil)
  if valid_595645 != nil:
    section.add "DBSubnetGroupDescription", valid_595645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595646: Call_PostModifyDBSubnetGroup_595631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595646.validator(path, query, header, formData, body)
  let scheme = call_595646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595646.url(scheme.get, call_595646.host, call_595646.base,
                         call_595646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595646, url, valid)

proc call*(call_595647: Call_PostModifyDBSubnetGroup_595631;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595648 = newJObject()
  var formData_595649 = newJObject()
  add(formData_595649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_595649.add "SubnetIds", SubnetIds
  add(query_595648, "Action", newJString(Action))
  add(formData_595649, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595648, "Version", newJString(Version))
  result = call_595647.call(nil, query_595648, nil, formData_595649, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_595631(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_595632, base: "/",
    url: url_PostModifyDBSubnetGroup_595633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_595613 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBSubnetGroup_595615(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_595614(path: JsonNode; query: JsonNode;
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
  var valid_595616 = query.getOrDefault("Action")
  valid_595616 = validateParameter(valid_595616, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595616 != nil:
    section.add "Action", valid_595616
  var valid_595617 = query.getOrDefault("DBSubnetGroupName")
  valid_595617 = validateParameter(valid_595617, JString, required = true,
                                 default = nil)
  if valid_595617 != nil:
    section.add "DBSubnetGroupName", valid_595617
  var valid_595618 = query.getOrDefault("SubnetIds")
  valid_595618 = validateParameter(valid_595618, JArray, required = true, default = nil)
  if valid_595618 != nil:
    section.add "SubnetIds", valid_595618
  var valid_595619 = query.getOrDefault("DBSubnetGroupDescription")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "DBSubnetGroupDescription", valid_595619
  var valid_595620 = query.getOrDefault("Version")
  valid_595620 = validateParameter(valid_595620, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595620 != nil:
    section.add "Version", valid_595620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595621 = header.getOrDefault("X-Amz-Date")
  valid_595621 = validateParameter(valid_595621, JString, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "X-Amz-Date", valid_595621
  var valid_595622 = header.getOrDefault("X-Amz-Security-Token")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "X-Amz-Security-Token", valid_595622
  var valid_595623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-Content-Sha256", valid_595623
  var valid_595624 = header.getOrDefault("X-Amz-Algorithm")
  valid_595624 = validateParameter(valid_595624, JString, required = false,
                                 default = nil)
  if valid_595624 != nil:
    section.add "X-Amz-Algorithm", valid_595624
  var valid_595625 = header.getOrDefault("X-Amz-Signature")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "X-Amz-Signature", valid_595625
  var valid_595626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "X-Amz-SignedHeaders", valid_595626
  var valid_595627 = header.getOrDefault("X-Amz-Credential")
  valid_595627 = validateParameter(valid_595627, JString, required = false,
                                 default = nil)
  if valid_595627 != nil:
    section.add "X-Amz-Credential", valid_595627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595628: Call_GetModifyDBSubnetGroup_595613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595628.validator(path, query, header, formData, body)
  let scheme = call_595628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595628.url(scheme.get, call_595628.host, call_595628.base,
                         call_595628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595628, url, valid)

proc call*(call_595629: Call_GetModifyDBSubnetGroup_595613;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_595630 = newJObject()
  add(query_595630, "Action", newJString(Action))
  add(query_595630, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_595630.add "SubnetIds", SubnetIds
  add(query_595630, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595630, "Version", newJString(Version))
  result = call_595629.call(nil, query_595630, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_595613(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_595614, base: "/",
    url: url_GetModifyDBSubnetGroup_595615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_595670 = ref object of OpenApiRestCall_593421
proc url_PostModifyEventSubscription_595672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_595671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595673 = query.getOrDefault("Action")
  valid_595673 = validateParameter(valid_595673, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595673 != nil:
    section.add "Action", valid_595673
  var valid_595674 = query.getOrDefault("Version")
  valid_595674 = validateParameter(valid_595674, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595674 != nil:
    section.add "Version", valid_595674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595675 = header.getOrDefault("X-Amz-Date")
  valid_595675 = validateParameter(valid_595675, JString, required = false,
                                 default = nil)
  if valid_595675 != nil:
    section.add "X-Amz-Date", valid_595675
  var valid_595676 = header.getOrDefault("X-Amz-Security-Token")
  valid_595676 = validateParameter(valid_595676, JString, required = false,
                                 default = nil)
  if valid_595676 != nil:
    section.add "X-Amz-Security-Token", valid_595676
  var valid_595677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595677 = validateParameter(valid_595677, JString, required = false,
                                 default = nil)
  if valid_595677 != nil:
    section.add "X-Amz-Content-Sha256", valid_595677
  var valid_595678 = header.getOrDefault("X-Amz-Algorithm")
  valid_595678 = validateParameter(valid_595678, JString, required = false,
                                 default = nil)
  if valid_595678 != nil:
    section.add "X-Amz-Algorithm", valid_595678
  var valid_595679 = header.getOrDefault("X-Amz-Signature")
  valid_595679 = validateParameter(valid_595679, JString, required = false,
                                 default = nil)
  if valid_595679 != nil:
    section.add "X-Amz-Signature", valid_595679
  var valid_595680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595680 = validateParameter(valid_595680, JString, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "X-Amz-SignedHeaders", valid_595680
  var valid_595681 = header.getOrDefault("X-Amz-Credential")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Credential", valid_595681
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_595682 = formData.getOrDefault("Enabled")
  valid_595682 = validateParameter(valid_595682, JBool, required = false, default = nil)
  if valid_595682 != nil:
    section.add "Enabled", valid_595682
  var valid_595683 = formData.getOrDefault("EventCategories")
  valid_595683 = validateParameter(valid_595683, JArray, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "EventCategories", valid_595683
  var valid_595684 = formData.getOrDefault("SnsTopicArn")
  valid_595684 = validateParameter(valid_595684, JString, required = false,
                                 default = nil)
  if valid_595684 != nil:
    section.add "SnsTopicArn", valid_595684
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_595685 = formData.getOrDefault("SubscriptionName")
  valid_595685 = validateParameter(valid_595685, JString, required = true,
                                 default = nil)
  if valid_595685 != nil:
    section.add "SubscriptionName", valid_595685
  var valid_595686 = formData.getOrDefault("SourceType")
  valid_595686 = validateParameter(valid_595686, JString, required = false,
                                 default = nil)
  if valid_595686 != nil:
    section.add "SourceType", valid_595686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595687: Call_PostModifyEventSubscription_595670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595687.validator(path, query, header, formData, body)
  let scheme = call_595687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595687.url(scheme.get, call_595687.host, call_595687.base,
                         call_595687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595687, url, valid)

proc call*(call_595688: Call_PostModifyEventSubscription_595670;
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
  var query_595689 = newJObject()
  var formData_595690 = newJObject()
  add(formData_595690, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_595690.add "EventCategories", EventCategories
  add(formData_595690, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_595690, "SubscriptionName", newJString(SubscriptionName))
  add(query_595689, "Action", newJString(Action))
  add(query_595689, "Version", newJString(Version))
  add(formData_595690, "SourceType", newJString(SourceType))
  result = call_595688.call(nil, query_595689, nil, formData_595690, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_595670(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_595671, base: "/",
    url: url_PostModifyEventSubscription_595672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_595650 = ref object of OpenApiRestCall_593421
proc url_GetModifyEventSubscription_595652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_595651(path: JsonNode; query: JsonNode;
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
  var valid_595653 = query.getOrDefault("SourceType")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "SourceType", valid_595653
  var valid_595654 = query.getOrDefault("Enabled")
  valid_595654 = validateParameter(valid_595654, JBool, required = false, default = nil)
  if valid_595654 != nil:
    section.add "Enabled", valid_595654
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595655 = query.getOrDefault("Action")
  valid_595655 = validateParameter(valid_595655, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_595655 != nil:
    section.add "Action", valid_595655
  var valid_595656 = query.getOrDefault("SnsTopicArn")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "SnsTopicArn", valid_595656
  var valid_595657 = query.getOrDefault("EventCategories")
  valid_595657 = validateParameter(valid_595657, JArray, required = false,
                                 default = nil)
  if valid_595657 != nil:
    section.add "EventCategories", valid_595657
  var valid_595658 = query.getOrDefault("SubscriptionName")
  valid_595658 = validateParameter(valid_595658, JString, required = true,
                                 default = nil)
  if valid_595658 != nil:
    section.add "SubscriptionName", valid_595658
  var valid_595659 = query.getOrDefault("Version")
  valid_595659 = validateParameter(valid_595659, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595659 != nil:
    section.add "Version", valid_595659
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595660 = header.getOrDefault("X-Amz-Date")
  valid_595660 = validateParameter(valid_595660, JString, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "X-Amz-Date", valid_595660
  var valid_595661 = header.getOrDefault("X-Amz-Security-Token")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "X-Amz-Security-Token", valid_595661
  var valid_595662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Content-Sha256", valid_595662
  var valid_595663 = header.getOrDefault("X-Amz-Algorithm")
  valid_595663 = validateParameter(valid_595663, JString, required = false,
                                 default = nil)
  if valid_595663 != nil:
    section.add "X-Amz-Algorithm", valid_595663
  var valid_595664 = header.getOrDefault("X-Amz-Signature")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "X-Amz-Signature", valid_595664
  var valid_595665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "X-Amz-SignedHeaders", valid_595665
  var valid_595666 = header.getOrDefault("X-Amz-Credential")
  valid_595666 = validateParameter(valid_595666, JString, required = false,
                                 default = nil)
  if valid_595666 != nil:
    section.add "X-Amz-Credential", valid_595666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595667: Call_GetModifyEventSubscription_595650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595667.validator(path, query, header, formData, body)
  let scheme = call_595667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595667.url(scheme.get, call_595667.host, call_595667.base,
                         call_595667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595667, url, valid)

proc call*(call_595668: Call_GetModifyEventSubscription_595650;
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
  var query_595669 = newJObject()
  add(query_595669, "SourceType", newJString(SourceType))
  add(query_595669, "Enabled", newJBool(Enabled))
  add(query_595669, "Action", newJString(Action))
  add(query_595669, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_595669.add "EventCategories", EventCategories
  add(query_595669, "SubscriptionName", newJString(SubscriptionName))
  add(query_595669, "Version", newJString(Version))
  result = call_595668.call(nil, query_595669, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_595650(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_595651, base: "/",
    url: url_GetModifyEventSubscription_595652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_595710 = ref object of OpenApiRestCall_593421
proc url_PostModifyOptionGroup_595712(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_595711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595713 = query.getOrDefault("Action")
  valid_595713 = validateParameter(valid_595713, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595713 != nil:
    section.add "Action", valid_595713
  var valid_595714 = query.getOrDefault("Version")
  valid_595714 = validateParameter(valid_595714, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595714 != nil:
    section.add "Version", valid_595714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595715 = header.getOrDefault("X-Amz-Date")
  valid_595715 = validateParameter(valid_595715, JString, required = false,
                                 default = nil)
  if valid_595715 != nil:
    section.add "X-Amz-Date", valid_595715
  var valid_595716 = header.getOrDefault("X-Amz-Security-Token")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "X-Amz-Security-Token", valid_595716
  var valid_595717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595717 = validateParameter(valid_595717, JString, required = false,
                                 default = nil)
  if valid_595717 != nil:
    section.add "X-Amz-Content-Sha256", valid_595717
  var valid_595718 = header.getOrDefault("X-Amz-Algorithm")
  valid_595718 = validateParameter(valid_595718, JString, required = false,
                                 default = nil)
  if valid_595718 != nil:
    section.add "X-Amz-Algorithm", valid_595718
  var valid_595719 = header.getOrDefault("X-Amz-Signature")
  valid_595719 = validateParameter(valid_595719, JString, required = false,
                                 default = nil)
  if valid_595719 != nil:
    section.add "X-Amz-Signature", valid_595719
  var valid_595720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595720 = validateParameter(valid_595720, JString, required = false,
                                 default = nil)
  if valid_595720 != nil:
    section.add "X-Amz-SignedHeaders", valid_595720
  var valid_595721 = header.getOrDefault("X-Amz-Credential")
  valid_595721 = validateParameter(valid_595721, JString, required = false,
                                 default = nil)
  if valid_595721 != nil:
    section.add "X-Amz-Credential", valid_595721
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_595722 = formData.getOrDefault("OptionsToRemove")
  valid_595722 = validateParameter(valid_595722, JArray, required = false,
                                 default = nil)
  if valid_595722 != nil:
    section.add "OptionsToRemove", valid_595722
  var valid_595723 = formData.getOrDefault("ApplyImmediately")
  valid_595723 = validateParameter(valid_595723, JBool, required = false, default = nil)
  if valid_595723 != nil:
    section.add "ApplyImmediately", valid_595723
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_595724 = formData.getOrDefault("OptionGroupName")
  valid_595724 = validateParameter(valid_595724, JString, required = true,
                                 default = nil)
  if valid_595724 != nil:
    section.add "OptionGroupName", valid_595724
  var valid_595725 = formData.getOrDefault("OptionsToInclude")
  valid_595725 = validateParameter(valid_595725, JArray, required = false,
                                 default = nil)
  if valid_595725 != nil:
    section.add "OptionsToInclude", valid_595725
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595726: Call_PostModifyOptionGroup_595710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595726.validator(path, query, header, formData, body)
  let scheme = call_595726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595726.url(scheme.get, call_595726.host, call_595726.base,
                         call_595726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595726, url, valid)

proc call*(call_595727: Call_PostModifyOptionGroup_595710; OptionGroupName: string;
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
  var query_595728 = newJObject()
  var formData_595729 = newJObject()
  if OptionsToRemove != nil:
    formData_595729.add "OptionsToRemove", OptionsToRemove
  add(formData_595729, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595729, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_595729.add "OptionsToInclude", OptionsToInclude
  add(query_595728, "Action", newJString(Action))
  add(query_595728, "Version", newJString(Version))
  result = call_595727.call(nil, query_595728, nil, formData_595729, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_595710(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_595711, base: "/",
    url: url_PostModifyOptionGroup_595712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_595691 = ref object of OpenApiRestCall_593421
proc url_GetModifyOptionGroup_595693(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_595692(path: JsonNode; query: JsonNode;
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
  var valid_595694 = query.getOrDefault("OptionGroupName")
  valid_595694 = validateParameter(valid_595694, JString, required = true,
                                 default = nil)
  if valid_595694 != nil:
    section.add "OptionGroupName", valid_595694
  var valid_595695 = query.getOrDefault("OptionsToRemove")
  valid_595695 = validateParameter(valid_595695, JArray, required = false,
                                 default = nil)
  if valid_595695 != nil:
    section.add "OptionsToRemove", valid_595695
  var valid_595696 = query.getOrDefault("Action")
  valid_595696 = validateParameter(valid_595696, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_595696 != nil:
    section.add "Action", valid_595696
  var valid_595697 = query.getOrDefault("Version")
  valid_595697 = validateParameter(valid_595697, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595697 != nil:
    section.add "Version", valid_595697
  var valid_595698 = query.getOrDefault("ApplyImmediately")
  valid_595698 = validateParameter(valid_595698, JBool, required = false, default = nil)
  if valid_595698 != nil:
    section.add "ApplyImmediately", valid_595698
  var valid_595699 = query.getOrDefault("OptionsToInclude")
  valid_595699 = validateParameter(valid_595699, JArray, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "OptionsToInclude", valid_595699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595700 = header.getOrDefault("X-Amz-Date")
  valid_595700 = validateParameter(valid_595700, JString, required = false,
                                 default = nil)
  if valid_595700 != nil:
    section.add "X-Amz-Date", valid_595700
  var valid_595701 = header.getOrDefault("X-Amz-Security-Token")
  valid_595701 = validateParameter(valid_595701, JString, required = false,
                                 default = nil)
  if valid_595701 != nil:
    section.add "X-Amz-Security-Token", valid_595701
  var valid_595702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595702 = validateParameter(valid_595702, JString, required = false,
                                 default = nil)
  if valid_595702 != nil:
    section.add "X-Amz-Content-Sha256", valid_595702
  var valid_595703 = header.getOrDefault("X-Amz-Algorithm")
  valid_595703 = validateParameter(valid_595703, JString, required = false,
                                 default = nil)
  if valid_595703 != nil:
    section.add "X-Amz-Algorithm", valid_595703
  var valid_595704 = header.getOrDefault("X-Amz-Signature")
  valid_595704 = validateParameter(valid_595704, JString, required = false,
                                 default = nil)
  if valid_595704 != nil:
    section.add "X-Amz-Signature", valid_595704
  var valid_595705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595705 = validateParameter(valid_595705, JString, required = false,
                                 default = nil)
  if valid_595705 != nil:
    section.add "X-Amz-SignedHeaders", valid_595705
  var valid_595706 = header.getOrDefault("X-Amz-Credential")
  valid_595706 = validateParameter(valid_595706, JString, required = false,
                                 default = nil)
  if valid_595706 != nil:
    section.add "X-Amz-Credential", valid_595706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595707: Call_GetModifyOptionGroup_595691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595707.validator(path, query, header, formData, body)
  let scheme = call_595707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595707.url(scheme.get, call_595707.host, call_595707.base,
                         call_595707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595707, url, valid)

proc call*(call_595708: Call_GetModifyOptionGroup_595691; OptionGroupName: string;
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
  var query_595709 = newJObject()
  add(query_595709, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_595709.add "OptionsToRemove", OptionsToRemove
  add(query_595709, "Action", newJString(Action))
  add(query_595709, "Version", newJString(Version))
  add(query_595709, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_595709.add "OptionsToInclude", OptionsToInclude
  result = call_595708.call(nil, query_595709, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_595691(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_595692, base: "/",
    url: url_GetModifyOptionGroup_595693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_595748 = ref object of OpenApiRestCall_593421
proc url_PostPromoteReadReplica_595750(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_595749(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595751 = query.getOrDefault("Action")
  valid_595751 = validateParameter(valid_595751, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595751 != nil:
    section.add "Action", valid_595751
  var valid_595752 = query.getOrDefault("Version")
  valid_595752 = validateParameter(valid_595752, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595752 != nil:
    section.add "Version", valid_595752
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595753 = header.getOrDefault("X-Amz-Date")
  valid_595753 = validateParameter(valid_595753, JString, required = false,
                                 default = nil)
  if valid_595753 != nil:
    section.add "X-Amz-Date", valid_595753
  var valid_595754 = header.getOrDefault("X-Amz-Security-Token")
  valid_595754 = validateParameter(valid_595754, JString, required = false,
                                 default = nil)
  if valid_595754 != nil:
    section.add "X-Amz-Security-Token", valid_595754
  var valid_595755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595755 = validateParameter(valid_595755, JString, required = false,
                                 default = nil)
  if valid_595755 != nil:
    section.add "X-Amz-Content-Sha256", valid_595755
  var valid_595756 = header.getOrDefault("X-Amz-Algorithm")
  valid_595756 = validateParameter(valid_595756, JString, required = false,
                                 default = nil)
  if valid_595756 != nil:
    section.add "X-Amz-Algorithm", valid_595756
  var valid_595757 = header.getOrDefault("X-Amz-Signature")
  valid_595757 = validateParameter(valid_595757, JString, required = false,
                                 default = nil)
  if valid_595757 != nil:
    section.add "X-Amz-Signature", valid_595757
  var valid_595758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595758 = validateParameter(valid_595758, JString, required = false,
                                 default = nil)
  if valid_595758 != nil:
    section.add "X-Amz-SignedHeaders", valid_595758
  var valid_595759 = header.getOrDefault("X-Amz-Credential")
  valid_595759 = validateParameter(valid_595759, JString, required = false,
                                 default = nil)
  if valid_595759 != nil:
    section.add "X-Amz-Credential", valid_595759
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595760 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595760 = validateParameter(valid_595760, JString, required = true,
                                 default = nil)
  if valid_595760 != nil:
    section.add "DBInstanceIdentifier", valid_595760
  var valid_595761 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595761 = validateParameter(valid_595761, JInt, required = false, default = nil)
  if valid_595761 != nil:
    section.add "BackupRetentionPeriod", valid_595761
  var valid_595762 = formData.getOrDefault("PreferredBackupWindow")
  valid_595762 = validateParameter(valid_595762, JString, required = false,
                                 default = nil)
  if valid_595762 != nil:
    section.add "PreferredBackupWindow", valid_595762
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595763: Call_PostPromoteReadReplica_595748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595763.validator(path, query, header, formData, body)
  let scheme = call_595763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595763.url(scheme.get, call_595763.host, call_595763.base,
                         call_595763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595763, url, valid)

proc call*(call_595764: Call_PostPromoteReadReplica_595748;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_595765 = newJObject()
  var formData_595766 = newJObject()
  add(formData_595766, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595766, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595765, "Action", newJString(Action))
  add(formData_595766, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595765, "Version", newJString(Version))
  result = call_595764.call(nil, query_595765, nil, formData_595766, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_595748(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_595749, base: "/",
    url: url_PostPromoteReadReplica_595750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_595730 = ref object of OpenApiRestCall_593421
proc url_GetPromoteReadReplica_595732(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_595731(path: JsonNode; query: JsonNode;
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
  var valid_595733 = query.getOrDefault("BackupRetentionPeriod")
  valid_595733 = validateParameter(valid_595733, JInt, required = false, default = nil)
  if valid_595733 != nil:
    section.add "BackupRetentionPeriod", valid_595733
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595734 = query.getOrDefault("Action")
  valid_595734 = validateParameter(valid_595734, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_595734 != nil:
    section.add "Action", valid_595734
  var valid_595735 = query.getOrDefault("PreferredBackupWindow")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "PreferredBackupWindow", valid_595735
  var valid_595736 = query.getOrDefault("Version")
  valid_595736 = validateParameter(valid_595736, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595736 != nil:
    section.add "Version", valid_595736
  var valid_595737 = query.getOrDefault("DBInstanceIdentifier")
  valid_595737 = validateParameter(valid_595737, JString, required = true,
                                 default = nil)
  if valid_595737 != nil:
    section.add "DBInstanceIdentifier", valid_595737
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595738 = header.getOrDefault("X-Amz-Date")
  valid_595738 = validateParameter(valid_595738, JString, required = false,
                                 default = nil)
  if valid_595738 != nil:
    section.add "X-Amz-Date", valid_595738
  var valid_595739 = header.getOrDefault("X-Amz-Security-Token")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-Security-Token", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Content-Sha256", valid_595740
  var valid_595741 = header.getOrDefault("X-Amz-Algorithm")
  valid_595741 = validateParameter(valid_595741, JString, required = false,
                                 default = nil)
  if valid_595741 != nil:
    section.add "X-Amz-Algorithm", valid_595741
  var valid_595742 = header.getOrDefault("X-Amz-Signature")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "X-Amz-Signature", valid_595742
  var valid_595743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595743 = validateParameter(valid_595743, JString, required = false,
                                 default = nil)
  if valid_595743 != nil:
    section.add "X-Amz-SignedHeaders", valid_595743
  var valid_595744 = header.getOrDefault("X-Amz-Credential")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "X-Amz-Credential", valid_595744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595745: Call_GetPromoteReadReplica_595730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595745.validator(path, query, header, formData, body)
  let scheme = call_595745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595745.url(scheme.get, call_595745.host, call_595745.base,
                         call_595745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595745, url, valid)

proc call*(call_595746: Call_GetPromoteReadReplica_595730;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595747 = newJObject()
  add(query_595747, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595747, "Action", newJString(Action))
  add(query_595747, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595747, "Version", newJString(Version))
  add(query_595747, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595746.call(nil, query_595747, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_595730(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_595731, base: "/",
    url: url_GetPromoteReadReplica_595732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_595785 = ref object of OpenApiRestCall_593421
proc url_PostPurchaseReservedDBInstancesOffering_595787(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_595786(path: JsonNode;
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
  var valid_595788 = query.getOrDefault("Action")
  valid_595788 = validateParameter(valid_595788, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595788 != nil:
    section.add "Action", valid_595788
  var valid_595789 = query.getOrDefault("Version")
  valid_595789 = validateParameter(valid_595789, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595789 != nil:
    section.add "Version", valid_595789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595790 = header.getOrDefault("X-Amz-Date")
  valid_595790 = validateParameter(valid_595790, JString, required = false,
                                 default = nil)
  if valid_595790 != nil:
    section.add "X-Amz-Date", valid_595790
  var valid_595791 = header.getOrDefault("X-Amz-Security-Token")
  valid_595791 = validateParameter(valid_595791, JString, required = false,
                                 default = nil)
  if valid_595791 != nil:
    section.add "X-Amz-Security-Token", valid_595791
  var valid_595792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595792 = validateParameter(valid_595792, JString, required = false,
                                 default = nil)
  if valid_595792 != nil:
    section.add "X-Amz-Content-Sha256", valid_595792
  var valid_595793 = header.getOrDefault("X-Amz-Algorithm")
  valid_595793 = validateParameter(valid_595793, JString, required = false,
                                 default = nil)
  if valid_595793 != nil:
    section.add "X-Amz-Algorithm", valid_595793
  var valid_595794 = header.getOrDefault("X-Amz-Signature")
  valid_595794 = validateParameter(valid_595794, JString, required = false,
                                 default = nil)
  if valid_595794 != nil:
    section.add "X-Amz-Signature", valid_595794
  var valid_595795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595795 = validateParameter(valid_595795, JString, required = false,
                                 default = nil)
  if valid_595795 != nil:
    section.add "X-Amz-SignedHeaders", valid_595795
  var valid_595796 = header.getOrDefault("X-Amz-Credential")
  valid_595796 = validateParameter(valid_595796, JString, required = false,
                                 default = nil)
  if valid_595796 != nil:
    section.add "X-Amz-Credential", valid_595796
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_595797 = formData.getOrDefault("ReservedDBInstanceId")
  valid_595797 = validateParameter(valid_595797, JString, required = false,
                                 default = nil)
  if valid_595797 != nil:
    section.add "ReservedDBInstanceId", valid_595797
  var valid_595798 = formData.getOrDefault("DBInstanceCount")
  valid_595798 = validateParameter(valid_595798, JInt, required = false, default = nil)
  if valid_595798 != nil:
    section.add "DBInstanceCount", valid_595798
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595799 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595799 = validateParameter(valid_595799, JString, required = true,
                                 default = nil)
  if valid_595799 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595799
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595800: Call_PostPurchaseReservedDBInstancesOffering_595785;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595800.validator(path, query, header, formData, body)
  let scheme = call_595800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595800.url(scheme.get, call_595800.host, call_595800.base,
                         call_595800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595800, url, valid)

proc call*(call_595801: Call_PostPurchaseReservedDBInstancesOffering_595785;
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
  var query_595802 = newJObject()
  var formData_595803 = newJObject()
  add(formData_595803, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_595803, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595802, "Action", newJString(Action))
  add(formData_595803, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595802, "Version", newJString(Version))
  result = call_595801.call(nil, query_595802, nil, formData_595803, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_595785(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_595786, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_595787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_595767 = ref object of OpenApiRestCall_593421
proc url_GetPurchaseReservedDBInstancesOffering_595769(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_595768(path: JsonNode;
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
  var valid_595770 = query.getOrDefault("DBInstanceCount")
  valid_595770 = validateParameter(valid_595770, JInt, required = false, default = nil)
  if valid_595770 != nil:
    section.add "DBInstanceCount", valid_595770
  var valid_595771 = query.getOrDefault("ReservedDBInstanceId")
  valid_595771 = validateParameter(valid_595771, JString, required = false,
                                 default = nil)
  if valid_595771 != nil:
    section.add "ReservedDBInstanceId", valid_595771
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_595772 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_595772 = validateParameter(valid_595772, JString, required = true,
                                 default = nil)
  if valid_595772 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_595772
  var valid_595773 = query.getOrDefault("Action")
  valid_595773 = validateParameter(valid_595773, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_595773 != nil:
    section.add "Action", valid_595773
  var valid_595774 = query.getOrDefault("Version")
  valid_595774 = validateParameter(valid_595774, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595774 != nil:
    section.add "Version", valid_595774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595775 = header.getOrDefault("X-Amz-Date")
  valid_595775 = validateParameter(valid_595775, JString, required = false,
                                 default = nil)
  if valid_595775 != nil:
    section.add "X-Amz-Date", valid_595775
  var valid_595776 = header.getOrDefault("X-Amz-Security-Token")
  valid_595776 = validateParameter(valid_595776, JString, required = false,
                                 default = nil)
  if valid_595776 != nil:
    section.add "X-Amz-Security-Token", valid_595776
  var valid_595777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595777 = validateParameter(valid_595777, JString, required = false,
                                 default = nil)
  if valid_595777 != nil:
    section.add "X-Amz-Content-Sha256", valid_595777
  var valid_595778 = header.getOrDefault("X-Amz-Algorithm")
  valid_595778 = validateParameter(valid_595778, JString, required = false,
                                 default = nil)
  if valid_595778 != nil:
    section.add "X-Amz-Algorithm", valid_595778
  var valid_595779 = header.getOrDefault("X-Amz-Signature")
  valid_595779 = validateParameter(valid_595779, JString, required = false,
                                 default = nil)
  if valid_595779 != nil:
    section.add "X-Amz-Signature", valid_595779
  var valid_595780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595780 = validateParameter(valid_595780, JString, required = false,
                                 default = nil)
  if valid_595780 != nil:
    section.add "X-Amz-SignedHeaders", valid_595780
  var valid_595781 = header.getOrDefault("X-Amz-Credential")
  valid_595781 = validateParameter(valid_595781, JString, required = false,
                                 default = nil)
  if valid_595781 != nil:
    section.add "X-Amz-Credential", valid_595781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595782: Call_GetPurchaseReservedDBInstancesOffering_595767;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595782.validator(path, query, header, formData, body)
  let scheme = call_595782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595782.url(scheme.get, call_595782.host, call_595782.base,
                         call_595782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595782, url, valid)

proc call*(call_595783: Call_GetPurchaseReservedDBInstancesOffering_595767;
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
  var query_595784 = newJObject()
  add(query_595784, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_595784, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_595784, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_595784, "Action", newJString(Action))
  add(query_595784, "Version", newJString(Version))
  result = call_595783.call(nil, query_595784, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_595767(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_595768, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_595769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_595821 = ref object of OpenApiRestCall_593421
proc url_PostRebootDBInstance_595823(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_595822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595824 = query.getOrDefault("Action")
  valid_595824 = validateParameter(valid_595824, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595824 != nil:
    section.add "Action", valid_595824
  var valid_595825 = query.getOrDefault("Version")
  valid_595825 = validateParameter(valid_595825, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595825 != nil:
    section.add "Version", valid_595825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595826 = header.getOrDefault("X-Amz-Date")
  valid_595826 = validateParameter(valid_595826, JString, required = false,
                                 default = nil)
  if valid_595826 != nil:
    section.add "X-Amz-Date", valid_595826
  var valid_595827 = header.getOrDefault("X-Amz-Security-Token")
  valid_595827 = validateParameter(valid_595827, JString, required = false,
                                 default = nil)
  if valid_595827 != nil:
    section.add "X-Amz-Security-Token", valid_595827
  var valid_595828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595828 = validateParameter(valid_595828, JString, required = false,
                                 default = nil)
  if valid_595828 != nil:
    section.add "X-Amz-Content-Sha256", valid_595828
  var valid_595829 = header.getOrDefault("X-Amz-Algorithm")
  valid_595829 = validateParameter(valid_595829, JString, required = false,
                                 default = nil)
  if valid_595829 != nil:
    section.add "X-Amz-Algorithm", valid_595829
  var valid_595830 = header.getOrDefault("X-Amz-Signature")
  valid_595830 = validateParameter(valid_595830, JString, required = false,
                                 default = nil)
  if valid_595830 != nil:
    section.add "X-Amz-Signature", valid_595830
  var valid_595831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595831 = validateParameter(valid_595831, JString, required = false,
                                 default = nil)
  if valid_595831 != nil:
    section.add "X-Amz-SignedHeaders", valid_595831
  var valid_595832 = header.getOrDefault("X-Amz-Credential")
  valid_595832 = validateParameter(valid_595832, JString, required = false,
                                 default = nil)
  if valid_595832 != nil:
    section.add "X-Amz-Credential", valid_595832
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595833 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595833 = validateParameter(valid_595833, JString, required = true,
                                 default = nil)
  if valid_595833 != nil:
    section.add "DBInstanceIdentifier", valid_595833
  var valid_595834 = formData.getOrDefault("ForceFailover")
  valid_595834 = validateParameter(valid_595834, JBool, required = false, default = nil)
  if valid_595834 != nil:
    section.add "ForceFailover", valid_595834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595835: Call_PostRebootDBInstance_595821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595835.validator(path, query, header, formData, body)
  let scheme = call_595835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595835.url(scheme.get, call_595835.host, call_595835.base,
                         call_595835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595835, url, valid)

proc call*(call_595836: Call_PostRebootDBInstance_595821;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_595837 = newJObject()
  var formData_595838 = newJObject()
  add(formData_595838, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595837, "Action", newJString(Action))
  add(formData_595838, "ForceFailover", newJBool(ForceFailover))
  add(query_595837, "Version", newJString(Version))
  result = call_595836.call(nil, query_595837, nil, formData_595838, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_595821(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_595822, base: "/",
    url: url_PostRebootDBInstance_595823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_595804 = ref object of OpenApiRestCall_593421
proc url_GetRebootDBInstance_595806(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_595805(path: JsonNode; query: JsonNode;
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
  var valid_595807 = query.getOrDefault("Action")
  valid_595807 = validateParameter(valid_595807, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595807 != nil:
    section.add "Action", valid_595807
  var valid_595808 = query.getOrDefault("ForceFailover")
  valid_595808 = validateParameter(valid_595808, JBool, required = false, default = nil)
  if valid_595808 != nil:
    section.add "ForceFailover", valid_595808
  var valid_595809 = query.getOrDefault("Version")
  valid_595809 = validateParameter(valid_595809, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595809 != nil:
    section.add "Version", valid_595809
  var valid_595810 = query.getOrDefault("DBInstanceIdentifier")
  valid_595810 = validateParameter(valid_595810, JString, required = true,
                                 default = nil)
  if valid_595810 != nil:
    section.add "DBInstanceIdentifier", valid_595810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595811 = header.getOrDefault("X-Amz-Date")
  valid_595811 = validateParameter(valid_595811, JString, required = false,
                                 default = nil)
  if valid_595811 != nil:
    section.add "X-Amz-Date", valid_595811
  var valid_595812 = header.getOrDefault("X-Amz-Security-Token")
  valid_595812 = validateParameter(valid_595812, JString, required = false,
                                 default = nil)
  if valid_595812 != nil:
    section.add "X-Amz-Security-Token", valid_595812
  var valid_595813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595813 = validateParameter(valid_595813, JString, required = false,
                                 default = nil)
  if valid_595813 != nil:
    section.add "X-Amz-Content-Sha256", valid_595813
  var valid_595814 = header.getOrDefault("X-Amz-Algorithm")
  valid_595814 = validateParameter(valid_595814, JString, required = false,
                                 default = nil)
  if valid_595814 != nil:
    section.add "X-Amz-Algorithm", valid_595814
  var valid_595815 = header.getOrDefault("X-Amz-Signature")
  valid_595815 = validateParameter(valid_595815, JString, required = false,
                                 default = nil)
  if valid_595815 != nil:
    section.add "X-Amz-Signature", valid_595815
  var valid_595816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595816 = validateParameter(valid_595816, JString, required = false,
                                 default = nil)
  if valid_595816 != nil:
    section.add "X-Amz-SignedHeaders", valid_595816
  var valid_595817 = header.getOrDefault("X-Amz-Credential")
  valid_595817 = validateParameter(valid_595817, JString, required = false,
                                 default = nil)
  if valid_595817 != nil:
    section.add "X-Amz-Credential", valid_595817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595818: Call_GetRebootDBInstance_595804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595818.validator(path, query, header, formData, body)
  let scheme = call_595818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595818.url(scheme.get, call_595818.host, call_595818.base,
                         call_595818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595818, url, valid)

proc call*(call_595819: Call_GetRebootDBInstance_595804;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_595820 = newJObject()
  add(query_595820, "Action", newJString(Action))
  add(query_595820, "ForceFailover", newJBool(ForceFailover))
  add(query_595820, "Version", newJString(Version))
  add(query_595820, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595819.call(nil, query_595820, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_595804(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_595805, base: "/",
    url: url_GetRebootDBInstance_595806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_595856 = ref object of OpenApiRestCall_593421
proc url_PostRemoveSourceIdentifierFromSubscription_595858(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_595857(path: JsonNode;
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
  var valid_595859 = query.getOrDefault("Action")
  valid_595859 = validateParameter(valid_595859, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595859 != nil:
    section.add "Action", valid_595859
  var valid_595860 = query.getOrDefault("Version")
  valid_595860 = validateParameter(valid_595860, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595860 != nil:
    section.add "Version", valid_595860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595861 = header.getOrDefault("X-Amz-Date")
  valid_595861 = validateParameter(valid_595861, JString, required = false,
                                 default = nil)
  if valid_595861 != nil:
    section.add "X-Amz-Date", valid_595861
  var valid_595862 = header.getOrDefault("X-Amz-Security-Token")
  valid_595862 = validateParameter(valid_595862, JString, required = false,
                                 default = nil)
  if valid_595862 != nil:
    section.add "X-Amz-Security-Token", valid_595862
  var valid_595863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595863 = validateParameter(valid_595863, JString, required = false,
                                 default = nil)
  if valid_595863 != nil:
    section.add "X-Amz-Content-Sha256", valid_595863
  var valid_595864 = header.getOrDefault("X-Amz-Algorithm")
  valid_595864 = validateParameter(valid_595864, JString, required = false,
                                 default = nil)
  if valid_595864 != nil:
    section.add "X-Amz-Algorithm", valid_595864
  var valid_595865 = header.getOrDefault("X-Amz-Signature")
  valid_595865 = validateParameter(valid_595865, JString, required = false,
                                 default = nil)
  if valid_595865 != nil:
    section.add "X-Amz-Signature", valid_595865
  var valid_595866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595866 = validateParameter(valid_595866, JString, required = false,
                                 default = nil)
  if valid_595866 != nil:
    section.add "X-Amz-SignedHeaders", valid_595866
  var valid_595867 = header.getOrDefault("X-Amz-Credential")
  valid_595867 = validateParameter(valid_595867, JString, required = false,
                                 default = nil)
  if valid_595867 != nil:
    section.add "X-Amz-Credential", valid_595867
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_595868 = formData.getOrDefault("SourceIdentifier")
  valid_595868 = validateParameter(valid_595868, JString, required = true,
                                 default = nil)
  if valid_595868 != nil:
    section.add "SourceIdentifier", valid_595868
  var valid_595869 = formData.getOrDefault("SubscriptionName")
  valid_595869 = validateParameter(valid_595869, JString, required = true,
                                 default = nil)
  if valid_595869 != nil:
    section.add "SubscriptionName", valid_595869
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595870: Call_PostRemoveSourceIdentifierFromSubscription_595856;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595870.validator(path, query, header, formData, body)
  let scheme = call_595870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595870.url(scheme.get, call_595870.host, call_595870.base,
                         call_595870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595870, url, valid)

proc call*(call_595871: Call_PostRemoveSourceIdentifierFromSubscription_595856;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595872 = newJObject()
  var formData_595873 = newJObject()
  add(formData_595873, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_595873, "SubscriptionName", newJString(SubscriptionName))
  add(query_595872, "Action", newJString(Action))
  add(query_595872, "Version", newJString(Version))
  result = call_595871.call(nil, query_595872, nil, formData_595873, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_595856(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_595857,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_595858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_595839 = ref object of OpenApiRestCall_593421
proc url_GetRemoveSourceIdentifierFromSubscription_595841(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_595840(path: JsonNode;
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
  var valid_595842 = query.getOrDefault("Action")
  valid_595842 = validateParameter(valid_595842, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_595842 != nil:
    section.add "Action", valid_595842
  var valid_595843 = query.getOrDefault("SourceIdentifier")
  valid_595843 = validateParameter(valid_595843, JString, required = true,
                                 default = nil)
  if valid_595843 != nil:
    section.add "SourceIdentifier", valid_595843
  var valid_595844 = query.getOrDefault("SubscriptionName")
  valid_595844 = validateParameter(valid_595844, JString, required = true,
                                 default = nil)
  if valid_595844 != nil:
    section.add "SubscriptionName", valid_595844
  var valid_595845 = query.getOrDefault("Version")
  valid_595845 = validateParameter(valid_595845, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595845 != nil:
    section.add "Version", valid_595845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595846 = header.getOrDefault("X-Amz-Date")
  valid_595846 = validateParameter(valid_595846, JString, required = false,
                                 default = nil)
  if valid_595846 != nil:
    section.add "X-Amz-Date", valid_595846
  var valid_595847 = header.getOrDefault("X-Amz-Security-Token")
  valid_595847 = validateParameter(valid_595847, JString, required = false,
                                 default = nil)
  if valid_595847 != nil:
    section.add "X-Amz-Security-Token", valid_595847
  var valid_595848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595848 = validateParameter(valid_595848, JString, required = false,
                                 default = nil)
  if valid_595848 != nil:
    section.add "X-Amz-Content-Sha256", valid_595848
  var valid_595849 = header.getOrDefault("X-Amz-Algorithm")
  valid_595849 = validateParameter(valid_595849, JString, required = false,
                                 default = nil)
  if valid_595849 != nil:
    section.add "X-Amz-Algorithm", valid_595849
  var valid_595850 = header.getOrDefault("X-Amz-Signature")
  valid_595850 = validateParameter(valid_595850, JString, required = false,
                                 default = nil)
  if valid_595850 != nil:
    section.add "X-Amz-Signature", valid_595850
  var valid_595851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595851 = validateParameter(valid_595851, JString, required = false,
                                 default = nil)
  if valid_595851 != nil:
    section.add "X-Amz-SignedHeaders", valid_595851
  var valid_595852 = header.getOrDefault("X-Amz-Credential")
  valid_595852 = validateParameter(valid_595852, JString, required = false,
                                 default = nil)
  if valid_595852 != nil:
    section.add "X-Amz-Credential", valid_595852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595853: Call_GetRemoveSourceIdentifierFromSubscription_595839;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595853.validator(path, query, header, formData, body)
  let scheme = call_595853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595853.url(scheme.get, call_595853.host, call_595853.base,
                         call_595853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595853, url, valid)

proc call*(call_595854: Call_GetRemoveSourceIdentifierFromSubscription_595839;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_595855 = newJObject()
  add(query_595855, "Action", newJString(Action))
  add(query_595855, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_595855, "SubscriptionName", newJString(SubscriptionName))
  add(query_595855, "Version", newJString(Version))
  result = call_595854.call(nil, query_595855, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_595839(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_595840,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_595841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_595891 = ref object of OpenApiRestCall_593421
proc url_PostRemoveTagsFromResource_595893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_595892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595894 = query.getOrDefault("Action")
  valid_595894 = validateParameter(valid_595894, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595894 != nil:
    section.add "Action", valid_595894
  var valid_595895 = query.getOrDefault("Version")
  valid_595895 = validateParameter(valid_595895, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595895 != nil:
    section.add "Version", valid_595895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595896 = header.getOrDefault("X-Amz-Date")
  valid_595896 = validateParameter(valid_595896, JString, required = false,
                                 default = nil)
  if valid_595896 != nil:
    section.add "X-Amz-Date", valid_595896
  var valid_595897 = header.getOrDefault("X-Amz-Security-Token")
  valid_595897 = validateParameter(valid_595897, JString, required = false,
                                 default = nil)
  if valid_595897 != nil:
    section.add "X-Amz-Security-Token", valid_595897
  var valid_595898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595898 = validateParameter(valid_595898, JString, required = false,
                                 default = nil)
  if valid_595898 != nil:
    section.add "X-Amz-Content-Sha256", valid_595898
  var valid_595899 = header.getOrDefault("X-Amz-Algorithm")
  valid_595899 = validateParameter(valid_595899, JString, required = false,
                                 default = nil)
  if valid_595899 != nil:
    section.add "X-Amz-Algorithm", valid_595899
  var valid_595900 = header.getOrDefault("X-Amz-Signature")
  valid_595900 = validateParameter(valid_595900, JString, required = false,
                                 default = nil)
  if valid_595900 != nil:
    section.add "X-Amz-Signature", valid_595900
  var valid_595901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595901 = validateParameter(valid_595901, JString, required = false,
                                 default = nil)
  if valid_595901 != nil:
    section.add "X-Amz-SignedHeaders", valid_595901
  var valid_595902 = header.getOrDefault("X-Amz-Credential")
  valid_595902 = validateParameter(valid_595902, JString, required = false,
                                 default = nil)
  if valid_595902 != nil:
    section.add "X-Amz-Credential", valid_595902
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595903 = formData.getOrDefault("TagKeys")
  valid_595903 = validateParameter(valid_595903, JArray, required = true, default = nil)
  if valid_595903 != nil:
    section.add "TagKeys", valid_595903
  var valid_595904 = formData.getOrDefault("ResourceName")
  valid_595904 = validateParameter(valid_595904, JString, required = true,
                                 default = nil)
  if valid_595904 != nil:
    section.add "ResourceName", valid_595904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595905: Call_PostRemoveTagsFromResource_595891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595905.validator(path, query, header, formData, body)
  let scheme = call_595905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595905.url(scheme.get, call_595905.host, call_595905.base,
                         call_595905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595905, url, valid)

proc call*(call_595906: Call_PostRemoveTagsFromResource_595891; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_595907 = newJObject()
  var formData_595908 = newJObject()
  add(query_595907, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595908.add "TagKeys", TagKeys
  add(formData_595908, "ResourceName", newJString(ResourceName))
  add(query_595907, "Version", newJString(Version))
  result = call_595906.call(nil, query_595907, nil, formData_595908, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_595891(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_595892, base: "/",
    url: url_PostRemoveTagsFromResource_595893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_595874 = ref object of OpenApiRestCall_593421
proc url_GetRemoveTagsFromResource_595876(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_595875(path: JsonNode; query: JsonNode;
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
  var valid_595877 = query.getOrDefault("ResourceName")
  valid_595877 = validateParameter(valid_595877, JString, required = true,
                                 default = nil)
  if valid_595877 != nil:
    section.add "ResourceName", valid_595877
  var valid_595878 = query.getOrDefault("Action")
  valid_595878 = validateParameter(valid_595878, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595878 != nil:
    section.add "Action", valid_595878
  var valid_595879 = query.getOrDefault("TagKeys")
  valid_595879 = validateParameter(valid_595879, JArray, required = true, default = nil)
  if valid_595879 != nil:
    section.add "TagKeys", valid_595879
  var valid_595880 = query.getOrDefault("Version")
  valid_595880 = validateParameter(valid_595880, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595880 != nil:
    section.add "Version", valid_595880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595881 = header.getOrDefault("X-Amz-Date")
  valid_595881 = validateParameter(valid_595881, JString, required = false,
                                 default = nil)
  if valid_595881 != nil:
    section.add "X-Amz-Date", valid_595881
  var valid_595882 = header.getOrDefault("X-Amz-Security-Token")
  valid_595882 = validateParameter(valid_595882, JString, required = false,
                                 default = nil)
  if valid_595882 != nil:
    section.add "X-Amz-Security-Token", valid_595882
  var valid_595883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595883 = validateParameter(valid_595883, JString, required = false,
                                 default = nil)
  if valid_595883 != nil:
    section.add "X-Amz-Content-Sha256", valid_595883
  var valid_595884 = header.getOrDefault("X-Amz-Algorithm")
  valid_595884 = validateParameter(valid_595884, JString, required = false,
                                 default = nil)
  if valid_595884 != nil:
    section.add "X-Amz-Algorithm", valid_595884
  var valid_595885 = header.getOrDefault("X-Amz-Signature")
  valid_595885 = validateParameter(valid_595885, JString, required = false,
                                 default = nil)
  if valid_595885 != nil:
    section.add "X-Amz-Signature", valid_595885
  var valid_595886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595886 = validateParameter(valid_595886, JString, required = false,
                                 default = nil)
  if valid_595886 != nil:
    section.add "X-Amz-SignedHeaders", valid_595886
  var valid_595887 = header.getOrDefault("X-Amz-Credential")
  valid_595887 = validateParameter(valid_595887, JString, required = false,
                                 default = nil)
  if valid_595887 != nil:
    section.add "X-Amz-Credential", valid_595887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595888: Call_GetRemoveTagsFromResource_595874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595888.validator(path, query, header, formData, body)
  let scheme = call_595888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595888.url(scheme.get, call_595888.host, call_595888.base,
                         call_595888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595888, url, valid)

proc call*(call_595889: Call_GetRemoveTagsFromResource_595874;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_595890 = newJObject()
  add(query_595890, "ResourceName", newJString(ResourceName))
  add(query_595890, "Action", newJString(Action))
  if TagKeys != nil:
    query_595890.add "TagKeys", TagKeys
  add(query_595890, "Version", newJString(Version))
  result = call_595889.call(nil, query_595890, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_595874(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_595875, base: "/",
    url: url_GetRemoveTagsFromResource_595876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_595927 = ref object of OpenApiRestCall_593421
proc url_PostResetDBParameterGroup_595929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_595928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595930 = query.getOrDefault("Action")
  valid_595930 = validateParameter(valid_595930, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595930 != nil:
    section.add "Action", valid_595930
  var valid_595931 = query.getOrDefault("Version")
  valid_595931 = validateParameter(valid_595931, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595931 != nil:
    section.add "Version", valid_595931
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595932 = header.getOrDefault("X-Amz-Date")
  valid_595932 = validateParameter(valid_595932, JString, required = false,
                                 default = nil)
  if valid_595932 != nil:
    section.add "X-Amz-Date", valid_595932
  var valid_595933 = header.getOrDefault("X-Amz-Security-Token")
  valid_595933 = validateParameter(valid_595933, JString, required = false,
                                 default = nil)
  if valid_595933 != nil:
    section.add "X-Amz-Security-Token", valid_595933
  var valid_595934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595934 = validateParameter(valid_595934, JString, required = false,
                                 default = nil)
  if valid_595934 != nil:
    section.add "X-Amz-Content-Sha256", valid_595934
  var valid_595935 = header.getOrDefault("X-Amz-Algorithm")
  valid_595935 = validateParameter(valid_595935, JString, required = false,
                                 default = nil)
  if valid_595935 != nil:
    section.add "X-Amz-Algorithm", valid_595935
  var valid_595936 = header.getOrDefault("X-Amz-Signature")
  valid_595936 = validateParameter(valid_595936, JString, required = false,
                                 default = nil)
  if valid_595936 != nil:
    section.add "X-Amz-Signature", valid_595936
  var valid_595937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595937 = validateParameter(valid_595937, JString, required = false,
                                 default = nil)
  if valid_595937 != nil:
    section.add "X-Amz-SignedHeaders", valid_595937
  var valid_595938 = header.getOrDefault("X-Amz-Credential")
  valid_595938 = validateParameter(valid_595938, JString, required = false,
                                 default = nil)
  if valid_595938 != nil:
    section.add "X-Amz-Credential", valid_595938
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_595939 = formData.getOrDefault("DBParameterGroupName")
  valid_595939 = validateParameter(valid_595939, JString, required = true,
                                 default = nil)
  if valid_595939 != nil:
    section.add "DBParameterGroupName", valid_595939
  var valid_595940 = formData.getOrDefault("Parameters")
  valid_595940 = validateParameter(valid_595940, JArray, required = false,
                                 default = nil)
  if valid_595940 != nil:
    section.add "Parameters", valid_595940
  var valid_595941 = formData.getOrDefault("ResetAllParameters")
  valid_595941 = validateParameter(valid_595941, JBool, required = false, default = nil)
  if valid_595941 != nil:
    section.add "ResetAllParameters", valid_595941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595942: Call_PostResetDBParameterGroup_595927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595942.validator(path, query, header, formData, body)
  let scheme = call_595942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595942.url(scheme.get, call_595942.host, call_595942.base,
                         call_595942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595942, url, valid)

proc call*(call_595943: Call_PostResetDBParameterGroup_595927;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_595944 = newJObject()
  var formData_595945 = newJObject()
  add(formData_595945, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_595945.add "Parameters", Parameters
  add(query_595944, "Action", newJString(Action))
  add(formData_595945, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595944, "Version", newJString(Version))
  result = call_595943.call(nil, query_595944, nil, formData_595945, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_595927(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_595928, base: "/",
    url: url_PostResetDBParameterGroup_595929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_595909 = ref object of OpenApiRestCall_593421
proc url_GetResetDBParameterGroup_595911(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_595910(path: JsonNode; query: JsonNode;
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
  var valid_595912 = query.getOrDefault("DBParameterGroupName")
  valid_595912 = validateParameter(valid_595912, JString, required = true,
                                 default = nil)
  if valid_595912 != nil:
    section.add "DBParameterGroupName", valid_595912
  var valid_595913 = query.getOrDefault("Parameters")
  valid_595913 = validateParameter(valid_595913, JArray, required = false,
                                 default = nil)
  if valid_595913 != nil:
    section.add "Parameters", valid_595913
  var valid_595914 = query.getOrDefault("Action")
  valid_595914 = validateParameter(valid_595914, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_595914 != nil:
    section.add "Action", valid_595914
  var valid_595915 = query.getOrDefault("ResetAllParameters")
  valid_595915 = validateParameter(valid_595915, JBool, required = false, default = nil)
  if valid_595915 != nil:
    section.add "ResetAllParameters", valid_595915
  var valid_595916 = query.getOrDefault("Version")
  valid_595916 = validateParameter(valid_595916, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595916 != nil:
    section.add "Version", valid_595916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595917 = header.getOrDefault("X-Amz-Date")
  valid_595917 = validateParameter(valid_595917, JString, required = false,
                                 default = nil)
  if valid_595917 != nil:
    section.add "X-Amz-Date", valid_595917
  var valid_595918 = header.getOrDefault("X-Amz-Security-Token")
  valid_595918 = validateParameter(valid_595918, JString, required = false,
                                 default = nil)
  if valid_595918 != nil:
    section.add "X-Amz-Security-Token", valid_595918
  var valid_595919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595919 = validateParameter(valid_595919, JString, required = false,
                                 default = nil)
  if valid_595919 != nil:
    section.add "X-Amz-Content-Sha256", valid_595919
  var valid_595920 = header.getOrDefault("X-Amz-Algorithm")
  valid_595920 = validateParameter(valid_595920, JString, required = false,
                                 default = nil)
  if valid_595920 != nil:
    section.add "X-Amz-Algorithm", valid_595920
  var valid_595921 = header.getOrDefault("X-Amz-Signature")
  valid_595921 = validateParameter(valid_595921, JString, required = false,
                                 default = nil)
  if valid_595921 != nil:
    section.add "X-Amz-Signature", valid_595921
  var valid_595922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595922 = validateParameter(valid_595922, JString, required = false,
                                 default = nil)
  if valid_595922 != nil:
    section.add "X-Amz-SignedHeaders", valid_595922
  var valid_595923 = header.getOrDefault("X-Amz-Credential")
  valid_595923 = validateParameter(valid_595923, JString, required = false,
                                 default = nil)
  if valid_595923 != nil:
    section.add "X-Amz-Credential", valid_595923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595924: Call_GetResetDBParameterGroup_595909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595924.validator(path, query, header, formData, body)
  let scheme = call_595924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595924.url(scheme.get, call_595924.host, call_595924.base,
                         call_595924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595924, url, valid)

proc call*(call_595925: Call_GetResetDBParameterGroup_595909;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_595926 = newJObject()
  add(query_595926, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_595926.add "Parameters", Parameters
  add(query_595926, "Action", newJString(Action))
  add(query_595926, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595926, "Version", newJString(Version))
  result = call_595925.call(nil, query_595926, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_595909(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_595910, base: "/",
    url: url_GetResetDBParameterGroup_595911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_595975 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceFromDBSnapshot_595977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_595976(path: JsonNode;
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
  var valid_595978 = query.getOrDefault("Action")
  valid_595978 = validateParameter(valid_595978, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595978 != nil:
    section.add "Action", valid_595978
  var valid_595979 = query.getOrDefault("Version")
  valid_595979 = validateParameter(valid_595979, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595979 != nil:
    section.add "Version", valid_595979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595980 = header.getOrDefault("X-Amz-Date")
  valid_595980 = validateParameter(valid_595980, JString, required = false,
                                 default = nil)
  if valid_595980 != nil:
    section.add "X-Amz-Date", valid_595980
  var valid_595981 = header.getOrDefault("X-Amz-Security-Token")
  valid_595981 = validateParameter(valid_595981, JString, required = false,
                                 default = nil)
  if valid_595981 != nil:
    section.add "X-Amz-Security-Token", valid_595981
  var valid_595982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595982 = validateParameter(valid_595982, JString, required = false,
                                 default = nil)
  if valid_595982 != nil:
    section.add "X-Amz-Content-Sha256", valid_595982
  var valid_595983 = header.getOrDefault("X-Amz-Algorithm")
  valid_595983 = validateParameter(valid_595983, JString, required = false,
                                 default = nil)
  if valid_595983 != nil:
    section.add "X-Amz-Algorithm", valid_595983
  var valid_595984 = header.getOrDefault("X-Amz-Signature")
  valid_595984 = validateParameter(valid_595984, JString, required = false,
                                 default = nil)
  if valid_595984 != nil:
    section.add "X-Amz-Signature", valid_595984
  var valid_595985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595985 = validateParameter(valid_595985, JString, required = false,
                                 default = nil)
  if valid_595985 != nil:
    section.add "X-Amz-SignedHeaders", valid_595985
  var valid_595986 = header.getOrDefault("X-Amz-Credential")
  valid_595986 = validateParameter(valid_595986, JString, required = false,
                                 default = nil)
  if valid_595986 != nil:
    section.add "X-Amz-Credential", valid_595986
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
  var valid_595987 = formData.getOrDefault("Port")
  valid_595987 = validateParameter(valid_595987, JInt, required = false, default = nil)
  if valid_595987 != nil:
    section.add "Port", valid_595987
  var valid_595988 = formData.getOrDefault("Engine")
  valid_595988 = validateParameter(valid_595988, JString, required = false,
                                 default = nil)
  if valid_595988 != nil:
    section.add "Engine", valid_595988
  var valid_595989 = formData.getOrDefault("Iops")
  valid_595989 = validateParameter(valid_595989, JInt, required = false, default = nil)
  if valid_595989 != nil:
    section.add "Iops", valid_595989
  var valid_595990 = formData.getOrDefault("DBName")
  valid_595990 = validateParameter(valid_595990, JString, required = false,
                                 default = nil)
  if valid_595990 != nil:
    section.add "DBName", valid_595990
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595991 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595991 = validateParameter(valid_595991, JString, required = true,
                                 default = nil)
  if valid_595991 != nil:
    section.add "DBInstanceIdentifier", valid_595991
  var valid_595992 = formData.getOrDefault("OptionGroupName")
  valid_595992 = validateParameter(valid_595992, JString, required = false,
                                 default = nil)
  if valid_595992 != nil:
    section.add "OptionGroupName", valid_595992
  var valid_595993 = formData.getOrDefault("DBSubnetGroupName")
  valid_595993 = validateParameter(valid_595993, JString, required = false,
                                 default = nil)
  if valid_595993 != nil:
    section.add "DBSubnetGroupName", valid_595993
  var valid_595994 = formData.getOrDefault("AvailabilityZone")
  valid_595994 = validateParameter(valid_595994, JString, required = false,
                                 default = nil)
  if valid_595994 != nil:
    section.add "AvailabilityZone", valid_595994
  var valid_595995 = formData.getOrDefault("MultiAZ")
  valid_595995 = validateParameter(valid_595995, JBool, required = false, default = nil)
  if valid_595995 != nil:
    section.add "MultiAZ", valid_595995
  var valid_595996 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_595996 = validateParameter(valid_595996, JString, required = true,
                                 default = nil)
  if valid_595996 != nil:
    section.add "DBSnapshotIdentifier", valid_595996
  var valid_595997 = formData.getOrDefault("PubliclyAccessible")
  valid_595997 = validateParameter(valid_595997, JBool, required = false, default = nil)
  if valid_595997 != nil:
    section.add "PubliclyAccessible", valid_595997
  var valid_595998 = formData.getOrDefault("DBInstanceClass")
  valid_595998 = validateParameter(valid_595998, JString, required = false,
                                 default = nil)
  if valid_595998 != nil:
    section.add "DBInstanceClass", valid_595998
  var valid_595999 = formData.getOrDefault("LicenseModel")
  valid_595999 = validateParameter(valid_595999, JString, required = false,
                                 default = nil)
  if valid_595999 != nil:
    section.add "LicenseModel", valid_595999
  var valid_596000 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596000 = validateParameter(valid_596000, JBool, required = false, default = nil)
  if valid_596000 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596000
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596001: Call_PostRestoreDBInstanceFromDBSnapshot_595975;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596001.validator(path, query, header, formData, body)
  let scheme = call_596001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596001.url(scheme.get, call_596001.host, call_596001.base,
                         call_596001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596001, url, valid)

proc call*(call_596002: Call_PostRestoreDBInstanceFromDBSnapshot_595975;
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
  var query_596003 = newJObject()
  var formData_596004 = newJObject()
  add(formData_596004, "Port", newJInt(Port))
  add(formData_596004, "Engine", newJString(Engine))
  add(formData_596004, "Iops", newJInt(Iops))
  add(formData_596004, "DBName", newJString(DBName))
  add(formData_596004, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_596004, "OptionGroupName", newJString(OptionGroupName))
  add(formData_596004, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596004, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596004, "MultiAZ", newJBool(MultiAZ))
  add(formData_596004, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_596003, "Action", newJString(Action))
  add(formData_596004, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596004, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596004, "LicenseModel", newJString(LicenseModel))
  add(formData_596004, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596003, "Version", newJString(Version))
  result = call_596002.call(nil, query_596003, nil, formData_596004, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_595975(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_595976, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_595977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_595946 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceFromDBSnapshot_595948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_595947(path: JsonNode;
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
  var valid_595949 = query.getOrDefault("Engine")
  valid_595949 = validateParameter(valid_595949, JString, required = false,
                                 default = nil)
  if valid_595949 != nil:
    section.add "Engine", valid_595949
  var valid_595950 = query.getOrDefault("OptionGroupName")
  valid_595950 = validateParameter(valid_595950, JString, required = false,
                                 default = nil)
  if valid_595950 != nil:
    section.add "OptionGroupName", valid_595950
  var valid_595951 = query.getOrDefault("AvailabilityZone")
  valid_595951 = validateParameter(valid_595951, JString, required = false,
                                 default = nil)
  if valid_595951 != nil:
    section.add "AvailabilityZone", valid_595951
  var valid_595952 = query.getOrDefault("Iops")
  valid_595952 = validateParameter(valid_595952, JInt, required = false, default = nil)
  if valid_595952 != nil:
    section.add "Iops", valid_595952
  var valid_595953 = query.getOrDefault("MultiAZ")
  valid_595953 = validateParameter(valid_595953, JBool, required = false, default = nil)
  if valid_595953 != nil:
    section.add "MultiAZ", valid_595953
  var valid_595954 = query.getOrDefault("LicenseModel")
  valid_595954 = validateParameter(valid_595954, JString, required = false,
                                 default = nil)
  if valid_595954 != nil:
    section.add "LicenseModel", valid_595954
  var valid_595955 = query.getOrDefault("DBName")
  valid_595955 = validateParameter(valid_595955, JString, required = false,
                                 default = nil)
  if valid_595955 != nil:
    section.add "DBName", valid_595955
  var valid_595956 = query.getOrDefault("DBInstanceClass")
  valid_595956 = validateParameter(valid_595956, JString, required = false,
                                 default = nil)
  if valid_595956 != nil:
    section.add "DBInstanceClass", valid_595956
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595957 = query.getOrDefault("Action")
  valid_595957 = validateParameter(valid_595957, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_595957 != nil:
    section.add "Action", valid_595957
  var valid_595958 = query.getOrDefault("DBSubnetGroupName")
  valid_595958 = validateParameter(valid_595958, JString, required = false,
                                 default = nil)
  if valid_595958 != nil:
    section.add "DBSubnetGroupName", valid_595958
  var valid_595959 = query.getOrDefault("PubliclyAccessible")
  valid_595959 = validateParameter(valid_595959, JBool, required = false, default = nil)
  if valid_595959 != nil:
    section.add "PubliclyAccessible", valid_595959
  var valid_595960 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595960 = validateParameter(valid_595960, JBool, required = false, default = nil)
  if valid_595960 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595960
  var valid_595961 = query.getOrDefault("Port")
  valid_595961 = validateParameter(valid_595961, JInt, required = false, default = nil)
  if valid_595961 != nil:
    section.add "Port", valid_595961
  var valid_595962 = query.getOrDefault("Version")
  valid_595962 = validateParameter(valid_595962, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_595962 != nil:
    section.add "Version", valid_595962
  var valid_595963 = query.getOrDefault("DBInstanceIdentifier")
  valid_595963 = validateParameter(valid_595963, JString, required = true,
                                 default = nil)
  if valid_595963 != nil:
    section.add "DBInstanceIdentifier", valid_595963
  var valid_595964 = query.getOrDefault("DBSnapshotIdentifier")
  valid_595964 = validateParameter(valid_595964, JString, required = true,
                                 default = nil)
  if valid_595964 != nil:
    section.add "DBSnapshotIdentifier", valid_595964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595965 = header.getOrDefault("X-Amz-Date")
  valid_595965 = validateParameter(valid_595965, JString, required = false,
                                 default = nil)
  if valid_595965 != nil:
    section.add "X-Amz-Date", valid_595965
  var valid_595966 = header.getOrDefault("X-Amz-Security-Token")
  valid_595966 = validateParameter(valid_595966, JString, required = false,
                                 default = nil)
  if valid_595966 != nil:
    section.add "X-Amz-Security-Token", valid_595966
  var valid_595967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595967 = validateParameter(valid_595967, JString, required = false,
                                 default = nil)
  if valid_595967 != nil:
    section.add "X-Amz-Content-Sha256", valid_595967
  var valid_595968 = header.getOrDefault("X-Amz-Algorithm")
  valid_595968 = validateParameter(valid_595968, JString, required = false,
                                 default = nil)
  if valid_595968 != nil:
    section.add "X-Amz-Algorithm", valid_595968
  var valid_595969 = header.getOrDefault("X-Amz-Signature")
  valid_595969 = validateParameter(valid_595969, JString, required = false,
                                 default = nil)
  if valid_595969 != nil:
    section.add "X-Amz-Signature", valid_595969
  var valid_595970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595970 = validateParameter(valid_595970, JString, required = false,
                                 default = nil)
  if valid_595970 != nil:
    section.add "X-Amz-SignedHeaders", valid_595970
  var valid_595971 = header.getOrDefault("X-Amz-Credential")
  valid_595971 = validateParameter(valid_595971, JString, required = false,
                                 default = nil)
  if valid_595971 != nil:
    section.add "X-Amz-Credential", valid_595971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595972: Call_GetRestoreDBInstanceFromDBSnapshot_595946;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_595972.validator(path, query, header, formData, body)
  let scheme = call_595972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595972.url(scheme.get, call_595972.host, call_595972.base,
                         call_595972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595972, url, valid)

proc call*(call_595973: Call_GetRestoreDBInstanceFromDBSnapshot_595946;
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
  var query_595974 = newJObject()
  add(query_595974, "Engine", newJString(Engine))
  add(query_595974, "OptionGroupName", newJString(OptionGroupName))
  add(query_595974, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_595974, "Iops", newJInt(Iops))
  add(query_595974, "MultiAZ", newJBool(MultiAZ))
  add(query_595974, "LicenseModel", newJString(LicenseModel))
  add(query_595974, "DBName", newJString(DBName))
  add(query_595974, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595974, "Action", newJString(Action))
  add(query_595974, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595974, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_595974, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595974, "Port", newJInt(Port))
  add(query_595974, "Version", newJString(Version))
  add(query_595974, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595974, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_595973.call(nil, query_595974, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_595946(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_595947, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_595948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_596036 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBInstanceToPointInTime_596038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_596037(path: JsonNode;
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
  var valid_596039 = query.getOrDefault("Action")
  valid_596039 = validateParameter(valid_596039, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596039 != nil:
    section.add "Action", valid_596039
  var valid_596040 = query.getOrDefault("Version")
  valid_596040 = validateParameter(valid_596040, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_596040 != nil:
    section.add "Version", valid_596040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_596041 = header.getOrDefault("X-Amz-Date")
  valid_596041 = validateParameter(valid_596041, JString, required = false,
                                 default = nil)
  if valid_596041 != nil:
    section.add "X-Amz-Date", valid_596041
  var valid_596042 = header.getOrDefault("X-Amz-Security-Token")
  valid_596042 = validateParameter(valid_596042, JString, required = false,
                                 default = nil)
  if valid_596042 != nil:
    section.add "X-Amz-Security-Token", valid_596042
  var valid_596043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596043 = validateParameter(valid_596043, JString, required = false,
                                 default = nil)
  if valid_596043 != nil:
    section.add "X-Amz-Content-Sha256", valid_596043
  var valid_596044 = header.getOrDefault("X-Amz-Algorithm")
  valid_596044 = validateParameter(valid_596044, JString, required = false,
                                 default = nil)
  if valid_596044 != nil:
    section.add "X-Amz-Algorithm", valid_596044
  var valid_596045 = header.getOrDefault("X-Amz-Signature")
  valid_596045 = validateParameter(valid_596045, JString, required = false,
                                 default = nil)
  if valid_596045 != nil:
    section.add "X-Amz-Signature", valid_596045
  var valid_596046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596046 = validateParameter(valid_596046, JString, required = false,
                                 default = nil)
  if valid_596046 != nil:
    section.add "X-Amz-SignedHeaders", valid_596046
  var valid_596047 = header.getOrDefault("X-Amz-Credential")
  valid_596047 = validateParameter(valid_596047, JString, required = false,
                                 default = nil)
  if valid_596047 != nil:
    section.add "X-Amz-Credential", valid_596047
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
  var valid_596048 = formData.getOrDefault("UseLatestRestorableTime")
  valid_596048 = validateParameter(valid_596048, JBool, required = false, default = nil)
  if valid_596048 != nil:
    section.add "UseLatestRestorableTime", valid_596048
  var valid_596049 = formData.getOrDefault("Port")
  valid_596049 = validateParameter(valid_596049, JInt, required = false, default = nil)
  if valid_596049 != nil:
    section.add "Port", valid_596049
  var valid_596050 = formData.getOrDefault("Engine")
  valid_596050 = validateParameter(valid_596050, JString, required = false,
                                 default = nil)
  if valid_596050 != nil:
    section.add "Engine", valid_596050
  var valid_596051 = formData.getOrDefault("Iops")
  valid_596051 = validateParameter(valid_596051, JInt, required = false, default = nil)
  if valid_596051 != nil:
    section.add "Iops", valid_596051
  var valid_596052 = formData.getOrDefault("DBName")
  valid_596052 = validateParameter(valid_596052, JString, required = false,
                                 default = nil)
  if valid_596052 != nil:
    section.add "DBName", valid_596052
  var valid_596053 = formData.getOrDefault("OptionGroupName")
  valid_596053 = validateParameter(valid_596053, JString, required = false,
                                 default = nil)
  if valid_596053 != nil:
    section.add "OptionGroupName", valid_596053
  var valid_596054 = formData.getOrDefault("DBSubnetGroupName")
  valid_596054 = validateParameter(valid_596054, JString, required = false,
                                 default = nil)
  if valid_596054 != nil:
    section.add "DBSubnetGroupName", valid_596054
  var valid_596055 = formData.getOrDefault("AvailabilityZone")
  valid_596055 = validateParameter(valid_596055, JString, required = false,
                                 default = nil)
  if valid_596055 != nil:
    section.add "AvailabilityZone", valid_596055
  var valid_596056 = formData.getOrDefault("MultiAZ")
  valid_596056 = validateParameter(valid_596056, JBool, required = false, default = nil)
  if valid_596056 != nil:
    section.add "MultiAZ", valid_596056
  var valid_596057 = formData.getOrDefault("RestoreTime")
  valid_596057 = validateParameter(valid_596057, JString, required = false,
                                 default = nil)
  if valid_596057 != nil:
    section.add "RestoreTime", valid_596057
  var valid_596058 = formData.getOrDefault("PubliclyAccessible")
  valid_596058 = validateParameter(valid_596058, JBool, required = false, default = nil)
  if valid_596058 != nil:
    section.add "PubliclyAccessible", valid_596058
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_596059 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_596059 = validateParameter(valid_596059, JString, required = true,
                                 default = nil)
  if valid_596059 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596059
  var valid_596060 = formData.getOrDefault("DBInstanceClass")
  valid_596060 = validateParameter(valid_596060, JString, required = false,
                                 default = nil)
  if valid_596060 != nil:
    section.add "DBInstanceClass", valid_596060
  var valid_596061 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_596061 = validateParameter(valid_596061, JString, required = true,
                                 default = nil)
  if valid_596061 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596061
  var valid_596062 = formData.getOrDefault("LicenseModel")
  valid_596062 = validateParameter(valid_596062, JString, required = false,
                                 default = nil)
  if valid_596062 != nil:
    section.add "LicenseModel", valid_596062
  var valid_596063 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_596063 = validateParameter(valid_596063, JBool, required = false, default = nil)
  if valid_596063 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596064: Call_PostRestoreDBInstanceToPointInTime_596036;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596064.validator(path, query, header, formData, body)
  let scheme = call_596064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596064.url(scheme.get, call_596064.host, call_596064.base,
                         call_596064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596064, url, valid)

proc call*(call_596065: Call_PostRestoreDBInstanceToPointInTime_596036;
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
  var query_596066 = newJObject()
  var formData_596067 = newJObject()
  add(formData_596067, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_596067, "Port", newJInt(Port))
  add(formData_596067, "Engine", newJString(Engine))
  add(formData_596067, "Iops", newJInt(Iops))
  add(formData_596067, "DBName", newJString(DBName))
  add(formData_596067, "OptionGroupName", newJString(OptionGroupName))
  add(formData_596067, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_596067, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_596067, "MultiAZ", newJBool(MultiAZ))
  add(query_596066, "Action", newJString(Action))
  add(formData_596067, "RestoreTime", newJString(RestoreTime))
  add(formData_596067, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_596067, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_596067, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_596067, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_596067, "LicenseModel", newJString(LicenseModel))
  add(formData_596067, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_596066, "Version", newJString(Version))
  result = call_596065.call(nil, query_596066, nil, formData_596067, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_596036(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_596037, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_596038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_596005 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBInstanceToPointInTime_596007(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_596006(path: JsonNode;
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
  var valid_596008 = query.getOrDefault("Engine")
  valid_596008 = validateParameter(valid_596008, JString, required = false,
                                 default = nil)
  if valid_596008 != nil:
    section.add "Engine", valid_596008
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_596009 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_596009 = validateParameter(valid_596009, JString, required = true,
                                 default = nil)
  if valid_596009 != nil:
    section.add "SourceDBInstanceIdentifier", valid_596009
  var valid_596010 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_596010 = validateParameter(valid_596010, JString, required = true,
                                 default = nil)
  if valid_596010 != nil:
    section.add "TargetDBInstanceIdentifier", valid_596010
  var valid_596011 = query.getOrDefault("AvailabilityZone")
  valid_596011 = validateParameter(valid_596011, JString, required = false,
                                 default = nil)
  if valid_596011 != nil:
    section.add "AvailabilityZone", valid_596011
  var valid_596012 = query.getOrDefault("Iops")
  valid_596012 = validateParameter(valid_596012, JInt, required = false, default = nil)
  if valid_596012 != nil:
    section.add "Iops", valid_596012
  var valid_596013 = query.getOrDefault("OptionGroupName")
  valid_596013 = validateParameter(valid_596013, JString, required = false,
                                 default = nil)
  if valid_596013 != nil:
    section.add "OptionGroupName", valid_596013
  var valid_596014 = query.getOrDefault("RestoreTime")
  valid_596014 = validateParameter(valid_596014, JString, required = false,
                                 default = nil)
  if valid_596014 != nil:
    section.add "RestoreTime", valid_596014
  var valid_596015 = query.getOrDefault("MultiAZ")
  valid_596015 = validateParameter(valid_596015, JBool, required = false, default = nil)
  if valid_596015 != nil:
    section.add "MultiAZ", valid_596015
  var valid_596016 = query.getOrDefault("LicenseModel")
  valid_596016 = validateParameter(valid_596016, JString, required = false,
                                 default = nil)
  if valid_596016 != nil:
    section.add "LicenseModel", valid_596016
  var valid_596017 = query.getOrDefault("DBName")
  valid_596017 = validateParameter(valid_596017, JString, required = false,
                                 default = nil)
  if valid_596017 != nil:
    section.add "DBName", valid_596017
  var valid_596018 = query.getOrDefault("DBInstanceClass")
  valid_596018 = validateParameter(valid_596018, JString, required = false,
                                 default = nil)
  if valid_596018 != nil:
    section.add "DBInstanceClass", valid_596018
  var valid_596019 = query.getOrDefault("Action")
  valid_596019 = validateParameter(valid_596019, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_596019 != nil:
    section.add "Action", valid_596019
  var valid_596020 = query.getOrDefault("UseLatestRestorableTime")
  valid_596020 = validateParameter(valid_596020, JBool, required = false, default = nil)
  if valid_596020 != nil:
    section.add "UseLatestRestorableTime", valid_596020
  var valid_596021 = query.getOrDefault("DBSubnetGroupName")
  valid_596021 = validateParameter(valid_596021, JString, required = false,
                                 default = nil)
  if valid_596021 != nil:
    section.add "DBSubnetGroupName", valid_596021
  var valid_596022 = query.getOrDefault("PubliclyAccessible")
  valid_596022 = validateParameter(valid_596022, JBool, required = false, default = nil)
  if valid_596022 != nil:
    section.add "PubliclyAccessible", valid_596022
  var valid_596023 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_596023 = validateParameter(valid_596023, JBool, required = false, default = nil)
  if valid_596023 != nil:
    section.add "AutoMinorVersionUpgrade", valid_596023
  var valid_596024 = query.getOrDefault("Port")
  valid_596024 = validateParameter(valid_596024, JInt, required = false, default = nil)
  if valid_596024 != nil:
    section.add "Port", valid_596024
  var valid_596025 = query.getOrDefault("Version")
  valid_596025 = validateParameter(valid_596025, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_596025 != nil:
    section.add "Version", valid_596025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_596026 = header.getOrDefault("X-Amz-Date")
  valid_596026 = validateParameter(valid_596026, JString, required = false,
                                 default = nil)
  if valid_596026 != nil:
    section.add "X-Amz-Date", valid_596026
  var valid_596027 = header.getOrDefault("X-Amz-Security-Token")
  valid_596027 = validateParameter(valid_596027, JString, required = false,
                                 default = nil)
  if valid_596027 != nil:
    section.add "X-Amz-Security-Token", valid_596027
  var valid_596028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596028 = validateParameter(valid_596028, JString, required = false,
                                 default = nil)
  if valid_596028 != nil:
    section.add "X-Amz-Content-Sha256", valid_596028
  var valid_596029 = header.getOrDefault("X-Amz-Algorithm")
  valid_596029 = validateParameter(valid_596029, JString, required = false,
                                 default = nil)
  if valid_596029 != nil:
    section.add "X-Amz-Algorithm", valid_596029
  var valid_596030 = header.getOrDefault("X-Amz-Signature")
  valid_596030 = validateParameter(valid_596030, JString, required = false,
                                 default = nil)
  if valid_596030 != nil:
    section.add "X-Amz-Signature", valid_596030
  var valid_596031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596031 = validateParameter(valid_596031, JString, required = false,
                                 default = nil)
  if valid_596031 != nil:
    section.add "X-Amz-SignedHeaders", valid_596031
  var valid_596032 = header.getOrDefault("X-Amz-Credential")
  valid_596032 = validateParameter(valid_596032, JString, required = false,
                                 default = nil)
  if valid_596032 != nil:
    section.add "X-Amz-Credential", valid_596032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596033: Call_GetRestoreDBInstanceToPointInTime_596005;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596033.validator(path, query, header, formData, body)
  let scheme = call_596033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596033.url(scheme.get, call_596033.host, call_596033.base,
                         call_596033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596033, url, valid)

proc call*(call_596034: Call_GetRestoreDBInstanceToPointInTime_596005;
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
  var query_596035 = newJObject()
  add(query_596035, "Engine", newJString(Engine))
  add(query_596035, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_596035, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_596035, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_596035, "Iops", newJInt(Iops))
  add(query_596035, "OptionGroupName", newJString(OptionGroupName))
  add(query_596035, "RestoreTime", newJString(RestoreTime))
  add(query_596035, "MultiAZ", newJBool(MultiAZ))
  add(query_596035, "LicenseModel", newJString(LicenseModel))
  add(query_596035, "DBName", newJString(DBName))
  add(query_596035, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_596035, "Action", newJString(Action))
  add(query_596035, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_596035, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_596035, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_596035, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_596035, "Port", newJInt(Port))
  add(query_596035, "Version", newJString(Version))
  result = call_596034.call(nil, query_596035, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_596005(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_596006, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_596007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_596088 = ref object of OpenApiRestCall_593421
proc url_PostRevokeDBSecurityGroupIngress_596090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_596089(path: JsonNode;
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
  var valid_596091 = query.getOrDefault("Action")
  valid_596091 = validateParameter(valid_596091, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596091 != nil:
    section.add "Action", valid_596091
  var valid_596092 = query.getOrDefault("Version")
  valid_596092 = validateParameter(valid_596092, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_596092 != nil:
    section.add "Version", valid_596092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_596093 = header.getOrDefault("X-Amz-Date")
  valid_596093 = validateParameter(valid_596093, JString, required = false,
                                 default = nil)
  if valid_596093 != nil:
    section.add "X-Amz-Date", valid_596093
  var valid_596094 = header.getOrDefault("X-Amz-Security-Token")
  valid_596094 = validateParameter(valid_596094, JString, required = false,
                                 default = nil)
  if valid_596094 != nil:
    section.add "X-Amz-Security-Token", valid_596094
  var valid_596095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596095 = validateParameter(valid_596095, JString, required = false,
                                 default = nil)
  if valid_596095 != nil:
    section.add "X-Amz-Content-Sha256", valid_596095
  var valid_596096 = header.getOrDefault("X-Amz-Algorithm")
  valid_596096 = validateParameter(valid_596096, JString, required = false,
                                 default = nil)
  if valid_596096 != nil:
    section.add "X-Amz-Algorithm", valid_596096
  var valid_596097 = header.getOrDefault("X-Amz-Signature")
  valid_596097 = validateParameter(valid_596097, JString, required = false,
                                 default = nil)
  if valid_596097 != nil:
    section.add "X-Amz-Signature", valid_596097
  var valid_596098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596098 = validateParameter(valid_596098, JString, required = false,
                                 default = nil)
  if valid_596098 != nil:
    section.add "X-Amz-SignedHeaders", valid_596098
  var valid_596099 = header.getOrDefault("X-Amz-Credential")
  valid_596099 = validateParameter(valid_596099, JString, required = false,
                                 default = nil)
  if valid_596099 != nil:
    section.add "X-Amz-Credential", valid_596099
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596100 = formData.getOrDefault("DBSecurityGroupName")
  valid_596100 = validateParameter(valid_596100, JString, required = true,
                                 default = nil)
  if valid_596100 != nil:
    section.add "DBSecurityGroupName", valid_596100
  var valid_596101 = formData.getOrDefault("EC2SecurityGroupName")
  valid_596101 = validateParameter(valid_596101, JString, required = false,
                                 default = nil)
  if valid_596101 != nil:
    section.add "EC2SecurityGroupName", valid_596101
  var valid_596102 = formData.getOrDefault("EC2SecurityGroupId")
  valid_596102 = validateParameter(valid_596102, JString, required = false,
                                 default = nil)
  if valid_596102 != nil:
    section.add "EC2SecurityGroupId", valid_596102
  var valid_596103 = formData.getOrDefault("CIDRIP")
  valid_596103 = validateParameter(valid_596103, JString, required = false,
                                 default = nil)
  if valid_596103 != nil:
    section.add "CIDRIP", valid_596103
  var valid_596104 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596104 = validateParameter(valid_596104, JString, required = false,
                                 default = nil)
  if valid_596104 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596104
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596105: Call_PostRevokeDBSecurityGroupIngress_596088;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596105.validator(path, query, header, formData, body)
  let scheme = call_596105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596105.url(scheme.get, call_596105.host, call_596105.base,
                         call_596105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596105, url, valid)

proc call*(call_596106: Call_PostRevokeDBSecurityGroupIngress_596088;
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
  var query_596107 = newJObject()
  var formData_596108 = newJObject()
  add(formData_596108, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596107, "Action", newJString(Action))
  add(formData_596108, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_596108, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_596108, "CIDRIP", newJString(CIDRIP))
  add(query_596107, "Version", newJString(Version))
  add(formData_596108, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_596106.call(nil, query_596107, nil, formData_596108, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_596088(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_596089, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_596090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_596068 = ref object of OpenApiRestCall_593421
proc url_GetRevokeDBSecurityGroupIngress_596070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_596069(path: JsonNode;
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
  var valid_596071 = query.getOrDefault("EC2SecurityGroupId")
  valid_596071 = validateParameter(valid_596071, JString, required = false,
                                 default = nil)
  if valid_596071 != nil:
    section.add "EC2SecurityGroupId", valid_596071
  var valid_596072 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_596072 = validateParameter(valid_596072, JString, required = false,
                                 default = nil)
  if valid_596072 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_596072
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_596073 = query.getOrDefault("DBSecurityGroupName")
  valid_596073 = validateParameter(valid_596073, JString, required = true,
                                 default = nil)
  if valid_596073 != nil:
    section.add "DBSecurityGroupName", valid_596073
  var valid_596074 = query.getOrDefault("Action")
  valid_596074 = validateParameter(valid_596074, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_596074 != nil:
    section.add "Action", valid_596074
  var valid_596075 = query.getOrDefault("CIDRIP")
  valid_596075 = validateParameter(valid_596075, JString, required = false,
                                 default = nil)
  if valid_596075 != nil:
    section.add "CIDRIP", valid_596075
  var valid_596076 = query.getOrDefault("EC2SecurityGroupName")
  valid_596076 = validateParameter(valid_596076, JString, required = false,
                                 default = nil)
  if valid_596076 != nil:
    section.add "EC2SecurityGroupName", valid_596076
  var valid_596077 = query.getOrDefault("Version")
  valid_596077 = validateParameter(valid_596077, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_596077 != nil:
    section.add "Version", valid_596077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_596078 = header.getOrDefault("X-Amz-Date")
  valid_596078 = validateParameter(valid_596078, JString, required = false,
                                 default = nil)
  if valid_596078 != nil:
    section.add "X-Amz-Date", valid_596078
  var valid_596079 = header.getOrDefault("X-Amz-Security-Token")
  valid_596079 = validateParameter(valid_596079, JString, required = false,
                                 default = nil)
  if valid_596079 != nil:
    section.add "X-Amz-Security-Token", valid_596079
  var valid_596080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_596080 = validateParameter(valid_596080, JString, required = false,
                                 default = nil)
  if valid_596080 != nil:
    section.add "X-Amz-Content-Sha256", valid_596080
  var valid_596081 = header.getOrDefault("X-Amz-Algorithm")
  valid_596081 = validateParameter(valid_596081, JString, required = false,
                                 default = nil)
  if valid_596081 != nil:
    section.add "X-Amz-Algorithm", valid_596081
  var valid_596082 = header.getOrDefault("X-Amz-Signature")
  valid_596082 = validateParameter(valid_596082, JString, required = false,
                                 default = nil)
  if valid_596082 != nil:
    section.add "X-Amz-Signature", valid_596082
  var valid_596083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_596083 = validateParameter(valid_596083, JString, required = false,
                                 default = nil)
  if valid_596083 != nil:
    section.add "X-Amz-SignedHeaders", valid_596083
  var valid_596084 = header.getOrDefault("X-Amz-Credential")
  valid_596084 = validateParameter(valid_596084, JString, required = false,
                                 default = nil)
  if valid_596084 != nil:
    section.add "X-Amz-Credential", valid_596084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_596085: Call_GetRevokeDBSecurityGroupIngress_596068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_596085.validator(path, query, header, formData, body)
  let scheme = call_596085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_596085.url(scheme.get, call_596085.host, call_596085.base,
                         call_596085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_596085, url, valid)

proc call*(call_596086: Call_GetRevokeDBSecurityGroupIngress_596068;
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
  var query_596087 = newJObject()
  add(query_596087, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_596087, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_596087, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_596087, "Action", newJString(Action))
  add(query_596087, "CIDRIP", newJString(CIDRIP))
  add(query_596087, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_596087, "Version", newJString(Version))
  result = call_596086.call(nil, query_596087, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_596068(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_596069, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_596070,
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

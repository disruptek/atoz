
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600421): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_601030 = ref object of OpenApiRestCall_600421
proc url_PostAddSourceIdentifierToSubscription_601032(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_601031(path: JsonNode;
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
  var valid_601033 = query.getOrDefault("Action")
  valid_601033 = validateParameter(valid_601033, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_601033 != nil:
    section.add "Action", valid_601033
  var valid_601034 = query.getOrDefault("Version")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601034 != nil:
    section.add "Version", valid_601034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Content-Sha256", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Algorithm")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Algorithm", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Signature")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Signature", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-SignedHeaders", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Credential")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Credential", valid_601041
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601042 = formData.getOrDefault("SourceIdentifier")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = nil)
  if valid_601042 != nil:
    section.add "SourceIdentifier", valid_601042
  var valid_601043 = formData.getOrDefault("SubscriptionName")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "SubscriptionName", valid_601043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601044: Call_PostAddSourceIdentifierToSubscription_601030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601044.validator(path, query, header, formData, body)
  let scheme = call_601044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601044.url(scheme.get, call_601044.host, call_601044.base,
                         call_601044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601044, url, valid)

proc call*(call_601045: Call_PostAddSourceIdentifierToSubscription_601030;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601046 = newJObject()
  var formData_601047 = newJObject()
  add(formData_601047, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601047, "SubscriptionName", newJString(SubscriptionName))
  add(query_601046, "Action", newJString(Action))
  add(query_601046, "Version", newJString(Version))
  result = call_601045.call(nil, query_601046, nil, formData_601047, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_601030(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_601031, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_601032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_600758 = ref object of OpenApiRestCall_600421
proc url_GetAddSourceIdentifierToSubscription_600760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_600759(path: JsonNode;
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
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("SourceIdentifier")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = nil)
  if valid_600886 != nil:
    section.add "SourceIdentifier", valid_600886
  var valid_600887 = query.getOrDefault("SubscriptionName")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = nil)
  if valid_600887 != nil:
    section.add "SubscriptionName", valid_600887
  var valid_600888 = query.getOrDefault("Version")
  valid_600888 = validateParameter(valid_600888, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600888 != nil:
    section.add "Version", valid_600888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600889 = header.getOrDefault("X-Amz-Date")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Date", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Security-Token")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Security-Token", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Content-Sha256", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Algorithm")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Algorithm", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Signature")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Signature", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-SignedHeaders", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Credential")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Credential", valid_600895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600918: Call_GetAddSourceIdentifierToSubscription_600758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600918.validator(path, query, header, formData, body)
  let scheme = call_600918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600918.url(scheme.get, call_600918.host, call_600918.base,
                         call_600918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600918, url, valid)

proc call*(call_600989: Call_GetAddSourceIdentifierToSubscription_600758;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600990 = newJObject()
  add(query_600990, "Action", newJString(Action))
  add(query_600990, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_600990, "SubscriptionName", newJString(SubscriptionName))
  add(query_600990, "Version", newJString(Version))
  result = call_600989.call(nil, query_600990, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_600758(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_600759, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_600760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_601065 = ref object of OpenApiRestCall_600421
proc url_PostAddTagsToResource_601067(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_601066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601068 = query.getOrDefault("Action")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601068 != nil:
    section.add "Action", valid_601068
  var valid_601069 = query.getOrDefault("Version")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601069 != nil:
    section.add "Version", valid_601069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601077 = formData.getOrDefault("Tags")
  valid_601077 = validateParameter(valid_601077, JArray, required = true, default = nil)
  if valid_601077 != nil:
    section.add "Tags", valid_601077
  var valid_601078 = formData.getOrDefault("ResourceName")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "ResourceName", valid_601078
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_PostAddTagsToResource_601065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_PostAddTagsToResource_601065; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601081 = newJObject()
  var formData_601082 = newJObject()
  if Tags != nil:
    formData_601082.add "Tags", Tags
  add(query_601081, "Action", newJString(Action))
  add(formData_601082, "ResourceName", newJString(ResourceName))
  add(query_601081, "Version", newJString(Version))
  result = call_601080.call(nil, query_601081, nil, formData_601082, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_601065(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_601066, base: "/",
    url: url_PostAddTagsToResource_601067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_601048 = ref object of OpenApiRestCall_600421
proc url_GetAddTagsToResource_601050(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_601049(path: JsonNode; query: JsonNode;
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
  var valid_601051 = query.getOrDefault("Tags")
  valid_601051 = validateParameter(valid_601051, JArray, required = true, default = nil)
  if valid_601051 != nil:
    section.add "Tags", valid_601051
  var valid_601052 = query.getOrDefault("ResourceName")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "ResourceName", valid_601052
  var valid_601053 = query.getOrDefault("Action")
  valid_601053 = validateParameter(valid_601053, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601053 != nil:
    section.add "Action", valid_601053
  var valid_601054 = query.getOrDefault("Version")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601054 != nil:
    section.add "Version", valid_601054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_GetAddTagsToResource_601048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_GetAddTagsToResource_601048; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601064 = newJObject()
  if Tags != nil:
    query_601064.add "Tags", Tags
  add(query_601064, "ResourceName", newJString(ResourceName))
  add(query_601064, "Action", newJString(Action))
  add(query_601064, "Version", newJString(Version))
  result = call_601063.call(nil, query_601064, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_601048(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_601049, base: "/",
    url: url_GetAddTagsToResource_601050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_601103 = ref object of OpenApiRestCall_600421
proc url_PostAuthorizeDBSecurityGroupIngress_601105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_601104(path: JsonNode;
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
  var valid_601106 = query.getOrDefault("Action")
  valid_601106 = validateParameter(valid_601106, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601106 != nil:
    section.add "Action", valid_601106
  var valid_601107 = query.getOrDefault("Version")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601107 != nil:
    section.add "Version", valid_601107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601108 = header.getOrDefault("X-Amz-Date")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Date", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Security-Token")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Security-Token", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601115 = formData.getOrDefault("DBSecurityGroupName")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = nil)
  if valid_601115 != nil:
    section.add "DBSecurityGroupName", valid_601115
  var valid_601116 = formData.getOrDefault("EC2SecurityGroupName")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "EC2SecurityGroupName", valid_601116
  var valid_601117 = formData.getOrDefault("EC2SecurityGroupId")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "EC2SecurityGroupId", valid_601117
  var valid_601118 = formData.getOrDefault("CIDRIP")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "CIDRIP", valid_601118
  var valid_601119 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601120: Call_PostAuthorizeDBSecurityGroupIngress_601103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601120.validator(path, query, header, formData, body)
  let scheme = call_601120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601120.url(scheme.get, call_601120.host, call_601120.base,
                         call_601120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601120, url, valid)

proc call*(call_601121: Call_PostAuthorizeDBSecurityGroupIngress_601103;
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
  var query_601122 = newJObject()
  var formData_601123 = newJObject()
  add(formData_601123, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601122, "Action", newJString(Action))
  add(formData_601123, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_601123, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_601123, "CIDRIP", newJString(CIDRIP))
  add(query_601122, "Version", newJString(Version))
  add(formData_601123, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_601121.call(nil, query_601122, nil, formData_601123, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_601103(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_601104, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_601083 = ref object of OpenApiRestCall_600421
proc url_GetAuthorizeDBSecurityGroupIngress_601085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_601084(path: JsonNode;
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
  var valid_601086 = query.getOrDefault("EC2SecurityGroupId")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "EC2SecurityGroupId", valid_601086
  var valid_601087 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601087
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601088 = query.getOrDefault("DBSecurityGroupName")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "DBSecurityGroupName", valid_601088
  var valid_601089 = query.getOrDefault("Action")
  valid_601089 = validateParameter(valid_601089, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601089 != nil:
    section.add "Action", valid_601089
  var valid_601090 = query.getOrDefault("CIDRIP")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "CIDRIP", valid_601090
  var valid_601091 = query.getOrDefault("EC2SecurityGroupName")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "EC2SecurityGroupName", valid_601091
  var valid_601092 = query.getOrDefault("Version")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601092 != nil:
    section.add "Version", valid_601092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_GetAuthorizeDBSecurityGroupIngress_601083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_GetAuthorizeDBSecurityGroupIngress_601083;
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
  var query_601102 = newJObject()
  add(query_601102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_601102, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_601102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601102, "Action", newJString(Action))
  add(query_601102, "CIDRIP", newJString(CIDRIP))
  add(query_601102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_601102, "Version", newJString(Version))
  result = call_601101.call(nil, query_601102, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_601083(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_601084, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_601085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_601143 = ref object of OpenApiRestCall_600421
proc url_PostCopyDBParameterGroup_601145(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBParameterGroup_601144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601146 = query.getOrDefault("Action")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_601146 != nil:
    section.add "Action", valid_601146
  var valid_601147 = query.getOrDefault("Version")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601147 != nil:
    section.add "Version", valid_601147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601148 = header.getOrDefault("X-Amz-Date")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Date", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Security-Token")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Security-Token", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_601155 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = nil)
  if valid_601155 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_601155
  var valid_601156 = formData.getOrDefault("Tags")
  valid_601156 = validateParameter(valid_601156, JArray, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "Tags", valid_601156
  var valid_601157 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = nil)
  if valid_601157 != nil:
    section.add "TargetDBParameterGroupDescription", valid_601157
  var valid_601158 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_601158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601159: Call_PostCopyDBParameterGroup_601143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601159.validator(path, query, header, formData, body)
  let scheme = call_601159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601159.url(scheme.get, call_601159.host, call_601159.base,
                         call_601159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601159, url, valid)

proc call*(call_601160: Call_PostCopyDBParameterGroup_601143;
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
  var query_601161 = newJObject()
  var formData_601162 = newJObject()
  add(formData_601162, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_601162.add "Tags", Tags
  add(query_601161, "Action", newJString(Action))
  add(formData_601162, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_601162, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_601161, "Version", newJString(Version))
  result = call_601160.call(nil, query_601161, nil, formData_601162, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_601143(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_601144, base: "/",
    url: url_PostCopyDBParameterGroup_601145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_601124 = ref object of OpenApiRestCall_600421
proc url_GetCopyDBParameterGroup_601126(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBParameterGroup_601125(path: JsonNode; query: JsonNode;
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
  var valid_601127 = query.getOrDefault("Tags")
  valid_601127 = validateParameter(valid_601127, JArray, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Tags", valid_601127
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601128 = query.getOrDefault("Action")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_601128 != nil:
    section.add "Action", valid_601128
  var valid_601129 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = nil)
  if valid_601129 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_601129
  var valid_601130 = query.getOrDefault("Version")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601130 != nil:
    section.add "Version", valid_601130
  var valid_601131 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = nil)
  if valid_601131 != nil:
    section.add "TargetDBParameterGroupDescription", valid_601131
  var valid_601132 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = nil)
  if valid_601132 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_601132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_GetCopyDBParameterGroup_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601140, url, valid)

proc call*(call_601141: Call_GetCopyDBParameterGroup_601124;
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
  var query_601142 = newJObject()
  if Tags != nil:
    query_601142.add "Tags", Tags
  add(query_601142, "Action", newJString(Action))
  add(query_601142, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_601142, "Version", newJString(Version))
  add(query_601142, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_601142, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_601141.call(nil, query_601142, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_601124(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_601125, base: "/",
    url: url_GetCopyDBParameterGroup_601126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_601181 = ref object of OpenApiRestCall_600421
proc url_PostCopyDBSnapshot_601183(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_601182(path: JsonNode; query: JsonNode;
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
  var valid_601184 = query.getOrDefault("Action")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601184 != nil:
    section.add "Action", valid_601184
  var valid_601185 = query.getOrDefault("Version")
  valid_601185 = validateParameter(valid_601185, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601185 != nil:
    section.add "Version", valid_601185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601186 = header.getOrDefault("X-Amz-Date")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Date", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Security-Token")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Security-Token", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Content-Sha256", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Algorithm")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Algorithm", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Signature")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Signature", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-SignedHeaders", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Credential")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Credential", valid_601192
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601193 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = nil)
  if valid_601193 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601193
  var valid_601194 = formData.getOrDefault("Tags")
  valid_601194 = validateParameter(valid_601194, JArray, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "Tags", valid_601194
  var valid_601195 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = nil)
  if valid_601195 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601196: Call_PostCopyDBSnapshot_601181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601196.validator(path, query, header, formData, body)
  let scheme = call_601196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601196.url(scheme.get, call_601196.host, call_601196.base,
                         call_601196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601196, url, valid)

proc call*(call_601197: Call_PostCopyDBSnapshot_601181;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601198 = newJObject()
  var formData_601199 = newJObject()
  add(formData_601199, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_601199.add "Tags", Tags
  add(query_601198, "Action", newJString(Action))
  add(formData_601199, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601198, "Version", newJString(Version))
  result = call_601197.call(nil, query_601198, nil, formData_601199, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601181(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601182, base: "/",
    url: url_PostCopyDBSnapshot_601183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_601163 = ref object of OpenApiRestCall_600421
proc url_GetCopyDBSnapshot_601165(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_601164(path: JsonNode; query: JsonNode;
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
  var valid_601166 = query.getOrDefault("Tags")
  valid_601166 = validateParameter(valid_601166, JArray, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "Tags", valid_601166
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601167 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601167
  var valid_601168 = query.getOrDefault("Action")
  valid_601168 = validateParameter(valid_601168, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601168 != nil:
    section.add "Action", valid_601168
  var valid_601169 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601169
  var valid_601170 = query.getOrDefault("Version")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601170 != nil:
    section.add "Version", valid_601170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601171 = header.getOrDefault("X-Amz-Date")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Date", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Security-Token")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Security-Token", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Content-Sha256", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Algorithm")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Algorithm", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Signature")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Signature", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-SignedHeaders", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Credential")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Credential", valid_601177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601178: Call_GetCopyDBSnapshot_601163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601178.validator(path, query, header, formData, body)
  let scheme = call_601178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601178.url(scheme.get, call_601178.host, call_601178.base,
                         call_601178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601178, url, valid)

proc call*(call_601179: Call_GetCopyDBSnapshot_601163;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601180 = newJObject()
  if Tags != nil:
    query_601180.add "Tags", Tags
  add(query_601180, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601180, "Action", newJString(Action))
  add(query_601180, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601180, "Version", newJString(Version))
  result = call_601179.call(nil, query_601180, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601163(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601164,
    base: "/", url: url_GetCopyDBSnapshot_601165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_601219 = ref object of OpenApiRestCall_600421
proc url_PostCopyOptionGroup_601221(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyOptionGroup_601220(path: JsonNode; query: JsonNode;
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
  var valid_601222 = query.getOrDefault("Action")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_601222 != nil:
    section.add "Action", valid_601222
  var valid_601223 = query.getOrDefault("Version")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601223 != nil:
    section.add "Version", valid_601223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601224 = header.getOrDefault("X-Amz-Date")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Date", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Security-Token")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Security-Token", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Content-Sha256", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Algorithm")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Algorithm", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Signature")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Signature", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-SignedHeaders", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Credential")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Credential", valid_601230
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_601231 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "TargetOptionGroupDescription", valid_601231
  var valid_601232 = formData.getOrDefault("Tags")
  valid_601232 = validateParameter(valid_601232, JArray, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "Tags", valid_601232
  var valid_601233 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "SourceOptionGroupIdentifier", valid_601233
  var valid_601234 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_601234 = validateParameter(valid_601234, JString, required = true,
                                 default = nil)
  if valid_601234 != nil:
    section.add "TargetOptionGroupIdentifier", valid_601234
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_PostCopyOptionGroup_601219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_PostCopyOptionGroup_601219;
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
  var query_601237 = newJObject()
  var formData_601238 = newJObject()
  add(formData_601238, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_601238.add "Tags", Tags
  add(formData_601238, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_601237, "Action", newJString(Action))
  add(formData_601238, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_601237, "Version", newJString(Version))
  result = call_601236.call(nil, query_601237, nil, formData_601238, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_601219(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_601220, base: "/",
    url: url_PostCopyOptionGroup_601221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_601200 = ref object of OpenApiRestCall_600421
proc url_GetCopyOptionGroup_601202(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyOptionGroup_601201(path: JsonNode; query: JsonNode;
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
  var valid_601203 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = nil)
  if valid_601203 != nil:
    section.add "SourceOptionGroupIdentifier", valid_601203
  var valid_601204 = query.getOrDefault("Tags")
  valid_601204 = validateParameter(valid_601204, JArray, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "Tags", valid_601204
  var valid_601205 = query.getOrDefault("Action")
  valid_601205 = validateParameter(valid_601205, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_601205 != nil:
    section.add "Action", valid_601205
  var valid_601206 = query.getOrDefault("TargetOptionGroupDescription")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "TargetOptionGroupDescription", valid_601206
  var valid_601207 = query.getOrDefault("Version")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601207 != nil:
    section.add "Version", valid_601207
  var valid_601208 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_601208 = validateParameter(valid_601208, JString, required = true,
                                 default = nil)
  if valid_601208 != nil:
    section.add "TargetOptionGroupIdentifier", valid_601208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601209 = header.getOrDefault("X-Amz-Date")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Date", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Security-Token")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Security-Token", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Content-Sha256", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Algorithm")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Algorithm", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Signature")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Signature", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-SignedHeaders", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Credential")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Credential", valid_601215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_GetCopyOptionGroup_601200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_GetCopyOptionGroup_601200;
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
  var query_601218 = newJObject()
  add(query_601218, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_601218.add "Tags", Tags
  add(query_601218, "Action", newJString(Action))
  add(query_601218, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_601218, "Version", newJString(Version))
  add(query_601218, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_601217.call(nil, query_601218, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_601200(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_601201,
    base: "/", url: url_GetCopyOptionGroup_601202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601282 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstance_601284(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_601283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601285 = query.getOrDefault("Action")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601285 != nil:
    section.add "Action", valid_601285
  var valid_601286 = query.getOrDefault("Version")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601286 != nil:
    section.add "Version", valid_601286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
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
  var valid_601294 = formData.getOrDefault("DBSecurityGroups")
  valid_601294 = validateParameter(valid_601294, JArray, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "DBSecurityGroups", valid_601294
  var valid_601295 = formData.getOrDefault("Port")
  valid_601295 = validateParameter(valid_601295, JInt, required = false, default = nil)
  if valid_601295 != nil:
    section.add "Port", valid_601295
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601296 = formData.getOrDefault("Engine")
  valid_601296 = validateParameter(valid_601296, JString, required = true,
                                 default = nil)
  if valid_601296 != nil:
    section.add "Engine", valid_601296
  var valid_601297 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601297 = validateParameter(valid_601297, JArray, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "VpcSecurityGroupIds", valid_601297
  var valid_601298 = formData.getOrDefault("Iops")
  valid_601298 = validateParameter(valid_601298, JInt, required = false, default = nil)
  if valid_601298 != nil:
    section.add "Iops", valid_601298
  var valid_601299 = formData.getOrDefault("DBName")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "DBName", valid_601299
  var valid_601300 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601300 = validateParameter(valid_601300, JString, required = true,
                                 default = nil)
  if valid_601300 != nil:
    section.add "DBInstanceIdentifier", valid_601300
  var valid_601301 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601301 = validateParameter(valid_601301, JInt, required = false, default = nil)
  if valid_601301 != nil:
    section.add "BackupRetentionPeriod", valid_601301
  var valid_601302 = formData.getOrDefault("DBParameterGroupName")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "DBParameterGroupName", valid_601302
  var valid_601303 = formData.getOrDefault("OptionGroupName")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "OptionGroupName", valid_601303
  var valid_601304 = formData.getOrDefault("Tags")
  valid_601304 = validateParameter(valid_601304, JArray, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "Tags", valid_601304
  var valid_601305 = formData.getOrDefault("MasterUserPassword")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = nil)
  if valid_601305 != nil:
    section.add "MasterUserPassword", valid_601305
  var valid_601306 = formData.getOrDefault("TdeCredentialArn")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "TdeCredentialArn", valid_601306
  var valid_601307 = formData.getOrDefault("DBSubnetGroupName")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "DBSubnetGroupName", valid_601307
  var valid_601308 = formData.getOrDefault("TdeCredentialPassword")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "TdeCredentialPassword", valid_601308
  var valid_601309 = formData.getOrDefault("AvailabilityZone")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "AvailabilityZone", valid_601309
  var valid_601310 = formData.getOrDefault("MultiAZ")
  valid_601310 = validateParameter(valid_601310, JBool, required = false, default = nil)
  if valid_601310 != nil:
    section.add "MultiAZ", valid_601310
  var valid_601311 = formData.getOrDefault("AllocatedStorage")
  valid_601311 = validateParameter(valid_601311, JInt, required = true, default = nil)
  if valid_601311 != nil:
    section.add "AllocatedStorage", valid_601311
  var valid_601312 = formData.getOrDefault("PubliclyAccessible")
  valid_601312 = validateParameter(valid_601312, JBool, required = false, default = nil)
  if valid_601312 != nil:
    section.add "PubliclyAccessible", valid_601312
  var valid_601313 = formData.getOrDefault("MasterUsername")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "MasterUsername", valid_601313
  var valid_601314 = formData.getOrDefault("StorageType")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "StorageType", valid_601314
  var valid_601315 = formData.getOrDefault("DBInstanceClass")
  valid_601315 = validateParameter(valid_601315, JString, required = true,
                                 default = nil)
  if valid_601315 != nil:
    section.add "DBInstanceClass", valid_601315
  var valid_601316 = formData.getOrDefault("CharacterSetName")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "CharacterSetName", valid_601316
  var valid_601317 = formData.getOrDefault("PreferredBackupWindow")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "PreferredBackupWindow", valid_601317
  var valid_601318 = formData.getOrDefault("LicenseModel")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "LicenseModel", valid_601318
  var valid_601319 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601319 = validateParameter(valid_601319, JBool, required = false, default = nil)
  if valid_601319 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601319
  var valid_601320 = formData.getOrDefault("EngineVersion")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "EngineVersion", valid_601320
  var valid_601321 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "PreferredMaintenanceWindow", valid_601321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601322: Call_PostCreateDBInstance_601282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601322.validator(path, query, header, formData, body)
  let scheme = call_601322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601322.url(scheme.get, call_601322.host, call_601322.base,
                         call_601322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601322, url, valid)

proc call*(call_601323: Call_PostCreateDBInstance_601282; Engine: string;
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
  var query_601324 = newJObject()
  var formData_601325 = newJObject()
  if DBSecurityGroups != nil:
    formData_601325.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601325, "Port", newJInt(Port))
  add(formData_601325, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601325.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601325, "Iops", newJInt(Iops))
  add(formData_601325, "DBName", newJString(DBName))
  add(formData_601325, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601325, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601325, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601325, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601325.add "Tags", Tags
  add(formData_601325, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601325, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_601325, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601325, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_601325, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601325, "MultiAZ", newJBool(MultiAZ))
  add(query_601324, "Action", newJString(Action))
  add(formData_601325, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601325, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601325, "MasterUsername", newJString(MasterUsername))
  add(formData_601325, "StorageType", newJString(StorageType))
  add(formData_601325, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601325, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601325, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601325, "LicenseModel", newJString(LicenseModel))
  add(formData_601325, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601325, "EngineVersion", newJString(EngineVersion))
  add(query_601324, "Version", newJString(Version))
  add(formData_601325, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601323.call(nil, query_601324, nil, formData_601325, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601282(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601283, base: "/",
    url: url_PostCreateDBInstance_601284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601239 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstance_601241(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_601240(path: JsonNode; query: JsonNode;
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
  var valid_601242 = query.getOrDefault("Engine")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = nil)
  if valid_601242 != nil:
    section.add "Engine", valid_601242
  var valid_601243 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "PreferredMaintenanceWindow", valid_601243
  var valid_601244 = query.getOrDefault("AllocatedStorage")
  valid_601244 = validateParameter(valid_601244, JInt, required = true, default = nil)
  if valid_601244 != nil:
    section.add "AllocatedStorage", valid_601244
  var valid_601245 = query.getOrDefault("StorageType")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "StorageType", valid_601245
  var valid_601246 = query.getOrDefault("OptionGroupName")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "OptionGroupName", valid_601246
  var valid_601247 = query.getOrDefault("DBSecurityGroups")
  valid_601247 = validateParameter(valid_601247, JArray, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "DBSecurityGroups", valid_601247
  var valid_601248 = query.getOrDefault("MasterUserPassword")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = nil)
  if valid_601248 != nil:
    section.add "MasterUserPassword", valid_601248
  var valid_601249 = query.getOrDefault("AvailabilityZone")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "AvailabilityZone", valid_601249
  var valid_601250 = query.getOrDefault("Iops")
  valid_601250 = validateParameter(valid_601250, JInt, required = false, default = nil)
  if valid_601250 != nil:
    section.add "Iops", valid_601250
  var valid_601251 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601251 = validateParameter(valid_601251, JArray, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "VpcSecurityGroupIds", valid_601251
  var valid_601252 = query.getOrDefault("MultiAZ")
  valid_601252 = validateParameter(valid_601252, JBool, required = false, default = nil)
  if valid_601252 != nil:
    section.add "MultiAZ", valid_601252
  var valid_601253 = query.getOrDefault("TdeCredentialPassword")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "TdeCredentialPassword", valid_601253
  var valid_601254 = query.getOrDefault("LicenseModel")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "LicenseModel", valid_601254
  var valid_601255 = query.getOrDefault("BackupRetentionPeriod")
  valid_601255 = validateParameter(valid_601255, JInt, required = false, default = nil)
  if valid_601255 != nil:
    section.add "BackupRetentionPeriod", valid_601255
  var valid_601256 = query.getOrDefault("DBName")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "DBName", valid_601256
  var valid_601257 = query.getOrDefault("DBParameterGroupName")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "DBParameterGroupName", valid_601257
  var valid_601258 = query.getOrDefault("Tags")
  valid_601258 = validateParameter(valid_601258, JArray, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "Tags", valid_601258
  var valid_601259 = query.getOrDefault("DBInstanceClass")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = nil)
  if valid_601259 != nil:
    section.add "DBInstanceClass", valid_601259
  var valid_601260 = query.getOrDefault("Action")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601260 != nil:
    section.add "Action", valid_601260
  var valid_601261 = query.getOrDefault("DBSubnetGroupName")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "DBSubnetGroupName", valid_601261
  var valid_601262 = query.getOrDefault("CharacterSetName")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "CharacterSetName", valid_601262
  var valid_601263 = query.getOrDefault("TdeCredentialArn")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "TdeCredentialArn", valid_601263
  var valid_601264 = query.getOrDefault("PubliclyAccessible")
  valid_601264 = validateParameter(valid_601264, JBool, required = false, default = nil)
  if valid_601264 != nil:
    section.add "PubliclyAccessible", valid_601264
  var valid_601265 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601265 = validateParameter(valid_601265, JBool, required = false, default = nil)
  if valid_601265 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601265
  var valid_601266 = query.getOrDefault("EngineVersion")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "EngineVersion", valid_601266
  var valid_601267 = query.getOrDefault("Port")
  valid_601267 = validateParameter(valid_601267, JInt, required = false, default = nil)
  if valid_601267 != nil:
    section.add "Port", valid_601267
  var valid_601268 = query.getOrDefault("PreferredBackupWindow")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "PreferredBackupWindow", valid_601268
  var valid_601269 = query.getOrDefault("Version")
  valid_601269 = validateParameter(valid_601269, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601269 != nil:
    section.add "Version", valid_601269
  var valid_601270 = query.getOrDefault("DBInstanceIdentifier")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = nil)
  if valid_601270 != nil:
    section.add "DBInstanceIdentifier", valid_601270
  var valid_601271 = query.getOrDefault("MasterUsername")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = nil)
  if valid_601271 != nil:
    section.add "MasterUsername", valid_601271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Content-Sha256", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Algorithm")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Algorithm", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Signature")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Signature", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-SignedHeaders", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Credential")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Credential", valid_601278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601279: Call_GetCreateDBInstance_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601279.validator(path, query, header, formData, body)
  let scheme = call_601279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601279.url(scheme.get, call_601279.host, call_601279.base,
                         call_601279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601279, url, valid)

proc call*(call_601280: Call_GetCreateDBInstance_601239; Engine: string;
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
  var query_601281 = newJObject()
  add(query_601281, "Engine", newJString(Engine))
  add(query_601281, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601281, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601281, "StorageType", newJString(StorageType))
  add(query_601281, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601281.add "DBSecurityGroups", DBSecurityGroups
  add(query_601281, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601281, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601281, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601281.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601281, "MultiAZ", newJBool(MultiAZ))
  add(query_601281, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_601281, "LicenseModel", newJString(LicenseModel))
  add(query_601281, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601281, "DBName", newJString(DBName))
  add(query_601281, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_601281.add "Tags", Tags
  add(query_601281, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601281, "Action", newJString(Action))
  add(query_601281, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601281, "CharacterSetName", newJString(CharacterSetName))
  add(query_601281, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_601281, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601281, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601281, "EngineVersion", newJString(EngineVersion))
  add(query_601281, "Port", newJInt(Port))
  add(query_601281, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601281, "Version", newJString(Version))
  add(query_601281, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601281, "MasterUsername", newJString(MasterUsername))
  result = call_601280.call(nil, query_601281, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601239(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601240, base: "/",
    url: url_GetCreateDBInstance_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601353 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstanceReadReplica_601355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_601354(path: JsonNode;
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
  var valid_601356 = query.getOrDefault("Action")
  valid_601356 = validateParameter(valid_601356, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601356 != nil:
    section.add "Action", valid_601356
  var valid_601357 = query.getOrDefault("Version")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601357 != nil:
    section.add "Version", valid_601357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601358 = header.getOrDefault("X-Amz-Date")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Date", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Security-Token")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Security-Token", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Content-Sha256", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Algorithm")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Algorithm", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Signature")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Signature", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-SignedHeaders", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Credential")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Credential", valid_601364
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
  var valid_601365 = formData.getOrDefault("Port")
  valid_601365 = validateParameter(valid_601365, JInt, required = false, default = nil)
  if valid_601365 != nil:
    section.add "Port", valid_601365
  var valid_601366 = formData.getOrDefault("Iops")
  valid_601366 = validateParameter(valid_601366, JInt, required = false, default = nil)
  if valid_601366 != nil:
    section.add "Iops", valid_601366
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601367 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601367 = validateParameter(valid_601367, JString, required = true,
                                 default = nil)
  if valid_601367 != nil:
    section.add "DBInstanceIdentifier", valid_601367
  var valid_601368 = formData.getOrDefault("OptionGroupName")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "OptionGroupName", valid_601368
  var valid_601369 = formData.getOrDefault("Tags")
  valid_601369 = validateParameter(valid_601369, JArray, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "Tags", valid_601369
  var valid_601370 = formData.getOrDefault("DBSubnetGroupName")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "DBSubnetGroupName", valid_601370
  var valid_601371 = formData.getOrDefault("AvailabilityZone")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "AvailabilityZone", valid_601371
  var valid_601372 = formData.getOrDefault("PubliclyAccessible")
  valid_601372 = validateParameter(valid_601372, JBool, required = false, default = nil)
  if valid_601372 != nil:
    section.add "PubliclyAccessible", valid_601372
  var valid_601373 = formData.getOrDefault("StorageType")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "StorageType", valid_601373
  var valid_601374 = formData.getOrDefault("DBInstanceClass")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "DBInstanceClass", valid_601374
  var valid_601375 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = nil)
  if valid_601375 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601375
  var valid_601376 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601376 = validateParameter(valid_601376, JBool, required = false, default = nil)
  if valid_601376 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601377: Call_PostCreateDBInstanceReadReplica_601353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601377.validator(path, query, header, formData, body)
  let scheme = call_601377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601377.url(scheme.get, call_601377.host, call_601377.base,
                         call_601377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601377, url, valid)

proc call*(call_601378: Call_PostCreateDBInstanceReadReplica_601353;
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
  var query_601379 = newJObject()
  var formData_601380 = newJObject()
  add(formData_601380, "Port", newJInt(Port))
  add(formData_601380, "Iops", newJInt(Iops))
  add(formData_601380, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601380, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601380.add "Tags", Tags
  add(formData_601380, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601380, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601379, "Action", newJString(Action))
  add(formData_601380, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601380, "StorageType", newJString(StorageType))
  add(formData_601380, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601380, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601380, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601379, "Version", newJString(Version))
  result = call_601378.call(nil, query_601379, nil, formData_601380, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601353(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601354, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601326 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstanceReadReplica_601328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_601327(path: JsonNode;
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
  var valid_601329 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = nil)
  if valid_601329 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601329
  var valid_601330 = query.getOrDefault("StorageType")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "StorageType", valid_601330
  var valid_601331 = query.getOrDefault("OptionGroupName")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "OptionGroupName", valid_601331
  var valid_601332 = query.getOrDefault("AvailabilityZone")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "AvailabilityZone", valid_601332
  var valid_601333 = query.getOrDefault("Iops")
  valid_601333 = validateParameter(valid_601333, JInt, required = false, default = nil)
  if valid_601333 != nil:
    section.add "Iops", valid_601333
  var valid_601334 = query.getOrDefault("Tags")
  valid_601334 = validateParameter(valid_601334, JArray, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "Tags", valid_601334
  var valid_601335 = query.getOrDefault("DBInstanceClass")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "DBInstanceClass", valid_601335
  var valid_601336 = query.getOrDefault("Action")
  valid_601336 = validateParameter(valid_601336, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601336 != nil:
    section.add "Action", valid_601336
  var valid_601337 = query.getOrDefault("DBSubnetGroupName")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "DBSubnetGroupName", valid_601337
  var valid_601338 = query.getOrDefault("PubliclyAccessible")
  valid_601338 = validateParameter(valid_601338, JBool, required = false, default = nil)
  if valid_601338 != nil:
    section.add "PubliclyAccessible", valid_601338
  var valid_601339 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601339 = validateParameter(valid_601339, JBool, required = false, default = nil)
  if valid_601339 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601339
  var valid_601340 = query.getOrDefault("Port")
  valid_601340 = validateParameter(valid_601340, JInt, required = false, default = nil)
  if valid_601340 != nil:
    section.add "Port", valid_601340
  var valid_601341 = query.getOrDefault("Version")
  valid_601341 = validateParameter(valid_601341, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601341 != nil:
    section.add "Version", valid_601341
  var valid_601342 = query.getOrDefault("DBInstanceIdentifier")
  valid_601342 = validateParameter(valid_601342, JString, required = true,
                                 default = nil)
  if valid_601342 != nil:
    section.add "DBInstanceIdentifier", valid_601342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601343 = header.getOrDefault("X-Amz-Date")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Date", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Security-Token")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Security-Token", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Content-Sha256", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Algorithm")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Algorithm", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Signature")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Signature", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-SignedHeaders", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Credential")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Credential", valid_601349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601350: Call_GetCreateDBInstanceReadReplica_601326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601350.validator(path, query, header, formData, body)
  let scheme = call_601350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601350.url(scheme.get, call_601350.host, call_601350.base,
                         call_601350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601350, url, valid)

proc call*(call_601351: Call_GetCreateDBInstanceReadReplica_601326;
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
  var query_601352 = newJObject()
  add(query_601352, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601352, "StorageType", newJString(StorageType))
  add(query_601352, "OptionGroupName", newJString(OptionGroupName))
  add(query_601352, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601352, "Iops", newJInt(Iops))
  if Tags != nil:
    query_601352.add "Tags", Tags
  add(query_601352, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601352, "Action", newJString(Action))
  add(query_601352, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601352, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601352, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601352, "Port", newJInt(Port))
  add(query_601352, "Version", newJString(Version))
  add(query_601352, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601351.call(nil, query_601352, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601326(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601327, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601400 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBParameterGroup_601402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_601401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601403 = query.getOrDefault("Action")
  valid_601403 = validateParameter(valid_601403, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601403 != nil:
    section.add "Action", valid_601403
  var valid_601404 = query.getOrDefault("Version")
  valid_601404 = validateParameter(valid_601404, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601404 != nil:
    section.add "Version", valid_601404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601405 = header.getOrDefault("X-Amz-Date")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Date", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Security-Token")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Security-Token", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Content-Sha256", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Algorithm")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Algorithm", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Signature")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Signature", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-SignedHeaders", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Credential")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Credential", valid_601411
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601412 = formData.getOrDefault("DBParameterGroupName")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = nil)
  if valid_601412 != nil:
    section.add "DBParameterGroupName", valid_601412
  var valid_601413 = formData.getOrDefault("Tags")
  valid_601413 = validateParameter(valid_601413, JArray, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "Tags", valid_601413
  var valid_601414 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = nil)
  if valid_601414 != nil:
    section.add "DBParameterGroupFamily", valid_601414
  var valid_601415 = formData.getOrDefault("Description")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = nil)
  if valid_601415 != nil:
    section.add "Description", valid_601415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_PostCreateDBParameterGroup_601400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_PostCreateDBParameterGroup_601400;
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
  var query_601418 = newJObject()
  var formData_601419 = newJObject()
  add(formData_601419, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_601419.add "Tags", Tags
  add(query_601418, "Action", newJString(Action))
  add(formData_601419, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601418, "Version", newJString(Version))
  add(formData_601419, "Description", newJString(Description))
  result = call_601417.call(nil, query_601418, nil, formData_601419, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601400(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601401, base: "/",
    url: url_PostCreateDBParameterGroup_601402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601381 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBParameterGroup_601383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_601382(path: JsonNode; query: JsonNode;
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
  var valid_601384 = query.getOrDefault("Description")
  valid_601384 = validateParameter(valid_601384, JString, required = true,
                                 default = nil)
  if valid_601384 != nil:
    section.add "Description", valid_601384
  var valid_601385 = query.getOrDefault("DBParameterGroupFamily")
  valid_601385 = validateParameter(valid_601385, JString, required = true,
                                 default = nil)
  if valid_601385 != nil:
    section.add "DBParameterGroupFamily", valid_601385
  var valid_601386 = query.getOrDefault("Tags")
  valid_601386 = validateParameter(valid_601386, JArray, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "Tags", valid_601386
  var valid_601387 = query.getOrDefault("DBParameterGroupName")
  valid_601387 = validateParameter(valid_601387, JString, required = true,
                                 default = nil)
  if valid_601387 != nil:
    section.add "DBParameterGroupName", valid_601387
  var valid_601388 = query.getOrDefault("Action")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601388 != nil:
    section.add "Action", valid_601388
  var valid_601389 = query.getOrDefault("Version")
  valid_601389 = validateParameter(valid_601389, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601389 != nil:
    section.add "Version", valid_601389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601390 = header.getOrDefault("X-Amz-Date")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Date", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Security-Token")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Security-Token", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Content-Sha256", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Algorithm")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Algorithm", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Signature")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Signature", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-SignedHeaders", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Credential")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Credential", valid_601396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601397: Call_GetCreateDBParameterGroup_601381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601397.validator(path, query, header, formData, body)
  let scheme = call_601397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601397.url(scheme.get, call_601397.host, call_601397.base,
                         call_601397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601397, url, valid)

proc call*(call_601398: Call_GetCreateDBParameterGroup_601381; Description: string;
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
  var query_601399 = newJObject()
  add(query_601399, "Description", newJString(Description))
  add(query_601399, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_601399.add "Tags", Tags
  add(query_601399, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601399, "Action", newJString(Action))
  add(query_601399, "Version", newJString(Version))
  result = call_601398.call(nil, query_601399, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601381(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601382, base: "/",
    url: url_GetCreateDBParameterGroup_601383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601438 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSecurityGroup_601440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_601439(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601441 = query.getOrDefault("Action")
  valid_601441 = validateParameter(valid_601441, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601441 != nil:
    section.add "Action", valid_601441
  var valid_601442 = query.getOrDefault("Version")
  valid_601442 = validateParameter(valid_601442, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601442 != nil:
    section.add "Version", valid_601442
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601443 = header.getOrDefault("X-Amz-Date")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Date", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Security-Token")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Security-Token", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Content-Sha256", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Algorithm")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Algorithm", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Signature")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Signature", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-SignedHeaders", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Credential")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Credential", valid_601449
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601450 = formData.getOrDefault("DBSecurityGroupName")
  valid_601450 = validateParameter(valid_601450, JString, required = true,
                                 default = nil)
  if valid_601450 != nil:
    section.add "DBSecurityGroupName", valid_601450
  var valid_601451 = formData.getOrDefault("Tags")
  valid_601451 = validateParameter(valid_601451, JArray, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "Tags", valid_601451
  var valid_601452 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601452 = validateParameter(valid_601452, JString, required = true,
                                 default = nil)
  if valid_601452 != nil:
    section.add "DBSecurityGroupDescription", valid_601452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601453: Call_PostCreateDBSecurityGroup_601438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601453.validator(path, query, header, formData, body)
  let scheme = call_601453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601453.url(scheme.get, call_601453.host, call_601453.base,
                         call_601453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601453, url, valid)

proc call*(call_601454: Call_PostCreateDBSecurityGroup_601438;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601455 = newJObject()
  var formData_601456 = newJObject()
  add(formData_601456, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_601456.add "Tags", Tags
  add(query_601455, "Action", newJString(Action))
  add(formData_601456, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601455, "Version", newJString(Version))
  result = call_601454.call(nil, query_601455, nil, formData_601456, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601438(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601439, base: "/",
    url: url_PostCreateDBSecurityGroup_601440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601420 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSecurityGroup_601422(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_601421(path: JsonNode; query: JsonNode;
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
  var valid_601423 = query.getOrDefault("DBSecurityGroupName")
  valid_601423 = validateParameter(valid_601423, JString, required = true,
                                 default = nil)
  if valid_601423 != nil:
    section.add "DBSecurityGroupName", valid_601423
  var valid_601424 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = nil)
  if valid_601424 != nil:
    section.add "DBSecurityGroupDescription", valid_601424
  var valid_601425 = query.getOrDefault("Tags")
  valid_601425 = validateParameter(valid_601425, JArray, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "Tags", valid_601425
  var valid_601426 = query.getOrDefault("Action")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601426 != nil:
    section.add "Action", valid_601426
  var valid_601427 = query.getOrDefault("Version")
  valid_601427 = validateParameter(valid_601427, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601427 != nil:
    section.add "Version", valid_601427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601428 = header.getOrDefault("X-Amz-Date")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Date", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Security-Token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Security-Token", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Content-Sha256", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Algorithm")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Algorithm", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Signature")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Signature", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-SignedHeaders", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Credential")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Credential", valid_601434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601435: Call_GetCreateDBSecurityGroup_601420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601435.validator(path, query, header, formData, body)
  let scheme = call_601435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601435.url(scheme.get, call_601435.host, call_601435.base,
                         call_601435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601435, url, valid)

proc call*(call_601436: Call_GetCreateDBSecurityGroup_601420;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601437 = newJObject()
  add(query_601437, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601437, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_601437.add "Tags", Tags
  add(query_601437, "Action", newJString(Action))
  add(query_601437, "Version", newJString(Version))
  result = call_601436.call(nil, query_601437, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601420(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601421, base: "/",
    url: url_GetCreateDBSecurityGroup_601422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601475 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSnapshot_601477(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_601476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601478 = query.getOrDefault("Action")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601478 != nil:
    section.add "Action", valid_601478
  var valid_601479 = query.getOrDefault("Version")
  valid_601479 = validateParameter(valid_601479, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601479 != nil:
    section.add "Version", valid_601479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601480 = header.getOrDefault("X-Amz-Date")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Date", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Security-Token")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Security-Token", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Content-Sha256", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Algorithm")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Algorithm", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Signature")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Signature", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-SignedHeaders", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Credential")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Credential", valid_601486
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601487 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601487 = validateParameter(valid_601487, JString, required = true,
                                 default = nil)
  if valid_601487 != nil:
    section.add "DBInstanceIdentifier", valid_601487
  var valid_601488 = formData.getOrDefault("Tags")
  valid_601488 = validateParameter(valid_601488, JArray, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "Tags", valid_601488
  var valid_601489 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = nil)
  if valid_601489 != nil:
    section.add "DBSnapshotIdentifier", valid_601489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_PostCreateDBSnapshot_601475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601490, url, valid)

proc call*(call_601491: Call_PostCreateDBSnapshot_601475;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601492 = newJObject()
  var formData_601493 = newJObject()
  add(formData_601493, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_601493.add "Tags", Tags
  add(formData_601493, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601492, "Action", newJString(Action))
  add(query_601492, "Version", newJString(Version))
  result = call_601491.call(nil, query_601492, nil, formData_601493, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601475(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601476, base: "/",
    url: url_PostCreateDBSnapshot_601477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601457 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSnapshot_601459(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_601458(path: JsonNode; query: JsonNode;
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
  var valid_601460 = query.getOrDefault("Tags")
  valid_601460 = validateParameter(valid_601460, JArray, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "Tags", valid_601460
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601461 = query.getOrDefault("Action")
  valid_601461 = validateParameter(valid_601461, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601461 != nil:
    section.add "Action", valid_601461
  var valid_601462 = query.getOrDefault("Version")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601462 != nil:
    section.add "Version", valid_601462
  var valid_601463 = query.getOrDefault("DBInstanceIdentifier")
  valid_601463 = validateParameter(valid_601463, JString, required = true,
                                 default = nil)
  if valid_601463 != nil:
    section.add "DBInstanceIdentifier", valid_601463
  var valid_601464 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601464 = validateParameter(valid_601464, JString, required = true,
                                 default = nil)
  if valid_601464 != nil:
    section.add "DBSnapshotIdentifier", valid_601464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601465 = header.getOrDefault("X-Amz-Date")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Date", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Security-Token")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Security-Token", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Content-Sha256", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Algorithm")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Algorithm", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Signature")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Signature", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-SignedHeaders", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Credential")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Credential", valid_601471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601472: Call_GetCreateDBSnapshot_601457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601472.validator(path, query, header, formData, body)
  let scheme = call_601472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601472.url(scheme.get, call_601472.host, call_601472.base,
                         call_601472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601472, url, valid)

proc call*(call_601473: Call_GetCreateDBSnapshot_601457;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601474 = newJObject()
  if Tags != nil:
    query_601474.add "Tags", Tags
  add(query_601474, "Action", newJString(Action))
  add(query_601474, "Version", newJString(Version))
  add(query_601474, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601474, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601473.call(nil, query_601474, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601457(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601458, base: "/",
    url: url_GetCreateDBSnapshot_601459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601513 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSubnetGroup_601515(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_601514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601516 = query.getOrDefault("Action")
  valid_601516 = validateParameter(valid_601516, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601516 != nil:
    section.add "Action", valid_601516
  var valid_601517 = query.getOrDefault("Version")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601517 != nil:
    section.add "Version", valid_601517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601518 = header.getOrDefault("X-Amz-Date")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Date", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Security-Token")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Security-Token", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Content-Sha256", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Algorithm")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Algorithm", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Signature")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Signature", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-SignedHeaders", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Credential")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Credential", valid_601524
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_601525 = formData.getOrDefault("Tags")
  valid_601525 = validateParameter(valid_601525, JArray, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "Tags", valid_601525
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601526 = formData.getOrDefault("DBSubnetGroupName")
  valid_601526 = validateParameter(valid_601526, JString, required = true,
                                 default = nil)
  if valid_601526 != nil:
    section.add "DBSubnetGroupName", valid_601526
  var valid_601527 = formData.getOrDefault("SubnetIds")
  valid_601527 = validateParameter(valid_601527, JArray, required = true, default = nil)
  if valid_601527 != nil:
    section.add "SubnetIds", valid_601527
  var valid_601528 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = nil)
  if valid_601528 != nil:
    section.add "DBSubnetGroupDescription", valid_601528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601529: Call_PostCreateDBSubnetGroup_601513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601529.validator(path, query, header, formData, body)
  let scheme = call_601529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601529.url(scheme.get, call_601529.host, call_601529.base,
                         call_601529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601529, url, valid)

proc call*(call_601530: Call_PostCreateDBSubnetGroup_601513;
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
  var query_601531 = newJObject()
  var formData_601532 = newJObject()
  if Tags != nil:
    formData_601532.add "Tags", Tags
  add(formData_601532, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601532.add "SubnetIds", SubnetIds
  add(query_601531, "Action", newJString(Action))
  add(formData_601532, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601531, "Version", newJString(Version))
  result = call_601530.call(nil, query_601531, nil, formData_601532, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601513(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601514, base: "/",
    url: url_PostCreateDBSubnetGroup_601515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601494 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSubnetGroup_601496(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_601495(path: JsonNode; query: JsonNode;
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
  var valid_601497 = query.getOrDefault("Tags")
  valid_601497 = validateParameter(valid_601497, JArray, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "Tags", valid_601497
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601498 = query.getOrDefault("Action")
  valid_601498 = validateParameter(valid_601498, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601498 != nil:
    section.add "Action", valid_601498
  var valid_601499 = query.getOrDefault("DBSubnetGroupName")
  valid_601499 = validateParameter(valid_601499, JString, required = true,
                                 default = nil)
  if valid_601499 != nil:
    section.add "DBSubnetGroupName", valid_601499
  var valid_601500 = query.getOrDefault("SubnetIds")
  valid_601500 = validateParameter(valid_601500, JArray, required = true, default = nil)
  if valid_601500 != nil:
    section.add "SubnetIds", valid_601500
  var valid_601501 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "DBSubnetGroupDescription", valid_601501
  var valid_601502 = query.getOrDefault("Version")
  valid_601502 = validateParameter(valid_601502, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601502 != nil:
    section.add "Version", valid_601502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601503 = header.getOrDefault("X-Amz-Date")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Date", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Security-Token")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Security-Token", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Content-Sha256", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Algorithm")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Algorithm", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Signature")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Signature", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-SignedHeaders", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Credential")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Credential", valid_601509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601510: Call_GetCreateDBSubnetGroup_601494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601510.validator(path, query, header, formData, body)
  let scheme = call_601510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601510.url(scheme.get, call_601510.host, call_601510.base,
                         call_601510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601510, url, valid)

proc call*(call_601511: Call_GetCreateDBSubnetGroup_601494;
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
  var query_601512 = newJObject()
  if Tags != nil:
    query_601512.add "Tags", Tags
  add(query_601512, "Action", newJString(Action))
  add(query_601512, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601512.add "SubnetIds", SubnetIds
  add(query_601512, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601512, "Version", newJString(Version))
  result = call_601511.call(nil, query_601512, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601494(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601495, base: "/",
    url: url_GetCreateDBSubnetGroup_601496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601555 = ref object of OpenApiRestCall_600421
proc url_PostCreateEventSubscription_601557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_601556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601558 = query.getOrDefault("Action")
  valid_601558 = validateParameter(valid_601558, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601558 != nil:
    section.add "Action", valid_601558
  var valid_601559 = query.getOrDefault("Version")
  valid_601559 = validateParameter(valid_601559, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601559 != nil:
    section.add "Version", valid_601559
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601560 = header.getOrDefault("X-Amz-Date")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Date", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Security-Token")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Security-Token", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Content-Sha256", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Algorithm")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Algorithm", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Signature")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Signature", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-SignedHeaders", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Credential")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Credential", valid_601566
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
  var valid_601567 = formData.getOrDefault("Enabled")
  valid_601567 = validateParameter(valid_601567, JBool, required = false, default = nil)
  if valid_601567 != nil:
    section.add "Enabled", valid_601567
  var valid_601568 = formData.getOrDefault("EventCategories")
  valid_601568 = validateParameter(valid_601568, JArray, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "EventCategories", valid_601568
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601569 = formData.getOrDefault("SnsTopicArn")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = nil)
  if valid_601569 != nil:
    section.add "SnsTopicArn", valid_601569
  var valid_601570 = formData.getOrDefault("SourceIds")
  valid_601570 = validateParameter(valid_601570, JArray, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "SourceIds", valid_601570
  var valid_601571 = formData.getOrDefault("Tags")
  valid_601571 = validateParameter(valid_601571, JArray, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "Tags", valid_601571
  var valid_601572 = formData.getOrDefault("SubscriptionName")
  valid_601572 = validateParameter(valid_601572, JString, required = true,
                                 default = nil)
  if valid_601572 != nil:
    section.add "SubscriptionName", valid_601572
  var valid_601573 = formData.getOrDefault("SourceType")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "SourceType", valid_601573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601574: Call_PostCreateEventSubscription_601555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601574.validator(path, query, header, formData, body)
  let scheme = call_601574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601574.url(scheme.get, call_601574.host, call_601574.base,
                         call_601574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601574, url, valid)

proc call*(call_601575: Call_PostCreateEventSubscription_601555;
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
  var query_601576 = newJObject()
  var formData_601577 = newJObject()
  add(formData_601577, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601577.add "EventCategories", EventCategories
  add(formData_601577, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601577.add "SourceIds", SourceIds
  if Tags != nil:
    formData_601577.add "Tags", Tags
  add(formData_601577, "SubscriptionName", newJString(SubscriptionName))
  add(query_601576, "Action", newJString(Action))
  add(query_601576, "Version", newJString(Version))
  add(formData_601577, "SourceType", newJString(SourceType))
  result = call_601575.call(nil, query_601576, nil, formData_601577, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601555(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601556, base: "/",
    url: url_PostCreateEventSubscription_601557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601533 = ref object of OpenApiRestCall_600421
proc url_GetCreateEventSubscription_601535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_601534(path: JsonNode; query: JsonNode;
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
  var valid_601536 = query.getOrDefault("SourceType")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "SourceType", valid_601536
  var valid_601537 = query.getOrDefault("SourceIds")
  valid_601537 = validateParameter(valid_601537, JArray, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "SourceIds", valid_601537
  var valid_601538 = query.getOrDefault("Enabled")
  valid_601538 = validateParameter(valid_601538, JBool, required = false, default = nil)
  if valid_601538 != nil:
    section.add "Enabled", valid_601538
  var valid_601539 = query.getOrDefault("Tags")
  valid_601539 = validateParameter(valid_601539, JArray, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "Tags", valid_601539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601540 = query.getOrDefault("Action")
  valid_601540 = validateParameter(valid_601540, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601540 != nil:
    section.add "Action", valid_601540
  var valid_601541 = query.getOrDefault("SnsTopicArn")
  valid_601541 = validateParameter(valid_601541, JString, required = true,
                                 default = nil)
  if valid_601541 != nil:
    section.add "SnsTopicArn", valid_601541
  var valid_601542 = query.getOrDefault("EventCategories")
  valid_601542 = validateParameter(valid_601542, JArray, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "EventCategories", valid_601542
  var valid_601543 = query.getOrDefault("SubscriptionName")
  valid_601543 = validateParameter(valid_601543, JString, required = true,
                                 default = nil)
  if valid_601543 != nil:
    section.add "SubscriptionName", valid_601543
  var valid_601544 = query.getOrDefault("Version")
  valid_601544 = validateParameter(valid_601544, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601544 != nil:
    section.add "Version", valid_601544
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601545 = header.getOrDefault("X-Amz-Date")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Date", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Security-Token")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Security-Token", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Content-Sha256", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Algorithm")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Algorithm", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Signature")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Signature", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-SignedHeaders", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Credential")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Credential", valid_601551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601552: Call_GetCreateEventSubscription_601533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601552.validator(path, query, header, formData, body)
  let scheme = call_601552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601552.url(scheme.get, call_601552.host, call_601552.base,
                         call_601552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601552, url, valid)

proc call*(call_601553: Call_GetCreateEventSubscription_601533;
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
  var query_601554 = newJObject()
  add(query_601554, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601554.add "SourceIds", SourceIds
  add(query_601554, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_601554.add "Tags", Tags
  add(query_601554, "Action", newJString(Action))
  add(query_601554, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601554.add "EventCategories", EventCategories
  add(query_601554, "SubscriptionName", newJString(SubscriptionName))
  add(query_601554, "Version", newJString(Version))
  result = call_601553.call(nil, query_601554, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601533(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601534, base: "/",
    url: url_GetCreateEventSubscription_601535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601598 = ref object of OpenApiRestCall_600421
proc url_PostCreateOptionGroup_601600(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_601599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601601 = query.getOrDefault("Action")
  valid_601601 = validateParameter(valid_601601, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601601 != nil:
    section.add "Action", valid_601601
  var valid_601602 = query.getOrDefault("Version")
  valid_601602 = validateParameter(valid_601602, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601602 != nil:
    section.add "Version", valid_601602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601603 = header.getOrDefault("X-Amz-Date")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Date", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Security-Token")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Security-Token", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601610 = formData.getOrDefault("MajorEngineVersion")
  valid_601610 = validateParameter(valid_601610, JString, required = true,
                                 default = nil)
  if valid_601610 != nil:
    section.add "MajorEngineVersion", valid_601610
  var valid_601611 = formData.getOrDefault("OptionGroupName")
  valid_601611 = validateParameter(valid_601611, JString, required = true,
                                 default = nil)
  if valid_601611 != nil:
    section.add "OptionGroupName", valid_601611
  var valid_601612 = formData.getOrDefault("Tags")
  valid_601612 = validateParameter(valid_601612, JArray, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "Tags", valid_601612
  var valid_601613 = formData.getOrDefault("EngineName")
  valid_601613 = validateParameter(valid_601613, JString, required = true,
                                 default = nil)
  if valid_601613 != nil:
    section.add "EngineName", valid_601613
  var valid_601614 = formData.getOrDefault("OptionGroupDescription")
  valid_601614 = validateParameter(valid_601614, JString, required = true,
                                 default = nil)
  if valid_601614 != nil:
    section.add "OptionGroupDescription", valid_601614
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601615: Call_PostCreateOptionGroup_601598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601615.validator(path, query, header, formData, body)
  let scheme = call_601615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601615.url(scheme.get, call_601615.host, call_601615.base,
                         call_601615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601615, url, valid)

proc call*(call_601616: Call_PostCreateOptionGroup_601598;
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
  var query_601617 = newJObject()
  var formData_601618 = newJObject()
  add(formData_601618, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601618, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601618.add "Tags", Tags
  add(query_601617, "Action", newJString(Action))
  add(formData_601618, "EngineName", newJString(EngineName))
  add(formData_601618, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601617, "Version", newJString(Version))
  result = call_601616.call(nil, query_601617, nil, formData_601618, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601598(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601599, base: "/",
    url: url_PostCreateOptionGroup_601600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601578 = ref object of OpenApiRestCall_600421
proc url_GetCreateOptionGroup_601580(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_601579(path: JsonNode; query: JsonNode;
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
  var valid_601581 = query.getOrDefault("OptionGroupName")
  valid_601581 = validateParameter(valid_601581, JString, required = true,
                                 default = nil)
  if valid_601581 != nil:
    section.add "OptionGroupName", valid_601581
  var valid_601582 = query.getOrDefault("Tags")
  valid_601582 = validateParameter(valid_601582, JArray, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "Tags", valid_601582
  var valid_601583 = query.getOrDefault("OptionGroupDescription")
  valid_601583 = validateParameter(valid_601583, JString, required = true,
                                 default = nil)
  if valid_601583 != nil:
    section.add "OptionGroupDescription", valid_601583
  var valid_601584 = query.getOrDefault("Action")
  valid_601584 = validateParameter(valid_601584, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601584 != nil:
    section.add "Action", valid_601584
  var valid_601585 = query.getOrDefault("Version")
  valid_601585 = validateParameter(valid_601585, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601585 != nil:
    section.add "Version", valid_601585
  var valid_601586 = query.getOrDefault("EngineName")
  valid_601586 = validateParameter(valid_601586, JString, required = true,
                                 default = nil)
  if valid_601586 != nil:
    section.add "EngineName", valid_601586
  var valid_601587 = query.getOrDefault("MajorEngineVersion")
  valid_601587 = validateParameter(valid_601587, JString, required = true,
                                 default = nil)
  if valid_601587 != nil:
    section.add "MajorEngineVersion", valid_601587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601588 = header.getOrDefault("X-Amz-Date")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Date", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Security-Token")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Security-Token", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Content-Sha256", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Algorithm")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Algorithm", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Signature")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Signature", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-SignedHeaders", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Credential")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Credential", valid_601594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601595: Call_GetCreateOptionGroup_601578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601595.validator(path, query, header, formData, body)
  let scheme = call_601595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601595.url(scheme.get, call_601595.host, call_601595.base,
                         call_601595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601595, url, valid)

proc call*(call_601596: Call_GetCreateOptionGroup_601578; OptionGroupName: string;
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
  var query_601597 = newJObject()
  add(query_601597, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_601597.add "Tags", Tags
  add(query_601597, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601597, "Action", newJString(Action))
  add(query_601597, "Version", newJString(Version))
  add(query_601597, "EngineName", newJString(EngineName))
  add(query_601597, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601596.call(nil, query_601597, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601578(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601579, base: "/",
    url: url_GetCreateOptionGroup_601580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601637 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBInstance_601639(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_601638(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601640 = query.getOrDefault("Action")
  valid_601640 = validateParameter(valid_601640, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601640 != nil:
    section.add "Action", valid_601640
  var valid_601641 = query.getOrDefault("Version")
  valid_601641 = validateParameter(valid_601641, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601641 != nil:
    section.add "Version", valid_601641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601642 = header.getOrDefault("X-Amz-Date")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Date", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Security-Token")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Security-Token", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Content-Sha256", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Algorithm")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Algorithm", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Signature")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Signature", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-SignedHeaders", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Credential")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Credential", valid_601648
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601649 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601649 = validateParameter(valid_601649, JString, required = true,
                                 default = nil)
  if valid_601649 != nil:
    section.add "DBInstanceIdentifier", valid_601649
  var valid_601650 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601650
  var valid_601651 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601651 = validateParameter(valid_601651, JBool, required = false, default = nil)
  if valid_601651 != nil:
    section.add "SkipFinalSnapshot", valid_601651
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601652: Call_PostDeleteDBInstance_601637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601652.validator(path, query, header, formData, body)
  let scheme = call_601652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601652.url(scheme.get, call_601652.host, call_601652.base,
                         call_601652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601652, url, valid)

proc call*(call_601653: Call_PostDeleteDBInstance_601637;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601654 = newJObject()
  var formData_601655 = newJObject()
  add(formData_601655, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601655, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601654, "Action", newJString(Action))
  add(query_601654, "Version", newJString(Version))
  add(formData_601655, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601653.call(nil, query_601654, nil, formData_601655, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601637(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601638, base: "/",
    url: url_PostDeleteDBInstance_601639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601619 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBInstance_601621(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_601620(path: JsonNode; query: JsonNode;
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
  var valid_601622 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601622
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601623 = query.getOrDefault("Action")
  valid_601623 = validateParameter(valid_601623, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601623 != nil:
    section.add "Action", valid_601623
  var valid_601624 = query.getOrDefault("SkipFinalSnapshot")
  valid_601624 = validateParameter(valid_601624, JBool, required = false, default = nil)
  if valid_601624 != nil:
    section.add "SkipFinalSnapshot", valid_601624
  var valid_601625 = query.getOrDefault("Version")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601625 != nil:
    section.add "Version", valid_601625
  var valid_601626 = query.getOrDefault("DBInstanceIdentifier")
  valid_601626 = validateParameter(valid_601626, JString, required = true,
                                 default = nil)
  if valid_601626 != nil:
    section.add "DBInstanceIdentifier", valid_601626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601627 = header.getOrDefault("X-Amz-Date")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Date", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Security-Token")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Security-Token", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Content-Sha256", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Algorithm")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Algorithm", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Signature")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Signature", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-SignedHeaders", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Credential")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Credential", valid_601633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601634: Call_GetDeleteDBInstance_601619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601634.validator(path, query, header, formData, body)
  let scheme = call_601634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601634.url(scheme.get, call_601634.host, call_601634.base,
                         call_601634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601634, url, valid)

proc call*(call_601635: Call_GetDeleteDBInstance_601619;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601636 = newJObject()
  add(query_601636, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601636, "Action", newJString(Action))
  add(query_601636, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601636, "Version", newJString(Version))
  add(query_601636, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601635.call(nil, query_601636, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601619(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601620, base: "/",
    url: url_GetDeleteDBInstance_601621, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601672 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBParameterGroup_601674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_601673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601675 = query.getOrDefault("Action")
  valid_601675 = validateParameter(valid_601675, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601675 != nil:
    section.add "Action", valid_601675
  var valid_601676 = query.getOrDefault("Version")
  valid_601676 = validateParameter(valid_601676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601676 != nil:
    section.add "Version", valid_601676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601677 = header.getOrDefault("X-Amz-Date")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Date", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Security-Token")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Security-Token", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Content-Sha256", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Algorithm")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Algorithm", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Signature")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Signature", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-SignedHeaders", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Credential")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Credential", valid_601683
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601684 = formData.getOrDefault("DBParameterGroupName")
  valid_601684 = validateParameter(valid_601684, JString, required = true,
                                 default = nil)
  if valid_601684 != nil:
    section.add "DBParameterGroupName", valid_601684
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601685: Call_PostDeleteDBParameterGroup_601672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601685.validator(path, query, header, formData, body)
  let scheme = call_601685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601685.url(scheme.get, call_601685.host, call_601685.base,
                         call_601685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601685, url, valid)

proc call*(call_601686: Call_PostDeleteDBParameterGroup_601672;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601687 = newJObject()
  var formData_601688 = newJObject()
  add(formData_601688, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601687, "Action", newJString(Action))
  add(query_601687, "Version", newJString(Version))
  result = call_601686.call(nil, query_601687, nil, formData_601688, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601672(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601673, base: "/",
    url: url_PostDeleteDBParameterGroup_601674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601656 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBParameterGroup_601658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_601657(path: JsonNode; query: JsonNode;
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
  var valid_601659 = query.getOrDefault("DBParameterGroupName")
  valid_601659 = validateParameter(valid_601659, JString, required = true,
                                 default = nil)
  if valid_601659 != nil:
    section.add "DBParameterGroupName", valid_601659
  var valid_601660 = query.getOrDefault("Action")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601660 != nil:
    section.add "Action", valid_601660
  var valid_601661 = query.getOrDefault("Version")
  valid_601661 = validateParameter(valid_601661, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601661 != nil:
    section.add "Version", valid_601661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601662 = header.getOrDefault("X-Amz-Date")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Date", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Security-Token")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Security-Token", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Content-Sha256", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Algorithm")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Algorithm", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Signature")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Signature", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-SignedHeaders", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Credential")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Credential", valid_601668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_GetDeleteDBParameterGroup_601656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_GetDeleteDBParameterGroup_601656;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601671 = newJObject()
  add(query_601671, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601671, "Action", newJString(Action))
  add(query_601671, "Version", newJString(Version))
  result = call_601670.call(nil, query_601671, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601656(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601657, base: "/",
    url: url_GetDeleteDBParameterGroup_601658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601705 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSecurityGroup_601707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_601706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601708 = query.getOrDefault("Action")
  valid_601708 = validateParameter(valid_601708, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601708 != nil:
    section.add "Action", valid_601708
  var valid_601709 = query.getOrDefault("Version")
  valid_601709 = validateParameter(valid_601709, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601709 != nil:
    section.add "Version", valid_601709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601710 = header.getOrDefault("X-Amz-Date")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Date", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Security-Token")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Security-Token", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Content-Sha256", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Algorithm")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Algorithm", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Signature")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Signature", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-SignedHeaders", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Credential")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Credential", valid_601716
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601717 = formData.getOrDefault("DBSecurityGroupName")
  valid_601717 = validateParameter(valid_601717, JString, required = true,
                                 default = nil)
  if valid_601717 != nil:
    section.add "DBSecurityGroupName", valid_601717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601718: Call_PostDeleteDBSecurityGroup_601705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601718.validator(path, query, header, formData, body)
  let scheme = call_601718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601718.url(scheme.get, call_601718.host, call_601718.base,
                         call_601718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601718, url, valid)

proc call*(call_601719: Call_PostDeleteDBSecurityGroup_601705;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601720 = newJObject()
  var formData_601721 = newJObject()
  add(formData_601721, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601720, "Action", newJString(Action))
  add(query_601720, "Version", newJString(Version))
  result = call_601719.call(nil, query_601720, nil, formData_601721, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601705(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601706, base: "/",
    url: url_PostDeleteDBSecurityGroup_601707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601689 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSecurityGroup_601691(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_601690(path: JsonNode; query: JsonNode;
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
  var valid_601692 = query.getOrDefault("DBSecurityGroupName")
  valid_601692 = validateParameter(valid_601692, JString, required = true,
                                 default = nil)
  if valid_601692 != nil:
    section.add "DBSecurityGroupName", valid_601692
  var valid_601693 = query.getOrDefault("Action")
  valid_601693 = validateParameter(valid_601693, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601693 != nil:
    section.add "Action", valid_601693
  var valid_601694 = query.getOrDefault("Version")
  valid_601694 = validateParameter(valid_601694, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601694 != nil:
    section.add "Version", valid_601694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601695 = header.getOrDefault("X-Amz-Date")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Date", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Security-Token")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Security-Token", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Content-Sha256", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Algorithm")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Algorithm", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Signature")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Signature", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-SignedHeaders", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Credential")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Credential", valid_601701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601702: Call_GetDeleteDBSecurityGroup_601689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601702.validator(path, query, header, formData, body)
  let scheme = call_601702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601702.url(scheme.get, call_601702.host, call_601702.base,
                         call_601702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601702, url, valid)

proc call*(call_601703: Call_GetDeleteDBSecurityGroup_601689;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601704 = newJObject()
  add(query_601704, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601704, "Action", newJString(Action))
  add(query_601704, "Version", newJString(Version))
  result = call_601703.call(nil, query_601704, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601689(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601690, base: "/",
    url: url_GetDeleteDBSecurityGroup_601691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601738 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSnapshot_601740(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_601739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601741 = query.getOrDefault("Action")
  valid_601741 = validateParameter(valid_601741, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601741 != nil:
    section.add "Action", valid_601741
  var valid_601742 = query.getOrDefault("Version")
  valid_601742 = validateParameter(valid_601742, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601742 != nil:
    section.add "Version", valid_601742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601743 = header.getOrDefault("X-Amz-Date")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Date", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Security-Token")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Security-Token", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Content-Sha256", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Algorithm")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Algorithm", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Signature")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Signature", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-SignedHeaders", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Credential")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Credential", valid_601749
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601750 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601750 = validateParameter(valid_601750, JString, required = true,
                                 default = nil)
  if valid_601750 != nil:
    section.add "DBSnapshotIdentifier", valid_601750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601751: Call_PostDeleteDBSnapshot_601738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601751.validator(path, query, header, formData, body)
  let scheme = call_601751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601751.url(scheme.get, call_601751.host, call_601751.base,
                         call_601751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601751, url, valid)

proc call*(call_601752: Call_PostDeleteDBSnapshot_601738;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601753 = newJObject()
  var formData_601754 = newJObject()
  add(formData_601754, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601753, "Action", newJString(Action))
  add(query_601753, "Version", newJString(Version))
  result = call_601752.call(nil, query_601753, nil, formData_601754, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601738(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601739, base: "/",
    url: url_PostDeleteDBSnapshot_601740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601722 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSnapshot_601724(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_601723(path: JsonNode; query: JsonNode;
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
  var valid_601725 = query.getOrDefault("Action")
  valid_601725 = validateParameter(valid_601725, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601725 != nil:
    section.add "Action", valid_601725
  var valid_601726 = query.getOrDefault("Version")
  valid_601726 = validateParameter(valid_601726, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601726 != nil:
    section.add "Version", valid_601726
  var valid_601727 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = nil)
  if valid_601727 != nil:
    section.add "DBSnapshotIdentifier", valid_601727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601728 = header.getOrDefault("X-Amz-Date")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Date", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Security-Token")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Security-Token", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Content-Sha256", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Algorithm")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Algorithm", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Signature")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Signature", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-SignedHeaders", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Credential")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Credential", valid_601734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601735: Call_GetDeleteDBSnapshot_601722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601735.validator(path, query, header, formData, body)
  let scheme = call_601735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601735.url(scheme.get, call_601735.host, call_601735.base,
                         call_601735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601735, url, valid)

proc call*(call_601736: Call_GetDeleteDBSnapshot_601722;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601737 = newJObject()
  add(query_601737, "Action", newJString(Action))
  add(query_601737, "Version", newJString(Version))
  add(query_601737, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601736.call(nil, query_601737, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601722(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601723, base: "/",
    url: url_GetDeleteDBSnapshot_601724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601771 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSubnetGroup_601773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_601772(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601774 = query.getOrDefault("Action")
  valid_601774 = validateParameter(valid_601774, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601774 != nil:
    section.add "Action", valid_601774
  var valid_601775 = query.getOrDefault("Version")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601775 != nil:
    section.add "Version", valid_601775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601776 = header.getOrDefault("X-Amz-Date")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Date", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Security-Token")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Security-Token", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Content-Sha256", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Algorithm")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Algorithm", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Signature")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Signature", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-SignedHeaders", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Credential")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Credential", valid_601782
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601783 = formData.getOrDefault("DBSubnetGroupName")
  valid_601783 = validateParameter(valid_601783, JString, required = true,
                                 default = nil)
  if valid_601783 != nil:
    section.add "DBSubnetGroupName", valid_601783
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601784: Call_PostDeleteDBSubnetGroup_601771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601784.validator(path, query, header, formData, body)
  let scheme = call_601784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601784.url(scheme.get, call_601784.host, call_601784.base,
                         call_601784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601784, url, valid)

proc call*(call_601785: Call_PostDeleteDBSubnetGroup_601771;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601786 = newJObject()
  var formData_601787 = newJObject()
  add(formData_601787, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601786, "Action", newJString(Action))
  add(query_601786, "Version", newJString(Version))
  result = call_601785.call(nil, query_601786, nil, formData_601787, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601771(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601772, base: "/",
    url: url_PostDeleteDBSubnetGroup_601773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601755 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSubnetGroup_601757(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_601756(path: JsonNode; query: JsonNode;
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
  var valid_601758 = query.getOrDefault("Action")
  valid_601758 = validateParameter(valid_601758, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601758 != nil:
    section.add "Action", valid_601758
  var valid_601759 = query.getOrDefault("DBSubnetGroupName")
  valid_601759 = validateParameter(valid_601759, JString, required = true,
                                 default = nil)
  if valid_601759 != nil:
    section.add "DBSubnetGroupName", valid_601759
  var valid_601760 = query.getOrDefault("Version")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601760 != nil:
    section.add "Version", valid_601760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601761 = header.getOrDefault("X-Amz-Date")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Date", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Security-Token")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Security-Token", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Content-Sha256", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Algorithm")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Algorithm", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Signature")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Signature", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-SignedHeaders", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Credential")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Credential", valid_601767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601768: Call_GetDeleteDBSubnetGroup_601755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601768.validator(path, query, header, formData, body)
  let scheme = call_601768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601768.url(scheme.get, call_601768.host, call_601768.base,
                         call_601768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601768, url, valid)

proc call*(call_601769: Call_GetDeleteDBSubnetGroup_601755;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601770 = newJObject()
  add(query_601770, "Action", newJString(Action))
  add(query_601770, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601770, "Version", newJString(Version))
  result = call_601769.call(nil, query_601770, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601755(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601756, base: "/",
    url: url_GetDeleteDBSubnetGroup_601757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601804 = ref object of OpenApiRestCall_600421
proc url_PostDeleteEventSubscription_601806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_601805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601807 = query.getOrDefault("Action")
  valid_601807 = validateParameter(valid_601807, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601807 != nil:
    section.add "Action", valid_601807
  var valid_601808 = query.getOrDefault("Version")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601808 != nil:
    section.add "Version", valid_601808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601809 = header.getOrDefault("X-Amz-Date")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Date", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Security-Token")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Security-Token", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Content-Sha256", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Algorithm")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Algorithm", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Signature")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Signature", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-SignedHeaders", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Credential")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Credential", valid_601815
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601816 = formData.getOrDefault("SubscriptionName")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = nil)
  if valid_601816 != nil:
    section.add "SubscriptionName", valid_601816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601817: Call_PostDeleteEventSubscription_601804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601817.validator(path, query, header, formData, body)
  let scheme = call_601817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601817.url(scheme.get, call_601817.host, call_601817.base,
                         call_601817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601817, url, valid)

proc call*(call_601818: Call_PostDeleteEventSubscription_601804;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601819 = newJObject()
  var formData_601820 = newJObject()
  add(formData_601820, "SubscriptionName", newJString(SubscriptionName))
  add(query_601819, "Action", newJString(Action))
  add(query_601819, "Version", newJString(Version))
  result = call_601818.call(nil, query_601819, nil, formData_601820, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601804(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601805, base: "/",
    url: url_PostDeleteEventSubscription_601806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601788 = ref object of OpenApiRestCall_600421
proc url_GetDeleteEventSubscription_601790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_601789(path: JsonNode; query: JsonNode;
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
  var valid_601791 = query.getOrDefault("Action")
  valid_601791 = validateParameter(valid_601791, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601791 != nil:
    section.add "Action", valid_601791
  var valid_601792 = query.getOrDefault("SubscriptionName")
  valid_601792 = validateParameter(valid_601792, JString, required = true,
                                 default = nil)
  if valid_601792 != nil:
    section.add "SubscriptionName", valid_601792
  var valid_601793 = query.getOrDefault("Version")
  valid_601793 = validateParameter(valid_601793, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601793 != nil:
    section.add "Version", valid_601793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601794 = header.getOrDefault("X-Amz-Date")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Date", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Security-Token")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Security-Token", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Content-Sha256", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Algorithm")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Algorithm", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Signature")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Signature", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-SignedHeaders", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Credential")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Credential", valid_601800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601801: Call_GetDeleteEventSubscription_601788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601801.validator(path, query, header, formData, body)
  let scheme = call_601801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601801.url(scheme.get, call_601801.host, call_601801.base,
                         call_601801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601801, url, valid)

proc call*(call_601802: Call_GetDeleteEventSubscription_601788;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601803 = newJObject()
  add(query_601803, "Action", newJString(Action))
  add(query_601803, "SubscriptionName", newJString(SubscriptionName))
  add(query_601803, "Version", newJString(Version))
  result = call_601802.call(nil, query_601803, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601788(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601789, base: "/",
    url: url_GetDeleteEventSubscription_601790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601837 = ref object of OpenApiRestCall_600421
proc url_PostDeleteOptionGroup_601839(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_601838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601840 = query.getOrDefault("Action")
  valid_601840 = validateParameter(valid_601840, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601840 != nil:
    section.add "Action", valid_601840
  var valid_601841 = query.getOrDefault("Version")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601841 != nil:
    section.add "Version", valid_601841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601842 = header.getOrDefault("X-Amz-Date")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Date", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Security-Token")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Security-Token", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Algorithm")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Algorithm", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601849 = formData.getOrDefault("OptionGroupName")
  valid_601849 = validateParameter(valid_601849, JString, required = true,
                                 default = nil)
  if valid_601849 != nil:
    section.add "OptionGroupName", valid_601849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601850: Call_PostDeleteOptionGroup_601837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601850.validator(path, query, header, formData, body)
  let scheme = call_601850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601850.url(scheme.get, call_601850.host, call_601850.base,
                         call_601850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601850, url, valid)

proc call*(call_601851: Call_PostDeleteOptionGroup_601837; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601852 = newJObject()
  var formData_601853 = newJObject()
  add(formData_601853, "OptionGroupName", newJString(OptionGroupName))
  add(query_601852, "Action", newJString(Action))
  add(query_601852, "Version", newJString(Version))
  result = call_601851.call(nil, query_601852, nil, formData_601853, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601837(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601838, base: "/",
    url: url_PostDeleteOptionGroup_601839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601821 = ref object of OpenApiRestCall_600421
proc url_GetDeleteOptionGroup_601823(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_601822(path: JsonNode; query: JsonNode;
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
  var valid_601824 = query.getOrDefault("OptionGroupName")
  valid_601824 = validateParameter(valid_601824, JString, required = true,
                                 default = nil)
  if valid_601824 != nil:
    section.add "OptionGroupName", valid_601824
  var valid_601825 = query.getOrDefault("Action")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601825 != nil:
    section.add "Action", valid_601825
  var valid_601826 = query.getOrDefault("Version")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601826 != nil:
    section.add "Version", valid_601826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601827 = header.getOrDefault("X-Amz-Date")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Date", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Security-Token")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Security-Token", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Content-Sha256", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Algorithm")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Algorithm", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Signature")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Signature", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-SignedHeaders", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Credential")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Credential", valid_601833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601834: Call_GetDeleteOptionGroup_601821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601834.validator(path, query, header, formData, body)
  let scheme = call_601834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601834.url(scheme.get, call_601834.host, call_601834.base,
                         call_601834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601834, url, valid)

proc call*(call_601835: Call_GetDeleteOptionGroup_601821; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601836 = newJObject()
  add(query_601836, "OptionGroupName", newJString(OptionGroupName))
  add(query_601836, "Action", newJString(Action))
  add(query_601836, "Version", newJString(Version))
  result = call_601835.call(nil, query_601836, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601821(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601822, base: "/",
    url: url_GetDeleteOptionGroup_601823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601877 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBEngineVersions_601879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_601878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601880 = query.getOrDefault("Action")
  valid_601880 = validateParameter(valid_601880, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601880 != nil:
    section.add "Action", valid_601880
  var valid_601881 = query.getOrDefault("Version")
  valid_601881 = validateParameter(valid_601881, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601881 != nil:
    section.add "Version", valid_601881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601882 = header.getOrDefault("X-Amz-Date")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Date", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Security-Token")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Security-Token", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Content-Sha256", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Algorithm")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Algorithm", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Signature")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Signature", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-SignedHeaders", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-Credential")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Credential", valid_601888
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
  var valid_601889 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601889 = validateParameter(valid_601889, JBool, required = false, default = nil)
  if valid_601889 != nil:
    section.add "ListSupportedCharacterSets", valid_601889
  var valid_601890 = formData.getOrDefault("Engine")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "Engine", valid_601890
  var valid_601891 = formData.getOrDefault("Marker")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "Marker", valid_601891
  var valid_601892 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "DBParameterGroupFamily", valid_601892
  var valid_601893 = formData.getOrDefault("Filters")
  valid_601893 = validateParameter(valid_601893, JArray, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "Filters", valid_601893
  var valid_601894 = formData.getOrDefault("MaxRecords")
  valid_601894 = validateParameter(valid_601894, JInt, required = false, default = nil)
  if valid_601894 != nil:
    section.add "MaxRecords", valid_601894
  var valid_601895 = formData.getOrDefault("EngineVersion")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "EngineVersion", valid_601895
  var valid_601896 = formData.getOrDefault("DefaultOnly")
  valid_601896 = validateParameter(valid_601896, JBool, required = false, default = nil)
  if valid_601896 != nil:
    section.add "DefaultOnly", valid_601896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601897: Call_PostDescribeDBEngineVersions_601877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601897.validator(path, query, header, formData, body)
  let scheme = call_601897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601897.url(scheme.get, call_601897.host, call_601897.base,
                         call_601897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601897, url, valid)

proc call*(call_601898: Call_PostDescribeDBEngineVersions_601877;
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
  var query_601899 = newJObject()
  var formData_601900 = newJObject()
  add(formData_601900, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601900, "Engine", newJString(Engine))
  add(formData_601900, "Marker", newJString(Marker))
  add(query_601899, "Action", newJString(Action))
  add(formData_601900, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601900.add "Filters", Filters
  add(formData_601900, "MaxRecords", newJInt(MaxRecords))
  add(formData_601900, "EngineVersion", newJString(EngineVersion))
  add(query_601899, "Version", newJString(Version))
  add(formData_601900, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601898.call(nil, query_601899, nil, formData_601900, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601877(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601878, base: "/",
    url: url_PostDescribeDBEngineVersions_601879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601854 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBEngineVersions_601856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_601855(path: JsonNode; query: JsonNode;
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
  var valid_601857 = query.getOrDefault("Engine")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "Engine", valid_601857
  var valid_601858 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601858 = validateParameter(valid_601858, JBool, required = false, default = nil)
  if valid_601858 != nil:
    section.add "ListSupportedCharacterSets", valid_601858
  var valid_601859 = query.getOrDefault("MaxRecords")
  valid_601859 = validateParameter(valid_601859, JInt, required = false, default = nil)
  if valid_601859 != nil:
    section.add "MaxRecords", valid_601859
  var valid_601860 = query.getOrDefault("DBParameterGroupFamily")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "DBParameterGroupFamily", valid_601860
  var valid_601861 = query.getOrDefault("Filters")
  valid_601861 = validateParameter(valid_601861, JArray, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "Filters", valid_601861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601862 = query.getOrDefault("Action")
  valid_601862 = validateParameter(valid_601862, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601862 != nil:
    section.add "Action", valid_601862
  var valid_601863 = query.getOrDefault("Marker")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "Marker", valid_601863
  var valid_601864 = query.getOrDefault("EngineVersion")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "EngineVersion", valid_601864
  var valid_601865 = query.getOrDefault("DefaultOnly")
  valid_601865 = validateParameter(valid_601865, JBool, required = false, default = nil)
  if valid_601865 != nil:
    section.add "DefaultOnly", valid_601865
  var valid_601866 = query.getOrDefault("Version")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601866 != nil:
    section.add "Version", valid_601866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601867 = header.getOrDefault("X-Amz-Date")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Date", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Security-Token")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Security-Token", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Content-Sha256", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Algorithm")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Algorithm", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Signature")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Signature", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-SignedHeaders", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Credential")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Credential", valid_601873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_GetDescribeDBEngineVersions_601854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601874, url, valid)

proc call*(call_601875: Call_GetDescribeDBEngineVersions_601854;
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
  var query_601876 = newJObject()
  add(query_601876, "Engine", newJString(Engine))
  add(query_601876, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601876, "MaxRecords", newJInt(MaxRecords))
  add(query_601876, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601876.add "Filters", Filters
  add(query_601876, "Action", newJString(Action))
  add(query_601876, "Marker", newJString(Marker))
  add(query_601876, "EngineVersion", newJString(EngineVersion))
  add(query_601876, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601876, "Version", newJString(Version))
  result = call_601875.call(nil, query_601876, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601854(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601855, base: "/",
    url: url_GetDescribeDBEngineVersions_601856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601920 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBInstances_601922(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_601921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601923 = query.getOrDefault("Action")
  valid_601923 = validateParameter(valid_601923, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601923 != nil:
    section.add "Action", valid_601923
  var valid_601924 = query.getOrDefault("Version")
  valid_601924 = validateParameter(valid_601924, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601924 != nil:
    section.add "Version", valid_601924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601925 = header.getOrDefault("X-Amz-Date")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Date", valid_601925
  var valid_601926 = header.getOrDefault("X-Amz-Security-Token")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-Security-Token", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Content-Sha256", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-Algorithm")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Algorithm", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Signature")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Signature", valid_601929
  var valid_601930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-SignedHeaders", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Credential")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Credential", valid_601931
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601932 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "DBInstanceIdentifier", valid_601932
  var valid_601933 = formData.getOrDefault("Marker")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "Marker", valid_601933
  var valid_601934 = formData.getOrDefault("Filters")
  valid_601934 = validateParameter(valid_601934, JArray, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "Filters", valid_601934
  var valid_601935 = formData.getOrDefault("MaxRecords")
  valid_601935 = validateParameter(valid_601935, JInt, required = false, default = nil)
  if valid_601935 != nil:
    section.add "MaxRecords", valid_601935
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601936: Call_PostDescribeDBInstances_601920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601936.validator(path, query, header, formData, body)
  let scheme = call_601936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601936.url(scheme.get, call_601936.host, call_601936.base,
                         call_601936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601936, url, valid)

proc call*(call_601937: Call_PostDescribeDBInstances_601920;
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
  var query_601938 = newJObject()
  var formData_601939 = newJObject()
  add(formData_601939, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601939, "Marker", newJString(Marker))
  add(query_601938, "Action", newJString(Action))
  if Filters != nil:
    formData_601939.add "Filters", Filters
  add(formData_601939, "MaxRecords", newJInt(MaxRecords))
  add(query_601938, "Version", newJString(Version))
  result = call_601937.call(nil, query_601938, nil, formData_601939, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601920(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601921, base: "/",
    url: url_PostDescribeDBInstances_601922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601901 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBInstances_601903(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_601902(path: JsonNode; query: JsonNode;
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
  var valid_601904 = query.getOrDefault("MaxRecords")
  valid_601904 = validateParameter(valid_601904, JInt, required = false, default = nil)
  if valid_601904 != nil:
    section.add "MaxRecords", valid_601904
  var valid_601905 = query.getOrDefault("Filters")
  valid_601905 = validateParameter(valid_601905, JArray, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "Filters", valid_601905
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601906 = query.getOrDefault("Action")
  valid_601906 = validateParameter(valid_601906, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601906 != nil:
    section.add "Action", valid_601906
  var valid_601907 = query.getOrDefault("Marker")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "Marker", valid_601907
  var valid_601908 = query.getOrDefault("Version")
  valid_601908 = validateParameter(valid_601908, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601908 != nil:
    section.add "Version", valid_601908
  var valid_601909 = query.getOrDefault("DBInstanceIdentifier")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "DBInstanceIdentifier", valid_601909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601910 = header.getOrDefault("X-Amz-Date")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Date", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Security-Token")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Security-Token", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Content-Sha256", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Algorithm")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Algorithm", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Signature")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Signature", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-SignedHeaders", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Credential")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Credential", valid_601916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601917: Call_GetDescribeDBInstances_601901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601917.validator(path, query, header, formData, body)
  let scheme = call_601917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601917.url(scheme.get, call_601917.host, call_601917.base,
                         call_601917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601917, url, valid)

proc call*(call_601918: Call_GetDescribeDBInstances_601901; MaxRecords: int = 0;
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
  var query_601919 = newJObject()
  add(query_601919, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601919.add "Filters", Filters
  add(query_601919, "Action", newJString(Action))
  add(query_601919, "Marker", newJString(Marker))
  add(query_601919, "Version", newJString(Version))
  add(query_601919, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601918.call(nil, query_601919, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601901(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601902, base: "/",
    url: url_GetDescribeDBInstances_601903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_601962 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBLogFiles_601964(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_601963(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601965 = query.getOrDefault("Action")
  valid_601965 = validateParameter(valid_601965, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601965 != nil:
    section.add "Action", valid_601965
  var valid_601966 = query.getOrDefault("Version")
  valid_601966 = validateParameter(valid_601966, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601966 != nil:
    section.add "Version", valid_601966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601967 = header.getOrDefault("X-Amz-Date")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Date", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Security-Token")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Security-Token", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Content-Sha256", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Algorithm")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Algorithm", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Signature")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Signature", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-SignedHeaders", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Credential")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Credential", valid_601973
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
  var valid_601974 = formData.getOrDefault("FilenameContains")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "FilenameContains", valid_601974
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601975 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601975 = validateParameter(valid_601975, JString, required = true,
                                 default = nil)
  if valid_601975 != nil:
    section.add "DBInstanceIdentifier", valid_601975
  var valid_601976 = formData.getOrDefault("FileSize")
  valid_601976 = validateParameter(valid_601976, JInt, required = false, default = nil)
  if valid_601976 != nil:
    section.add "FileSize", valid_601976
  var valid_601977 = formData.getOrDefault("Marker")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "Marker", valid_601977
  var valid_601978 = formData.getOrDefault("Filters")
  valid_601978 = validateParameter(valid_601978, JArray, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "Filters", valid_601978
  var valid_601979 = formData.getOrDefault("MaxRecords")
  valid_601979 = validateParameter(valid_601979, JInt, required = false, default = nil)
  if valid_601979 != nil:
    section.add "MaxRecords", valid_601979
  var valid_601980 = formData.getOrDefault("FileLastWritten")
  valid_601980 = validateParameter(valid_601980, JInt, required = false, default = nil)
  if valid_601980 != nil:
    section.add "FileLastWritten", valid_601980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601981: Call_PostDescribeDBLogFiles_601962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601981.validator(path, query, header, formData, body)
  let scheme = call_601981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601981.url(scheme.get, call_601981.host, call_601981.base,
                         call_601981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601981, url, valid)

proc call*(call_601982: Call_PostDescribeDBLogFiles_601962;
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
  var query_601983 = newJObject()
  var formData_601984 = newJObject()
  add(formData_601984, "FilenameContains", newJString(FilenameContains))
  add(formData_601984, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601984, "FileSize", newJInt(FileSize))
  add(formData_601984, "Marker", newJString(Marker))
  add(query_601983, "Action", newJString(Action))
  if Filters != nil:
    formData_601984.add "Filters", Filters
  add(formData_601984, "MaxRecords", newJInt(MaxRecords))
  add(formData_601984, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601983, "Version", newJString(Version))
  result = call_601982.call(nil, query_601983, nil, formData_601984, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601962(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601963, base: "/",
    url: url_PostDescribeDBLogFiles_601964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601940 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBLogFiles_601942(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_601941(path: JsonNode; query: JsonNode;
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
  var valid_601943 = query.getOrDefault("FileLastWritten")
  valid_601943 = validateParameter(valid_601943, JInt, required = false, default = nil)
  if valid_601943 != nil:
    section.add "FileLastWritten", valid_601943
  var valid_601944 = query.getOrDefault("MaxRecords")
  valid_601944 = validateParameter(valid_601944, JInt, required = false, default = nil)
  if valid_601944 != nil:
    section.add "MaxRecords", valid_601944
  var valid_601945 = query.getOrDefault("FilenameContains")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "FilenameContains", valid_601945
  var valid_601946 = query.getOrDefault("FileSize")
  valid_601946 = validateParameter(valid_601946, JInt, required = false, default = nil)
  if valid_601946 != nil:
    section.add "FileSize", valid_601946
  var valid_601947 = query.getOrDefault("Filters")
  valid_601947 = validateParameter(valid_601947, JArray, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "Filters", valid_601947
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601948 = query.getOrDefault("Action")
  valid_601948 = validateParameter(valid_601948, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601948 != nil:
    section.add "Action", valid_601948
  var valid_601949 = query.getOrDefault("Marker")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "Marker", valid_601949
  var valid_601950 = query.getOrDefault("Version")
  valid_601950 = validateParameter(valid_601950, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601950 != nil:
    section.add "Version", valid_601950
  var valid_601951 = query.getOrDefault("DBInstanceIdentifier")
  valid_601951 = validateParameter(valid_601951, JString, required = true,
                                 default = nil)
  if valid_601951 != nil:
    section.add "DBInstanceIdentifier", valid_601951
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601952 = header.getOrDefault("X-Amz-Date")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Date", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Security-Token")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Security-Token", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Content-Sha256", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Algorithm")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Algorithm", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Signature")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Signature", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-SignedHeaders", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Credential")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Credential", valid_601958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601959: Call_GetDescribeDBLogFiles_601940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601959.validator(path, query, header, formData, body)
  let scheme = call_601959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601959.url(scheme.get, call_601959.host, call_601959.base,
                         call_601959.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601959, url, valid)

proc call*(call_601960: Call_GetDescribeDBLogFiles_601940;
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
  var query_601961 = newJObject()
  add(query_601961, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601961, "MaxRecords", newJInt(MaxRecords))
  add(query_601961, "FilenameContains", newJString(FilenameContains))
  add(query_601961, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_601961.add "Filters", Filters
  add(query_601961, "Action", newJString(Action))
  add(query_601961, "Marker", newJString(Marker))
  add(query_601961, "Version", newJString(Version))
  add(query_601961, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601960.call(nil, query_601961, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601940(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601941, base: "/",
    url: url_GetDescribeDBLogFiles_601942, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_602004 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameterGroups_602006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_602005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602007 = query.getOrDefault("Action")
  valid_602007 = validateParameter(valid_602007, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602007 != nil:
    section.add "Action", valid_602007
  var valid_602008 = query.getOrDefault("Version")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602008 != nil:
    section.add "Version", valid_602008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Content-Sha256", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Credential")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Credential", valid_602015
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602016 = formData.getOrDefault("DBParameterGroupName")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "DBParameterGroupName", valid_602016
  var valid_602017 = formData.getOrDefault("Marker")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "Marker", valid_602017
  var valid_602018 = formData.getOrDefault("Filters")
  valid_602018 = validateParameter(valid_602018, JArray, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "Filters", valid_602018
  var valid_602019 = formData.getOrDefault("MaxRecords")
  valid_602019 = validateParameter(valid_602019, JInt, required = false, default = nil)
  if valid_602019 != nil:
    section.add "MaxRecords", valid_602019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602020: Call_PostDescribeDBParameterGroups_602004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602020.validator(path, query, header, formData, body)
  let scheme = call_602020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602020.url(scheme.get, call_602020.host, call_602020.base,
                         call_602020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602020, url, valid)

proc call*(call_602021: Call_PostDescribeDBParameterGroups_602004;
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
  var query_602022 = newJObject()
  var formData_602023 = newJObject()
  add(formData_602023, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602023, "Marker", newJString(Marker))
  add(query_602022, "Action", newJString(Action))
  if Filters != nil:
    formData_602023.add "Filters", Filters
  add(formData_602023, "MaxRecords", newJInt(MaxRecords))
  add(query_602022, "Version", newJString(Version))
  result = call_602021.call(nil, query_602022, nil, formData_602023, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_602004(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_602005, base: "/",
    url: url_PostDescribeDBParameterGroups_602006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601985 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameterGroups_601987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_601986(path: JsonNode; query: JsonNode;
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
  var valid_601988 = query.getOrDefault("MaxRecords")
  valid_601988 = validateParameter(valid_601988, JInt, required = false, default = nil)
  if valid_601988 != nil:
    section.add "MaxRecords", valid_601988
  var valid_601989 = query.getOrDefault("Filters")
  valid_601989 = validateParameter(valid_601989, JArray, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "Filters", valid_601989
  var valid_601990 = query.getOrDefault("DBParameterGroupName")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "DBParameterGroupName", valid_601990
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601991 = query.getOrDefault("Action")
  valid_601991 = validateParameter(valid_601991, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601991 != nil:
    section.add "Action", valid_601991
  var valid_601992 = query.getOrDefault("Marker")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "Marker", valid_601992
  var valid_601993 = query.getOrDefault("Version")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601993 != nil:
    section.add "Version", valid_601993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601994 = header.getOrDefault("X-Amz-Date")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Date", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Content-Sha256", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Algorithm")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Algorithm", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Signature")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Signature", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-SignedHeaders", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602001: Call_GetDescribeDBParameterGroups_601985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602001.validator(path, query, header, formData, body)
  let scheme = call_602001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602001.url(scheme.get, call_602001.host, call_602001.base,
                         call_602001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602001, url, valid)

proc call*(call_602002: Call_GetDescribeDBParameterGroups_601985;
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
  var query_602003 = newJObject()
  add(query_602003, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602003.add "Filters", Filters
  add(query_602003, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602003, "Action", newJString(Action))
  add(query_602003, "Marker", newJString(Marker))
  add(query_602003, "Version", newJString(Version))
  result = call_602002.call(nil, query_602003, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601985(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601986, base: "/",
    url: url_GetDescribeDBParameterGroups_601987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602044 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameters_602046(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_602045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602047 = query.getOrDefault("Action")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602047 != nil:
    section.add "Action", valid_602047
  var valid_602048 = query.getOrDefault("Version")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602048 != nil:
    section.add "Version", valid_602048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602049 = header.getOrDefault("X-Amz-Date")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Date", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Content-Sha256", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Signature")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Signature", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-SignedHeaders", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Credential")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Credential", valid_602055
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602056 = formData.getOrDefault("DBParameterGroupName")
  valid_602056 = validateParameter(valid_602056, JString, required = true,
                                 default = nil)
  if valid_602056 != nil:
    section.add "DBParameterGroupName", valid_602056
  var valid_602057 = formData.getOrDefault("Marker")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "Marker", valid_602057
  var valid_602058 = formData.getOrDefault("Filters")
  valid_602058 = validateParameter(valid_602058, JArray, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "Filters", valid_602058
  var valid_602059 = formData.getOrDefault("MaxRecords")
  valid_602059 = validateParameter(valid_602059, JInt, required = false, default = nil)
  if valid_602059 != nil:
    section.add "MaxRecords", valid_602059
  var valid_602060 = formData.getOrDefault("Source")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "Source", valid_602060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602061: Call_PostDescribeDBParameters_602044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602061.validator(path, query, header, formData, body)
  let scheme = call_602061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602061.url(scheme.get, call_602061.host, call_602061.base,
                         call_602061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602061, url, valid)

proc call*(call_602062: Call_PostDescribeDBParameters_602044;
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
  var query_602063 = newJObject()
  var formData_602064 = newJObject()
  add(formData_602064, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602064, "Marker", newJString(Marker))
  add(query_602063, "Action", newJString(Action))
  if Filters != nil:
    formData_602064.add "Filters", Filters
  add(formData_602064, "MaxRecords", newJInt(MaxRecords))
  add(query_602063, "Version", newJString(Version))
  add(formData_602064, "Source", newJString(Source))
  result = call_602062.call(nil, query_602063, nil, formData_602064, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602044(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602045, base: "/",
    url: url_PostDescribeDBParameters_602046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602024 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameters_602026(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_602025(path: JsonNode; query: JsonNode;
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
  var valid_602027 = query.getOrDefault("MaxRecords")
  valid_602027 = validateParameter(valid_602027, JInt, required = false, default = nil)
  if valid_602027 != nil:
    section.add "MaxRecords", valid_602027
  var valid_602028 = query.getOrDefault("Filters")
  valid_602028 = validateParameter(valid_602028, JArray, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "Filters", valid_602028
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602029 = query.getOrDefault("DBParameterGroupName")
  valid_602029 = validateParameter(valid_602029, JString, required = true,
                                 default = nil)
  if valid_602029 != nil:
    section.add "DBParameterGroupName", valid_602029
  var valid_602030 = query.getOrDefault("Action")
  valid_602030 = validateParameter(valid_602030, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602030 != nil:
    section.add "Action", valid_602030
  var valid_602031 = query.getOrDefault("Marker")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "Marker", valid_602031
  var valid_602032 = query.getOrDefault("Source")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "Source", valid_602032
  var valid_602033 = query.getOrDefault("Version")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602033 != nil:
    section.add "Version", valid_602033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602034 = header.getOrDefault("X-Amz-Date")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Date", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Content-Sha256", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Signature")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Signature", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Credential")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Credential", valid_602040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602041: Call_GetDescribeDBParameters_602024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602041.validator(path, query, header, formData, body)
  let scheme = call_602041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602041.url(scheme.get, call_602041.host, call_602041.base,
                         call_602041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602041, url, valid)

proc call*(call_602042: Call_GetDescribeDBParameters_602024;
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
  var query_602043 = newJObject()
  add(query_602043, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602043.add "Filters", Filters
  add(query_602043, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602043, "Action", newJString(Action))
  add(query_602043, "Marker", newJString(Marker))
  add(query_602043, "Source", newJString(Source))
  add(query_602043, "Version", newJString(Version))
  result = call_602042.call(nil, query_602043, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602024(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602025, base: "/",
    url: url_GetDescribeDBParameters_602026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_602084 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSecurityGroups_602086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_602085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602087 = query.getOrDefault("Action")
  valid_602087 = validateParameter(valid_602087, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602087 != nil:
    section.add "Action", valid_602087
  var valid_602088 = query.getOrDefault("Version")
  valid_602088 = validateParameter(valid_602088, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602088 != nil:
    section.add "Version", valid_602088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602089 = header.getOrDefault("X-Amz-Date")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Date", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Security-Token")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Security-Token", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Algorithm")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Algorithm", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Signature")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Signature", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-SignedHeaders", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Credential")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Credential", valid_602095
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602096 = formData.getOrDefault("DBSecurityGroupName")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "DBSecurityGroupName", valid_602096
  var valid_602097 = formData.getOrDefault("Marker")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "Marker", valid_602097
  var valid_602098 = formData.getOrDefault("Filters")
  valid_602098 = validateParameter(valid_602098, JArray, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "Filters", valid_602098
  var valid_602099 = formData.getOrDefault("MaxRecords")
  valid_602099 = validateParameter(valid_602099, JInt, required = false, default = nil)
  if valid_602099 != nil:
    section.add "MaxRecords", valid_602099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_PostDescribeDBSecurityGroups_602084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602100, url, valid)

proc call*(call_602101: Call_PostDescribeDBSecurityGroups_602084;
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
  var query_602102 = newJObject()
  var formData_602103 = newJObject()
  add(formData_602103, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602103, "Marker", newJString(Marker))
  add(query_602102, "Action", newJString(Action))
  if Filters != nil:
    formData_602103.add "Filters", Filters
  add(formData_602103, "MaxRecords", newJInt(MaxRecords))
  add(query_602102, "Version", newJString(Version))
  result = call_602101.call(nil, query_602102, nil, formData_602103, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_602084(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_602085, base: "/",
    url: url_PostDescribeDBSecurityGroups_602086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_602065 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSecurityGroups_602067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_602066(path: JsonNode; query: JsonNode;
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
  var valid_602068 = query.getOrDefault("MaxRecords")
  valid_602068 = validateParameter(valid_602068, JInt, required = false, default = nil)
  if valid_602068 != nil:
    section.add "MaxRecords", valid_602068
  var valid_602069 = query.getOrDefault("DBSecurityGroupName")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "DBSecurityGroupName", valid_602069
  var valid_602070 = query.getOrDefault("Filters")
  valid_602070 = validateParameter(valid_602070, JArray, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "Filters", valid_602070
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602071 = query.getOrDefault("Action")
  valid_602071 = validateParameter(valid_602071, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602071 != nil:
    section.add "Action", valid_602071
  var valid_602072 = query.getOrDefault("Marker")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "Marker", valid_602072
  var valid_602073 = query.getOrDefault("Version")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602073 != nil:
    section.add "Version", valid_602073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602074 = header.getOrDefault("X-Amz-Date")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Date", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Security-Token")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Security-Token", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Algorithm")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Algorithm", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Signature")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Signature", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-SignedHeaders", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Credential")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Credential", valid_602080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_GetDescribeDBSecurityGroups_602065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602081, url, valid)

proc call*(call_602082: Call_GetDescribeDBSecurityGroups_602065;
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
  var query_602083 = newJObject()
  add(query_602083, "MaxRecords", newJInt(MaxRecords))
  add(query_602083, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_602083.add "Filters", Filters
  add(query_602083, "Action", newJString(Action))
  add(query_602083, "Marker", newJString(Marker))
  add(query_602083, "Version", newJString(Version))
  result = call_602082.call(nil, query_602083, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_602065(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_602066, base: "/",
    url: url_GetDescribeDBSecurityGroups_602067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602125 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSnapshots_602127(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_602126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602128 = query.getOrDefault("Action")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602128 != nil:
    section.add "Action", valid_602128
  var valid_602129 = query.getOrDefault("Version")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602129 != nil:
    section.add "Version", valid_602129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602130 = header.getOrDefault("X-Amz-Date")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Date", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Algorithm")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Algorithm", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-SignedHeaders", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Credential")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Credential", valid_602136
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602137 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "DBInstanceIdentifier", valid_602137
  var valid_602138 = formData.getOrDefault("SnapshotType")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "SnapshotType", valid_602138
  var valid_602139 = formData.getOrDefault("Marker")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "Marker", valid_602139
  var valid_602140 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "DBSnapshotIdentifier", valid_602140
  var valid_602141 = formData.getOrDefault("Filters")
  valid_602141 = validateParameter(valid_602141, JArray, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "Filters", valid_602141
  var valid_602142 = formData.getOrDefault("MaxRecords")
  valid_602142 = validateParameter(valid_602142, JInt, required = false, default = nil)
  if valid_602142 != nil:
    section.add "MaxRecords", valid_602142
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_PostDescribeDBSnapshots_602125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602143, url, valid)

proc call*(call_602144: Call_PostDescribeDBSnapshots_602125;
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
  var query_602145 = newJObject()
  var formData_602146 = newJObject()
  add(formData_602146, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602146, "SnapshotType", newJString(SnapshotType))
  add(formData_602146, "Marker", newJString(Marker))
  add(formData_602146, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602145, "Action", newJString(Action))
  if Filters != nil:
    formData_602146.add "Filters", Filters
  add(formData_602146, "MaxRecords", newJInt(MaxRecords))
  add(query_602145, "Version", newJString(Version))
  result = call_602144.call(nil, query_602145, nil, formData_602146, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602125(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602126, base: "/",
    url: url_PostDescribeDBSnapshots_602127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602104 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSnapshots_602106(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_602105(path: JsonNode; query: JsonNode;
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
  var valid_602107 = query.getOrDefault("MaxRecords")
  valid_602107 = validateParameter(valid_602107, JInt, required = false, default = nil)
  if valid_602107 != nil:
    section.add "MaxRecords", valid_602107
  var valid_602108 = query.getOrDefault("Filters")
  valid_602108 = validateParameter(valid_602108, JArray, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "Filters", valid_602108
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602109 = query.getOrDefault("Action")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602109 != nil:
    section.add "Action", valid_602109
  var valid_602110 = query.getOrDefault("Marker")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "Marker", valid_602110
  var valid_602111 = query.getOrDefault("SnapshotType")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "SnapshotType", valid_602111
  var valid_602112 = query.getOrDefault("Version")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602112 != nil:
    section.add "Version", valid_602112
  var valid_602113 = query.getOrDefault("DBInstanceIdentifier")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "DBInstanceIdentifier", valid_602113
  var valid_602114 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "DBSnapshotIdentifier", valid_602114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Security-Token")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Security-Token", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Content-Sha256", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-SignedHeaders", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602122: Call_GetDescribeDBSnapshots_602104; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602122.validator(path, query, header, formData, body)
  let scheme = call_602122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602122.url(scheme.get, call_602122.host, call_602122.base,
                         call_602122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602122, url, valid)

proc call*(call_602123: Call_GetDescribeDBSnapshots_602104; MaxRecords: int = 0;
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
  var query_602124 = newJObject()
  add(query_602124, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602124.add "Filters", Filters
  add(query_602124, "Action", newJString(Action))
  add(query_602124, "Marker", newJString(Marker))
  add(query_602124, "SnapshotType", newJString(SnapshotType))
  add(query_602124, "Version", newJString(Version))
  add(query_602124, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602124, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602123.call(nil, query_602124, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602104(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602105, base: "/",
    url: url_GetDescribeDBSnapshots_602106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602166 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSubnetGroups_602168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_602167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602169 = query.getOrDefault("Action")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602169 != nil:
    section.add "Action", valid_602169
  var valid_602170 = query.getOrDefault("Version")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602170 != nil:
    section.add "Version", valid_602170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602171 = header.getOrDefault("X-Amz-Date")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Date", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Security-Token")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Security-Token", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Content-Sha256", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Algorithm")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Algorithm", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Signature")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Signature", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-SignedHeaders", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602178 = formData.getOrDefault("DBSubnetGroupName")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "DBSubnetGroupName", valid_602178
  var valid_602179 = formData.getOrDefault("Marker")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "Marker", valid_602179
  var valid_602180 = formData.getOrDefault("Filters")
  valid_602180 = validateParameter(valid_602180, JArray, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Filters", valid_602180
  var valid_602181 = formData.getOrDefault("MaxRecords")
  valid_602181 = validateParameter(valid_602181, JInt, required = false, default = nil)
  if valid_602181 != nil:
    section.add "MaxRecords", valid_602181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_PostDescribeDBSubnetGroups_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602182, url, valid)

proc call*(call_602183: Call_PostDescribeDBSubnetGroups_602166;
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
  var query_602184 = newJObject()
  var formData_602185 = newJObject()
  add(formData_602185, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602185, "Marker", newJString(Marker))
  add(query_602184, "Action", newJString(Action))
  if Filters != nil:
    formData_602185.add "Filters", Filters
  add(formData_602185, "MaxRecords", newJInt(MaxRecords))
  add(query_602184, "Version", newJString(Version))
  result = call_602183.call(nil, query_602184, nil, formData_602185, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602166(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602167, base: "/",
    url: url_PostDescribeDBSubnetGroups_602168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602147 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSubnetGroups_602149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_602148(path: JsonNode; query: JsonNode;
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
  var valid_602150 = query.getOrDefault("MaxRecords")
  valid_602150 = validateParameter(valid_602150, JInt, required = false, default = nil)
  if valid_602150 != nil:
    section.add "MaxRecords", valid_602150
  var valid_602151 = query.getOrDefault("Filters")
  valid_602151 = validateParameter(valid_602151, JArray, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "Filters", valid_602151
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602152 = query.getOrDefault("Action")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602152 != nil:
    section.add "Action", valid_602152
  var valid_602153 = query.getOrDefault("Marker")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "Marker", valid_602153
  var valid_602154 = query.getOrDefault("DBSubnetGroupName")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "DBSubnetGroupName", valid_602154
  var valid_602155 = query.getOrDefault("Version")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602155 != nil:
    section.add "Version", valid_602155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Signature")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Signature", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Credential")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Credential", valid_602162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602163: Call_GetDescribeDBSubnetGroups_602147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602163.validator(path, query, header, formData, body)
  let scheme = call_602163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602163.url(scheme.get, call_602163.host, call_602163.base,
                         call_602163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602163, url, valid)

proc call*(call_602164: Call_GetDescribeDBSubnetGroups_602147; MaxRecords: int = 0;
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
  var query_602165 = newJObject()
  add(query_602165, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602165.add "Filters", Filters
  add(query_602165, "Action", newJString(Action))
  add(query_602165, "Marker", newJString(Marker))
  add(query_602165, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602165, "Version", newJString(Version))
  result = call_602164.call(nil, query_602165, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602147(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602148, base: "/",
    url: url_GetDescribeDBSubnetGroups_602149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602205 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEngineDefaultParameters_602207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_602206(path: JsonNode;
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
  var valid_602208 = query.getOrDefault("Action")
  valid_602208 = validateParameter(valid_602208, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602208 != nil:
    section.add "Action", valid_602208
  var valid_602209 = query.getOrDefault("Version")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602209 != nil:
    section.add "Version", valid_602209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602210 = header.getOrDefault("X-Amz-Date")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Date", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Security-Token")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Security-Token", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Algorithm")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Algorithm", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Signature")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Signature", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-SignedHeaders", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Credential")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Credential", valid_602216
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602217 = formData.getOrDefault("Marker")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "Marker", valid_602217
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602218 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = nil)
  if valid_602218 != nil:
    section.add "DBParameterGroupFamily", valid_602218
  var valid_602219 = formData.getOrDefault("Filters")
  valid_602219 = validateParameter(valid_602219, JArray, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "Filters", valid_602219
  var valid_602220 = formData.getOrDefault("MaxRecords")
  valid_602220 = validateParameter(valid_602220, JInt, required = false, default = nil)
  if valid_602220 != nil:
    section.add "MaxRecords", valid_602220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602221: Call_PostDescribeEngineDefaultParameters_602205;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602221.validator(path, query, header, formData, body)
  let scheme = call_602221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602221.url(scheme.get, call_602221.host, call_602221.base,
                         call_602221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602221, url, valid)

proc call*(call_602222: Call_PostDescribeEngineDefaultParameters_602205;
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
  var query_602223 = newJObject()
  var formData_602224 = newJObject()
  add(formData_602224, "Marker", newJString(Marker))
  add(query_602223, "Action", newJString(Action))
  add(formData_602224, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_602224.add "Filters", Filters
  add(formData_602224, "MaxRecords", newJInt(MaxRecords))
  add(query_602223, "Version", newJString(Version))
  result = call_602222.call(nil, query_602223, nil, formData_602224, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602205(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602206, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602186 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEngineDefaultParameters_602188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_602187(path: JsonNode;
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
  var valid_602189 = query.getOrDefault("MaxRecords")
  valid_602189 = validateParameter(valid_602189, JInt, required = false, default = nil)
  if valid_602189 != nil:
    section.add "MaxRecords", valid_602189
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602190 = query.getOrDefault("DBParameterGroupFamily")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "DBParameterGroupFamily", valid_602190
  var valid_602191 = query.getOrDefault("Filters")
  valid_602191 = validateParameter(valid_602191, JArray, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "Filters", valid_602191
  var valid_602192 = query.getOrDefault("Action")
  valid_602192 = validateParameter(valid_602192, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602192 != nil:
    section.add "Action", valid_602192
  var valid_602193 = query.getOrDefault("Marker")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "Marker", valid_602193
  var valid_602194 = query.getOrDefault("Version")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602194 != nil:
    section.add "Version", valid_602194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602195 = header.getOrDefault("X-Amz-Date")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Date", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Security-Token")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Security-Token", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Content-Sha256", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Signature")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Signature", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Credential")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Credential", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_GetDescribeEngineDefaultParameters_602186;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602202, url, valid)

proc call*(call_602203: Call_GetDescribeEngineDefaultParameters_602186;
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
  var query_602204 = newJObject()
  add(query_602204, "MaxRecords", newJInt(MaxRecords))
  add(query_602204, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_602204.add "Filters", Filters
  add(query_602204, "Action", newJString(Action))
  add(query_602204, "Marker", newJString(Marker))
  add(query_602204, "Version", newJString(Version))
  result = call_602203.call(nil, query_602204, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602186(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602187, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602242 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventCategories_602244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_602243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602245 = query.getOrDefault("Action")
  valid_602245 = validateParameter(valid_602245, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602245 != nil:
    section.add "Action", valid_602245
  var valid_602246 = query.getOrDefault("Version")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602246 != nil:
    section.add "Version", valid_602246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Security-Token")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Security-Token", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Content-Sha256", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Signature")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Signature", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-SignedHeaders", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_602254 = formData.getOrDefault("Filters")
  valid_602254 = validateParameter(valid_602254, JArray, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "Filters", valid_602254
  var valid_602255 = formData.getOrDefault("SourceType")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "SourceType", valid_602255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602256: Call_PostDescribeEventCategories_602242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602256.validator(path, query, header, formData, body)
  let scheme = call_602256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602256.url(scheme.get, call_602256.host, call_602256.base,
                         call_602256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602256, url, valid)

proc call*(call_602257: Call_PostDescribeEventCategories_602242;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_602258 = newJObject()
  var formData_602259 = newJObject()
  add(query_602258, "Action", newJString(Action))
  if Filters != nil:
    formData_602259.add "Filters", Filters
  add(query_602258, "Version", newJString(Version))
  add(formData_602259, "SourceType", newJString(SourceType))
  result = call_602257.call(nil, query_602258, nil, formData_602259, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602242(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602243, base: "/",
    url: url_PostDescribeEventCategories_602244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602225 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventCategories_602227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_602226(path: JsonNode; query: JsonNode;
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
  var valid_602228 = query.getOrDefault("SourceType")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "SourceType", valid_602228
  var valid_602229 = query.getOrDefault("Filters")
  valid_602229 = validateParameter(valid_602229, JArray, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "Filters", valid_602229
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602230 = query.getOrDefault("Action")
  valid_602230 = validateParameter(valid_602230, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602230 != nil:
    section.add "Action", valid_602230
  var valid_602231 = query.getOrDefault("Version")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602231 != nil:
    section.add "Version", valid_602231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602232 = header.getOrDefault("X-Amz-Date")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Date", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Security-Token")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Security-Token", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Algorithm")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Algorithm", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Signature")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Signature", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602239: Call_GetDescribeEventCategories_602225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602239.validator(path, query, header, formData, body)
  let scheme = call_602239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602239.url(scheme.get, call_602239.host, call_602239.base,
                         call_602239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602239, url, valid)

proc call*(call_602240: Call_GetDescribeEventCategories_602225;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602241 = newJObject()
  add(query_602241, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_602241.add "Filters", Filters
  add(query_602241, "Action", newJString(Action))
  add(query_602241, "Version", newJString(Version))
  result = call_602240.call(nil, query_602241, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602225(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602226, base: "/",
    url: url_GetDescribeEventCategories_602227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602279 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventSubscriptions_602281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_602280(path: JsonNode;
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
  var valid_602282 = query.getOrDefault("Action")
  valid_602282 = validateParameter(valid_602282, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602282 != nil:
    section.add "Action", valid_602282
  var valid_602283 = query.getOrDefault("Version")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602283 != nil:
    section.add "Version", valid_602283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602284 = header.getOrDefault("X-Amz-Date")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Date", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Security-Token")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Security-Token", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Algorithm")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Algorithm", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Signature")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Signature", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Credential")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Credential", valid_602290
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602291 = formData.getOrDefault("Marker")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "Marker", valid_602291
  var valid_602292 = formData.getOrDefault("SubscriptionName")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "SubscriptionName", valid_602292
  var valid_602293 = formData.getOrDefault("Filters")
  valid_602293 = validateParameter(valid_602293, JArray, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "Filters", valid_602293
  var valid_602294 = formData.getOrDefault("MaxRecords")
  valid_602294 = validateParameter(valid_602294, JInt, required = false, default = nil)
  if valid_602294 != nil:
    section.add "MaxRecords", valid_602294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602295: Call_PostDescribeEventSubscriptions_602279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602295.validator(path, query, header, formData, body)
  let scheme = call_602295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602295.url(scheme.get, call_602295.host, call_602295.base,
                         call_602295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602295, url, valid)

proc call*(call_602296: Call_PostDescribeEventSubscriptions_602279;
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
  var query_602297 = newJObject()
  var formData_602298 = newJObject()
  add(formData_602298, "Marker", newJString(Marker))
  add(formData_602298, "SubscriptionName", newJString(SubscriptionName))
  add(query_602297, "Action", newJString(Action))
  if Filters != nil:
    formData_602298.add "Filters", Filters
  add(formData_602298, "MaxRecords", newJInt(MaxRecords))
  add(query_602297, "Version", newJString(Version))
  result = call_602296.call(nil, query_602297, nil, formData_602298, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602279(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602280, base: "/",
    url: url_PostDescribeEventSubscriptions_602281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602260 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventSubscriptions_602262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_602261(path: JsonNode; query: JsonNode;
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
  var valid_602263 = query.getOrDefault("MaxRecords")
  valid_602263 = validateParameter(valid_602263, JInt, required = false, default = nil)
  if valid_602263 != nil:
    section.add "MaxRecords", valid_602263
  var valid_602264 = query.getOrDefault("Filters")
  valid_602264 = validateParameter(valid_602264, JArray, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "Filters", valid_602264
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602265 = query.getOrDefault("Action")
  valid_602265 = validateParameter(valid_602265, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602265 != nil:
    section.add "Action", valid_602265
  var valid_602266 = query.getOrDefault("Marker")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "Marker", valid_602266
  var valid_602267 = query.getOrDefault("SubscriptionName")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "SubscriptionName", valid_602267
  var valid_602268 = query.getOrDefault("Version")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602268 != nil:
    section.add "Version", valid_602268
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602269 = header.getOrDefault("X-Amz-Date")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Date", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Security-Token")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Security-Token", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Content-Sha256", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Algorithm")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Algorithm", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Signature")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Signature", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_GetDescribeEventSubscriptions_602260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602276, url, valid)

proc call*(call_602277: Call_GetDescribeEventSubscriptions_602260;
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
  var query_602278 = newJObject()
  add(query_602278, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602278.add "Filters", Filters
  add(query_602278, "Action", newJString(Action))
  add(query_602278, "Marker", newJString(Marker))
  add(query_602278, "SubscriptionName", newJString(SubscriptionName))
  add(query_602278, "Version", newJString(Version))
  result = call_602277.call(nil, query_602278, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602260(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602261, base: "/",
    url: url_GetDescribeEventSubscriptions_602262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602323 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEvents_602325(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_602324(path: JsonNode; query: JsonNode;
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
  var valid_602326 = query.getOrDefault("Action")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602326 != nil:
    section.add "Action", valid_602326
  var valid_602327 = query.getOrDefault("Version")
  valid_602327 = validateParameter(valid_602327, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602327 != nil:
    section.add "Version", valid_602327
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602328 = header.getOrDefault("X-Amz-Date")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Date", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Security-Token")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Security-Token", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Content-Sha256", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Algorithm")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Algorithm", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Signature")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Signature", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-SignedHeaders", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
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
  var valid_602335 = formData.getOrDefault("SourceIdentifier")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "SourceIdentifier", valid_602335
  var valid_602336 = formData.getOrDefault("EventCategories")
  valid_602336 = validateParameter(valid_602336, JArray, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "EventCategories", valid_602336
  var valid_602337 = formData.getOrDefault("Marker")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "Marker", valid_602337
  var valid_602338 = formData.getOrDefault("StartTime")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "StartTime", valid_602338
  var valid_602339 = formData.getOrDefault("Duration")
  valid_602339 = validateParameter(valid_602339, JInt, required = false, default = nil)
  if valid_602339 != nil:
    section.add "Duration", valid_602339
  var valid_602340 = formData.getOrDefault("Filters")
  valid_602340 = validateParameter(valid_602340, JArray, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "Filters", valid_602340
  var valid_602341 = formData.getOrDefault("EndTime")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "EndTime", valid_602341
  var valid_602342 = formData.getOrDefault("MaxRecords")
  valid_602342 = validateParameter(valid_602342, JInt, required = false, default = nil)
  if valid_602342 != nil:
    section.add "MaxRecords", valid_602342
  var valid_602343 = formData.getOrDefault("SourceType")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602343 != nil:
    section.add "SourceType", valid_602343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602344: Call_PostDescribeEvents_602323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602344.validator(path, query, header, formData, body)
  let scheme = call_602344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602344.url(scheme.get, call_602344.host, call_602344.base,
                         call_602344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602344, url, valid)

proc call*(call_602345: Call_PostDescribeEvents_602323;
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
  var query_602346 = newJObject()
  var formData_602347 = newJObject()
  add(formData_602347, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602347.add "EventCategories", EventCategories
  add(formData_602347, "Marker", newJString(Marker))
  add(formData_602347, "StartTime", newJString(StartTime))
  add(query_602346, "Action", newJString(Action))
  add(formData_602347, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_602347.add "Filters", Filters
  add(formData_602347, "EndTime", newJString(EndTime))
  add(formData_602347, "MaxRecords", newJInt(MaxRecords))
  add(query_602346, "Version", newJString(Version))
  add(formData_602347, "SourceType", newJString(SourceType))
  result = call_602345.call(nil, query_602346, nil, formData_602347, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602323(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602324, base: "/",
    url: url_PostDescribeEvents_602325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602299 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEvents_602301(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_602300(path: JsonNode; query: JsonNode;
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
  var valid_602302 = query.getOrDefault("SourceType")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602302 != nil:
    section.add "SourceType", valid_602302
  var valid_602303 = query.getOrDefault("MaxRecords")
  valid_602303 = validateParameter(valid_602303, JInt, required = false, default = nil)
  if valid_602303 != nil:
    section.add "MaxRecords", valid_602303
  var valid_602304 = query.getOrDefault("StartTime")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "StartTime", valid_602304
  var valid_602305 = query.getOrDefault("Filters")
  valid_602305 = validateParameter(valid_602305, JArray, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "Filters", valid_602305
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602306 = query.getOrDefault("Action")
  valid_602306 = validateParameter(valid_602306, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602306 != nil:
    section.add "Action", valid_602306
  var valid_602307 = query.getOrDefault("SourceIdentifier")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "SourceIdentifier", valid_602307
  var valid_602308 = query.getOrDefault("Marker")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "Marker", valid_602308
  var valid_602309 = query.getOrDefault("EventCategories")
  valid_602309 = validateParameter(valid_602309, JArray, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "EventCategories", valid_602309
  var valid_602310 = query.getOrDefault("Duration")
  valid_602310 = validateParameter(valid_602310, JInt, required = false, default = nil)
  if valid_602310 != nil:
    section.add "Duration", valid_602310
  var valid_602311 = query.getOrDefault("EndTime")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "EndTime", valid_602311
  var valid_602312 = query.getOrDefault("Version")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602312 != nil:
    section.add "Version", valid_602312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602313 = header.getOrDefault("X-Amz-Date")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Date", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Algorithm")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Algorithm", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Signature")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Signature", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-SignedHeaders", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Credential")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Credential", valid_602319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602320: Call_GetDescribeEvents_602299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602320.validator(path, query, header, formData, body)
  let scheme = call_602320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602320.url(scheme.get, call_602320.host, call_602320.base,
                         call_602320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602320, url, valid)

proc call*(call_602321: Call_GetDescribeEvents_602299;
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
  var query_602322 = newJObject()
  add(query_602322, "SourceType", newJString(SourceType))
  add(query_602322, "MaxRecords", newJInt(MaxRecords))
  add(query_602322, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_602322.add "Filters", Filters
  add(query_602322, "Action", newJString(Action))
  add(query_602322, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602322, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602322.add "EventCategories", EventCategories
  add(query_602322, "Duration", newJInt(Duration))
  add(query_602322, "EndTime", newJString(EndTime))
  add(query_602322, "Version", newJString(Version))
  result = call_602321.call(nil, query_602322, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602299(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602300,
    base: "/", url: url_GetDescribeEvents_602301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602368 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroupOptions_602370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_602369(path: JsonNode;
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
  var valid_602371 = query.getOrDefault("Action")
  valid_602371 = validateParameter(valid_602371, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602371 != nil:
    section.add "Action", valid_602371
  var valid_602372 = query.getOrDefault("Version")
  valid_602372 = validateParameter(valid_602372, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602372 != nil:
    section.add "Version", valid_602372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602373 = header.getOrDefault("X-Amz-Date")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Date", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Security-Token")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Security-Token", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Content-Sha256", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Algorithm")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Algorithm", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Signature")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Signature", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-SignedHeaders", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Credential")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Credential", valid_602379
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602380 = formData.getOrDefault("MajorEngineVersion")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "MajorEngineVersion", valid_602380
  var valid_602381 = formData.getOrDefault("Marker")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "Marker", valid_602381
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602382 = formData.getOrDefault("EngineName")
  valid_602382 = validateParameter(valid_602382, JString, required = true,
                                 default = nil)
  if valid_602382 != nil:
    section.add "EngineName", valid_602382
  var valid_602383 = formData.getOrDefault("Filters")
  valid_602383 = validateParameter(valid_602383, JArray, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "Filters", valid_602383
  var valid_602384 = formData.getOrDefault("MaxRecords")
  valid_602384 = validateParameter(valid_602384, JInt, required = false, default = nil)
  if valid_602384 != nil:
    section.add "MaxRecords", valid_602384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602385: Call_PostDescribeOptionGroupOptions_602368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602385.validator(path, query, header, formData, body)
  let scheme = call_602385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602385.url(scheme.get, call_602385.host, call_602385.base,
                         call_602385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602385, url, valid)

proc call*(call_602386: Call_PostDescribeOptionGroupOptions_602368;
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
  var query_602387 = newJObject()
  var formData_602388 = newJObject()
  add(formData_602388, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602388, "Marker", newJString(Marker))
  add(query_602387, "Action", newJString(Action))
  add(formData_602388, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602388.add "Filters", Filters
  add(formData_602388, "MaxRecords", newJInt(MaxRecords))
  add(query_602387, "Version", newJString(Version))
  result = call_602386.call(nil, query_602387, nil, formData_602388, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602368(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602369, base: "/",
    url: url_PostDescribeOptionGroupOptions_602370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602348 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroupOptions_602350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_602349(path: JsonNode; query: JsonNode;
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
  var valid_602351 = query.getOrDefault("MaxRecords")
  valid_602351 = validateParameter(valid_602351, JInt, required = false, default = nil)
  if valid_602351 != nil:
    section.add "MaxRecords", valid_602351
  var valid_602352 = query.getOrDefault("Filters")
  valid_602352 = validateParameter(valid_602352, JArray, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "Filters", valid_602352
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602353 = query.getOrDefault("Action")
  valid_602353 = validateParameter(valid_602353, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602353 != nil:
    section.add "Action", valid_602353
  var valid_602354 = query.getOrDefault("Marker")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "Marker", valid_602354
  var valid_602355 = query.getOrDefault("Version")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602355 != nil:
    section.add "Version", valid_602355
  var valid_602356 = query.getOrDefault("EngineName")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = nil)
  if valid_602356 != nil:
    section.add "EngineName", valid_602356
  var valid_602357 = query.getOrDefault("MajorEngineVersion")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "MajorEngineVersion", valid_602357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602358 = header.getOrDefault("X-Amz-Date")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Date", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Security-Token")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Security-Token", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Content-Sha256", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Algorithm")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Algorithm", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Signature")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Signature", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-SignedHeaders", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Credential")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Credential", valid_602364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602365: Call_GetDescribeOptionGroupOptions_602348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602365.validator(path, query, header, formData, body)
  let scheme = call_602365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602365.url(scheme.get, call_602365.host, call_602365.base,
                         call_602365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602365, url, valid)

proc call*(call_602366: Call_GetDescribeOptionGroupOptions_602348;
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
  var query_602367 = newJObject()
  add(query_602367, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602367.add "Filters", Filters
  add(query_602367, "Action", newJString(Action))
  add(query_602367, "Marker", newJString(Marker))
  add(query_602367, "Version", newJString(Version))
  add(query_602367, "EngineName", newJString(EngineName))
  add(query_602367, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602366.call(nil, query_602367, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602348(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602349, base: "/",
    url: url_GetDescribeOptionGroupOptions_602350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602410 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroups_602412(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_602411(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602413 = query.getOrDefault("Action")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602413 != nil:
    section.add "Action", valid_602413
  var valid_602414 = query.getOrDefault("Version")
  valid_602414 = validateParameter(valid_602414, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602414 != nil:
    section.add "Version", valid_602414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602415 = header.getOrDefault("X-Amz-Date")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Date", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Content-Sha256", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Algorithm")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Algorithm", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Signature")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Signature", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-SignedHeaders", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Credential")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Credential", valid_602421
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602422 = formData.getOrDefault("MajorEngineVersion")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "MajorEngineVersion", valid_602422
  var valid_602423 = formData.getOrDefault("OptionGroupName")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "OptionGroupName", valid_602423
  var valid_602424 = formData.getOrDefault("Marker")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "Marker", valid_602424
  var valid_602425 = formData.getOrDefault("EngineName")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "EngineName", valid_602425
  var valid_602426 = formData.getOrDefault("Filters")
  valid_602426 = validateParameter(valid_602426, JArray, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "Filters", valid_602426
  var valid_602427 = formData.getOrDefault("MaxRecords")
  valid_602427 = validateParameter(valid_602427, JInt, required = false, default = nil)
  if valid_602427 != nil:
    section.add "MaxRecords", valid_602427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602428: Call_PostDescribeOptionGroups_602410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602428.validator(path, query, header, formData, body)
  let scheme = call_602428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602428.url(scheme.get, call_602428.host, call_602428.base,
                         call_602428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602428, url, valid)

proc call*(call_602429: Call_PostDescribeOptionGroups_602410;
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
  var query_602430 = newJObject()
  var formData_602431 = newJObject()
  add(formData_602431, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602431, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602431, "Marker", newJString(Marker))
  add(query_602430, "Action", newJString(Action))
  add(formData_602431, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602431.add "Filters", Filters
  add(formData_602431, "MaxRecords", newJInt(MaxRecords))
  add(query_602430, "Version", newJString(Version))
  result = call_602429.call(nil, query_602430, nil, formData_602431, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602410(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602411, base: "/",
    url: url_PostDescribeOptionGroups_602412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602389 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroups_602391(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_602390(path: JsonNode; query: JsonNode;
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
  var valid_602392 = query.getOrDefault("MaxRecords")
  valid_602392 = validateParameter(valid_602392, JInt, required = false, default = nil)
  if valid_602392 != nil:
    section.add "MaxRecords", valid_602392
  var valid_602393 = query.getOrDefault("OptionGroupName")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "OptionGroupName", valid_602393
  var valid_602394 = query.getOrDefault("Filters")
  valid_602394 = validateParameter(valid_602394, JArray, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "Filters", valid_602394
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602395 = query.getOrDefault("Action")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602395 != nil:
    section.add "Action", valid_602395
  var valid_602396 = query.getOrDefault("Marker")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "Marker", valid_602396
  var valid_602397 = query.getOrDefault("Version")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602397 != nil:
    section.add "Version", valid_602397
  var valid_602398 = query.getOrDefault("EngineName")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "EngineName", valid_602398
  var valid_602399 = query.getOrDefault("MajorEngineVersion")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "MajorEngineVersion", valid_602399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602400 = header.getOrDefault("X-Amz-Date")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Date", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Content-Sha256", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Algorithm")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Algorithm", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Signature")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Signature", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-SignedHeaders", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Credential")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Credential", valid_602406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602407: Call_GetDescribeOptionGroups_602389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602407.validator(path, query, header, formData, body)
  let scheme = call_602407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602407.url(scheme.get, call_602407.host, call_602407.base,
                         call_602407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602407, url, valid)

proc call*(call_602408: Call_GetDescribeOptionGroups_602389; MaxRecords: int = 0;
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
  var query_602409 = newJObject()
  add(query_602409, "MaxRecords", newJInt(MaxRecords))
  add(query_602409, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_602409.add "Filters", Filters
  add(query_602409, "Action", newJString(Action))
  add(query_602409, "Marker", newJString(Marker))
  add(query_602409, "Version", newJString(Version))
  add(query_602409, "EngineName", newJString(EngineName))
  add(query_602409, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602408.call(nil, query_602409, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602389(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602390, base: "/",
    url: url_GetDescribeOptionGroups_602391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602455 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOrderableDBInstanceOptions_602457(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602456(path: JsonNode;
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
  var valid_602458 = query.getOrDefault("Action")
  valid_602458 = validateParameter(valid_602458, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602458 != nil:
    section.add "Action", valid_602458
  var valid_602459 = query.getOrDefault("Version")
  valid_602459 = validateParameter(valid_602459, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602459 != nil:
    section.add "Version", valid_602459
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602460 = header.getOrDefault("X-Amz-Date")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Date", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Security-Token")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Security-Token", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Content-Sha256", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Algorithm")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Algorithm", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Signature")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Signature", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-SignedHeaders", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Credential")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Credential", valid_602466
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
  var valid_602467 = formData.getOrDefault("Engine")
  valid_602467 = validateParameter(valid_602467, JString, required = true,
                                 default = nil)
  if valid_602467 != nil:
    section.add "Engine", valid_602467
  var valid_602468 = formData.getOrDefault("Marker")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "Marker", valid_602468
  var valid_602469 = formData.getOrDefault("Vpc")
  valid_602469 = validateParameter(valid_602469, JBool, required = false, default = nil)
  if valid_602469 != nil:
    section.add "Vpc", valid_602469
  var valid_602470 = formData.getOrDefault("DBInstanceClass")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "DBInstanceClass", valid_602470
  var valid_602471 = formData.getOrDefault("Filters")
  valid_602471 = validateParameter(valid_602471, JArray, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "Filters", valid_602471
  var valid_602472 = formData.getOrDefault("LicenseModel")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "LicenseModel", valid_602472
  var valid_602473 = formData.getOrDefault("MaxRecords")
  valid_602473 = validateParameter(valid_602473, JInt, required = false, default = nil)
  if valid_602473 != nil:
    section.add "MaxRecords", valid_602473
  var valid_602474 = formData.getOrDefault("EngineVersion")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "EngineVersion", valid_602474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602475: Call_PostDescribeOrderableDBInstanceOptions_602455;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602475.validator(path, query, header, formData, body)
  let scheme = call_602475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602475.url(scheme.get, call_602475.host, call_602475.base,
                         call_602475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602475, url, valid)

proc call*(call_602476: Call_PostDescribeOrderableDBInstanceOptions_602455;
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
  var query_602477 = newJObject()
  var formData_602478 = newJObject()
  add(formData_602478, "Engine", newJString(Engine))
  add(formData_602478, "Marker", newJString(Marker))
  add(query_602477, "Action", newJString(Action))
  add(formData_602478, "Vpc", newJBool(Vpc))
  add(formData_602478, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602478.add "Filters", Filters
  add(formData_602478, "LicenseModel", newJString(LicenseModel))
  add(formData_602478, "MaxRecords", newJInt(MaxRecords))
  add(formData_602478, "EngineVersion", newJString(EngineVersion))
  add(query_602477, "Version", newJString(Version))
  result = call_602476.call(nil, query_602477, nil, formData_602478, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602455(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602456, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602432 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOrderableDBInstanceOptions_602434(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602433(path: JsonNode;
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
  var valid_602435 = query.getOrDefault("Engine")
  valid_602435 = validateParameter(valid_602435, JString, required = true,
                                 default = nil)
  if valid_602435 != nil:
    section.add "Engine", valid_602435
  var valid_602436 = query.getOrDefault("MaxRecords")
  valid_602436 = validateParameter(valid_602436, JInt, required = false, default = nil)
  if valid_602436 != nil:
    section.add "MaxRecords", valid_602436
  var valid_602437 = query.getOrDefault("Filters")
  valid_602437 = validateParameter(valid_602437, JArray, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "Filters", valid_602437
  var valid_602438 = query.getOrDefault("LicenseModel")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "LicenseModel", valid_602438
  var valid_602439 = query.getOrDefault("Vpc")
  valid_602439 = validateParameter(valid_602439, JBool, required = false, default = nil)
  if valid_602439 != nil:
    section.add "Vpc", valid_602439
  var valid_602440 = query.getOrDefault("DBInstanceClass")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "DBInstanceClass", valid_602440
  var valid_602441 = query.getOrDefault("Action")
  valid_602441 = validateParameter(valid_602441, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602441 != nil:
    section.add "Action", valid_602441
  var valid_602442 = query.getOrDefault("Marker")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "Marker", valid_602442
  var valid_602443 = query.getOrDefault("EngineVersion")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "EngineVersion", valid_602443
  var valid_602444 = query.getOrDefault("Version")
  valid_602444 = validateParameter(valid_602444, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602444 != nil:
    section.add "Version", valid_602444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602445 = header.getOrDefault("X-Amz-Date")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Date", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Content-Sha256", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Algorithm")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Algorithm", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Signature")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Signature", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-SignedHeaders", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Credential")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Credential", valid_602451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602452: Call_GetDescribeOrderableDBInstanceOptions_602432;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602452.validator(path, query, header, formData, body)
  let scheme = call_602452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602452.url(scheme.get, call_602452.host, call_602452.base,
                         call_602452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602452, url, valid)

proc call*(call_602453: Call_GetDescribeOrderableDBInstanceOptions_602432;
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
  var query_602454 = newJObject()
  add(query_602454, "Engine", newJString(Engine))
  add(query_602454, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602454.add "Filters", Filters
  add(query_602454, "LicenseModel", newJString(LicenseModel))
  add(query_602454, "Vpc", newJBool(Vpc))
  add(query_602454, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602454, "Action", newJString(Action))
  add(query_602454, "Marker", newJString(Marker))
  add(query_602454, "EngineVersion", newJString(EngineVersion))
  add(query_602454, "Version", newJString(Version))
  result = call_602453.call(nil, query_602454, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602432(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602433, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602504 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstances_602506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_602505(path: JsonNode;
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
  var valid_602507 = query.getOrDefault("Action")
  valid_602507 = validateParameter(valid_602507, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602507 != nil:
    section.add "Action", valid_602507
  var valid_602508 = query.getOrDefault("Version")
  valid_602508 = validateParameter(valid_602508, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602508 != nil:
    section.add "Version", valid_602508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602509 = header.getOrDefault("X-Amz-Date")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Date", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Security-Token")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Security-Token", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Content-Sha256", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Algorithm")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Algorithm", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Signature")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Signature", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-SignedHeaders", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Credential")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Credential", valid_602515
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
  var valid_602516 = formData.getOrDefault("OfferingType")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "OfferingType", valid_602516
  var valid_602517 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "ReservedDBInstanceId", valid_602517
  var valid_602518 = formData.getOrDefault("Marker")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "Marker", valid_602518
  var valid_602519 = formData.getOrDefault("MultiAZ")
  valid_602519 = validateParameter(valid_602519, JBool, required = false, default = nil)
  if valid_602519 != nil:
    section.add "MultiAZ", valid_602519
  var valid_602520 = formData.getOrDefault("Duration")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "Duration", valid_602520
  var valid_602521 = formData.getOrDefault("DBInstanceClass")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "DBInstanceClass", valid_602521
  var valid_602522 = formData.getOrDefault("Filters")
  valid_602522 = validateParameter(valid_602522, JArray, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "Filters", valid_602522
  var valid_602523 = formData.getOrDefault("ProductDescription")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "ProductDescription", valid_602523
  var valid_602524 = formData.getOrDefault("MaxRecords")
  valid_602524 = validateParameter(valid_602524, JInt, required = false, default = nil)
  if valid_602524 != nil:
    section.add "MaxRecords", valid_602524
  var valid_602525 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602526: Call_PostDescribeReservedDBInstances_602504;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602526.validator(path, query, header, formData, body)
  let scheme = call_602526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602526.url(scheme.get, call_602526.host, call_602526.base,
                         call_602526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602526, url, valid)

proc call*(call_602527: Call_PostDescribeReservedDBInstances_602504;
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
  var query_602528 = newJObject()
  var formData_602529 = newJObject()
  add(formData_602529, "OfferingType", newJString(OfferingType))
  add(formData_602529, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602529, "Marker", newJString(Marker))
  add(formData_602529, "MultiAZ", newJBool(MultiAZ))
  add(query_602528, "Action", newJString(Action))
  add(formData_602529, "Duration", newJString(Duration))
  add(formData_602529, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602529.add "Filters", Filters
  add(formData_602529, "ProductDescription", newJString(ProductDescription))
  add(formData_602529, "MaxRecords", newJInt(MaxRecords))
  add(formData_602529, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602528, "Version", newJString(Version))
  result = call_602527.call(nil, query_602528, nil, formData_602529, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602504(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602505, base: "/",
    url: url_PostDescribeReservedDBInstances_602506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602479 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstances_602481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_602480(path: JsonNode;
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
  var valid_602482 = query.getOrDefault("ProductDescription")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "ProductDescription", valid_602482
  var valid_602483 = query.getOrDefault("MaxRecords")
  valid_602483 = validateParameter(valid_602483, JInt, required = false, default = nil)
  if valid_602483 != nil:
    section.add "MaxRecords", valid_602483
  var valid_602484 = query.getOrDefault("OfferingType")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "OfferingType", valid_602484
  var valid_602485 = query.getOrDefault("Filters")
  valid_602485 = validateParameter(valid_602485, JArray, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "Filters", valid_602485
  var valid_602486 = query.getOrDefault("MultiAZ")
  valid_602486 = validateParameter(valid_602486, JBool, required = false, default = nil)
  if valid_602486 != nil:
    section.add "MultiAZ", valid_602486
  var valid_602487 = query.getOrDefault("ReservedDBInstanceId")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "ReservedDBInstanceId", valid_602487
  var valid_602488 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602488
  var valid_602489 = query.getOrDefault("DBInstanceClass")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "DBInstanceClass", valid_602489
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602490 = query.getOrDefault("Action")
  valid_602490 = validateParameter(valid_602490, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602490 != nil:
    section.add "Action", valid_602490
  var valid_602491 = query.getOrDefault("Marker")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "Marker", valid_602491
  var valid_602492 = query.getOrDefault("Duration")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "Duration", valid_602492
  var valid_602493 = query.getOrDefault("Version")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602493 != nil:
    section.add "Version", valid_602493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602494 = header.getOrDefault("X-Amz-Date")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Date", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Security-Token")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Security-Token", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Content-Sha256", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Algorithm")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Algorithm", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Signature")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Signature", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-SignedHeaders", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Credential")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Credential", valid_602500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602501: Call_GetDescribeReservedDBInstances_602479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602501.validator(path, query, header, formData, body)
  let scheme = call_602501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602501.url(scheme.get, call_602501.host, call_602501.base,
                         call_602501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602501, url, valid)

proc call*(call_602502: Call_GetDescribeReservedDBInstances_602479;
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
  var query_602503 = newJObject()
  add(query_602503, "ProductDescription", newJString(ProductDescription))
  add(query_602503, "MaxRecords", newJInt(MaxRecords))
  add(query_602503, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602503.add "Filters", Filters
  add(query_602503, "MultiAZ", newJBool(MultiAZ))
  add(query_602503, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602503, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602503, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602503, "Action", newJString(Action))
  add(query_602503, "Marker", newJString(Marker))
  add(query_602503, "Duration", newJString(Duration))
  add(query_602503, "Version", newJString(Version))
  result = call_602502.call(nil, query_602503, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602479(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602480, base: "/",
    url: url_GetDescribeReservedDBInstances_602481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602554 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstancesOfferings_602556(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602555(path: JsonNode;
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
  var valid_602557 = query.getOrDefault("Action")
  valid_602557 = validateParameter(valid_602557, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602557 != nil:
    section.add "Action", valid_602557
  var valid_602558 = query.getOrDefault("Version")
  valid_602558 = validateParameter(valid_602558, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602558 != nil:
    section.add "Version", valid_602558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602559 = header.getOrDefault("X-Amz-Date")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Date", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Content-Sha256", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Algorithm")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Algorithm", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Signature")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Signature", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-SignedHeaders", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
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
  var valid_602566 = formData.getOrDefault("OfferingType")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "OfferingType", valid_602566
  var valid_602567 = formData.getOrDefault("Marker")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "Marker", valid_602567
  var valid_602568 = formData.getOrDefault("MultiAZ")
  valid_602568 = validateParameter(valid_602568, JBool, required = false, default = nil)
  if valid_602568 != nil:
    section.add "MultiAZ", valid_602568
  var valid_602569 = formData.getOrDefault("Duration")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "Duration", valid_602569
  var valid_602570 = formData.getOrDefault("DBInstanceClass")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "DBInstanceClass", valid_602570
  var valid_602571 = formData.getOrDefault("Filters")
  valid_602571 = validateParameter(valid_602571, JArray, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "Filters", valid_602571
  var valid_602572 = formData.getOrDefault("ProductDescription")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "ProductDescription", valid_602572
  var valid_602573 = formData.getOrDefault("MaxRecords")
  valid_602573 = validateParameter(valid_602573, JInt, required = false, default = nil)
  if valid_602573 != nil:
    section.add "MaxRecords", valid_602573
  var valid_602574 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602575: Call_PostDescribeReservedDBInstancesOfferings_602554;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602575.validator(path, query, header, formData, body)
  let scheme = call_602575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602575.url(scheme.get, call_602575.host, call_602575.base,
                         call_602575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602575, url, valid)

proc call*(call_602576: Call_PostDescribeReservedDBInstancesOfferings_602554;
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
  var query_602577 = newJObject()
  var formData_602578 = newJObject()
  add(formData_602578, "OfferingType", newJString(OfferingType))
  add(formData_602578, "Marker", newJString(Marker))
  add(formData_602578, "MultiAZ", newJBool(MultiAZ))
  add(query_602577, "Action", newJString(Action))
  add(formData_602578, "Duration", newJString(Duration))
  add(formData_602578, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602578.add "Filters", Filters
  add(formData_602578, "ProductDescription", newJString(ProductDescription))
  add(formData_602578, "MaxRecords", newJInt(MaxRecords))
  add(formData_602578, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602577, "Version", newJString(Version))
  result = call_602576.call(nil, query_602577, nil, formData_602578, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602554(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602555,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602530 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstancesOfferings_602532(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602531(path: JsonNode;
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
  var valid_602533 = query.getOrDefault("ProductDescription")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "ProductDescription", valid_602533
  var valid_602534 = query.getOrDefault("MaxRecords")
  valid_602534 = validateParameter(valid_602534, JInt, required = false, default = nil)
  if valid_602534 != nil:
    section.add "MaxRecords", valid_602534
  var valid_602535 = query.getOrDefault("OfferingType")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "OfferingType", valid_602535
  var valid_602536 = query.getOrDefault("Filters")
  valid_602536 = validateParameter(valid_602536, JArray, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "Filters", valid_602536
  var valid_602537 = query.getOrDefault("MultiAZ")
  valid_602537 = validateParameter(valid_602537, JBool, required = false, default = nil)
  if valid_602537 != nil:
    section.add "MultiAZ", valid_602537
  var valid_602538 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602538
  var valid_602539 = query.getOrDefault("DBInstanceClass")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "DBInstanceClass", valid_602539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602540 = query.getOrDefault("Action")
  valid_602540 = validateParameter(valid_602540, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602540 != nil:
    section.add "Action", valid_602540
  var valid_602541 = query.getOrDefault("Marker")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "Marker", valid_602541
  var valid_602542 = query.getOrDefault("Duration")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "Duration", valid_602542
  var valid_602543 = query.getOrDefault("Version")
  valid_602543 = validateParameter(valid_602543, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602543 != nil:
    section.add "Version", valid_602543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602544 = header.getOrDefault("X-Amz-Date")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Date", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Security-Token")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Security-Token", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Content-Sha256", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Algorithm")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Algorithm", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Signature")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Signature", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-SignedHeaders", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Credential")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Credential", valid_602550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602551: Call_GetDescribeReservedDBInstancesOfferings_602530;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602551.validator(path, query, header, formData, body)
  let scheme = call_602551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602551.url(scheme.get, call_602551.host, call_602551.base,
                         call_602551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602551, url, valid)

proc call*(call_602552: Call_GetDescribeReservedDBInstancesOfferings_602530;
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
  var query_602553 = newJObject()
  add(query_602553, "ProductDescription", newJString(ProductDescription))
  add(query_602553, "MaxRecords", newJInt(MaxRecords))
  add(query_602553, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602553.add "Filters", Filters
  add(query_602553, "MultiAZ", newJBool(MultiAZ))
  add(query_602553, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602553, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602553, "Action", newJString(Action))
  add(query_602553, "Marker", newJString(Marker))
  add(query_602553, "Duration", newJString(Duration))
  add(query_602553, "Version", newJString(Version))
  result = call_602552.call(nil, query_602553, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602530(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602531, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602598 = ref object of OpenApiRestCall_600421
proc url_PostDownloadDBLogFilePortion_602600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_602599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602601 = query.getOrDefault("Action")
  valid_602601 = validateParameter(valid_602601, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602601 != nil:
    section.add "Action", valid_602601
  var valid_602602 = query.getOrDefault("Version")
  valid_602602 = validateParameter(valid_602602, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602602 != nil:
    section.add "Version", valid_602602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602603 = header.getOrDefault("X-Amz-Date")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Date", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Security-Token")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Security-Token", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Content-Sha256", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Algorithm")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Algorithm", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Signature")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Signature", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-SignedHeaders", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Credential")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Credential", valid_602609
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602610 = formData.getOrDefault("NumberOfLines")
  valid_602610 = validateParameter(valid_602610, JInt, required = false, default = nil)
  if valid_602610 != nil:
    section.add "NumberOfLines", valid_602610
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602611 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602611 = validateParameter(valid_602611, JString, required = true,
                                 default = nil)
  if valid_602611 != nil:
    section.add "DBInstanceIdentifier", valid_602611
  var valid_602612 = formData.getOrDefault("Marker")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "Marker", valid_602612
  var valid_602613 = formData.getOrDefault("LogFileName")
  valid_602613 = validateParameter(valid_602613, JString, required = true,
                                 default = nil)
  if valid_602613 != nil:
    section.add "LogFileName", valid_602613
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602614: Call_PostDownloadDBLogFilePortion_602598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602614.validator(path, query, header, formData, body)
  let scheme = call_602614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602614.url(scheme.get, call_602614.host, call_602614.base,
                         call_602614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602614, url, valid)

proc call*(call_602615: Call_PostDownloadDBLogFilePortion_602598;
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
  var query_602616 = newJObject()
  var formData_602617 = newJObject()
  add(formData_602617, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602617, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602617, "Marker", newJString(Marker))
  add(query_602616, "Action", newJString(Action))
  add(formData_602617, "LogFileName", newJString(LogFileName))
  add(query_602616, "Version", newJString(Version))
  result = call_602615.call(nil, query_602616, nil, formData_602617, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602598(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602599, base: "/",
    url: url_PostDownloadDBLogFilePortion_602600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602579 = ref object of OpenApiRestCall_600421
proc url_GetDownloadDBLogFilePortion_602581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_602580(path: JsonNode; query: JsonNode;
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
  var valid_602582 = query.getOrDefault("NumberOfLines")
  valid_602582 = validateParameter(valid_602582, JInt, required = false, default = nil)
  if valid_602582 != nil:
    section.add "NumberOfLines", valid_602582
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602583 = query.getOrDefault("LogFileName")
  valid_602583 = validateParameter(valid_602583, JString, required = true,
                                 default = nil)
  if valid_602583 != nil:
    section.add "LogFileName", valid_602583
  var valid_602584 = query.getOrDefault("Action")
  valid_602584 = validateParameter(valid_602584, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602584 != nil:
    section.add "Action", valid_602584
  var valid_602585 = query.getOrDefault("Marker")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "Marker", valid_602585
  var valid_602586 = query.getOrDefault("Version")
  valid_602586 = validateParameter(valid_602586, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602586 != nil:
    section.add "Version", valid_602586
  var valid_602587 = query.getOrDefault("DBInstanceIdentifier")
  valid_602587 = validateParameter(valid_602587, JString, required = true,
                                 default = nil)
  if valid_602587 != nil:
    section.add "DBInstanceIdentifier", valid_602587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602588 = header.getOrDefault("X-Amz-Date")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Date", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Security-Token")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Security-Token", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Content-Sha256", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Algorithm")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Algorithm", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Signature")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Signature", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-SignedHeaders", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Credential")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Credential", valid_602594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602595: Call_GetDownloadDBLogFilePortion_602579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602595.validator(path, query, header, formData, body)
  let scheme = call_602595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602595.url(scheme.get, call_602595.host, call_602595.base,
                         call_602595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602595, url, valid)

proc call*(call_602596: Call_GetDownloadDBLogFilePortion_602579;
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
  var query_602597 = newJObject()
  add(query_602597, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602597, "LogFileName", newJString(LogFileName))
  add(query_602597, "Action", newJString(Action))
  add(query_602597, "Marker", newJString(Marker))
  add(query_602597, "Version", newJString(Version))
  add(query_602597, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602596.call(nil, query_602597, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602579(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602580, base: "/",
    url: url_GetDownloadDBLogFilePortion_602581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602635 = ref object of OpenApiRestCall_600421
proc url_PostListTagsForResource_602637(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_602636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602638 = query.getOrDefault("Action")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602638 != nil:
    section.add "Action", valid_602638
  var valid_602639 = query.getOrDefault("Version")
  valid_602639 = validateParameter(valid_602639, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602639 != nil:
    section.add "Version", valid_602639
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602640 = header.getOrDefault("X-Amz-Date")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Date", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Security-Token")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Security-Token", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Algorithm")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Algorithm", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Signature")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Signature", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-SignedHeaders", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Credential")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Credential", valid_602646
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_602647 = formData.getOrDefault("Filters")
  valid_602647 = validateParameter(valid_602647, JArray, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "Filters", valid_602647
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602648 = formData.getOrDefault("ResourceName")
  valid_602648 = validateParameter(valid_602648, JString, required = true,
                                 default = nil)
  if valid_602648 != nil:
    section.add "ResourceName", valid_602648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602649: Call_PostListTagsForResource_602635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602649.validator(path, query, header, formData, body)
  let scheme = call_602649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602649.url(scheme.get, call_602649.host, call_602649.base,
                         call_602649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602649, url, valid)

proc call*(call_602650: Call_PostListTagsForResource_602635; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602651 = newJObject()
  var formData_602652 = newJObject()
  add(query_602651, "Action", newJString(Action))
  if Filters != nil:
    formData_602652.add "Filters", Filters
  add(formData_602652, "ResourceName", newJString(ResourceName))
  add(query_602651, "Version", newJString(Version))
  result = call_602650.call(nil, query_602651, nil, formData_602652, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602635(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602636, base: "/",
    url: url_PostListTagsForResource_602637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602618 = ref object of OpenApiRestCall_600421
proc url_GetListTagsForResource_602620(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_602619(path: JsonNode; query: JsonNode;
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
  var valid_602621 = query.getOrDefault("Filters")
  valid_602621 = validateParameter(valid_602621, JArray, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "Filters", valid_602621
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_602622 = query.getOrDefault("ResourceName")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = nil)
  if valid_602622 != nil:
    section.add "ResourceName", valid_602622
  var valid_602623 = query.getOrDefault("Action")
  valid_602623 = validateParameter(valid_602623, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602623 != nil:
    section.add "Action", valid_602623
  var valid_602624 = query.getOrDefault("Version")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602624 != nil:
    section.add "Version", valid_602624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602625 = header.getOrDefault("X-Amz-Date")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Date", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Security-Token")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Security-Token", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Content-Sha256", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Algorithm")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Algorithm", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Signature")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Signature", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-SignedHeaders", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Credential")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Credential", valid_602631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602632: Call_GetListTagsForResource_602618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602632.validator(path, query, header, formData, body)
  let scheme = call_602632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602632.url(scheme.get, call_602632.host, call_602632.base,
                         call_602632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602632, url, valid)

proc call*(call_602633: Call_GetListTagsForResource_602618; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602634 = newJObject()
  if Filters != nil:
    query_602634.add "Filters", Filters
  add(query_602634, "ResourceName", newJString(ResourceName))
  add(query_602634, "Action", newJString(Action))
  add(query_602634, "Version", newJString(Version))
  result = call_602633.call(nil, query_602634, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602618(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602619, base: "/",
    url: url_GetListTagsForResource_602620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602689 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBInstance_602691(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_602690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602692 = query.getOrDefault("Action")
  valid_602692 = validateParameter(valid_602692, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602692 != nil:
    section.add "Action", valid_602692
  var valid_602693 = query.getOrDefault("Version")
  valid_602693 = validateParameter(valid_602693, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602693 != nil:
    section.add "Version", valid_602693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602694 = header.getOrDefault("X-Amz-Date")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Date", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Security-Token")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Security-Token", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Content-Sha256", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Algorithm")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Algorithm", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Signature")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Signature", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-SignedHeaders", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Credential")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Credential", valid_602700
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
  var valid_602701 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "PreferredMaintenanceWindow", valid_602701
  var valid_602702 = formData.getOrDefault("DBSecurityGroups")
  valid_602702 = validateParameter(valid_602702, JArray, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "DBSecurityGroups", valid_602702
  var valid_602703 = formData.getOrDefault("ApplyImmediately")
  valid_602703 = validateParameter(valid_602703, JBool, required = false, default = nil)
  if valid_602703 != nil:
    section.add "ApplyImmediately", valid_602703
  var valid_602704 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602704 = validateParameter(valid_602704, JArray, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "VpcSecurityGroupIds", valid_602704
  var valid_602705 = formData.getOrDefault("Iops")
  valid_602705 = validateParameter(valid_602705, JInt, required = false, default = nil)
  if valid_602705 != nil:
    section.add "Iops", valid_602705
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602706 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602706 = validateParameter(valid_602706, JString, required = true,
                                 default = nil)
  if valid_602706 != nil:
    section.add "DBInstanceIdentifier", valid_602706
  var valid_602707 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602707 = validateParameter(valid_602707, JInt, required = false, default = nil)
  if valid_602707 != nil:
    section.add "BackupRetentionPeriod", valid_602707
  var valid_602708 = formData.getOrDefault("DBParameterGroupName")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "DBParameterGroupName", valid_602708
  var valid_602709 = formData.getOrDefault("OptionGroupName")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "OptionGroupName", valid_602709
  var valid_602710 = formData.getOrDefault("MasterUserPassword")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "MasterUserPassword", valid_602710
  var valid_602711 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "NewDBInstanceIdentifier", valid_602711
  var valid_602712 = formData.getOrDefault("TdeCredentialArn")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "TdeCredentialArn", valid_602712
  var valid_602713 = formData.getOrDefault("TdeCredentialPassword")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "TdeCredentialPassword", valid_602713
  var valid_602714 = formData.getOrDefault("MultiAZ")
  valid_602714 = validateParameter(valid_602714, JBool, required = false, default = nil)
  if valid_602714 != nil:
    section.add "MultiAZ", valid_602714
  var valid_602715 = formData.getOrDefault("AllocatedStorage")
  valid_602715 = validateParameter(valid_602715, JInt, required = false, default = nil)
  if valid_602715 != nil:
    section.add "AllocatedStorage", valid_602715
  var valid_602716 = formData.getOrDefault("StorageType")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "StorageType", valid_602716
  var valid_602717 = formData.getOrDefault("DBInstanceClass")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "DBInstanceClass", valid_602717
  var valid_602718 = formData.getOrDefault("PreferredBackupWindow")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "PreferredBackupWindow", valid_602718
  var valid_602719 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602719 = validateParameter(valid_602719, JBool, required = false, default = nil)
  if valid_602719 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602719
  var valid_602720 = formData.getOrDefault("EngineVersion")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "EngineVersion", valid_602720
  var valid_602721 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602721 = validateParameter(valid_602721, JBool, required = false, default = nil)
  if valid_602721 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602722: Call_PostModifyDBInstance_602689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602722.validator(path, query, header, formData, body)
  let scheme = call_602722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602722.url(scheme.get, call_602722.host, call_602722.base,
                         call_602722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602722, url, valid)

proc call*(call_602723: Call_PostModifyDBInstance_602689;
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
  var query_602724 = newJObject()
  var formData_602725 = newJObject()
  add(formData_602725, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602725.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602725, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602725.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602725, "Iops", newJInt(Iops))
  add(formData_602725, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602725, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602725, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602725, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602725, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602725, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602725, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_602725, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_602725, "MultiAZ", newJBool(MultiAZ))
  add(query_602724, "Action", newJString(Action))
  add(formData_602725, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602725, "StorageType", newJString(StorageType))
  add(formData_602725, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602725, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602725, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602725, "EngineVersion", newJString(EngineVersion))
  add(query_602724, "Version", newJString(Version))
  add(formData_602725, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602723.call(nil, query_602724, nil, formData_602725, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602689(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602690, base: "/",
    url: url_PostModifyDBInstance_602691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602653 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBInstance_602655(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_602654(path: JsonNode; query: JsonNode;
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
  var valid_602656 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "PreferredMaintenanceWindow", valid_602656
  var valid_602657 = query.getOrDefault("AllocatedStorage")
  valid_602657 = validateParameter(valid_602657, JInt, required = false, default = nil)
  if valid_602657 != nil:
    section.add "AllocatedStorage", valid_602657
  var valid_602658 = query.getOrDefault("StorageType")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "StorageType", valid_602658
  var valid_602659 = query.getOrDefault("OptionGroupName")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "OptionGroupName", valid_602659
  var valid_602660 = query.getOrDefault("DBSecurityGroups")
  valid_602660 = validateParameter(valid_602660, JArray, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "DBSecurityGroups", valid_602660
  var valid_602661 = query.getOrDefault("MasterUserPassword")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "MasterUserPassword", valid_602661
  var valid_602662 = query.getOrDefault("Iops")
  valid_602662 = validateParameter(valid_602662, JInt, required = false, default = nil)
  if valid_602662 != nil:
    section.add "Iops", valid_602662
  var valid_602663 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602663 = validateParameter(valid_602663, JArray, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "VpcSecurityGroupIds", valid_602663
  var valid_602664 = query.getOrDefault("MultiAZ")
  valid_602664 = validateParameter(valid_602664, JBool, required = false, default = nil)
  if valid_602664 != nil:
    section.add "MultiAZ", valid_602664
  var valid_602665 = query.getOrDefault("TdeCredentialPassword")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "TdeCredentialPassword", valid_602665
  var valid_602666 = query.getOrDefault("BackupRetentionPeriod")
  valid_602666 = validateParameter(valid_602666, JInt, required = false, default = nil)
  if valid_602666 != nil:
    section.add "BackupRetentionPeriod", valid_602666
  var valid_602667 = query.getOrDefault("DBParameterGroupName")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "DBParameterGroupName", valid_602667
  var valid_602668 = query.getOrDefault("DBInstanceClass")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "DBInstanceClass", valid_602668
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602669 = query.getOrDefault("Action")
  valid_602669 = validateParameter(valid_602669, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602669 != nil:
    section.add "Action", valid_602669
  var valid_602670 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602670 = validateParameter(valid_602670, JBool, required = false, default = nil)
  if valid_602670 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602670
  var valid_602671 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "NewDBInstanceIdentifier", valid_602671
  var valid_602672 = query.getOrDefault("TdeCredentialArn")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "TdeCredentialArn", valid_602672
  var valid_602673 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602673 = validateParameter(valid_602673, JBool, required = false, default = nil)
  if valid_602673 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602673
  var valid_602674 = query.getOrDefault("EngineVersion")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "EngineVersion", valid_602674
  var valid_602675 = query.getOrDefault("PreferredBackupWindow")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "PreferredBackupWindow", valid_602675
  var valid_602676 = query.getOrDefault("Version")
  valid_602676 = validateParameter(valid_602676, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602676 != nil:
    section.add "Version", valid_602676
  var valid_602677 = query.getOrDefault("DBInstanceIdentifier")
  valid_602677 = validateParameter(valid_602677, JString, required = true,
                                 default = nil)
  if valid_602677 != nil:
    section.add "DBInstanceIdentifier", valid_602677
  var valid_602678 = query.getOrDefault("ApplyImmediately")
  valid_602678 = validateParameter(valid_602678, JBool, required = false, default = nil)
  if valid_602678 != nil:
    section.add "ApplyImmediately", valid_602678
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602679 = header.getOrDefault("X-Amz-Date")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Date", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Security-Token")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Security-Token", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Content-Sha256", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Algorithm")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Algorithm", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Signature")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Signature", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-SignedHeaders", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Credential")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Credential", valid_602685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602686: Call_GetModifyDBInstance_602653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602686.validator(path, query, header, formData, body)
  let scheme = call_602686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602686.url(scheme.get, call_602686.host, call_602686.base,
                         call_602686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602686, url, valid)

proc call*(call_602687: Call_GetModifyDBInstance_602653;
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
  var query_602688 = newJObject()
  add(query_602688, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602688, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602688, "StorageType", newJString(StorageType))
  add(query_602688, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602688.add "DBSecurityGroups", DBSecurityGroups
  add(query_602688, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602688, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602688.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602688, "MultiAZ", newJBool(MultiAZ))
  add(query_602688, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_602688, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602688, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602688, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602688, "Action", newJString(Action))
  add(query_602688, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602688, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602688, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_602688, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602688, "EngineVersion", newJString(EngineVersion))
  add(query_602688, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602688, "Version", newJString(Version))
  add(query_602688, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602688, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602687.call(nil, query_602688, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602653(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602654, base: "/",
    url: url_GetModifyDBInstance_602655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602743 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBParameterGroup_602745(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_602744(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602746 = query.getOrDefault("Action")
  valid_602746 = validateParameter(valid_602746, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602746 != nil:
    section.add "Action", valid_602746
  var valid_602747 = query.getOrDefault("Version")
  valid_602747 = validateParameter(valid_602747, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602747 != nil:
    section.add "Version", valid_602747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602748 = header.getOrDefault("X-Amz-Date")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Date", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Security-Token")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Security-Token", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Content-Sha256", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Algorithm")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Algorithm", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Signature")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Signature", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-SignedHeaders", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Credential")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Credential", valid_602754
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602755 = formData.getOrDefault("DBParameterGroupName")
  valid_602755 = validateParameter(valid_602755, JString, required = true,
                                 default = nil)
  if valid_602755 != nil:
    section.add "DBParameterGroupName", valid_602755
  var valid_602756 = formData.getOrDefault("Parameters")
  valid_602756 = validateParameter(valid_602756, JArray, required = true, default = nil)
  if valid_602756 != nil:
    section.add "Parameters", valid_602756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602757: Call_PostModifyDBParameterGroup_602743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602757.validator(path, query, header, formData, body)
  let scheme = call_602757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602757.url(scheme.get, call_602757.host, call_602757.base,
                         call_602757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602757, url, valid)

proc call*(call_602758: Call_PostModifyDBParameterGroup_602743;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602759 = newJObject()
  var formData_602760 = newJObject()
  add(formData_602760, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602760.add "Parameters", Parameters
  add(query_602759, "Action", newJString(Action))
  add(query_602759, "Version", newJString(Version))
  result = call_602758.call(nil, query_602759, nil, formData_602760, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602743(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602744, base: "/",
    url: url_PostModifyDBParameterGroup_602745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602726 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBParameterGroup_602728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_602727(path: JsonNode; query: JsonNode;
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
  var valid_602729 = query.getOrDefault("DBParameterGroupName")
  valid_602729 = validateParameter(valid_602729, JString, required = true,
                                 default = nil)
  if valid_602729 != nil:
    section.add "DBParameterGroupName", valid_602729
  var valid_602730 = query.getOrDefault("Parameters")
  valid_602730 = validateParameter(valid_602730, JArray, required = true, default = nil)
  if valid_602730 != nil:
    section.add "Parameters", valid_602730
  var valid_602731 = query.getOrDefault("Action")
  valid_602731 = validateParameter(valid_602731, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602731 != nil:
    section.add "Action", valid_602731
  var valid_602732 = query.getOrDefault("Version")
  valid_602732 = validateParameter(valid_602732, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602732 != nil:
    section.add "Version", valid_602732
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602733 = header.getOrDefault("X-Amz-Date")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Date", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Security-Token")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Security-Token", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Content-Sha256", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Algorithm")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Algorithm", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Signature")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Signature", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-SignedHeaders", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Credential")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Credential", valid_602739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602740: Call_GetModifyDBParameterGroup_602726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602740.validator(path, query, header, formData, body)
  let scheme = call_602740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602740.url(scheme.get, call_602740.host, call_602740.base,
                         call_602740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602740, url, valid)

proc call*(call_602741: Call_GetModifyDBParameterGroup_602726;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602742 = newJObject()
  add(query_602742, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602742.add "Parameters", Parameters
  add(query_602742, "Action", newJString(Action))
  add(query_602742, "Version", newJString(Version))
  result = call_602741.call(nil, query_602742, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602726(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602727, base: "/",
    url: url_GetModifyDBParameterGroup_602728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602779 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBSubnetGroup_602781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_602780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602782 = query.getOrDefault("Action")
  valid_602782 = validateParameter(valid_602782, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602782 != nil:
    section.add "Action", valid_602782
  var valid_602783 = query.getOrDefault("Version")
  valid_602783 = validateParameter(valid_602783, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602783 != nil:
    section.add "Version", valid_602783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602784 = header.getOrDefault("X-Amz-Date")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Date", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Security-Token")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Security-Token", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Content-Sha256", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Algorithm")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Algorithm", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Signature")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Signature", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-SignedHeaders", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Credential")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Credential", valid_602790
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602791 = formData.getOrDefault("DBSubnetGroupName")
  valid_602791 = validateParameter(valid_602791, JString, required = true,
                                 default = nil)
  if valid_602791 != nil:
    section.add "DBSubnetGroupName", valid_602791
  var valid_602792 = formData.getOrDefault("SubnetIds")
  valid_602792 = validateParameter(valid_602792, JArray, required = true, default = nil)
  if valid_602792 != nil:
    section.add "SubnetIds", valid_602792
  var valid_602793 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "DBSubnetGroupDescription", valid_602793
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602794: Call_PostModifyDBSubnetGroup_602779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602794.validator(path, query, header, formData, body)
  let scheme = call_602794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602794.url(scheme.get, call_602794.host, call_602794.base,
                         call_602794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602794, url, valid)

proc call*(call_602795: Call_PostModifyDBSubnetGroup_602779;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602796 = newJObject()
  var formData_602797 = newJObject()
  add(formData_602797, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602797.add "SubnetIds", SubnetIds
  add(query_602796, "Action", newJString(Action))
  add(formData_602797, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602796, "Version", newJString(Version))
  result = call_602795.call(nil, query_602796, nil, formData_602797, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602779(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602780, base: "/",
    url: url_PostModifyDBSubnetGroup_602781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602761 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBSubnetGroup_602763(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_602762(path: JsonNode; query: JsonNode;
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
  var valid_602764 = query.getOrDefault("Action")
  valid_602764 = validateParameter(valid_602764, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602764 != nil:
    section.add "Action", valid_602764
  var valid_602765 = query.getOrDefault("DBSubnetGroupName")
  valid_602765 = validateParameter(valid_602765, JString, required = true,
                                 default = nil)
  if valid_602765 != nil:
    section.add "DBSubnetGroupName", valid_602765
  var valid_602766 = query.getOrDefault("SubnetIds")
  valid_602766 = validateParameter(valid_602766, JArray, required = true, default = nil)
  if valid_602766 != nil:
    section.add "SubnetIds", valid_602766
  var valid_602767 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "DBSubnetGroupDescription", valid_602767
  var valid_602768 = query.getOrDefault("Version")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602768 != nil:
    section.add "Version", valid_602768
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602769 = header.getOrDefault("X-Amz-Date")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Date", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Security-Token")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Security-Token", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Content-Sha256", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Algorithm")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Algorithm", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Signature")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Signature", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-SignedHeaders", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Credential")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Credential", valid_602775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602776: Call_GetModifyDBSubnetGroup_602761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602776.validator(path, query, header, formData, body)
  let scheme = call_602776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602776.url(scheme.get, call_602776.host, call_602776.base,
                         call_602776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602776, url, valid)

proc call*(call_602777: Call_GetModifyDBSubnetGroup_602761;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602778 = newJObject()
  add(query_602778, "Action", newJString(Action))
  add(query_602778, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602778.add "SubnetIds", SubnetIds
  add(query_602778, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602778, "Version", newJString(Version))
  result = call_602777.call(nil, query_602778, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602761(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602762, base: "/",
    url: url_GetModifyDBSubnetGroup_602763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602818 = ref object of OpenApiRestCall_600421
proc url_PostModifyEventSubscription_602820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_602819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602821 = query.getOrDefault("Action")
  valid_602821 = validateParameter(valid_602821, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602821 != nil:
    section.add "Action", valid_602821
  var valid_602822 = query.getOrDefault("Version")
  valid_602822 = validateParameter(valid_602822, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602822 != nil:
    section.add "Version", valid_602822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602823 = header.getOrDefault("X-Amz-Date")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Date", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Security-Token")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Security-Token", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-Content-Sha256", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Algorithm")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Algorithm", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-Signature")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-Signature", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-SignedHeaders", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Credential")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Credential", valid_602829
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602830 = formData.getOrDefault("Enabled")
  valid_602830 = validateParameter(valid_602830, JBool, required = false, default = nil)
  if valid_602830 != nil:
    section.add "Enabled", valid_602830
  var valid_602831 = formData.getOrDefault("EventCategories")
  valid_602831 = validateParameter(valid_602831, JArray, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "EventCategories", valid_602831
  var valid_602832 = formData.getOrDefault("SnsTopicArn")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "SnsTopicArn", valid_602832
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602833 = formData.getOrDefault("SubscriptionName")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = nil)
  if valid_602833 != nil:
    section.add "SubscriptionName", valid_602833
  var valid_602834 = formData.getOrDefault("SourceType")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "SourceType", valid_602834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602835: Call_PostModifyEventSubscription_602818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602835.validator(path, query, header, formData, body)
  let scheme = call_602835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602835.url(scheme.get, call_602835.host, call_602835.base,
                         call_602835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602835, url, valid)

proc call*(call_602836: Call_PostModifyEventSubscription_602818;
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
  var query_602837 = newJObject()
  var formData_602838 = newJObject()
  add(formData_602838, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602838.add "EventCategories", EventCategories
  add(formData_602838, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602838, "SubscriptionName", newJString(SubscriptionName))
  add(query_602837, "Action", newJString(Action))
  add(query_602837, "Version", newJString(Version))
  add(formData_602838, "SourceType", newJString(SourceType))
  result = call_602836.call(nil, query_602837, nil, formData_602838, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602818(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602819, base: "/",
    url: url_PostModifyEventSubscription_602820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602798 = ref object of OpenApiRestCall_600421
proc url_GetModifyEventSubscription_602800(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_602799(path: JsonNode; query: JsonNode;
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
  var valid_602801 = query.getOrDefault("SourceType")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "SourceType", valid_602801
  var valid_602802 = query.getOrDefault("Enabled")
  valid_602802 = validateParameter(valid_602802, JBool, required = false, default = nil)
  if valid_602802 != nil:
    section.add "Enabled", valid_602802
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602803 = query.getOrDefault("Action")
  valid_602803 = validateParameter(valid_602803, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602803 != nil:
    section.add "Action", valid_602803
  var valid_602804 = query.getOrDefault("SnsTopicArn")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "SnsTopicArn", valid_602804
  var valid_602805 = query.getOrDefault("EventCategories")
  valid_602805 = validateParameter(valid_602805, JArray, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "EventCategories", valid_602805
  var valid_602806 = query.getOrDefault("SubscriptionName")
  valid_602806 = validateParameter(valid_602806, JString, required = true,
                                 default = nil)
  if valid_602806 != nil:
    section.add "SubscriptionName", valid_602806
  var valid_602807 = query.getOrDefault("Version")
  valid_602807 = validateParameter(valid_602807, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602807 != nil:
    section.add "Version", valid_602807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602808 = header.getOrDefault("X-Amz-Date")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Date", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Security-Token")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Security-Token", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Content-Sha256", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Algorithm")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Algorithm", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Signature")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Signature", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-SignedHeaders", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Credential")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Credential", valid_602814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602815: Call_GetModifyEventSubscription_602798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602815.validator(path, query, header, formData, body)
  let scheme = call_602815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602815.url(scheme.get, call_602815.host, call_602815.base,
                         call_602815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602815, url, valid)

proc call*(call_602816: Call_GetModifyEventSubscription_602798;
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
  var query_602817 = newJObject()
  add(query_602817, "SourceType", newJString(SourceType))
  add(query_602817, "Enabled", newJBool(Enabled))
  add(query_602817, "Action", newJString(Action))
  add(query_602817, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602817.add "EventCategories", EventCategories
  add(query_602817, "SubscriptionName", newJString(SubscriptionName))
  add(query_602817, "Version", newJString(Version))
  result = call_602816.call(nil, query_602817, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602798(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602799, base: "/",
    url: url_GetModifyEventSubscription_602800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602858 = ref object of OpenApiRestCall_600421
proc url_PostModifyOptionGroup_602860(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_602859(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602861 = query.getOrDefault("Action")
  valid_602861 = validateParameter(valid_602861, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602861 != nil:
    section.add "Action", valid_602861
  var valid_602862 = query.getOrDefault("Version")
  valid_602862 = validateParameter(valid_602862, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602862 != nil:
    section.add "Version", valid_602862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602863 = header.getOrDefault("X-Amz-Date")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Date", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Security-Token")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Security-Token", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Content-Sha256", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Algorithm")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Algorithm", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Signature")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Signature", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-SignedHeaders", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Credential")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Credential", valid_602869
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602870 = formData.getOrDefault("OptionsToRemove")
  valid_602870 = validateParameter(valid_602870, JArray, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "OptionsToRemove", valid_602870
  var valid_602871 = formData.getOrDefault("ApplyImmediately")
  valid_602871 = validateParameter(valid_602871, JBool, required = false, default = nil)
  if valid_602871 != nil:
    section.add "ApplyImmediately", valid_602871
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602872 = formData.getOrDefault("OptionGroupName")
  valid_602872 = validateParameter(valid_602872, JString, required = true,
                                 default = nil)
  if valid_602872 != nil:
    section.add "OptionGroupName", valid_602872
  var valid_602873 = formData.getOrDefault("OptionsToInclude")
  valid_602873 = validateParameter(valid_602873, JArray, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "OptionsToInclude", valid_602873
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602874: Call_PostModifyOptionGroup_602858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602874.validator(path, query, header, formData, body)
  let scheme = call_602874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602874.url(scheme.get, call_602874.host, call_602874.base,
                         call_602874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602874, url, valid)

proc call*(call_602875: Call_PostModifyOptionGroup_602858; OptionGroupName: string;
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
  var query_602876 = newJObject()
  var formData_602877 = newJObject()
  if OptionsToRemove != nil:
    formData_602877.add "OptionsToRemove", OptionsToRemove
  add(formData_602877, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602877, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602877.add "OptionsToInclude", OptionsToInclude
  add(query_602876, "Action", newJString(Action))
  add(query_602876, "Version", newJString(Version))
  result = call_602875.call(nil, query_602876, nil, formData_602877, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602858(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602859, base: "/",
    url: url_PostModifyOptionGroup_602860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602839 = ref object of OpenApiRestCall_600421
proc url_GetModifyOptionGroup_602841(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_602840(path: JsonNode; query: JsonNode;
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
  var valid_602842 = query.getOrDefault("OptionGroupName")
  valid_602842 = validateParameter(valid_602842, JString, required = true,
                                 default = nil)
  if valid_602842 != nil:
    section.add "OptionGroupName", valid_602842
  var valid_602843 = query.getOrDefault("OptionsToRemove")
  valid_602843 = validateParameter(valid_602843, JArray, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "OptionsToRemove", valid_602843
  var valid_602844 = query.getOrDefault("Action")
  valid_602844 = validateParameter(valid_602844, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602844 != nil:
    section.add "Action", valid_602844
  var valid_602845 = query.getOrDefault("Version")
  valid_602845 = validateParameter(valid_602845, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602845 != nil:
    section.add "Version", valid_602845
  var valid_602846 = query.getOrDefault("ApplyImmediately")
  valid_602846 = validateParameter(valid_602846, JBool, required = false, default = nil)
  if valid_602846 != nil:
    section.add "ApplyImmediately", valid_602846
  var valid_602847 = query.getOrDefault("OptionsToInclude")
  valid_602847 = validateParameter(valid_602847, JArray, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "OptionsToInclude", valid_602847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602848 = header.getOrDefault("X-Amz-Date")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Date", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Security-Token")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Security-Token", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Content-Sha256", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Algorithm")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Algorithm", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-Signature")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-Signature", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-SignedHeaders", valid_602853
  var valid_602854 = header.getOrDefault("X-Amz-Credential")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "X-Amz-Credential", valid_602854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602855: Call_GetModifyOptionGroup_602839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602855.validator(path, query, header, formData, body)
  let scheme = call_602855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602855.url(scheme.get, call_602855.host, call_602855.base,
                         call_602855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602855, url, valid)

proc call*(call_602856: Call_GetModifyOptionGroup_602839; OptionGroupName: string;
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
  var query_602857 = newJObject()
  add(query_602857, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602857.add "OptionsToRemove", OptionsToRemove
  add(query_602857, "Action", newJString(Action))
  add(query_602857, "Version", newJString(Version))
  add(query_602857, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602857.add "OptionsToInclude", OptionsToInclude
  result = call_602856.call(nil, query_602857, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602839(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602840, base: "/",
    url: url_GetModifyOptionGroup_602841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602896 = ref object of OpenApiRestCall_600421
proc url_PostPromoteReadReplica_602898(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_602897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602899 = query.getOrDefault("Action")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602899 != nil:
    section.add "Action", valid_602899
  var valid_602900 = query.getOrDefault("Version")
  valid_602900 = validateParameter(valid_602900, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602900 != nil:
    section.add "Version", valid_602900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602901 = header.getOrDefault("X-Amz-Date")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Date", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Security-Token")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Security-Token", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Content-Sha256", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Algorithm")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Algorithm", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Signature")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Signature", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-SignedHeaders", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Credential")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Credential", valid_602907
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602908 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = nil)
  if valid_602908 != nil:
    section.add "DBInstanceIdentifier", valid_602908
  var valid_602909 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602909 = validateParameter(valid_602909, JInt, required = false, default = nil)
  if valid_602909 != nil:
    section.add "BackupRetentionPeriod", valid_602909
  var valid_602910 = formData.getOrDefault("PreferredBackupWindow")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "PreferredBackupWindow", valid_602910
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602911: Call_PostPromoteReadReplica_602896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602911.validator(path, query, header, formData, body)
  let scheme = call_602911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602911.url(scheme.get, call_602911.host, call_602911.base,
                         call_602911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602911, url, valid)

proc call*(call_602912: Call_PostPromoteReadReplica_602896;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602913 = newJObject()
  var formData_602914 = newJObject()
  add(formData_602914, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602914, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602913, "Action", newJString(Action))
  add(formData_602914, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602913, "Version", newJString(Version))
  result = call_602912.call(nil, query_602913, nil, formData_602914, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602896(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602897, base: "/",
    url: url_PostPromoteReadReplica_602898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602878 = ref object of OpenApiRestCall_600421
proc url_GetPromoteReadReplica_602880(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_602879(path: JsonNode; query: JsonNode;
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
  var valid_602881 = query.getOrDefault("BackupRetentionPeriod")
  valid_602881 = validateParameter(valid_602881, JInt, required = false, default = nil)
  if valid_602881 != nil:
    section.add "BackupRetentionPeriod", valid_602881
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602882 = query.getOrDefault("Action")
  valid_602882 = validateParameter(valid_602882, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602882 != nil:
    section.add "Action", valid_602882
  var valid_602883 = query.getOrDefault("PreferredBackupWindow")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "PreferredBackupWindow", valid_602883
  var valid_602884 = query.getOrDefault("Version")
  valid_602884 = validateParameter(valid_602884, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602884 != nil:
    section.add "Version", valid_602884
  var valid_602885 = query.getOrDefault("DBInstanceIdentifier")
  valid_602885 = validateParameter(valid_602885, JString, required = true,
                                 default = nil)
  if valid_602885 != nil:
    section.add "DBInstanceIdentifier", valid_602885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602886 = header.getOrDefault("X-Amz-Date")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Date", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Security-Token")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Security-Token", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Content-Sha256", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Algorithm")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Algorithm", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Signature")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Signature", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-SignedHeaders", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Credential")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Credential", valid_602892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602893: Call_GetPromoteReadReplica_602878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602893.validator(path, query, header, formData, body)
  let scheme = call_602893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602893.url(scheme.get, call_602893.host, call_602893.base,
                         call_602893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602893, url, valid)

proc call*(call_602894: Call_GetPromoteReadReplica_602878;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602895 = newJObject()
  add(query_602895, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602895, "Action", newJString(Action))
  add(query_602895, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602895, "Version", newJString(Version))
  add(query_602895, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602894.call(nil, query_602895, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602878(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602879, base: "/",
    url: url_GetPromoteReadReplica_602880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602934 = ref object of OpenApiRestCall_600421
proc url_PostPurchaseReservedDBInstancesOffering_602936(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602935(path: JsonNode;
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
  var valid_602937 = query.getOrDefault("Action")
  valid_602937 = validateParameter(valid_602937, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602937 != nil:
    section.add "Action", valid_602937
  var valid_602938 = query.getOrDefault("Version")
  valid_602938 = validateParameter(valid_602938, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602938 != nil:
    section.add "Version", valid_602938
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602939 = header.getOrDefault("X-Amz-Date")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Date", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Security-Token")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Security-Token", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Content-Sha256", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Algorithm")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Algorithm", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-Signature")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Signature", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-SignedHeaders", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Credential")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Credential", valid_602945
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602946 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "ReservedDBInstanceId", valid_602946
  var valid_602947 = formData.getOrDefault("Tags")
  valid_602947 = validateParameter(valid_602947, JArray, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "Tags", valid_602947
  var valid_602948 = formData.getOrDefault("DBInstanceCount")
  valid_602948 = validateParameter(valid_602948, JInt, required = false, default = nil)
  if valid_602948 != nil:
    section.add "DBInstanceCount", valid_602948
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602949 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602949 = validateParameter(valid_602949, JString, required = true,
                                 default = nil)
  if valid_602949 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602949
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602950: Call_PostPurchaseReservedDBInstancesOffering_602934;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602950.validator(path, query, header, formData, body)
  let scheme = call_602950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602950.url(scheme.get, call_602950.host, call_602950.base,
                         call_602950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602950, url, valid)

proc call*(call_602951: Call_PostPurchaseReservedDBInstancesOffering_602934;
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
  var query_602952 = newJObject()
  var formData_602953 = newJObject()
  add(formData_602953, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_602953.add "Tags", Tags
  add(formData_602953, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602952, "Action", newJString(Action))
  add(formData_602953, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602952, "Version", newJString(Version))
  result = call_602951.call(nil, query_602952, nil, formData_602953, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602934(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602935, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602915 = ref object of OpenApiRestCall_600421
proc url_GetPurchaseReservedDBInstancesOffering_602917(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602916(path: JsonNode;
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
  var valid_602918 = query.getOrDefault("DBInstanceCount")
  valid_602918 = validateParameter(valid_602918, JInt, required = false, default = nil)
  if valid_602918 != nil:
    section.add "DBInstanceCount", valid_602918
  var valid_602919 = query.getOrDefault("Tags")
  valid_602919 = validateParameter(valid_602919, JArray, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "Tags", valid_602919
  var valid_602920 = query.getOrDefault("ReservedDBInstanceId")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "ReservedDBInstanceId", valid_602920
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602921 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602921
  var valid_602922 = query.getOrDefault("Action")
  valid_602922 = validateParameter(valid_602922, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602922 != nil:
    section.add "Action", valid_602922
  var valid_602923 = query.getOrDefault("Version")
  valid_602923 = validateParameter(valid_602923, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602923 != nil:
    section.add "Version", valid_602923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602924 = header.getOrDefault("X-Amz-Date")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Date", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Security-Token")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Security-Token", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Content-Sha256", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Algorithm")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Algorithm", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Signature")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Signature", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-SignedHeaders", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Credential")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Credential", valid_602930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602931: Call_GetPurchaseReservedDBInstancesOffering_602915;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602931.validator(path, query, header, formData, body)
  let scheme = call_602931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602931.url(scheme.get, call_602931.host, call_602931.base,
                         call_602931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602931, url, valid)

proc call*(call_602932: Call_GetPurchaseReservedDBInstancesOffering_602915;
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
  var query_602933 = newJObject()
  add(query_602933, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_602933.add "Tags", Tags
  add(query_602933, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602933, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602933, "Action", newJString(Action))
  add(query_602933, "Version", newJString(Version))
  result = call_602932.call(nil, query_602933, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602915(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602916, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602971 = ref object of OpenApiRestCall_600421
proc url_PostRebootDBInstance_602973(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_602972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602974 = query.getOrDefault("Action")
  valid_602974 = validateParameter(valid_602974, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602974 != nil:
    section.add "Action", valid_602974
  var valid_602975 = query.getOrDefault("Version")
  valid_602975 = validateParameter(valid_602975, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602975 != nil:
    section.add "Version", valid_602975
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602976 = header.getOrDefault("X-Amz-Date")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Date", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Security-Token")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Security-Token", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Content-Sha256", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Algorithm")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Algorithm", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Signature")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Signature", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-SignedHeaders", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Credential")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Credential", valid_602982
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602983 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602983 = validateParameter(valid_602983, JString, required = true,
                                 default = nil)
  if valid_602983 != nil:
    section.add "DBInstanceIdentifier", valid_602983
  var valid_602984 = formData.getOrDefault("ForceFailover")
  valid_602984 = validateParameter(valid_602984, JBool, required = false, default = nil)
  if valid_602984 != nil:
    section.add "ForceFailover", valid_602984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602985: Call_PostRebootDBInstance_602971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602985.validator(path, query, header, formData, body)
  let scheme = call_602985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602985.url(scheme.get, call_602985.host, call_602985.base,
                         call_602985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602985, url, valid)

proc call*(call_602986: Call_PostRebootDBInstance_602971;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602987 = newJObject()
  var formData_602988 = newJObject()
  add(formData_602988, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602987, "Action", newJString(Action))
  add(formData_602988, "ForceFailover", newJBool(ForceFailover))
  add(query_602987, "Version", newJString(Version))
  result = call_602986.call(nil, query_602987, nil, formData_602988, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602971(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602972, base: "/",
    url: url_PostRebootDBInstance_602973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602954 = ref object of OpenApiRestCall_600421
proc url_GetRebootDBInstance_602956(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_602955(path: JsonNode; query: JsonNode;
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
  var valid_602957 = query.getOrDefault("Action")
  valid_602957 = validateParameter(valid_602957, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602957 != nil:
    section.add "Action", valid_602957
  var valid_602958 = query.getOrDefault("ForceFailover")
  valid_602958 = validateParameter(valid_602958, JBool, required = false, default = nil)
  if valid_602958 != nil:
    section.add "ForceFailover", valid_602958
  var valid_602959 = query.getOrDefault("Version")
  valid_602959 = validateParameter(valid_602959, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602959 != nil:
    section.add "Version", valid_602959
  var valid_602960 = query.getOrDefault("DBInstanceIdentifier")
  valid_602960 = validateParameter(valid_602960, JString, required = true,
                                 default = nil)
  if valid_602960 != nil:
    section.add "DBInstanceIdentifier", valid_602960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602961 = header.getOrDefault("X-Amz-Date")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Date", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Security-Token")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Security-Token", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Content-Sha256", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Algorithm")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Algorithm", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Signature")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Signature", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-SignedHeaders", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Credential")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Credential", valid_602967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602968: Call_GetRebootDBInstance_602954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602968.validator(path, query, header, formData, body)
  let scheme = call_602968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602968.url(scheme.get, call_602968.host, call_602968.base,
                         call_602968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602968, url, valid)

proc call*(call_602969: Call_GetRebootDBInstance_602954;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602970 = newJObject()
  add(query_602970, "Action", newJString(Action))
  add(query_602970, "ForceFailover", newJBool(ForceFailover))
  add(query_602970, "Version", newJString(Version))
  add(query_602970, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602969.call(nil, query_602970, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602954(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602955, base: "/",
    url: url_GetRebootDBInstance_602956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603006 = ref object of OpenApiRestCall_600421
proc url_PostRemoveSourceIdentifierFromSubscription_603008(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_603007(path: JsonNode;
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
  var valid_603009 = query.getOrDefault("Action")
  valid_603009 = validateParameter(valid_603009, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603009 != nil:
    section.add "Action", valid_603009
  var valid_603010 = query.getOrDefault("Version")
  valid_603010 = validateParameter(valid_603010, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603010 != nil:
    section.add "Version", valid_603010
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603011 = header.getOrDefault("X-Amz-Date")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Date", valid_603011
  var valid_603012 = header.getOrDefault("X-Amz-Security-Token")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-Security-Token", valid_603012
  var valid_603013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "X-Amz-Content-Sha256", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Algorithm")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Algorithm", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Signature")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Signature", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-SignedHeaders", valid_603016
  var valid_603017 = header.getOrDefault("X-Amz-Credential")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Credential", valid_603017
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_603018 = formData.getOrDefault("SourceIdentifier")
  valid_603018 = validateParameter(valid_603018, JString, required = true,
                                 default = nil)
  if valid_603018 != nil:
    section.add "SourceIdentifier", valid_603018
  var valid_603019 = formData.getOrDefault("SubscriptionName")
  valid_603019 = validateParameter(valid_603019, JString, required = true,
                                 default = nil)
  if valid_603019 != nil:
    section.add "SubscriptionName", valid_603019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603020: Call_PostRemoveSourceIdentifierFromSubscription_603006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603020.validator(path, query, header, formData, body)
  let scheme = call_603020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603020.url(scheme.get, call_603020.host, call_603020.base,
                         call_603020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603020, url, valid)

proc call*(call_603021: Call_PostRemoveSourceIdentifierFromSubscription_603006;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603022 = newJObject()
  var formData_603023 = newJObject()
  add(formData_603023, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603023, "SubscriptionName", newJString(SubscriptionName))
  add(query_603022, "Action", newJString(Action))
  add(query_603022, "Version", newJString(Version))
  result = call_603021.call(nil, query_603022, nil, formData_603023, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603006(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603007,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602989 = ref object of OpenApiRestCall_600421
proc url_GetRemoveSourceIdentifierFromSubscription_602991(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602990(path: JsonNode;
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
  var valid_602992 = query.getOrDefault("Action")
  valid_602992 = validateParameter(valid_602992, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602992 != nil:
    section.add "Action", valid_602992
  var valid_602993 = query.getOrDefault("SourceIdentifier")
  valid_602993 = validateParameter(valid_602993, JString, required = true,
                                 default = nil)
  if valid_602993 != nil:
    section.add "SourceIdentifier", valid_602993
  var valid_602994 = query.getOrDefault("SubscriptionName")
  valid_602994 = validateParameter(valid_602994, JString, required = true,
                                 default = nil)
  if valid_602994 != nil:
    section.add "SubscriptionName", valid_602994
  var valid_602995 = query.getOrDefault("Version")
  valid_602995 = validateParameter(valid_602995, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602995 != nil:
    section.add "Version", valid_602995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602996 = header.getOrDefault("X-Amz-Date")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Date", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-Security-Token")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Security-Token", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Content-Sha256", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Algorithm")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Algorithm", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Signature")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Signature", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-SignedHeaders", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Credential")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Credential", valid_603002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603003: Call_GetRemoveSourceIdentifierFromSubscription_602989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603003.validator(path, query, header, formData, body)
  let scheme = call_603003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603003.url(scheme.get, call_603003.host, call_603003.base,
                         call_603003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603003, url, valid)

proc call*(call_603004: Call_GetRemoveSourceIdentifierFromSubscription_602989;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603005 = newJObject()
  add(query_603005, "Action", newJString(Action))
  add(query_603005, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603005, "SubscriptionName", newJString(SubscriptionName))
  add(query_603005, "Version", newJString(Version))
  result = call_603004.call(nil, query_603005, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602989(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602990,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603041 = ref object of OpenApiRestCall_600421
proc url_PostRemoveTagsFromResource_603043(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_603042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603044 = query.getOrDefault("Action")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603044 != nil:
    section.add "Action", valid_603044
  var valid_603045 = query.getOrDefault("Version")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603045 != nil:
    section.add "Version", valid_603045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603046 = header.getOrDefault("X-Amz-Date")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Date", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Security-Token")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Security-Token", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Content-Sha256", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Algorithm")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Algorithm", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Signature")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Signature", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-SignedHeaders", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Credential")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Credential", valid_603052
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603053 = formData.getOrDefault("TagKeys")
  valid_603053 = validateParameter(valid_603053, JArray, required = true, default = nil)
  if valid_603053 != nil:
    section.add "TagKeys", valid_603053
  var valid_603054 = formData.getOrDefault("ResourceName")
  valid_603054 = validateParameter(valid_603054, JString, required = true,
                                 default = nil)
  if valid_603054 != nil:
    section.add "ResourceName", valid_603054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603055: Call_PostRemoveTagsFromResource_603041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603055.validator(path, query, header, formData, body)
  let scheme = call_603055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603055.url(scheme.get, call_603055.host, call_603055.base,
                         call_603055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603055, url, valid)

proc call*(call_603056: Call_PostRemoveTagsFromResource_603041; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_603057 = newJObject()
  var formData_603058 = newJObject()
  add(query_603057, "Action", newJString(Action))
  if TagKeys != nil:
    formData_603058.add "TagKeys", TagKeys
  add(formData_603058, "ResourceName", newJString(ResourceName))
  add(query_603057, "Version", newJString(Version))
  result = call_603056.call(nil, query_603057, nil, formData_603058, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603041(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603042, base: "/",
    url: url_PostRemoveTagsFromResource_603043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603024 = ref object of OpenApiRestCall_600421
proc url_GetRemoveTagsFromResource_603026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_603025(path: JsonNode; query: JsonNode;
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
  var valid_603027 = query.getOrDefault("ResourceName")
  valid_603027 = validateParameter(valid_603027, JString, required = true,
                                 default = nil)
  if valid_603027 != nil:
    section.add "ResourceName", valid_603027
  var valid_603028 = query.getOrDefault("Action")
  valid_603028 = validateParameter(valid_603028, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603028 != nil:
    section.add "Action", valid_603028
  var valid_603029 = query.getOrDefault("TagKeys")
  valid_603029 = validateParameter(valid_603029, JArray, required = true, default = nil)
  if valid_603029 != nil:
    section.add "TagKeys", valid_603029
  var valid_603030 = query.getOrDefault("Version")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603038: Call_GetRemoveTagsFromResource_603024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603038.validator(path, query, header, formData, body)
  let scheme = call_603038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603038.url(scheme.get, call_603038.host, call_603038.base,
                         call_603038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603038, url, valid)

proc call*(call_603039: Call_GetRemoveTagsFromResource_603024;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_603040 = newJObject()
  add(query_603040, "ResourceName", newJString(ResourceName))
  add(query_603040, "Action", newJString(Action))
  if TagKeys != nil:
    query_603040.add "TagKeys", TagKeys
  add(query_603040, "Version", newJString(Version))
  result = call_603039.call(nil, query_603040, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603024(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603025, base: "/",
    url: url_GetRemoveTagsFromResource_603026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_603077 = ref object of OpenApiRestCall_600421
proc url_PostResetDBParameterGroup_603079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_603078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603080 = query.getOrDefault("Action")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603080 != nil:
    section.add "Action", valid_603080
  var valid_603081 = query.getOrDefault("Version")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603081 != nil:
    section.add "Version", valid_603081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603089 = formData.getOrDefault("DBParameterGroupName")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = nil)
  if valid_603089 != nil:
    section.add "DBParameterGroupName", valid_603089
  var valid_603090 = formData.getOrDefault("Parameters")
  valid_603090 = validateParameter(valid_603090, JArray, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "Parameters", valid_603090
  var valid_603091 = formData.getOrDefault("ResetAllParameters")
  valid_603091 = validateParameter(valid_603091, JBool, required = false, default = nil)
  if valid_603091 != nil:
    section.add "ResetAllParameters", valid_603091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603092: Call_PostResetDBParameterGroup_603077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603092.validator(path, query, header, formData, body)
  let scheme = call_603092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603092.url(scheme.get, call_603092.host, call_603092.base,
                         call_603092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603092, url, valid)

proc call*(call_603093: Call_PostResetDBParameterGroup_603077;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_603094 = newJObject()
  var formData_603095 = newJObject()
  add(formData_603095, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_603095.add "Parameters", Parameters
  add(query_603094, "Action", newJString(Action))
  add(formData_603095, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603094, "Version", newJString(Version))
  result = call_603093.call(nil, query_603094, nil, formData_603095, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_603077(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_603078, base: "/",
    url: url_PostResetDBParameterGroup_603079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_603059 = ref object of OpenApiRestCall_600421
proc url_GetResetDBParameterGroup_603061(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_603060(path: JsonNode; query: JsonNode;
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
  var valid_603062 = query.getOrDefault("DBParameterGroupName")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "DBParameterGroupName", valid_603062
  var valid_603063 = query.getOrDefault("Parameters")
  valid_603063 = validateParameter(valid_603063, JArray, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "Parameters", valid_603063
  var valid_603064 = query.getOrDefault("Action")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603064 != nil:
    section.add "Action", valid_603064
  var valid_603065 = query.getOrDefault("ResetAllParameters")
  valid_603065 = validateParameter(valid_603065, JBool, required = false, default = nil)
  if valid_603065 != nil:
    section.add "ResetAllParameters", valid_603065
  var valid_603066 = query.getOrDefault("Version")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603066 != nil:
    section.add "Version", valid_603066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603067 = header.getOrDefault("X-Amz-Date")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Date", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603074: Call_GetResetDBParameterGroup_603059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603074.validator(path, query, header, formData, body)
  let scheme = call_603074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603074.url(scheme.get, call_603074.host, call_603074.base,
                         call_603074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603074, url, valid)

proc call*(call_603075: Call_GetResetDBParameterGroup_603059;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_603076 = newJObject()
  add(query_603076, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603076.add "Parameters", Parameters
  add(query_603076, "Action", newJString(Action))
  add(query_603076, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603076, "Version", newJString(Version))
  result = call_603075.call(nil, query_603076, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_603059(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_603060, base: "/",
    url: url_GetResetDBParameterGroup_603061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603129 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceFromDBSnapshot_603131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_603130(path: JsonNode;
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
  var valid_603132 = query.getOrDefault("Action")
  valid_603132 = validateParameter(valid_603132, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603132 != nil:
    section.add "Action", valid_603132
  var valid_603133 = query.getOrDefault("Version")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603133 != nil:
    section.add "Version", valid_603133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603134 = header.getOrDefault("X-Amz-Date")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Date", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Security-Token")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Security-Token", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Content-Sha256", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Signature")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Signature", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
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
  var valid_603141 = formData.getOrDefault("Port")
  valid_603141 = validateParameter(valid_603141, JInt, required = false, default = nil)
  if valid_603141 != nil:
    section.add "Port", valid_603141
  var valid_603142 = formData.getOrDefault("Engine")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "Engine", valid_603142
  var valid_603143 = formData.getOrDefault("Iops")
  valid_603143 = validateParameter(valid_603143, JInt, required = false, default = nil)
  if valid_603143 != nil:
    section.add "Iops", valid_603143
  var valid_603144 = formData.getOrDefault("DBName")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "DBName", valid_603144
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603145 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = nil)
  if valid_603145 != nil:
    section.add "DBInstanceIdentifier", valid_603145
  var valid_603146 = formData.getOrDefault("OptionGroupName")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "OptionGroupName", valid_603146
  var valid_603147 = formData.getOrDefault("Tags")
  valid_603147 = validateParameter(valid_603147, JArray, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "Tags", valid_603147
  var valid_603148 = formData.getOrDefault("TdeCredentialArn")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "TdeCredentialArn", valid_603148
  var valid_603149 = formData.getOrDefault("DBSubnetGroupName")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "DBSubnetGroupName", valid_603149
  var valid_603150 = formData.getOrDefault("TdeCredentialPassword")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "TdeCredentialPassword", valid_603150
  var valid_603151 = formData.getOrDefault("AvailabilityZone")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "AvailabilityZone", valid_603151
  var valid_603152 = formData.getOrDefault("MultiAZ")
  valid_603152 = validateParameter(valid_603152, JBool, required = false, default = nil)
  if valid_603152 != nil:
    section.add "MultiAZ", valid_603152
  var valid_603153 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = nil)
  if valid_603153 != nil:
    section.add "DBSnapshotIdentifier", valid_603153
  var valid_603154 = formData.getOrDefault("PubliclyAccessible")
  valid_603154 = validateParameter(valid_603154, JBool, required = false, default = nil)
  if valid_603154 != nil:
    section.add "PubliclyAccessible", valid_603154
  var valid_603155 = formData.getOrDefault("StorageType")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "StorageType", valid_603155
  var valid_603156 = formData.getOrDefault("DBInstanceClass")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "DBInstanceClass", valid_603156
  var valid_603157 = formData.getOrDefault("LicenseModel")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "LicenseModel", valid_603157
  var valid_603158 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603158 = validateParameter(valid_603158, JBool, required = false, default = nil)
  if valid_603158 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_PostRestoreDBInstanceFromDBSnapshot_603129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_PostRestoreDBInstanceFromDBSnapshot_603129;
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
  var query_603161 = newJObject()
  var formData_603162 = newJObject()
  add(formData_603162, "Port", newJInt(Port))
  add(formData_603162, "Engine", newJString(Engine))
  add(formData_603162, "Iops", newJInt(Iops))
  add(formData_603162, "DBName", newJString(DBName))
  add(formData_603162, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603162, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603162.add "Tags", Tags
  add(formData_603162, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603162, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603162, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603162, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603162, "MultiAZ", newJBool(MultiAZ))
  add(formData_603162, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603161, "Action", newJString(Action))
  add(formData_603162, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603162, "StorageType", newJString(StorageType))
  add(formData_603162, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603162, "LicenseModel", newJString(LicenseModel))
  add(formData_603162, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603161, "Version", newJString(Version))
  result = call_603160.call(nil, query_603161, nil, formData_603162, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603129(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603130, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603096 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceFromDBSnapshot_603098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_603097(path: JsonNode;
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
  var valid_603099 = query.getOrDefault("Engine")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "Engine", valid_603099
  var valid_603100 = query.getOrDefault("StorageType")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "StorageType", valid_603100
  var valid_603101 = query.getOrDefault("OptionGroupName")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "OptionGroupName", valid_603101
  var valid_603102 = query.getOrDefault("AvailabilityZone")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "AvailabilityZone", valid_603102
  var valid_603103 = query.getOrDefault("Iops")
  valid_603103 = validateParameter(valid_603103, JInt, required = false, default = nil)
  if valid_603103 != nil:
    section.add "Iops", valid_603103
  var valid_603104 = query.getOrDefault("MultiAZ")
  valid_603104 = validateParameter(valid_603104, JBool, required = false, default = nil)
  if valid_603104 != nil:
    section.add "MultiAZ", valid_603104
  var valid_603105 = query.getOrDefault("TdeCredentialPassword")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "TdeCredentialPassword", valid_603105
  var valid_603106 = query.getOrDefault("LicenseModel")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "LicenseModel", valid_603106
  var valid_603107 = query.getOrDefault("Tags")
  valid_603107 = validateParameter(valid_603107, JArray, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "Tags", valid_603107
  var valid_603108 = query.getOrDefault("DBName")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "DBName", valid_603108
  var valid_603109 = query.getOrDefault("DBInstanceClass")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "DBInstanceClass", valid_603109
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603110 = query.getOrDefault("Action")
  valid_603110 = validateParameter(valid_603110, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603110 != nil:
    section.add "Action", valid_603110
  var valid_603111 = query.getOrDefault("DBSubnetGroupName")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "DBSubnetGroupName", valid_603111
  var valid_603112 = query.getOrDefault("TdeCredentialArn")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "TdeCredentialArn", valid_603112
  var valid_603113 = query.getOrDefault("PubliclyAccessible")
  valid_603113 = validateParameter(valid_603113, JBool, required = false, default = nil)
  if valid_603113 != nil:
    section.add "PubliclyAccessible", valid_603113
  var valid_603114 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603114 = validateParameter(valid_603114, JBool, required = false, default = nil)
  if valid_603114 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603114
  var valid_603115 = query.getOrDefault("Port")
  valid_603115 = validateParameter(valid_603115, JInt, required = false, default = nil)
  if valid_603115 != nil:
    section.add "Port", valid_603115
  var valid_603116 = query.getOrDefault("Version")
  valid_603116 = validateParameter(valid_603116, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603116 != nil:
    section.add "Version", valid_603116
  var valid_603117 = query.getOrDefault("DBInstanceIdentifier")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "DBInstanceIdentifier", valid_603117
  var valid_603118 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = nil)
  if valid_603118 != nil:
    section.add "DBSnapshotIdentifier", valid_603118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603119 = header.getOrDefault("X-Amz-Date")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Date", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Content-Sha256", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Signature")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Signature", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-SignedHeaders", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Credential")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Credential", valid_603125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_GetRestoreDBInstanceFromDBSnapshot_603096;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_GetRestoreDBInstanceFromDBSnapshot_603096;
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
  var query_603128 = newJObject()
  add(query_603128, "Engine", newJString(Engine))
  add(query_603128, "StorageType", newJString(StorageType))
  add(query_603128, "OptionGroupName", newJString(OptionGroupName))
  add(query_603128, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603128, "Iops", newJInt(Iops))
  add(query_603128, "MultiAZ", newJBool(MultiAZ))
  add(query_603128, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603128, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603128.add "Tags", Tags
  add(query_603128, "DBName", newJString(DBName))
  add(query_603128, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603128, "Action", newJString(Action))
  add(query_603128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603128, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603128, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603128, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603128, "Port", newJInt(Port))
  add(query_603128, "Version", newJString(Version))
  add(query_603128, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603128, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603127.call(nil, query_603128, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603096(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603097, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603198 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceToPointInTime_603200(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_603199(path: JsonNode;
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
  var valid_603201 = query.getOrDefault("Action")
  valid_603201 = validateParameter(valid_603201, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603201 != nil:
    section.add "Action", valid_603201
  var valid_603202 = query.getOrDefault("Version")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603202 != nil:
    section.add "Version", valid_603202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603203 = header.getOrDefault("X-Amz-Date")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Date", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Security-Token")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Security-Token", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Algorithm")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Algorithm", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Signature")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Signature", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-SignedHeaders", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Credential")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Credential", valid_603209
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
  var valid_603210 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603210 = validateParameter(valid_603210, JBool, required = false, default = nil)
  if valid_603210 != nil:
    section.add "UseLatestRestorableTime", valid_603210
  var valid_603211 = formData.getOrDefault("Port")
  valid_603211 = validateParameter(valid_603211, JInt, required = false, default = nil)
  if valid_603211 != nil:
    section.add "Port", valid_603211
  var valid_603212 = formData.getOrDefault("Engine")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "Engine", valid_603212
  var valid_603213 = formData.getOrDefault("Iops")
  valid_603213 = validateParameter(valid_603213, JInt, required = false, default = nil)
  if valid_603213 != nil:
    section.add "Iops", valid_603213
  var valid_603214 = formData.getOrDefault("DBName")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "DBName", valid_603214
  var valid_603215 = formData.getOrDefault("OptionGroupName")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "OptionGroupName", valid_603215
  var valid_603216 = formData.getOrDefault("Tags")
  valid_603216 = validateParameter(valid_603216, JArray, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "Tags", valid_603216
  var valid_603217 = formData.getOrDefault("TdeCredentialArn")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "TdeCredentialArn", valid_603217
  var valid_603218 = formData.getOrDefault("DBSubnetGroupName")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "DBSubnetGroupName", valid_603218
  var valid_603219 = formData.getOrDefault("TdeCredentialPassword")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "TdeCredentialPassword", valid_603219
  var valid_603220 = formData.getOrDefault("AvailabilityZone")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "AvailabilityZone", valid_603220
  var valid_603221 = formData.getOrDefault("MultiAZ")
  valid_603221 = validateParameter(valid_603221, JBool, required = false, default = nil)
  if valid_603221 != nil:
    section.add "MultiAZ", valid_603221
  var valid_603222 = formData.getOrDefault("RestoreTime")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "RestoreTime", valid_603222
  var valid_603223 = formData.getOrDefault("PubliclyAccessible")
  valid_603223 = validateParameter(valid_603223, JBool, required = false, default = nil)
  if valid_603223 != nil:
    section.add "PubliclyAccessible", valid_603223
  var valid_603224 = formData.getOrDefault("StorageType")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "StorageType", valid_603224
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603225 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603225
  var valid_603226 = formData.getOrDefault("DBInstanceClass")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "DBInstanceClass", valid_603226
  var valid_603227 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603227
  var valid_603228 = formData.getOrDefault("LicenseModel")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "LicenseModel", valid_603228
  var valid_603229 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603229 = validateParameter(valid_603229, JBool, required = false, default = nil)
  if valid_603229 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603230: Call_PostRestoreDBInstanceToPointInTime_603198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603230.validator(path, query, header, formData, body)
  let scheme = call_603230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603230.url(scheme.get, call_603230.host, call_603230.base,
                         call_603230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603230, url, valid)

proc call*(call_603231: Call_PostRestoreDBInstanceToPointInTime_603198;
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
  var query_603232 = newJObject()
  var formData_603233 = newJObject()
  add(formData_603233, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603233, "Port", newJInt(Port))
  add(formData_603233, "Engine", newJString(Engine))
  add(formData_603233, "Iops", newJInt(Iops))
  add(formData_603233, "DBName", newJString(DBName))
  add(formData_603233, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603233.add "Tags", Tags
  add(formData_603233, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603233, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603233, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603233, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603233, "MultiAZ", newJBool(MultiAZ))
  add(query_603232, "Action", newJString(Action))
  add(formData_603233, "RestoreTime", newJString(RestoreTime))
  add(formData_603233, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603233, "StorageType", newJString(StorageType))
  add(formData_603233, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603233, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603233, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603233, "LicenseModel", newJString(LicenseModel))
  add(formData_603233, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603232, "Version", newJString(Version))
  result = call_603231.call(nil, query_603232, nil, formData_603233, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603198(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603199, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603163 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceToPointInTime_603165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_603164(path: JsonNode;
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
  var valid_603166 = query.getOrDefault("Engine")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "Engine", valid_603166
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603167 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = nil)
  if valid_603167 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603167
  var valid_603168 = query.getOrDefault("StorageType")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "StorageType", valid_603168
  var valid_603169 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603169
  var valid_603170 = query.getOrDefault("AvailabilityZone")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "AvailabilityZone", valid_603170
  var valid_603171 = query.getOrDefault("Iops")
  valid_603171 = validateParameter(valid_603171, JInt, required = false, default = nil)
  if valid_603171 != nil:
    section.add "Iops", valid_603171
  var valid_603172 = query.getOrDefault("OptionGroupName")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "OptionGroupName", valid_603172
  var valid_603173 = query.getOrDefault("RestoreTime")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "RestoreTime", valid_603173
  var valid_603174 = query.getOrDefault("MultiAZ")
  valid_603174 = validateParameter(valid_603174, JBool, required = false, default = nil)
  if valid_603174 != nil:
    section.add "MultiAZ", valid_603174
  var valid_603175 = query.getOrDefault("TdeCredentialPassword")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "TdeCredentialPassword", valid_603175
  var valid_603176 = query.getOrDefault("LicenseModel")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "LicenseModel", valid_603176
  var valid_603177 = query.getOrDefault("Tags")
  valid_603177 = validateParameter(valid_603177, JArray, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "Tags", valid_603177
  var valid_603178 = query.getOrDefault("DBName")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "DBName", valid_603178
  var valid_603179 = query.getOrDefault("DBInstanceClass")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "DBInstanceClass", valid_603179
  var valid_603180 = query.getOrDefault("Action")
  valid_603180 = validateParameter(valid_603180, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603180 != nil:
    section.add "Action", valid_603180
  var valid_603181 = query.getOrDefault("UseLatestRestorableTime")
  valid_603181 = validateParameter(valid_603181, JBool, required = false, default = nil)
  if valid_603181 != nil:
    section.add "UseLatestRestorableTime", valid_603181
  var valid_603182 = query.getOrDefault("DBSubnetGroupName")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "DBSubnetGroupName", valid_603182
  var valid_603183 = query.getOrDefault("TdeCredentialArn")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "TdeCredentialArn", valid_603183
  var valid_603184 = query.getOrDefault("PubliclyAccessible")
  valid_603184 = validateParameter(valid_603184, JBool, required = false, default = nil)
  if valid_603184 != nil:
    section.add "PubliclyAccessible", valid_603184
  var valid_603185 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603185 = validateParameter(valid_603185, JBool, required = false, default = nil)
  if valid_603185 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603185
  var valid_603186 = query.getOrDefault("Port")
  valid_603186 = validateParameter(valid_603186, JInt, required = false, default = nil)
  if valid_603186 != nil:
    section.add "Port", valid_603186
  var valid_603187 = query.getOrDefault("Version")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603187 != nil:
    section.add "Version", valid_603187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603188 = header.getOrDefault("X-Amz-Date")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Date", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Algorithm")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Algorithm", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Signature")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Signature", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-SignedHeaders", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Credential")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Credential", valid_603194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603195: Call_GetRestoreDBInstanceToPointInTime_603163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603195.validator(path, query, header, formData, body)
  let scheme = call_603195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603195.url(scheme.get, call_603195.host, call_603195.base,
                         call_603195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603195, url, valid)

proc call*(call_603196: Call_GetRestoreDBInstanceToPointInTime_603163;
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
  var query_603197 = newJObject()
  add(query_603197, "Engine", newJString(Engine))
  add(query_603197, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603197, "StorageType", newJString(StorageType))
  add(query_603197, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603197, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603197, "Iops", newJInt(Iops))
  add(query_603197, "OptionGroupName", newJString(OptionGroupName))
  add(query_603197, "RestoreTime", newJString(RestoreTime))
  add(query_603197, "MultiAZ", newJBool(MultiAZ))
  add(query_603197, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603197, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603197.add "Tags", Tags
  add(query_603197, "DBName", newJString(DBName))
  add(query_603197, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603197, "Action", newJString(Action))
  add(query_603197, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603197, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603197, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603197, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603197, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603197, "Port", newJInt(Port))
  add(query_603197, "Version", newJString(Version))
  result = call_603196.call(nil, query_603197, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603163(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603164, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603254 = ref object of OpenApiRestCall_600421
proc url_PostRevokeDBSecurityGroupIngress_603256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_603255(path: JsonNode;
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
  var valid_603257 = query.getOrDefault("Action")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603257 != nil:
    section.add "Action", valid_603257
  var valid_603258 = query.getOrDefault("Version")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603258 != nil:
    section.add "Version", valid_603258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603266 = formData.getOrDefault("DBSecurityGroupName")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "DBSecurityGroupName", valid_603266
  var valid_603267 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "EC2SecurityGroupName", valid_603267
  var valid_603268 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "EC2SecurityGroupId", valid_603268
  var valid_603269 = formData.getOrDefault("CIDRIP")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "CIDRIP", valid_603269
  var valid_603270 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603271: Call_PostRevokeDBSecurityGroupIngress_603254;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603271.validator(path, query, header, formData, body)
  let scheme = call_603271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603271.url(scheme.get, call_603271.host, call_603271.base,
                         call_603271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603271, url, valid)

proc call*(call_603272: Call_PostRevokeDBSecurityGroupIngress_603254;
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
  var query_603273 = newJObject()
  var formData_603274 = newJObject()
  add(formData_603274, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603273, "Action", newJString(Action))
  add(formData_603274, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603274, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603274, "CIDRIP", newJString(CIDRIP))
  add(query_603273, "Version", newJString(Version))
  add(formData_603274, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603272.call(nil, query_603273, nil, formData_603274, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603254(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603255, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603234 = ref object of OpenApiRestCall_600421
proc url_GetRevokeDBSecurityGroupIngress_603236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_603235(path: JsonNode;
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
  var valid_603237 = query.getOrDefault("EC2SecurityGroupId")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "EC2SecurityGroupId", valid_603237
  var valid_603238 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603238
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603239 = query.getOrDefault("DBSecurityGroupName")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = nil)
  if valid_603239 != nil:
    section.add "DBSecurityGroupName", valid_603239
  var valid_603240 = query.getOrDefault("Action")
  valid_603240 = validateParameter(valid_603240, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603240 != nil:
    section.add "Action", valid_603240
  var valid_603241 = query.getOrDefault("CIDRIP")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "CIDRIP", valid_603241
  var valid_603242 = query.getOrDefault("EC2SecurityGroupName")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "EC2SecurityGroupName", valid_603242
  var valid_603243 = query.getOrDefault("Version")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603243 != nil:
    section.add "Version", valid_603243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Content-Sha256", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Algorithm")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Algorithm", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Signature")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Signature", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-SignedHeaders", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Credential")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Credential", valid_603250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_GetRevokeDBSecurityGroupIngress_603234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_GetRevokeDBSecurityGroupIngress_603234;
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
  var query_603253 = newJObject()
  add(query_603253, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603253, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603253, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603253, "Action", newJString(Action))
  add(query_603253, "CIDRIP", newJString(CIDRIP))
  add(query_603253, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603253, "Version", newJString(Version))
  result = call_603252.call(nil, query_603253, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603234(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603235, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603236,
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

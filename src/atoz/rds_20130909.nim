
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_601142 = ref object of OpenApiRestCall_600421
proc url_PostCopyDBSnapshot_601144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_601143(path: JsonNode; query: JsonNode;
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
  var valid_601145 = query.getOrDefault("Action")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601145 != nil:
    section.add "Action", valid_601145
  var valid_601146 = query.getOrDefault("Version")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601146 != nil:
    section.add "Version", valid_601146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Content-Sha256", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Algorithm")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Algorithm", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Signature")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Signature", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-SignedHeaders", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Credential")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Credential", valid_601153
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601154 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601154 = validateParameter(valid_601154, JString, required = true,
                                 default = nil)
  if valid_601154 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601154
  var valid_601155 = formData.getOrDefault("Tags")
  valid_601155 = validateParameter(valid_601155, JArray, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "Tags", valid_601155
  var valid_601156 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601156
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601157: Call_PostCopyDBSnapshot_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601157.validator(path, query, header, formData, body)
  let scheme = call_601157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601157.url(scheme.get, call_601157.host, call_601157.base,
                         call_601157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601157, url, valid)

proc call*(call_601158: Call_PostCopyDBSnapshot_601142;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601159 = newJObject()
  var formData_601160 = newJObject()
  add(formData_601160, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_601160.add "Tags", Tags
  add(query_601159, "Action", newJString(Action))
  add(formData_601160, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601159, "Version", newJString(Version))
  result = call_601158.call(nil, query_601159, nil, formData_601160, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601142(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601143, base: "/",
    url: url_PostCopyDBSnapshot_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_601124 = ref object of OpenApiRestCall_600421
proc url_GetCopyDBSnapshot_601126(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_601125(path: JsonNode; query: JsonNode;
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
  var valid_601127 = query.getOrDefault("Tags")
  valid_601127 = validateParameter(valid_601127, JArray, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Tags", valid_601127
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601128 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = nil)
  if valid_601128 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601128
  var valid_601129 = query.getOrDefault("Action")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601129 != nil:
    section.add "Action", valid_601129
  var valid_601130 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = nil)
  if valid_601130 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601130
  var valid_601131 = query.getOrDefault("Version")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601131 != nil:
    section.add "Version", valid_601131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601132 = header.getOrDefault("X-Amz-Date")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Date", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Security-Token")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Security-Token", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Content-Sha256", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Algorithm")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Algorithm", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Signature")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Signature", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-SignedHeaders", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Credential")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Credential", valid_601138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_GetCopyDBSnapshot_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_GetCopyDBSnapshot_601124;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601141 = newJObject()
  if Tags != nil:
    query_601141.add "Tags", Tags
  add(query_601141, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601141, "Action", newJString(Action))
  add(query_601141, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601141, "Version", newJString(Version))
  result = call_601140.call(nil, query_601141, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601124(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601125,
    base: "/", url: url_GetCopyDBSnapshot_601126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601201 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstance_601203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_601202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601204 = query.getOrDefault("Action")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601204 != nil:
    section.add "Action", valid_601204
  var valid_601205 = query.getOrDefault("Version")
  valid_601205 = validateParameter(valid_601205, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601205 != nil:
    section.add "Version", valid_601205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601206 = header.getOrDefault("X-Amz-Date")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Date", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Security-Token")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Security-Token", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
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
  var valid_601213 = formData.getOrDefault("DBSecurityGroups")
  valid_601213 = validateParameter(valid_601213, JArray, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "DBSecurityGroups", valid_601213
  var valid_601214 = formData.getOrDefault("Port")
  valid_601214 = validateParameter(valid_601214, JInt, required = false, default = nil)
  if valid_601214 != nil:
    section.add "Port", valid_601214
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601215 = formData.getOrDefault("Engine")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "Engine", valid_601215
  var valid_601216 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601216 = validateParameter(valid_601216, JArray, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "VpcSecurityGroupIds", valid_601216
  var valid_601217 = formData.getOrDefault("Iops")
  valid_601217 = validateParameter(valid_601217, JInt, required = false, default = nil)
  if valid_601217 != nil:
    section.add "Iops", valid_601217
  var valid_601218 = formData.getOrDefault("DBName")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "DBName", valid_601218
  var valid_601219 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601219 = validateParameter(valid_601219, JString, required = true,
                                 default = nil)
  if valid_601219 != nil:
    section.add "DBInstanceIdentifier", valid_601219
  var valid_601220 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601220 = validateParameter(valid_601220, JInt, required = false, default = nil)
  if valid_601220 != nil:
    section.add "BackupRetentionPeriod", valid_601220
  var valid_601221 = formData.getOrDefault("DBParameterGroupName")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "DBParameterGroupName", valid_601221
  var valid_601222 = formData.getOrDefault("OptionGroupName")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "OptionGroupName", valid_601222
  var valid_601223 = formData.getOrDefault("Tags")
  valid_601223 = validateParameter(valid_601223, JArray, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "Tags", valid_601223
  var valid_601224 = formData.getOrDefault("MasterUserPassword")
  valid_601224 = validateParameter(valid_601224, JString, required = true,
                                 default = nil)
  if valid_601224 != nil:
    section.add "MasterUserPassword", valid_601224
  var valid_601225 = formData.getOrDefault("DBSubnetGroupName")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "DBSubnetGroupName", valid_601225
  var valid_601226 = formData.getOrDefault("AvailabilityZone")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "AvailabilityZone", valid_601226
  var valid_601227 = formData.getOrDefault("MultiAZ")
  valid_601227 = validateParameter(valid_601227, JBool, required = false, default = nil)
  if valid_601227 != nil:
    section.add "MultiAZ", valid_601227
  var valid_601228 = formData.getOrDefault("AllocatedStorage")
  valid_601228 = validateParameter(valid_601228, JInt, required = true, default = nil)
  if valid_601228 != nil:
    section.add "AllocatedStorage", valid_601228
  var valid_601229 = formData.getOrDefault("PubliclyAccessible")
  valid_601229 = validateParameter(valid_601229, JBool, required = false, default = nil)
  if valid_601229 != nil:
    section.add "PubliclyAccessible", valid_601229
  var valid_601230 = formData.getOrDefault("MasterUsername")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "MasterUsername", valid_601230
  var valid_601231 = formData.getOrDefault("DBInstanceClass")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "DBInstanceClass", valid_601231
  var valid_601232 = formData.getOrDefault("CharacterSetName")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "CharacterSetName", valid_601232
  var valid_601233 = formData.getOrDefault("PreferredBackupWindow")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "PreferredBackupWindow", valid_601233
  var valid_601234 = formData.getOrDefault("LicenseModel")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "LicenseModel", valid_601234
  var valid_601235 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601235 = validateParameter(valid_601235, JBool, required = false, default = nil)
  if valid_601235 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601235
  var valid_601236 = formData.getOrDefault("EngineVersion")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "EngineVersion", valid_601236
  var valid_601237 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "PreferredMaintenanceWindow", valid_601237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601238: Call_PostCreateDBInstance_601201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601238.validator(path, query, header, formData, body)
  let scheme = call_601238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601238.url(scheme.get, call_601238.host, call_601238.base,
                         call_601238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601238, url, valid)

proc call*(call_601239: Call_PostCreateDBInstance_601201; Engine: string;
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
  var query_601240 = newJObject()
  var formData_601241 = newJObject()
  if DBSecurityGroups != nil:
    formData_601241.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601241, "Port", newJInt(Port))
  add(formData_601241, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601241.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601241, "Iops", newJInt(Iops))
  add(formData_601241, "DBName", newJString(DBName))
  add(formData_601241, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601241, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601241, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601241, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601241.add "Tags", Tags
  add(formData_601241, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601241, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601241, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601241, "MultiAZ", newJBool(MultiAZ))
  add(query_601240, "Action", newJString(Action))
  add(formData_601241, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601241, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601241, "MasterUsername", newJString(MasterUsername))
  add(formData_601241, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601241, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601241, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601241, "LicenseModel", newJString(LicenseModel))
  add(formData_601241, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601241, "EngineVersion", newJString(EngineVersion))
  add(query_601240, "Version", newJString(Version))
  add(formData_601241, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601239.call(nil, query_601240, nil, formData_601241, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601201(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601202, base: "/",
    url: url_PostCreateDBInstance_601203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601161 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstance_601163(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_601162(path: JsonNode; query: JsonNode;
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
  var valid_601164 = query.getOrDefault("Engine")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = nil)
  if valid_601164 != nil:
    section.add "Engine", valid_601164
  var valid_601165 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "PreferredMaintenanceWindow", valid_601165
  var valid_601166 = query.getOrDefault("AllocatedStorage")
  valid_601166 = validateParameter(valid_601166, JInt, required = true, default = nil)
  if valid_601166 != nil:
    section.add "AllocatedStorage", valid_601166
  var valid_601167 = query.getOrDefault("OptionGroupName")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "OptionGroupName", valid_601167
  var valid_601168 = query.getOrDefault("DBSecurityGroups")
  valid_601168 = validateParameter(valid_601168, JArray, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "DBSecurityGroups", valid_601168
  var valid_601169 = query.getOrDefault("MasterUserPassword")
  valid_601169 = validateParameter(valid_601169, JString, required = true,
                                 default = nil)
  if valid_601169 != nil:
    section.add "MasterUserPassword", valid_601169
  var valid_601170 = query.getOrDefault("AvailabilityZone")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "AvailabilityZone", valid_601170
  var valid_601171 = query.getOrDefault("Iops")
  valid_601171 = validateParameter(valid_601171, JInt, required = false, default = nil)
  if valid_601171 != nil:
    section.add "Iops", valid_601171
  var valid_601172 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601172 = validateParameter(valid_601172, JArray, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "VpcSecurityGroupIds", valid_601172
  var valid_601173 = query.getOrDefault("MultiAZ")
  valid_601173 = validateParameter(valid_601173, JBool, required = false, default = nil)
  if valid_601173 != nil:
    section.add "MultiAZ", valid_601173
  var valid_601174 = query.getOrDefault("LicenseModel")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "LicenseModel", valid_601174
  var valid_601175 = query.getOrDefault("BackupRetentionPeriod")
  valid_601175 = validateParameter(valid_601175, JInt, required = false, default = nil)
  if valid_601175 != nil:
    section.add "BackupRetentionPeriod", valid_601175
  var valid_601176 = query.getOrDefault("DBName")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "DBName", valid_601176
  var valid_601177 = query.getOrDefault("DBParameterGroupName")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "DBParameterGroupName", valid_601177
  var valid_601178 = query.getOrDefault("Tags")
  valid_601178 = validateParameter(valid_601178, JArray, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "Tags", valid_601178
  var valid_601179 = query.getOrDefault("DBInstanceClass")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "DBInstanceClass", valid_601179
  var valid_601180 = query.getOrDefault("Action")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601180 != nil:
    section.add "Action", valid_601180
  var valid_601181 = query.getOrDefault("DBSubnetGroupName")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "DBSubnetGroupName", valid_601181
  var valid_601182 = query.getOrDefault("CharacterSetName")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "CharacterSetName", valid_601182
  var valid_601183 = query.getOrDefault("PubliclyAccessible")
  valid_601183 = validateParameter(valid_601183, JBool, required = false, default = nil)
  if valid_601183 != nil:
    section.add "PubliclyAccessible", valid_601183
  var valid_601184 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601184 = validateParameter(valid_601184, JBool, required = false, default = nil)
  if valid_601184 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601184
  var valid_601185 = query.getOrDefault("EngineVersion")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "EngineVersion", valid_601185
  var valid_601186 = query.getOrDefault("Port")
  valid_601186 = validateParameter(valid_601186, JInt, required = false, default = nil)
  if valid_601186 != nil:
    section.add "Port", valid_601186
  var valid_601187 = query.getOrDefault("PreferredBackupWindow")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "PreferredBackupWindow", valid_601187
  var valid_601188 = query.getOrDefault("Version")
  valid_601188 = validateParameter(valid_601188, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601188 != nil:
    section.add "Version", valid_601188
  var valid_601189 = query.getOrDefault("DBInstanceIdentifier")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "DBInstanceIdentifier", valid_601189
  var valid_601190 = query.getOrDefault("MasterUsername")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "MasterUsername", valid_601190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601191 = header.getOrDefault("X-Amz-Date")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Date", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Security-Token")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Security-Token", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601198: Call_GetCreateDBInstance_601161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601198.validator(path, query, header, formData, body)
  let scheme = call_601198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601198.url(scheme.get, call_601198.host, call_601198.base,
                         call_601198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601198, url, valid)

proc call*(call_601199: Call_GetCreateDBInstance_601161; Engine: string;
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
  var query_601200 = newJObject()
  add(query_601200, "Engine", newJString(Engine))
  add(query_601200, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601200, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601200, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601200.add "DBSecurityGroups", DBSecurityGroups
  add(query_601200, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601200, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601200, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601200.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601200, "MultiAZ", newJBool(MultiAZ))
  add(query_601200, "LicenseModel", newJString(LicenseModel))
  add(query_601200, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601200, "DBName", newJString(DBName))
  add(query_601200, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_601200.add "Tags", Tags
  add(query_601200, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601200, "Action", newJString(Action))
  add(query_601200, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601200, "CharacterSetName", newJString(CharacterSetName))
  add(query_601200, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601200, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601200, "EngineVersion", newJString(EngineVersion))
  add(query_601200, "Port", newJInt(Port))
  add(query_601200, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601200, "Version", newJString(Version))
  add(query_601200, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601200, "MasterUsername", newJString(MasterUsername))
  result = call_601199.call(nil, query_601200, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601161(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601162, base: "/",
    url: url_GetCreateDBInstance_601163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601268 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBInstanceReadReplica_601270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_601269(path: JsonNode;
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
  var valid_601271 = query.getOrDefault("Action")
  valid_601271 = validateParameter(valid_601271, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601271 != nil:
    section.add "Action", valid_601271
  var valid_601272 = query.getOrDefault("Version")
  valid_601272 = validateParameter(valid_601272, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601272 != nil:
    section.add "Version", valid_601272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601273 = header.getOrDefault("X-Amz-Date")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Date", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Security-Token")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Security-Token", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
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
  var valid_601280 = formData.getOrDefault("Port")
  valid_601280 = validateParameter(valid_601280, JInt, required = false, default = nil)
  if valid_601280 != nil:
    section.add "Port", valid_601280
  var valid_601281 = formData.getOrDefault("Iops")
  valid_601281 = validateParameter(valid_601281, JInt, required = false, default = nil)
  if valid_601281 != nil:
    section.add "Iops", valid_601281
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601282 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601282 = validateParameter(valid_601282, JString, required = true,
                                 default = nil)
  if valid_601282 != nil:
    section.add "DBInstanceIdentifier", valid_601282
  var valid_601283 = formData.getOrDefault("OptionGroupName")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "OptionGroupName", valid_601283
  var valid_601284 = formData.getOrDefault("Tags")
  valid_601284 = validateParameter(valid_601284, JArray, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "Tags", valid_601284
  var valid_601285 = formData.getOrDefault("DBSubnetGroupName")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "DBSubnetGroupName", valid_601285
  var valid_601286 = formData.getOrDefault("AvailabilityZone")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "AvailabilityZone", valid_601286
  var valid_601287 = formData.getOrDefault("PubliclyAccessible")
  valid_601287 = validateParameter(valid_601287, JBool, required = false, default = nil)
  if valid_601287 != nil:
    section.add "PubliclyAccessible", valid_601287
  var valid_601288 = formData.getOrDefault("DBInstanceClass")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "DBInstanceClass", valid_601288
  var valid_601289 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = nil)
  if valid_601289 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601289
  var valid_601290 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601290 = validateParameter(valid_601290, JBool, required = false, default = nil)
  if valid_601290 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601291: Call_PostCreateDBInstanceReadReplica_601268;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601291.validator(path, query, header, formData, body)
  let scheme = call_601291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601291.url(scheme.get, call_601291.host, call_601291.base,
                         call_601291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601291, url, valid)

proc call*(call_601292: Call_PostCreateDBInstanceReadReplica_601268;
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
  var query_601293 = newJObject()
  var formData_601294 = newJObject()
  add(formData_601294, "Port", newJInt(Port))
  add(formData_601294, "Iops", newJInt(Iops))
  add(formData_601294, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601294, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601294.add "Tags", Tags
  add(formData_601294, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601294, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601293, "Action", newJString(Action))
  add(formData_601294, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601294, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601294, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601294, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601293, "Version", newJString(Version))
  result = call_601292.call(nil, query_601293, nil, formData_601294, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601268(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601269, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601242 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBInstanceReadReplica_601244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_601243(path: JsonNode;
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
  var valid_601245 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601245
  var valid_601246 = query.getOrDefault("OptionGroupName")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "OptionGroupName", valid_601246
  var valid_601247 = query.getOrDefault("AvailabilityZone")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "AvailabilityZone", valid_601247
  var valid_601248 = query.getOrDefault("Iops")
  valid_601248 = validateParameter(valid_601248, JInt, required = false, default = nil)
  if valid_601248 != nil:
    section.add "Iops", valid_601248
  var valid_601249 = query.getOrDefault("Tags")
  valid_601249 = validateParameter(valid_601249, JArray, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "Tags", valid_601249
  var valid_601250 = query.getOrDefault("DBInstanceClass")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "DBInstanceClass", valid_601250
  var valid_601251 = query.getOrDefault("Action")
  valid_601251 = validateParameter(valid_601251, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601251 != nil:
    section.add "Action", valid_601251
  var valid_601252 = query.getOrDefault("DBSubnetGroupName")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "DBSubnetGroupName", valid_601252
  var valid_601253 = query.getOrDefault("PubliclyAccessible")
  valid_601253 = validateParameter(valid_601253, JBool, required = false, default = nil)
  if valid_601253 != nil:
    section.add "PubliclyAccessible", valid_601253
  var valid_601254 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601254 = validateParameter(valid_601254, JBool, required = false, default = nil)
  if valid_601254 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601254
  var valid_601255 = query.getOrDefault("Port")
  valid_601255 = validateParameter(valid_601255, JInt, required = false, default = nil)
  if valid_601255 != nil:
    section.add "Port", valid_601255
  var valid_601256 = query.getOrDefault("Version")
  valid_601256 = validateParameter(valid_601256, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601256 != nil:
    section.add "Version", valid_601256
  var valid_601257 = query.getOrDefault("DBInstanceIdentifier")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = nil)
  if valid_601257 != nil:
    section.add "DBInstanceIdentifier", valid_601257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601258 = header.getOrDefault("X-Amz-Date")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Date", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Security-Token")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Security-Token", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601265: Call_GetCreateDBInstanceReadReplica_601242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601265.validator(path, query, header, formData, body)
  let scheme = call_601265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601265.url(scheme.get, call_601265.host, call_601265.base,
                         call_601265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601265, url, valid)

proc call*(call_601266: Call_GetCreateDBInstanceReadReplica_601242;
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
  var query_601267 = newJObject()
  add(query_601267, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601267, "OptionGroupName", newJString(OptionGroupName))
  add(query_601267, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601267, "Iops", newJInt(Iops))
  if Tags != nil:
    query_601267.add "Tags", Tags
  add(query_601267, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601267, "Action", newJString(Action))
  add(query_601267, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601267, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601267, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601267, "Port", newJInt(Port))
  add(query_601267, "Version", newJString(Version))
  add(query_601267, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601266.call(nil, query_601267, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601242(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601243, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601314 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBParameterGroup_601316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_601315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601317 = query.getOrDefault("Action")
  valid_601317 = validateParameter(valid_601317, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601317 != nil:
    section.add "Action", valid_601317
  var valid_601318 = query.getOrDefault("Version")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601318 != nil:
    section.add "Version", valid_601318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601319 = header.getOrDefault("X-Amz-Date")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Date", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Security-Token")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Security-Token", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Content-Sha256", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Algorithm")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Algorithm", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Signature")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Signature", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-SignedHeaders", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Credential")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Credential", valid_601325
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601326 = formData.getOrDefault("DBParameterGroupName")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "DBParameterGroupName", valid_601326
  var valid_601327 = formData.getOrDefault("Tags")
  valid_601327 = validateParameter(valid_601327, JArray, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "Tags", valid_601327
  var valid_601328 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "DBParameterGroupFamily", valid_601328
  var valid_601329 = formData.getOrDefault("Description")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = nil)
  if valid_601329 != nil:
    section.add "Description", valid_601329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601330: Call_PostCreateDBParameterGroup_601314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601330.validator(path, query, header, formData, body)
  let scheme = call_601330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601330.url(scheme.get, call_601330.host, call_601330.base,
                         call_601330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601330, url, valid)

proc call*(call_601331: Call_PostCreateDBParameterGroup_601314;
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
  var query_601332 = newJObject()
  var formData_601333 = newJObject()
  add(formData_601333, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_601333.add "Tags", Tags
  add(query_601332, "Action", newJString(Action))
  add(formData_601333, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601332, "Version", newJString(Version))
  add(formData_601333, "Description", newJString(Description))
  result = call_601331.call(nil, query_601332, nil, formData_601333, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601314(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601315, base: "/",
    url: url_PostCreateDBParameterGroup_601316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601295 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBParameterGroup_601297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_601296(path: JsonNode; query: JsonNode;
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
  var valid_601298 = query.getOrDefault("Description")
  valid_601298 = validateParameter(valid_601298, JString, required = true,
                                 default = nil)
  if valid_601298 != nil:
    section.add "Description", valid_601298
  var valid_601299 = query.getOrDefault("DBParameterGroupFamily")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = nil)
  if valid_601299 != nil:
    section.add "DBParameterGroupFamily", valid_601299
  var valid_601300 = query.getOrDefault("Tags")
  valid_601300 = validateParameter(valid_601300, JArray, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "Tags", valid_601300
  var valid_601301 = query.getOrDefault("DBParameterGroupName")
  valid_601301 = validateParameter(valid_601301, JString, required = true,
                                 default = nil)
  if valid_601301 != nil:
    section.add "DBParameterGroupName", valid_601301
  var valid_601302 = query.getOrDefault("Action")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601302 != nil:
    section.add "Action", valid_601302
  var valid_601303 = query.getOrDefault("Version")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601303 != nil:
    section.add "Version", valid_601303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601304 = header.getOrDefault("X-Amz-Date")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Date", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Security-Token")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Security-Token", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Content-Sha256", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Algorithm")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Algorithm", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Signature")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Signature", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-SignedHeaders", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Credential")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Credential", valid_601310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601311: Call_GetCreateDBParameterGroup_601295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601311.validator(path, query, header, formData, body)
  let scheme = call_601311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601311.url(scheme.get, call_601311.host, call_601311.base,
                         call_601311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601311, url, valid)

proc call*(call_601312: Call_GetCreateDBParameterGroup_601295; Description: string;
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
  var query_601313 = newJObject()
  add(query_601313, "Description", newJString(Description))
  add(query_601313, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_601313.add "Tags", Tags
  add(query_601313, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601313, "Action", newJString(Action))
  add(query_601313, "Version", newJString(Version))
  result = call_601312.call(nil, query_601313, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601295(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601296, base: "/",
    url: url_GetCreateDBParameterGroup_601297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601352 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSecurityGroup_601354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_601353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601355 = query.getOrDefault("Action")
  valid_601355 = validateParameter(valid_601355, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601355 != nil:
    section.add "Action", valid_601355
  var valid_601356 = query.getOrDefault("Version")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601356 != nil:
    section.add "Version", valid_601356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601364 = formData.getOrDefault("DBSecurityGroupName")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = nil)
  if valid_601364 != nil:
    section.add "DBSecurityGroupName", valid_601364
  var valid_601365 = formData.getOrDefault("Tags")
  valid_601365 = validateParameter(valid_601365, JArray, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "Tags", valid_601365
  var valid_601366 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = nil)
  if valid_601366 != nil:
    section.add "DBSecurityGroupDescription", valid_601366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601367: Call_PostCreateDBSecurityGroup_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601367.validator(path, query, header, formData, body)
  let scheme = call_601367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601367.url(scheme.get, call_601367.host, call_601367.base,
                         call_601367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601367, url, valid)

proc call*(call_601368: Call_PostCreateDBSecurityGroup_601352;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601369 = newJObject()
  var formData_601370 = newJObject()
  add(formData_601370, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_601370.add "Tags", Tags
  add(query_601369, "Action", newJString(Action))
  add(formData_601370, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601369, "Version", newJString(Version))
  result = call_601368.call(nil, query_601369, nil, formData_601370, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601352(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601353, base: "/",
    url: url_PostCreateDBSecurityGroup_601354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601334 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSecurityGroup_601336(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_601335(path: JsonNode; query: JsonNode;
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
  var valid_601337 = query.getOrDefault("DBSecurityGroupName")
  valid_601337 = validateParameter(valid_601337, JString, required = true,
                                 default = nil)
  if valid_601337 != nil:
    section.add "DBSecurityGroupName", valid_601337
  var valid_601338 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = nil)
  if valid_601338 != nil:
    section.add "DBSecurityGroupDescription", valid_601338
  var valid_601339 = query.getOrDefault("Tags")
  valid_601339 = validateParameter(valid_601339, JArray, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "Tags", valid_601339
  var valid_601340 = query.getOrDefault("Action")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601340 != nil:
    section.add "Action", valid_601340
  var valid_601341 = query.getOrDefault("Version")
  valid_601341 = validateParameter(valid_601341, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601341 != nil:
    section.add "Version", valid_601341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601342 = header.getOrDefault("X-Amz-Date")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Date", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Security-Token")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Security-Token", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_GetCreateDBSecurityGroup_601334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_GetCreateDBSecurityGroup_601334;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601351 = newJObject()
  add(query_601351, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601351, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_601351.add "Tags", Tags
  add(query_601351, "Action", newJString(Action))
  add(query_601351, "Version", newJString(Version))
  result = call_601350.call(nil, query_601351, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601334(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601335, base: "/",
    url: url_GetCreateDBSecurityGroup_601336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601389 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSnapshot_601391(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_601390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601392 = query.getOrDefault("Action")
  valid_601392 = validateParameter(valid_601392, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601392 != nil:
    section.add "Action", valid_601392
  var valid_601393 = query.getOrDefault("Version")
  valid_601393 = validateParameter(valid_601393, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601393 != nil:
    section.add "Version", valid_601393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601394 = header.getOrDefault("X-Amz-Date")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Date", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Security-Token")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Security-Token", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Content-Sha256", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Algorithm")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Algorithm", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Signature")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Signature", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-SignedHeaders", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Credential")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Credential", valid_601400
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601401 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601401 = validateParameter(valid_601401, JString, required = true,
                                 default = nil)
  if valid_601401 != nil:
    section.add "DBInstanceIdentifier", valid_601401
  var valid_601402 = formData.getOrDefault("Tags")
  valid_601402 = validateParameter(valid_601402, JArray, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "Tags", valid_601402
  var valid_601403 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601403 = validateParameter(valid_601403, JString, required = true,
                                 default = nil)
  if valid_601403 != nil:
    section.add "DBSnapshotIdentifier", valid_601403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601404: Call_PostCreateDBSnapshot_601389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601404.validator(path, query, header, formData, body)
  let scheme = call_601404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601404.url(scheme.get, call_601404.host, call_601404.base,
                         call_601404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601404, url, valid)

proc call*(call_601405: Call_PostCreateDBSnapshot_601389;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601406 = newJObject()
  var formData_601407 = newJObject()
  add(formData_601407, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_601407.add "Tags", Tags
  add(formData_601407, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601406, "Action", newJString(Action))
  add(query_601406, "Version", newJString(Version))
  result = call_601405.call(nil, query_601406, nil, formData_601407, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601389(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601390, base: "/",
    url: url_PostCreateDBSnapshot_601391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601371 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSnapshot_601373(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_601372(path: JsonNode; query: JsonNode;
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
  var valid_601374 = query.getOrDefault("Tags")
  valid_601374 = validateParameter(valid_601374, JArray, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "Tags", valid_601374
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601375 = query.getOrDefault("Action")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601375 != nil:
    section.add "Action", valid_601375
  var valid_601376 = query.getOrDefault("Version")
  valid_601376 = validateParameter(valid_601376, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601376 != nil:
    section.add "Version", valid_601376
  var valid_601377 = query.getOrDefault("DBInstanceIdentifier")
  valid_601377 = validateParameter(valid_601377, JString, required = true,
                                 default = nil)
  if valid_601377 != nil:
    section.add "DBInstanceIdentifier", valid_601377
  var valid_601378 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = nil)
  if valid_601378 != nil:
    section.add "DBSnapshotIdentifier", valid_601378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601379 = header.getOrDefault("X-Amz-Date")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Date", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Security-Token")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Security-Token", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Content-Sha256", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Algorithm")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Algorithm", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Signature")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Signature", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-SignedHeaders", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Credential")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Credential", valid_601385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601386: Call_GetCreateDBSnapshot_601371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601386.validator(path, query, header, formData, body)
  let scheme = call_601386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601386.url(scheme.get, call_601386.host, call_601386.base,
                         call_601386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601386, url, valid)

proc call*(call_601387: Call_GetCreateDBSnapshot_601371;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601388 = newJObject()
  if Tags != nil:
    query_601388.add "Tags", Tags
  add(query_601388, "Action", newJString(Action))
  add(query_601388, "Version", newJString(Version))
  add(query_601388, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601388, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601387.call(nil, query_601388, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601371(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601372, base: "/",
    url: url_GetCreateDBSnapshot_601373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601427 = ref object of OpenApiRestCall_600421
proc url_PostCreateDBSubnetGroup_601429(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_601428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601430 = query.getOrDefault("Action")
  valid_601430 = validateParameter(valid_601430, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601430 != nil:
    section.add "Action", valid_601430
  var valid_601431 = query.getOrDefault("Version")
  valid_601431 = validateParameter(valid_601431, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601431 != nil:
    section.add "Version", valid_601431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601432 = header.getOrDefault("X-Amz-Date")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Date", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Security-Token")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Security-Token", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Content-Sha256", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Algorithm")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Algorithm", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Signature")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Signature", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-SignedHeaders", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Credential")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Credential", valid_601438
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_601439 = formData.getOrDefault("Tags")
  valid_601439 = validateParameter(valid_601439, JArray, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "Tags", valid_601439
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601440 = formData.getOrDefault("DBSubnetGroupName")
  valid_601440 = validateParameter(valid_601440, JString, required = true,
                                 default = nil)
  if valid_601440 != nil:
    section.add "DBSubnetGroupName", valid_601440
  var valid_601441 = formData.getOrDefault("SubnetIds")
  valid_601441 = validateParameter(valid_601441, JArray, required = true, default = nil)
  if valid_601441 != nil:
    section.add "SubnetIds", valid_601441
  var valid_601442 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601442 = validateParameter(valid_601442, JString, required = true,
                                 default = nil)
  if valid_601442 != nil:
    section.add "DBSubnetGroupDescription", valid_601442
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_PostCreateDBSubnetGroup_601427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_PostCreateDBSubnetGroup_601427;
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
  var query_601445 = newJObject()
  var formData_601446 = newJObject()
  if Tags != nil:
    formData_601446.add "Tags", Tags
  add(formData_601446, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601446.add "SubnetIds", SubnetIds
  add(query_601445, "Action", newJString(Action))
  add(formData_601446, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601445, "Version", newJString(Version))
  result = call_601444.call(nil, query_601445, nil, formData_601446, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601427(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601428, base: "/",
    url: url_PostCreateDBSubnetGroup_601429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601408 = ref object of OpenApiRestCall_600421
proc url_GetCreateDBSubnetGroup_601410(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_601409(path: JsonNode; query: JsonNode;
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
  var valid_601411 = query.getOrDefault("Tags")
  valid_601411 = validateParameter(valid_601411, JArray, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "Tags", valid_601411
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601412 = query.getOrDefault("Action")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601412 != nil:
    section.add "Action", valid_601412
  var valid_601413 = query.getOrDefault("DBSubnetGroupName")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = nil)
  if valid_601413 != nil:
    section.add "DBSubnetGroupName", valid_601413
  var valid_601414 = query.getOrDefault("SubnetIds")
  valid_601414 = validateParameter(valid_601414, JArray, required = true, default = nil)
  if valid_601414 != nil:
    section.add "SubnetIds", valid_601414
  var valid_601415 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = nil)
  if valid_601415 != nil:
    section.add "DBSubnetGroupDescription", valid_601415
  var valid_601416 = query.getOrDefault("Version")
  valid_601416 = validateParameter(valid_601416, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601416 != nil:
    section.add "Version", valid_601416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601417 = header.getOrDefault("X-Amz-Date")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Date", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Security-Token")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Security-Token", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Content-Sha256", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Algorithm")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Algorithm", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Signature")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Signature", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-SignedHeaders", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Credential")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Credential", valid_601423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601424: Call_GetCreateDBSubnetGroup_601408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601424.validator(path, query, header, formData, body)
  let scheme = call_601424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601424.url(scheme.get, call_601424.host, call_601424.base,
                         call_601424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601424, url, valid)

proc call*(call_601425: Call_GetCreateDBSubnetGroup_601408;
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
  var query_601426 = newJObject()
  if Tags != nil:
    query_601426.add "Tags", Tags
  add(query_601426, "Action", newJString(Action))
  add(query_601426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601426.add "SubnetIds", SubnetIds
  add(query_601426, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601426, "Version", newJString(Version))
  result = call_601425.call(nil, query_601426, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601408(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601409, base: "/",
    url: url_GetCreateDBSubnetGroup_601410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601469 = ref object of OpenApiRestCall_600421
proc url_PostCreateEventSubscription_601471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_601470(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601472 = query.getOrDefault("Action")
  valid_601472 = validateParameter(valid_601472, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601472 != nil:
    section.add "Action", valid_601472
  var valid_601473 = query.getOrDefault("Version")
  valid_601473 = validateParameter(valid_601473, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601473 != nil:
    section.add "Version", valid_601473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601474 = header.getOrDefault("X-Amz-Date")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Date", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Security-Token")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Security-Token", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Content-Sha256", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Algorithm")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Algorithm", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Signature")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Signature", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-SignedHeaders", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Credential")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Credential", valid_601480
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
  var valid_601481 = formData.getOrDefault("Enabled")
  valid_601481 = validateParameter(valid_601481, JBool, required = false, default = nil)
  if valid_601481 != nil:
    section.add "Enabled", valid_601481
  var valid_601482 = formData.getOrDefault("EventCategories")
  valid_601482 = validateParameter(valid_601482, JArray, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "EventCategories", valid_601482
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601483 = formData.getOrDefault("SnsTopicArn")
  valid_601483 = validateParameter(valid_601483, JString, required = true,
                                 default = nil)
  if valid_601483 != nil:
    section.add "SnsTopicArn", valid_601483
  var valid_601484 = formData.getOrDefault("SourceIds")
  valid_601484 = validateParameter(valid_601484, JArray, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "SourceIds", valid_601484
  var valid_601485 = formData.getOrDefault("Tags")
  valid_601485 = validateParameter(valid_601485, JArray, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "Tags", valid_601485
  var valid_601486 = formData.getOrDefault("SubscriptionName")
  valid_601486 = validateParameter(valid_601486, JString, required = true,
                                 default = nil)
  if valid_601486 != nil:
    section.add "SubscriptionName", valid_601486
  var valid_601487 = formData.getOrDefault("SourceType")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "SourceType", valid_601487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601488: Call_PostCreateEventSubscription_601469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601488.validator(path, query, header, formData, body)
  let scheme = call_601488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601488.url(scheme.get, call_601488.host, call_601488.base,
                         call_601488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601488, url, valid)

proc call*(call_601489: Call_PostCreateEventSubscription_601469;
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
  var query_601490 = newJObject()
  var formData_601491 = newJObject()
  add(formData_601491, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601491.add "EventCategories", EventCategories
  add(formData_601491, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601491.add "SourceIds", SourceIds
  if Tags != nil:
    formData_601491.add "Tags", Tags
  add(formData_601491, "SubscriptionName", newJString(SubscriptionName))
  add(query_601490, "Action", newJString(Action))
  add(query_601490, "Version", newJString(Version))
  add(formData_601491, "SourceType", newJString(SourceType))
  result = call_601489.call(nil, query_601490, nil, formData_601491, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601469(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601470, base: "/",
    url: url_PostCreateEventSubscription_601471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601447 = ref object of OpenApiRestCall_600421
proc url_GetCreateEventSubscription_601449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_601448(path: JsonNode; query: JsonNode;
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
  var valid_601450 = query.getOrDefault("SourceType")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "SourceType", valid_601450
  var valid_601451 = query.getOrDefault("SourceIds")
  valid_601451 = validateParameter(valid_601451, JArray, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "SourceIds", valid_601451
  var valid_601452 = query.getOrDefault("Enabled")
  valid_601452 = validateParameter(valid_601452, JBool, required = false, default = nil)
  if valid_601452 != nil:
    section.add "Enabled", valid_601452
  var valid_601453 = query.getOrDefault("Tags")
  valid_601453 = validateParameter(valid_601453, JArray, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "Tags", valid_601453
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601454 = query.getOrDefault("Action")
  valid_601454 = validateParameter(valid_601454, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601454 != nil:
    section.add "Action", valid_601454
  var valid_601455 = query.getOrDefault("SnsTopicArn")
  valid_601455 = validateParameter(valid_601455, JString, required = true,
                                 default = nil)
  if valid_601455 != nil:
    section.add "SnsTopicArn", valid_601455
  var valid_601456 = query.getOrDefault("EventCategories")
  valid_601456 = validateParameter(valid_601456, JArray, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "EventCategories", valid_601456
  var valid_601457 = query.getOrDefault("SubscriptionName")
  valid_601457 = validateParameter(valid_601457, JString, required = true,
                                 default = nil)
  if valid_601457 != nil:
    section.add "SubscriptionName", valid_601457
  var valid_601458 = query.getOrDefault("Version")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601458 != nil:
    section.add "Version", valid_601458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601459 = header.getOrDefault("X-Amz-Date")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Date", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Security-Token")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Security-Token", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Content-Sha256", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Algorithm")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Algorithm", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Signature")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Signature", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-SignedHeaders", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Credential")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Credential", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601466: Call_GetCreateEventSubscription_601447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601466.validator(path, query, header, formData, body)
  let scheme = call_601466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601466.url(scheme.get, call_601466.host, call_601466.base,
                         call_601466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601466, url, valid)

proc call*(call_601467: Call_GetCreateEventSubscription_601447;
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
  var query_601468 = newJObject()
  add(query_601468, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601468.add "SourceIds", SourceIds
  add(query_601468, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_601468.add "Tags", Tags
  add(query_601468, "Action", newJString(Action))
  add(query_601468, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601468.add "EventCategories", EventCategories
  add(query_601468, "SubscriptionName", newJString(SubscriptionName))
  add(query_601468, "Version", newJString(Version))
  result = call_601467.call(nil, query_601468, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601447(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601448, base: "/",
    url: url_GetCreateEventSubscription_601449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601512 = ref object of OpenApiRestCall_600421
proc url_PostCreateOptionGroup_601514(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_601513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601515 = query.getOrDefault("Action")
  valid_601515 = validateParameter(valid_601515, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601515 != nil:
    section.add "Action", valid_601515
  var valid_601516 = query.getOrDefault("Version")
  valid_601516 = validateParameter(valid_601516, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601516 != nil:
    section.add "Version", valid_601516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601517 = header.getOrDefault("X-Amz-Date")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Date", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Security-Token")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Security-Token", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Content-Sha256", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Algorithm")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Algorithm", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Signature")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Signature", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-SignedHeaders", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Credential")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Credential", valid_601523
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601524 = formData.getOrDefault("MajorEngineVersion")
  valid_601524 = validateParameter(valid_601524, JString, required = true,
                                 default = nil)
  if valid_601524 != nil:
    section.add "MajorEngineVersion", valid_601524
  var valid_601525 = formData.getOrDefault("OptionGroupName")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = nil)
  if valid_601525 != nil:
    section.add "OptionGroupName", valid_601525
  var valid_601526 = formData.getOrDefault("Tags")
  valid_601526 = validateParameter(valid_601526, JArray, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "Tags", valid_601526
  var valid_601527 = formData.getOrDefault("EngineName")
  valid_601527 = validateParameter(valid_601527, JString, required = true,
                                 default = nil)
  if valid_601527 != nil:
    section.add "EngineName", valid_601527
  var valid_601528 = formData.getOrDefault("OptionGroupDescription")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = nil)
  if valid_601528 != nil:
    section.add "OptionGroupDescription", valid_601528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601529: Call_PostCreateOptionGroup_601512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601529.validator(path, query, header, formData, body)
  let scheme = call_601529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601529.url(scheme.get, call_601529.host, call_601529.base,
                         call_601529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601529, url, valid)

proc call*(call_601530: Call_PostCreateOptionGroup_601512;
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
  var query_601531 = newJObject()
  var formData_601532 = newJObject()
  add(formData_601532, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601532, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601532.add "Tags", Tags
  add(query_601531, "Action", newJString(Action))
  add(formData_601532, "EngineName", newJString(EngineName))
  add(formData_601532, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601531, "Version", newJString(Version))
  result = call_601530.call(nil, query_601531, nil, formData_601532, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601512(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601513, base: "/",
    url: url_PostCreateOptionGroup_601514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601492 = ref object of OpenApiRestCall_600421
proc url_GetCreateOptionGroup_601494(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_601493(path: JsonNode; query: JsonNode;
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
  var valid_601495 = query.getOrDefault("OptionGroupName")
  valid_601495 = validateParameter(valid_601495, JString, required = true,
                                 default = nil)
  if valid_601495 != nil:
    section.add "OptionGroupName", valid_601495
  var valid_601496 = query.getOrDefault("Tags")
  valid_601496 = validateParameter(valid_601496, JArray, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "Tags", valid_601496
  var valid_601497 = query.getOrDefault("OptionGroupDescription")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = nil)
  if valid_601497 != nil:
    section.add "OptionGroupDescription", valid_601497
  var valid_601498 = query.getOrDefault("Action")
  valid_601498 = validateParameter(valid_601498, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601498 != nil:
    section.add "Action", valid_601498
  var valid_601499 = query.getOrDefault("Version")
  valid_601499 = validateParameter(valid_601499, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601499 != nil:
    section.add "Version", valid_601499
  var valid_601500 = query.getOrDefault("EngineName")
  valid_601500 = validateParameter(valid_601500, JString, required = true,
                                 default = nil)
  if valid_601500 != nil:
    section.add "EngineName", valid_601500
  var valid_601501 = query.getOrDefault("MajorEngineVersion")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "MajorEngineVersion", valid_601501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601502 = header.getOrDefault("X-Amz-Date")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Date", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Security-Token")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Security-Token", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Content-Sha256", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Algorithm")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Algorithm", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Signature")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Signature", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-SignedHeaders", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Credential")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Credential", valid_601508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601509: Call_GetCreateOptionGroup_601492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601509.validator(path, query, header, formData, body)
  let scheme = call_601509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601509.url(scheme.get, call_601509.host, call_601509.base,
                         call_601509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601509, url, valid)

proc call*(call_601510: Call_GetCreateOptionGroup_601492; OptionGroupName: string;
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
  var query_601511 = newJObject()
  add(query_601511, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_601511.add "Tags", Tags
  add(query_601511, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601511, "Action", newJString(Action))
  add(query_601511, "Version", newJString(Version))
  add(query_601511, "EngineName", newJString(EngineName))
  add(query_601511, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601510.call(nil, query_601511, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601492(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601493, base: "/",
    url: url_GetCreateOptionGroup_601494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601551 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBInstance_601553(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_601552(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601554 = query.getOrDefault("Action")
  valid_601554 = validateParameter(valid_601554, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601554 != nil:
    section.add "Action", valid_601554
  var valid_601555 = query.getOrDefault("Version")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601555 != nil:
    section.add "Version", valid_601555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601556 = header.getOrDefault("X-Amz-Date")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Date", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Security-Token")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Security-Token", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Content-Sha256", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Algorithm")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Algorithm", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Signature")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Signature", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-SignedHeaders", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Credential")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Credential", valid_601562
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601563 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601563 = validateParameter(valid_601563, JString, required = true,
                                 default = nil)
  if valid_601563 != nil:
    section.add "DBInstanceIdentifier", valid_601563
  var valid_601564 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601564
  var valid_601565 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601565 = validateParameter(valid_601565, JBool, required = false, default = nil)
  if valid_601565 != nil:
    section.add "SkipFinalSnapshot", valid_601565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_PostDeleteDBInstance_601551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_PostDeleteDBInstance_601551;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601568 = newJObject()
  var formData_601569 = newJObject()
  add(formData_601569, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601569, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601568, "Action", newJString(Action))
  add(query_601568, "Version", newJString(Version))
  add(formData_601569, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601567.call(nil, query_601568, nil, formData_601569, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601551(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601552, base: "/",
    url: url_PostDeleteDBInstance_601553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601533 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBInstance_601535(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_601534(path: JsonNode; query: JsonNode;
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
  var valid_601536 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601536
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601537 = query.getOrDefault("Action")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601537 != nil:
    section.add "Action", valid_601537
  var valid_601538 = query.getOrDefault("SkipFinalSnapshot")
  valid_601538 = validateParameter(valid_601538, JBool, required = false, default = nil)
  if valid_601538 != nil:
    section.add "SkipFinalSnapshot", valid_601538
  var valid_601539 = query.getOrDefault("Version")
  valid_601539 = validateParameter(valid_601539, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601539 != nil:
    section.add "Version", valid_601539
  var valid_601540 = query.getOrDefault("DBInstanceIdentifier")
  valid_601540 = validateParameter(valid_601540, JString, required = true,
                                 default = nil)
  if valid_601540 != nil:
    section.add "DBInstanceIdentifier", valid_601540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601541 = header.getOrDefault("X-Amz-Date")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Date", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Security-Token")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Security-Token", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Content-Sha256", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Algorithm")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Algorithm", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Signature")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Signature", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-SignedHeaders", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Credential")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Credential", valid_601547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601548: Call_GetDeleteDBInstance_601533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601548.validator(path, query, header, formData, body)
  let scheme = call_601548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601548.url(scheme.get, call_601548.host, call_601548.base,
                         call_601548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601548, url, valid)

proc call*(call_601549: Call_GetDeleteDBInstance_601533;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601550 = newJObject()
  add(query_601550, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601550, "Action", newJString(Action))
  add(query_601550, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601550, "Version", newJString(Version))
  add(query_601550, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601549.call(nil, query_601550, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601533(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601534, base: "/",
    url: url_GetDeleteDBInstance_601535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601586 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBParameterGroup_601588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_601587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601589 = query.getOrDefault("Action")
  valid_601589 = validateParameter(valid_601589, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601589 != nil:
    section.add "Action", valid_601589
  var valid_601590 = query.getOrDefault("Version")
  valid_601590 = validateParameter(valid_601590, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601590 != nil:
    section.add "Version", valid_601590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601591 = header.getOrDefault("X-Amz-Date")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Date", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Security-Token")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Security-Token", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Content-Sha256", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Algorithm")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Algorithm", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Signature")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Signature", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-SignedHeaders", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Credential")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Credential", valid_601597
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601598 = formData.getOrDefault("DBParameterGroupName")
  valid_601598 = validateParameter(valid_601598, JString, required = true,
                                 default = nil)
  if valid_601598 != nil:
    section.add "DBParameterGroupName", valid_601598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601599: Call_PostDeleteDBParameterGroup_601586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601599.validator(path, query, header, formData, body)
  let scheme = call_601599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601599.url(scheme.get, call_601599.host, call_601599.base,
                         call_601599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601599, url, valid)

proc call*(call_601600: Call_PostDeleteDBParameterGroup_601586;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601601 = newJObject()
  var formData_601602 = newJObject()
  add(formData_601602, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601601, "Action", newJString(Action))
  add(query_601601, "Version", newJString(Version))
  result = call_601600.call(nil, query_601601, nil, formData_601602, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601586(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601587, base: "/",
    url: url_PostDeleteDBParameterGroup_601588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601570 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBParameterGroup_601572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_601571(path: JsonNode; query: JsonNode;
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
  var valid_601573 = query.getOrDefault("DBParameterGroupName")
  valid_601573 = validateParameter(valid_601573, JString, required = true,
                                 default = nil)
  if valid_601573 != nil:
    section.add "DBParameterGroupName", valid_601573
  var valid_601574 = query.getOrDefault("Action")
  valid_601574 = validateParameter(valid_601574, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601574 != nil:
    section.add "Action", valid_601574
  var valid_601575 = query.getOrDefault("Version")
  valid_601575 = validateParameter(valid_601575, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601575 != nil:
    section.add "Version", valid_601575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601576 = header.getOrDefault("X-Amz-Date")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Date", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Security-Token")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Security-Token", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Content-Sha256", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Algorithm")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Algorithm", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Signature")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Signature", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-SignedHeaders", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Credential")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Credential", valid_601582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601583: Call_GetDeleteDBParameterGroup_601570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601583.validator(path, query, header, formData, body)
  let scheme = call_601583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601583.url(scheme.get, call_601583.host, call_601583.base,
                         call_601583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601583, url, valid)

proc call*(call_601584: Call_GetDeleteDBParameterGroup_601570;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601585 = newJObject()
  add(query_601585, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601585, "Action", newJString(Action))
  add(query_601585, "Version", newJString(Version))
  result = call_601584.call(nil, query_601585, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601570(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601571, base: "/",
    url: url_GetDeleteDBParameterGroup_601572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601619 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSecurityGroup_601621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_601620(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601622 = query.getOrDefault("Action")
  valid_601622 = validateParameter(valid_601622, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601622 != nil:
    section.add "Action", valid_601622
  var valid_601623 = query.getOrDefault("Version")
  valid_601623 = validateParameter(valid_601623, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601623 != nil:
    section.add "Version", valid_601623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601624 = header.getOrDefault("X-Amz-Date")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Date", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Security-Token")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Security-Token", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Content-Sha256", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Algorithm")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Algorithm", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Signature")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Signature", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-SignedHeaders", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Credential")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Credential", valid_601630
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601631 = formData.getOrDefault("DBSecurityGroupName")
  valid_601631 = validateParameter(valid_601631, JString, required = true,
                                 default = nil)
  if valid_601631 != nil:
    section.add "DBSecurityGroupName", valid_601631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601632: Call_PostDeleteDBSecurityGroup_601619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601632.validator(path, query, header, formData, body)
  let scheme = call_601632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601632.url(scheme.get, call_601632.host, call_601632.base,
                         call_601632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601632, url, valid)

proc call*(call_601633: Call_PostDeleteDBSecurityGroup_601619;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601634 = newJObject()
  var formData_601635 = newJObject()
  add(formData_601635, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601634, "Action", newJString(Action))
  add(query_601634, "Version", newJString(Version))
  result = call_601633.call(nil, query_601634, nil, formData_601635, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601619(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601620, base: "/",
    url: url_PostDeleteDBSecurityGroup_601621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601603 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSecurityGroup_601605(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_601604(path: JsonNode; query: JsonNode;
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
  var valid_601606 = query.getOrDefault("DBSecurityGroupName")
  valid_601606 = validateParameter(valid_601606, JString, required = true,
                                 default = nil)
  if valid_601606 != nil:
    section.add "DBSecurityGroupName", valid_601606
  var valid_601607 = query.getOrDefault("Action")
  valid_601607 = validateParameter(valid_601607, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601607 != nil:
    section.add "Action", valid_601607
  var valid_601608 = query.getOrDefault("Version")
  valid_601608 = validateParameter(valid_601608, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601608 != nil:
    section.add "Version", valid_601608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601609 = header.getOrDefault("X-Amz-Date")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Date", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Security-Token")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Security-Token", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Content-Sha256", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Algorithm")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Algorithm", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Signature")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Signature", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-SignedHeaders", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Credential")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Credential", valid_601615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601616: Call_GetDeleteDBSecurityGroup_601603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601616.validator(path, query, header, formData, body)
  let scheme = call_601616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601616.url(scheme.get, call_601616.host, call_601616.base,
                         call_601616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601616, url, valid)

proc call*(call_601617: Call_GetDeleteDBSecurityGroup_601603;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601618 = newJObject()
  add(query_601618, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601618, "Action", newJString(Action))
  add(query_601618, "Version", newJString(Version))
  result = call_601617.call(nil, query_601618, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601603(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601604, base: "/",
    url: url_GetDeleteDBSecurityGroup_601605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601652 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSnapshot_601654(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_601653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601655 = query.getOrDefault("Action")
  valid_601655 = validateParameter(valid_601655, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601655 != nil:
    section.add "Action", valid_601655
  var valid_601656 = query.getOrDefault("Version")
  valid_601656 = validateParameter(valid_601656, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601656 != nil:
    section.add "Version", valid_601656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601657 = header.getOrDefault("X-Amz-Date")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Date", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Security-Token")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Security-Token", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Content-Sha256", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Algorithm")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Algorithm", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Signature")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Signature", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-SignedHeaders", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Credential")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Credential", valid_601663
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601664 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601664 = validateParameter(valid_601664, JString, required = true,
                                 default = nil)
  if valid_601664 != nil:
    section.add "DBSnapshotIdentifier", valid_601664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601665: Call_PostDeleteDBSnapshot_601652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601665.validator(path, query, header, formData, body)
  let scheme = call_601665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601665.url(scheme.get, call_601665.host, call_601665.base,
                         call_601665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601665, url, valid)

proc call*(call_601666: Call_PostDeleteDBSnapshot_601652;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601667 = newJObject()
  var formData_601668 = newJObject()
  add(formData_601668, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601667, "Action", newJString(Action))
  add(query_601667, "Version", newJString(Version))
  result = call_601666.call(nil, query_601667, nil, formData_601668, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601652(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601653, base: "/",
    url: url_PostDeleteDBSnapshot_601654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601636 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSnapshot_601638(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_601637(path: JsonNode; query: JsonNode;
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
  var valid_601639 = query.getOrDefault("Action")
  valid_601639 = validateParameter(valid_601639, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601639 != nil:
    section.add "Action", valid_601639
  var valid_601640 = query.getOrDefault("Version")
  valid_601640 = validateParameter(valid_601640, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601640 != nil:
    section.add "Version", valid_601640
  var valid_601641 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601641 = validateParameter(valid_601641, JString, required = true,
                                 default = nil)
  if valid_601641 != nil:
    section.add "DBSnapshotIdentifier", valid_601641
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601649: Call_GetDeleteDBSnapshot_601636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601649.validator(path, query, header, formData, body)
  let scheme = call_601649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601649.url(scheme.get, call_601649.host, call_601649.base,
                         call_601649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601649, url, valid)

proc call*(call_601650: Call_GetDeleteDBSnapshot_601636;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601651 = newJObject()
  add(query_601651, "Action", newJString(Action))
  add(query_601651, "Version", newJString(Version))
  add(query_601651, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601650.call(nil, query_601651, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601636(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601637, base: "/",
    url: url_GetDeleteDBSnapshot_601638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601685 = ref object of OpenApiRestCall_600421
proc url_PostDeleteDBSubnetGroup_601687(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_601686(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601688 = query.getOrDefault("Action")
  valid_601688 = validateParameter(valid_601688, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601688 != nil:
    section.add "Action", valid_601688
  var valid_601689 = query.getOrDefault("Version")
  valid_601689 = validateParameter(valid_601689, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601689 != nil:
    section.add "Version", valid_601689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601690 = header.getOrDefault("X-Amz-Date")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Date", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Security-Token")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Security-Token", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Content-Sha256", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Algorithm")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Algorithm", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Signature")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Signature", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-SignedHeaders", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Credential")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Credential", valid_601696
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601697 = formData.getOrDefault("DBSubnetGroupName")
  valid_601697 = validateParameter(valid_601697, JString, required = true,
                                 default = nil)
  if valid_601697 != nil:
    section.add "DBSubnetGroupName", valid_601697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601698: Call_PostDeleteDBSubnetGroup_601685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601698.validator(path, query, header, formData, body)
  let scheme = call_601698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601698.url(scheme.get, call_601698.host, call_601698.base,
                         call_601698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601698, url, valid)

proc call*(call_601699: Call_PostDeleteDBSubnetGroup_601685;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601700 = newJObject()
  var formData_601701 = newJObject()
  add(formData_601701, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601700, "Action", newJString(Action))
  add(query_601700, "Version", newJString(Version))
  result = call_601699.call(nil, query_601700, nil, formData_601701, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601685(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601686, base: "/",
    url: url_PostDeleteDBSubnetGroup_601687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601669 = ref object of OpenApiRestCall_600421
proc url_GetDeleteDBSubnetGroup_601671(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_601670(path: JsonNode; query: JsonNode;
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
  var valid_601672 = query.getOrDefault("Action")
  valid_601672 = validateParameter(valid_601672, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601672 != nil:
    section.add "Action", valid_601672
  var valid_601673 = query.getOrDefault("DBSubnetGroupName")
  valid_601673 = validateParameter(valid_601673, JString, required = true,
                                 default = nil)
  if valid_601673 != nil:
    section.add "DBSubnetGroupName", valid_601673
  var valid_601674 = query.getOrDefault("Version")
  valid_601674 = validateParameter(valid_601674, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601674 != nil:
    section.add "Version", valid_601674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601675 = header.getOrDefault("X-Amz-Date")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Date", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Security-Token")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Security-Token", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Content-Sha256", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Algorithm")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Algorithm", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Signature")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Signature", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-SignedHeaders", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Credential")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Credential", valid_601681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601682: Call_GetDeleteDBSubnetGroup_601669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601682.validator(path, query, header, formData, body)
  let scheme = call_601682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601682.url(scheme.get, call_601682.host, call_601682.base,
                         call_601682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601682, url, valid)

proc call*(call_601683: Call_GetDeleteDBSubnetGroup_601669;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601684 = newJObject()
  add(query_601684, "Action", newJString(Action))
  add(query_601684, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601684, "Version", newJString(Version))
  result = call_601683.call(nil, query_601684, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601669(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601670, base: "/",
    url: url_GetDeleteDBSubnetGroup_601671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601718 = ref object of OpenApiRestCall_600421
proc url_PostDeleteEventSubscription_601720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_601719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601721 = query.getOrDefault("Action")
  valid_601721 = validateParameter(valid_601721, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601721 != nil:
    section.add "Action", valid_601721
  var valid_601722 = query.getOrDefault("Version")
  valid_601722 = validateParameter(valid_601722, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601722 != nil:
    section.add "Version", valid_601722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601723 = header.getOrDefault("X-Amz-Date")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Date", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Security-Token")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Security-Token", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Content-Sha256", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Algorithm")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Algorithm", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Signature")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Signature", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-SignedHeaders", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Credential")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Credential", valid_601729
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601730 = formData.getOrDefault("SubscriptionName")
  valid_601730 = validateParameter(valid_601730, JString, required = true,
                                 default = nil)
  if valid_601730 != nil:
    section.add "SubscriptionName", valid_601730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_PostDeleteEventSubscription_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601731, url, valid)

proc call*(call_601732: Call_PostDeleteEventSubscription_601718;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601733 = newJObject()
  var formData_601734 = newJObject()
  add(formData_601734, "SubscriptionName", newJString(SubscriptionName))
  add(query_601733, "Action", newJString(Action))
  add(query_601733, "Version", newJString(Version))
  result = call_601732.call(nil, query_601733, nil, formData_601734, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601718(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601719, base: "/",
    url: url_PostDeleteEventSubscription_601720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601702 = ref object of OpenApiRestCall_600421
proc url_GetDeleteEventSubscription_601704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_601703(path: JsonNode; query: JsonNode;
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
  var valid_601705 = query.getOrDefault("Action")
  valid_601705 = validateParameter(valid_601705, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601705 != nil:
    section.add "Action", valid_601705
  var valid_601706 = query.getOrDefault("SubscriptionName")
  valid_601706 = validateParameter(valid_601706, JString, required = true,
                                 default = nil)
  if valid_601706 != nil:
    section.add "SubscriptionName", valid_601706
  var valid_601707 = query.getOrDefault("Version")
  valid_601707 = validateParameter(valid_601707, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601707 != nil:
    section.add "Version", valid_601707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601708 = header.getOrDefault("X-Amz-Date")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Date", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Security-Token")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Security-Token", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Content-Sha256", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Algorithm")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Algorithm", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Signature")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Signature", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-SignedHeaders", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Credential")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Credential", valid_601714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601715: Call_GetDeleteEventSubscription_601702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601715.validator(path, query, header, formData, body)
  let scheme = call_601715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601715.url(scheme.get, call_601715.host, call_601715.base,
                         call_601715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601715, url, valid)

proc call*(call_601716: Call_GetDeleteEventSubscription_601702;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601717 = newJObject()
  add(query_601717, "Action", newJString(Action))
  add(query_601717, "SubscriptionName", newJString(SubscriptionName))
  add(query_601717, "Version", newJString(Version))
  result = call_601716.call(nil, query_601717, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601702(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601703, base: "/",
    url: url_GetDeleteEventSubscription_601704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601751 = ref object of OpenApiRestCall_600421
proc url_PostDeleteOptionGroup_601753(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_601752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601754 = query.getOrDefault("Action")
  valid_601754 = validateParameter(valid_601754, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601754 != nil:
    section.add "Action", valid_601754
  var valid_601755 = query.getOrDefault("Version")
  valid_601755 = validateParameter(valid_601755, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601755 != nil:
    section.add "Version", valid_601755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601756 = header.getOrDefault("X-Amz-Date")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Date", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Security-Token")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Security-Token", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Content-Sha256", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Algorithm")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Algorithm", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Signature")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Signature", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-SignedHeaders", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Credential")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Credential", valid_601762
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601763 = formData.getOrDefault("OptionGroupName")
  valid_601763 = validateParameter(valid_601763, JString, required = true,
                                 default = nil)
  if valid_601763 != nil:
    section.add "OptionGroupName", valid_601763
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601764: Call_PostDeleteOptionGroup_601751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601764.validator(path, query, header, formData, body)
  let scheme = call_601764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601764.url(scheme.get, call_601764.host, call_601764.base,
                         call_601764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601764, url, valid)

proc call*(call_601765: Call_PostDeleteOptionGroup_601751; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601766 = newJObject()
  var formData_601767 = newJObject()
  add(formData_601767, "OptionGroupName", newJString(OptionGroupName))
  add(query_601766, "Action", newJString(Action))
  add(query_601766, "Version", newJString(Version))
  result = call_601765.call(nil, query_601766, nil, formData_601767, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601751(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601752, base: "/",
    url: url_PostDeleteOptionGroup_601753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601735 = ref object of OpenApiRestCall_600421
proc url_GetDeleteOptionGroup_601737(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_601736(path: JsonNode; query: JsonNode;
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
  var valid_601738 = query.getOrDefault("OptionGroupName")
  valid_601738 = validateParameter(valid_601738, JString, required = true,
                                 default = nil)
  if valid_601738 != nil:
    section.add "OptionGroupName", valid_601738
  var valid_601739 = query.getOrDefault("Action")
  valid_601739 = validateParameter(valid_601739, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601739 != nil:
    section.add "Action", valid_601739
  var valid_601740 = query.getOrDefault("Version")
  valid_601740 = validateParameter(valid_601740, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601740 != nil:
    section.add "Version", valid_601740
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601741 = header.getOrDefault("X-Amz-Date")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Date", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Security-Token")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Security-Token", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Content-Sha256", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Algorithm")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Algorithm", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Signature")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Signature", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-SignedHeaders", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Credential")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Credential", valid_601747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601748: Call_GetDeleteOptionGroup_601735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601748.validator(path, query, header, formData, body)
  let scheme = call_601748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601748.url(scheme.get, call_601748.host, call_601748.base,
                         call_601748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601748, url, valid)

proc call*(call_601749: Call_GetDeleteOptionGroup_601735; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601750 = newJObject()
  add(query_601750, "OptionGroupName", newJString(OptionGroupName))
  add(query_601750, "Action", newJString(Action))
  add(query_601750, "Version", newJString(Version))
  result = call_601749.call(nil, query_601750, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601735(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601736, base: "/",
    url: url_GetDeleteOptionGroup_601737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601791 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBEngineVersions_601793(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_601792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601794 = query.getOrDefault("Action")
  valid_601794 = validateParameter(valid_601794, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601794 != nil:
    section.add "Action", valid_601794
  var valid_601795 = query.getOrDefault("Version")
  valid_601795 = validateParameter(valid_601795, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601795 != nil:
    section.add "Version", valid_601795
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601796 = header.getOrDefault("X-Amz-Date")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Date", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Security-Token")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Security-Token", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Content-Sha256", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Algorithm")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Algorithm", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Signature")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Signature", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-SignedHeaders", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Credential")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Credential", valid_601802
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
  var valid_601803 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601803 = validateParameter(valid_601803, JBool, required = false, default = nil)
  if valid_601803 != nil:
    section.add "ListSupportedCharacterSets", valid_601803
  var valid_601804 = formData.getOrDefault("Engine")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "Engine", valid_601804
  var valid_601805 = formData.getOrDefault("Marker")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "Marker", valid_601805
  var valid_601806 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "DBParameterGroupFamily", valid_601806
  var valid_601807 = formData.getOrDefault("Filters")
  valid_601807 = validateParameter(valid_601807, JArray, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "Filters", valid_601807
  var valid_601808 = formData.getOrDefault("MaxRecords")
  valid_601808 = validateParameter(valid_601808, JInt, required = false, default = nil)
  if valid_601808 != nil:
    section.add "MaxRecords", valid_601808
  var valid_601809 = formData.getOrDefault("EngineVersion")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "EngineVersion", valid_601809
  var valid_601810 = formData.getOrDefault("DefaultOnly")
  valid_601810 = validateParameter(valid_601810, JBool, required = false, default = nil)
  if valid_601810 != nil:
    section.add "DefaultOnly", valid_601810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601811: Call_PostDescribeDBEngineVersions_601791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601811.validator(path, query, header, formData, body)
  let scheme = call_601811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601811.url(scheme.get, call_601811.host, call_601811.base,
                         call_601811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601811, url, valid)

proc call*(call_601812: Call_PostDescribeDBEngineVersions_601791;
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
  var query_601813 = newJObject()
  var formData_601814 = newJObject()
  add(formData_601814, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601814, "Engine", newJString(Engine))
  add(formData_601814, "Marker", newJString(Marker))
  add(query_601813, "Action", newJString(Action))
  add(formData_601814, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601814.add "Filters", Filters
  add(formData_601814, "MaxRecords", newJInt(MaxRecords))
  add(formData_601814, "EngineVersion", newJString(EngineVersion))
  add(query_601813, "Version", newJString(Version))
  add(formData_601814, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601812.call(nil, query_601813, nil, formData_601814, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601791(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601792, base: "/",
    url: url_PostDescribeDBEngineVersions_601793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601768 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBEngineVersions_601770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_601769(path: JsonNode; query: JsonNode;
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
  var valid_601771 = query.getOrDefault("Engine")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "Engine", valid_601771
  var valid_601772 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601772 = validateParameter(valid_601772, JBool, required = false, default = nil)
  if valid_601772 != nil:
    section.add "ListSupportedCharacterSets", valid_601772
  var valid_601773 = query.getOrDefault("MaxRecords")
  valid_601773 = validateParameter(valid_601773, JInt, required = false, default = nil)
  if valid_601773 != nil:
    section.add "MaxRecords", valid_601773
  var valid_601774 = query.getOrDefault("DBParameterGroupFamily")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "DBParameterGroupFamily", valid_601774
  var valid_601775 = query.getOrDefault("Filters")
  valid_601775 = validateParameter(valid_601775, JArray, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "Filters", valid_601775
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601776 = query.getOrDefault("Action")
  valid_601776 = validateParameter(valid_601776, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601776 != nil:
    section.add "Action", valid_601776
  var valid_601777 = query.getOrDefault("Marker")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "Marker", valid_601777
  var valid_601778 = query.getOrDefault("EngineVersion")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "EngineVersion", valid_601778
  var valid_601779 = query.getOrDefault("DefaultOnly")
  valid_601779 = validateParameter(valid_601779, JBool, required = false, default = nil)
  if valid_601779 != nil:
    section.add "DefaultOnly", valid_601779
  var valid_601780 = query.getOrDefault("Version")
  valid_601780 = validateParameter(valid_601780, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601780 != nil:
    section.add "Version", valid_601780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601781 = header.getOrDefault("X-Amz-Date")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Date", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Security-Token")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Security-Token", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Content-Sha256", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Algorithm")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Algorithm", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-Signature")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Signature", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-SignedHeaders", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Credential")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Credential", valid_601787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601788: Call_GetDescribeDBEngineVersions_601768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601788.validator(path, query, header, formData, body)
  let scheme = call_601788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601788.url(scheme.get, call_601788.host, call_601788.base,
                         call_601788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601788, url, valid)

proc call*(call_601789: Call_GetDescribeDBEngineVersions_601768;
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
  var query_601790 = newJObject()
  add(query_601790, "Engine", newJString(Engine))
  add(query_601790, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601790, "MaxRecords", newJInt(MaxRecords))
  add(query_601790, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601790.add "Filters", Filters
  add(query_601790, "Action", newJString(Action))
  add(query_601790, "Marker", newJString(Marker))
  add(query_601790, "EngineVersion", newJString(EngineVersion))
  add(query_601790, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601790, "Version", newJString(Version))
  result = call_601789.call(nil, query_601790, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601768(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601769, base: "/",
    url: url_GetDescribeDBEngineVersions_601770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601834 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBInstances_601836(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_601835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601837 = query.getOrDefault("Action")
  valid_601837 = validateParameter(valid_601837, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601837 != nil:
    section.add "Action", valid_601837
  var valid_601838 = query.getOrDefault("Version")
  valid_601838 = validateParameter(valid_601838, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601838 != nil:
    section.add "Version", valid_601838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601839 = header.getOrDefault("X-Amz-Date")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Date", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Security-Token")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Security-Token", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Content-Sha256", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Algorithm")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Algorithm", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-SignedHeaders", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601846 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "DBInstanceIdentifier", valid_601846
  var valid_601847 = formData.getOrDefault("Marker")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "Marker", valid_601847
  var valid_601848 = formData.getOrDefault("Filters")
  valid_601848 = validateParameter(valid_601848, JArray, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "Filters", valid_601848
  var valid_601849 = formData.getOrDefault("MaxRecords")
  valid_601849 = validateParameter(valid_601849, JInt, required = false, default = nil)
  if valid_601849 != nil:
    section.add "MaxRecords", valid_601849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601850: Call_PostDescribeDBInstances_601834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601850.validator(path, query, header, formData, body)
  let scheme = call_601850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601850.url(scheme.get, call_601850.host, call_601850.base,
                         call_601850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601850, url, valid)

proc call*(call_601851: Call_PostDescribeDBInstances_601834;
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
  var query_601852 = newJObject()
  var formData_601853 = newJObject()
  add(formData_601853, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601853, "Marker", newJString(Marker))
  add(query_601852, "Action", newJString(Action))
  if Filters != nil:
    formData_601853.add "Filters", Filters
  add(formData_601853, "MaxRecords", newJInt(MaxRecords))
  add(query_601852, "Version", newJString(Version))
  result = call_601851.call(nil, query_601852, nil, formData_601853, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601834(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601835, base: "/",
    url: url_PostDescribeDBInstances_601836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601815 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBInstances_601817(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_601816(path: JsonNode; query: JsonNode;
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
  var valid_601818 = query.getOrDefault("MaxRecords")
  valid_601818 = validateParameter(valid_601818, JInt, required = false, default = nil)
  if valid_601818 != nil:
    section.add "MaxRecords", valid_601818
  var valid_601819 = query.getOrDefault("Filters")
  valid_601819 = validateParameter(valid_601819, JArray, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "Filters", valid_601819
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601820 = query.getOrDefault("Action")
  valid_601820 = validateParameter(valid_601820, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601820 != nil:
    section.add "Action", valid_601820
  var valid_601821 = query.getOrDefault("Marker")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "Marker", valid_601821
  var valid_601822 = query.getOrDefault("Version")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601822 != nil:
    section.add "Version", valid_601822
  var valid_601823 = query.getOrDefault("DBInstanceIdentifier")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "DBInstanceIdentifier", valid_601823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601824 = header.getOrDefault("X-Amz-Date")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Date", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Security-Token")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Security-Token", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Content-Sha256", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Algorithm")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Algorithm", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Signature")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Signature", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-SignedHeaders", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Credential")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Credential", valid_601830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601831: Call_GetDescribeDBInstances_601815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601831.validator(path, query, header, formData, body)
  let scheme = call_601831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601831.url(scheme.get, call_601831.host, call_601831.base,
                         call_601831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601831, url, valid)

proc call*(call_601832: Call_GetDescribeDBInstances_601815; MaxRecords: int = 0;
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
  var query_601833 = newJObject()
  add(query_601833, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601833.add "Filters", Filters
  add(query_601833, "Action", newJString(Action))
  add(query_601833, "Marker", newJString(Marker))
  add(query_601833, "Version", newJString(Version))
  add(query_601833, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601832.call(nil, query_601833, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601815(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601816, base: "/",
    url: url_GetDescribeDBInstances_601817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_601876 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBLogFiles_601878(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBLogFiles_601877(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601879 = query.getOrDefault("Action")
  valid_601879 = validateParameter(valid_601879, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601879 != nil:
    section.add "Action", valid_601879
  var valid_601880 = query.getOrDefault("Version")
  valid_601880 = validateParameter(valid_601880, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601880 != nil:
    section.add "Version", valid_601880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601881 = header.getOrDefault("X-Amz-Date")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Date", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Security-Token")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Security-Token", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Content-Sha256", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Algorithm")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Algorithm", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Signature")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Signature", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-SignedHeaders", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Credential")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Credential", valid_601887
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
  var valid_601888 = formData.getOrDefault("FilenameContains")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "FilenameContains", valid_601888
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601889 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601889 = validateParameter(valid_601889, JString, required = true,
                                 default = nil)
  if valid_601889 != nil:
    section.add "DBInstanceIdentifier", valid_601889
  var valid_601890 = formData.getOrDefault("FileSize")
  valid_601890 = validateParameter(valid_601890, JInt, required = false, default = nil)
  if valid_601890 != nil:
    section.add "FileSize", valid_601890
  var valid_601891 = formData.getOrDefault("Marker")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "Marker", valid_601891
  var valid_601892 = formData.getOrDefault("Filters")
  valid_601892 = validateParameter(valid_601892, JArray, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "Filters", valid_601892
  var valid_601893 = formData.getOrDefault("MaxRecords")
  valid_601893 = validateParameter(valid_601893, JInt, required = false, default = nil)
  if valid_601893 != nil:
    section.add "MaxRecords", valid_601893
  var valid_601894 = formData.getOrDefault("FileLastWritten")
  valid_601894 = validateParameter(valid_601894, JInt, required = false, default = nil)
  if valid_601894 != nil:
    section.add "FileLastWritten", valid_601894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601895: Call_PostDescribeDBLogFiles_601876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601895.validator(path, query, header, formData, body)
  let scheme = call_601895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601895.url(scheme.get, call_601895.host, call_601895.base,
                         call_601895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601895, url, valid)

proc call*(call_601896: Call_PostDescribeDBLogFiles_601876;
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
  var query_601897 = newJObject()
  var formData_601898 = newJObject()
  add(formData_601898, "FilenameContains", newJString(FilenameContains))
  add(formData_601898, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601898, "FileSize", newJInt(FileSize))
  add(formData_601898, "Marker", newJString(Marker))
  add(query_601897, "Action", newJString(Action))
  if Filters != nil:
    formData_601898.add "Filters", Filters
  add(formData_601898, "MaxRecords", newJInt(MaxRecords))
  add(formData_601898, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601897, "Version", newJString(Version))
  result = call_601896.call(nil, query_601897, nil, formData_601898, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601876(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601877, base: "/",
    url: url_PostDescribeDBLogFiles_601878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601854 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBLogFiles_601856(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBLogFiles_601855(path: JsonNode; query: JsonNode;
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
  var valid_601857 = query.getOrDefault("FileLastWritten")
  valid_601857 = validateParameter(valid_601857, JInt, required = false, default = nil)
  if valid_601857 != nil:
    section.add "FileLastWritten", valid_601857
  var valid_601858 = query.getOrDefault("MaxRecords")
  valid_601858 = validateParameter(valid_601858, JInt, required = false, default = nil)
  if valid_601858 != nil:
    section.add "MaxRecords", valid_601858
  var valid_601859 = query.getOrDefault("FilenameContains")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "FilenameContains", valid_601859
  var valid_601860 = query.getOrDefault("FileSize")
  valid_601860 = validateParameter(valid_601860, JInt, required = false, default = nil)
  if valid_601860 != nil:
    section.add "FileSize", valid_601860
  var valid_601861 = query.getOrDefault("Filters")
  valid_601861 = validateParameter(valid_601861, JArray, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "Filters", valid_601861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601862 = query.getOrDefault("Action")
  valid_601862 = validateParameter(valid_601862, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601862 != nil:
    section.add "Action", valid_601862
  var valid_601863 = query.getOrDefault("Marker")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "Marker", valid_601863
  var valid_601864 = query.getOrDefault("Version")
  valid_601864 = validateParameter(valid_601864, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601864 != nil:
    section.add "Version", valid_601864
  var valid_601865 = query.getOrDefault("DBInstanceIdentifier")
  valid_601865 = validateParameter(valid_601865, JString, required = true,
                                 default = nil)
  if valid_601865 != nil:
    section.add "DBInstanceIdentifier", valid_601865
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601866 = header.getOrDefault("X-Amz-Date")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Date", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Security-Token")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Security-Token", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Content-Sha256", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Algorithm")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Algorithm", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Signature")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Signature", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-SignedHeaders", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Credential")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Credential", valid_601872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601873: Call_GetDescribeDBLogFiles_601854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601873.validator(path, query, header, formData, body)
  let scheme = call_601873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601873.url(scheme.get, call_601873.host, call_601873.base,
                         call_601873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601873, url, valid)

proc call*(call_601874: Call_GetDescribeDBLogFiles_601854;
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
  var query_601875 = newJObject()
  add(query_601875, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601875, "MaxRecords", newJInt(MaxRecords))
  add(query_601875, "FilenameContains", newJString(FilenameContains))
  add(query_601875, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_601875.add "Filters", Filters
  add(query_601875, "Action", newJString(Action))
  add(query_601875, "Marker", newJString(Marker))
  add(query_601875, "Version", newJString(Version))
  add(query_601875, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601874.call(nil, query_601875, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601854(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601855, base: "/",
    url: url_GetDescribeDBLogFiles_601856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601918 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameterGroups_601920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_601919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601921 = query.getOrDefault("Action")
  valid_601921 = validateParameter(valid_601921, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601921 != nil:
    section.add "Action", valid_601921
  var valid_601922 = query.getOrDefault("Version")
  valid_601922 = validateParameter(valid_601922, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601922 != nil:
    section.add "Version", valid_601922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601923 = header.getOrDefault("X-Amz-Date")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Date", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-Security-Token")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-Security-Token", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Content-Sha256", valid_601925
  var valid_601926 = header.getOrDefault("X-Amz-Algorithm")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-Algorithm", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Signature")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Signature", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-SignedHeaders", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Credential")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Credential", valid_601929
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601930 = formData.getOrDefault("DBParameterGroupName")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "DBParameterGroupName", valid_601930
  var valid_601931 = formData.getOrDefault("Marker")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "Marker", valid_601931
  var valid_601932 = formData.getOrDefault("Filters")
  valid_601932 = validateParameter(valid_601932, JArray, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "Filters", valid_601932
  var valid_601933 = formData.getOrDefault("MaxRecords")
  valid_601933 = validateParameter(valid_601933, JInt, required = false, default = nil)
  if valid_601933 != nil:
    section.add "MaxRecords", valid_601933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601934: Call_PostDescribeDBParameterGroups_601918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601934.validator(path, query, header, formData, body)
  let scheme = call_601934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601934.url(scheme.get, call_601934.host, call_601934.base,
                         call_601934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601934, url, valid)

proc call*(call_601935: Call_PostDescribeDBParameterGroups_601918;
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
  var query_601936 = newJObject()
  var formData_601937 = newJObject()
  add(formData_601937, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601937, "Marker", newJString(Marker))
  add(query_601936, "Action", newJString(Action))
  if Filters != nil:
    formData_601937.add "Filters", Filters
  add(formData_601937, "MaxRecords", newJInt(MaxRecords))
  add(query_601936, "Version", newJString(Version))
  result = call_601935.call(nil, query_601936, nil, formData_601937, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601918(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601919, base: "/",
    url: url_PostDescribeDBParameterGroups_601920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601899 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameterGroups_601901(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_601900(path: JsonNode; query: JsonNode;
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
  var valid_601902 = query.getOrDefault("MaxRecords")
  valid_601902 = validateParameter(valid_601902, JInt, required = false, default = nil)
  if valid_601902 != nil:
    section.add "MaxRecords", valid_601902
  var valid_601903 = query.getOrDefault("Filters")
  valid_601903 = validateParameter(valid_601903, JArray, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "Filters", valid_601903
  var valid_601904 = query.getOrDefault("DBParameterGroupName")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "DBParameterGroupName", valid_601904
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601905 = query.getOrDefault("Action")
  valid_601905 = validateParameter(valid_601905, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601905 != nil:
    section.add "Action", valid_601905
  var valid_601906 = query.getOrDefault("Marker")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "Marker", valid_601906
  var valid_601907 = query.getOrDefault("Version")
  valid_601907 = validateParameter(valid_601907, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601907 != nil:
    section.add "Version", valid_601907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601908 = header.getOrDefault("X-Amz-Date")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Date", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Security-Token")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Security-Token", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Content-Sha256", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Algorithm")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Algorithm", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Signature")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Signature", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-SignedHeaders", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Credential")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Credential", valid_601914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601915: Call_GetDescribeDBParameterGroups_601899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601915.validator(path, query, header, formData, body)
  let scheme = call_601915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601915.url(scheme.get, call_601915.host, call_601915.base,
                         call_601915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601915, url, valid)

proc call*(call_601916: Call_GetDescribeDBParameterGroups_601899;
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
  var query_601917 = newJObject()
  add(query_601917, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601917.add "Filters", Filters
  add(query_601917, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601917, "Action", newJString(Action))
  add(query_601917, "Marker", newJString(Marker))
  add(query_601917, "Version", newJString(Version))
  result = call_601916.call(nil, query_601917, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601899(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601900, base: "/",
    url: url_GetDescribeDBParameterGroups_601901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_601958 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBParameters_601960(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_601959(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601961 = query.getOrDefault("Action")
  valid_601961 = validateParameter(valid_601961, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601961 != nil:
    section.add "Action", valid_601961
  var valid_601962 = query.getOrDefault("Version")
  valid_601962 = validateParameter(valid_601962, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601962 != nil:
    section.add "Version", valid_601962
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601963 = header.getOrDefault("X-Amz-Date")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Date", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Security-Token")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Security-Token", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Content-Sha256", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Algorithm")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Algorithm", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Signature")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Signature", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-SignedHeaders", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Credential")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Credential", valid_601969
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601970 = formData.getOrDefault("DBParameterGroupName")
  valid_601970 = validateParameter(valid_601970, JString, required = true,
                                 default = nil)
  if valid_601970 != nil:
    section.add "DBParameterGroupName", valid_601970
  var valid_601971 = formData.getOrDefault("Marker")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "Marker", valid_601971
  var valid_601972 = formData.getOrDefault("Filters")
  valid_601972 = validateParameter(valid_601972, JArray, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "Filters", valid_601972
  var valid_601973 = formData.getOrDefault("MaxRecords")
  valid_601973 = validateParameter(valid_601973, JInt, required = false, default = nil)
  if valid_601973 != nil:
    section.add "MaxRecords", valid_601973
  var valid_601974 = formData.getOrDefault("Source")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "Source", valid_601974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601975: Call_PostDescribeDBParameters_601958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601975.validator(path, query, header, formData, body)
  let scheme = call_601975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601975.url(scheme.get, call_601975.host, call_601975.base,
                         call_601975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601975, url, valid)

proc call*(call_601976: Call_PostDescribeDBParameters_601958;
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
  var query_601977 = newJObject()
  var formData_601978 = newJObject()
  add(formData_601978, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601978, "Marker", newJString(Marker))
  add(query_601977, "Action", newJString(Action))
  if Filters != nil:
    formData_601978.add "Filters", Filters
  add(formData_601978, "MaxRecords", newJInt(MaxRecords))
  add(query_601977, "Version", newJString(Version))
  add(formData_601978, "Source", newJString(Source))
  result = call_601976.call(nil, query_601977, nil, formData_601978, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_601958(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_601959, base: "/",
    url: url_PostDescribeDBParameters_601960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_601938 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBParameters_601940(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_601939(path: JsonNode; query: JsonNode;
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
  var valid_601941 = query.getOrDefault("MaxRecords")
  valid_601941 = validateParameter(valid_601941, JInt, required = false, default = nil)
  if valid_601941 != nil:
    section.add "MaxRecords", valid_601941
  var valid_601942 = query.getOrDefault("Filters")
  valid_601942 = validateParameter(valid_601942, JArray, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "Filters", valid_601942
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_601943 = query.getOrDefault("DBParameterGroupName")
  valid_601943 = validateParameter(valid_601943, JString, required = true,
                                 default = nil)
  if valid_601943 != nil:
    section.add "DBParameterGroupName", valid_601943
  var valid_601944 = query.getOrDefault("Action")
  valid_601944 = validateParameter(valid_601944, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601944 != nil:
    section.add "Action", valid_601944
  var valid_601945 = query.getOrDefault("Marker")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "Marker", valid_601945
  var valid_601946 = query.getOrDefault("Source")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "Source", valid_601946
  var valid_601947 = query.getOrDefault("Version")
  valid_601947 = validateParameter(valid_601947, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601947 != nil:
    section.add "Version", valid_601947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601948 = header.getOrDefault("X-Amz-Date")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Date", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Security-Token")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Security-Token", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Content-Sha256", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Algorithm")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Algorithm", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Signature")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Signature", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-SignedHeaders", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Credential")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Credential", valid_601954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601955: Call_GetDescribeDBParameters_601938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601955.validator(path, query, header, formData, body)
  let scheme = call_601955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601955.url(scheme.get, call_601955.host, call_601955.base,
                         call_601955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601955, url, valid)

proc call*(call_601956: Call_GetDescribeDBParameters_601938;
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
  var query_601957 = newJObject()
  add(query_601957, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601957.add "Filters", Filters
  add(query_601957, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601957, "Action", newJString(Action))
  add(query_601957, "Marker", newJString(Marker))
  add(query_601957, "Source", newJString(Source))
  add(query_601957, "Version", newJString(Version))
  result = call_601956.call(nil, query_601957, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_601938(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_601939, base: "/",
    url: url_GetDescribeDBParameters_601940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601998 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSecurityGroups_602000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_601999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602001 = query.getOrDefault("Action")
  valid_602001 = validateParameter(valid_602001, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602001 != nil:
    section.add "Action", valid_602001
  var valid_602002 = query.getOrDefault("Version")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602002 != nil:
    section.add "Version", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-SignedHeaders", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602010 = formData.getOrDefault("DBSecurityGroupName")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "DBSecurityGroupName", valid_602010
  var valid_602011 = formData.getOrDefault("Marker")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "Marker", valid_602011
  var valid_602012 = formData.getOrDefault("Filters")
  valid_602012 = validateParameter(valid_602012, JArray, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "Filters", valid_602012
  var valid_602013 = formData.getOrDefault("MaxRecords")
  valid_602013 = validateParameter(valid_602013, JInt, required = false, default = nil)
  if valid_602013 != nil:
    section.add "MaxRecords", valid_602013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_PostDescribeDBSecurityGroups_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602014, url, valid)

proc call*(call_602015: Call_PostDescribeDBSecurityGroups_601998;
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
  var query_602016 = newJObject()
  var formData_602017 = newJObject()
  add(formData_602017, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602017, "Marker", newJString(Marker))
  add(query_602016, "Action", newJString(Action))
  if Filters != nil:
    formData_602017.add "Filters", Filters
  add(formData_602017, "MaxRecords", newJInt(MaxRecords))
  add(query_602016, "Version", newJString(Version))
  result = call_602015.call(nil, query_602016, nil, formData_602017, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601998(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601999, base: "/",
    url: url_PostDescribeDBSecurityGroups_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_601979 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSecurityGroups_601981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_601980(path: JsonNode; query: JsonNode;
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
  var valid_601982 = query.getOrDefault("MaxRecords")
  valid_601982 = validateParameter(valid_601982, JInt, required = false, default = nil)
  if valid_601982 != nil:
    section.add "MaxRecords", valid_601982
  var valid_601983 = query.getOrDefault("DBSecurityGroupName")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "DBSecurityGroupName", valid_601983
  var valid_601984 = query.getOrDefault("Filters")
  valid_601984 = validateParameter(valid_601984, JArray, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "Filters", valid_601984
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601985 = query.getOrDefault("Action")
  valid_601985 = validateParameter(valid_601985, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601985 != nil:
    section.add "Action", valid_601985
  var valid_601986 = query.getOrDefault("Marker")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "Marker", valid_601986
  var valid_601987 = query.getOrDefault("Version")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601987 != nil:
    section.add "Version", valid_601987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601988 = header.getOrDefault("X-Amz-Date")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Date", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Security-Token")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Security-Token", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Algorithm")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Algorithm", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Signature")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Signature", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_GetDescribeDBSecurityGroups_601979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601995, url, valid)

proc call*(call_601996: Call_GetDescribeDBSecurityGroups_601979;
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
  var query_601997 = newJObject()
  add(query_601997, "MaxRecords", newJInt(MaxRecords))
  add(query_601997, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_601997.add "Filters", Filters
  add(query_601997, "Action", newJString(Action))
  add(query_601997, "Marker", newJString(Marker))
  add(query_601997, "Version", newJString(Version))
  result = call_601996.call(nil, query_601997, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_601979(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_601980, base: "/",
    url: url_GetDescribeDBSecurityGroups_601981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602039 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSnapshots_602041(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_602040(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602042 = query.getOrDefault("Action")
  valid_602042 = validateParameter(valid_602042, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602042 != nil:
    section.add "Action", valid_602042
  var valid_602043 = query.getOrDefault("Version")
  valid_602043 = validateParameter(valid_602043, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602043 != nil:
    section.add "Version", valid_602043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602044 = header.getOrDefault("X-Amz-Date")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Date", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Algorithm")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Algorithm", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-SignedHeaders", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602051 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "DBInstanceIdentifier", valid_602051
  var valid_602052 = formData.getOrDefault("SnapshotType")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "SnapshotType", valid_602052
  var valid_602053 = formData.getOrDefault("Marker")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "Marker", valid_602053
  var valid_602054 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "DBSnapshotIdentifier", valid_602054
  var valid_602055 = formData.getOrDefault("Filters")
  valid_602055 = validateParameter(valid_602055, JArray, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "Filters", valid_602055
  var valid_602056 = formData.getOrDefault("MaxRecords")
  valid_602056 = validateParameter(valid_602056, JInt, required = false, default = nil)
  if valid_602056 != nil:
    section.add "MaxRecords", valid_602056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_PostDescribeDBSnapshots_602039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602057.validator(path, query, header, formData, body)
  let scheme = call_602057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602057.url(scheme.get, call_602057.host, call_602057.base,
                         call_602057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602057, url, valid)

proc call*(call_602058: Call_PostDescribeDBSnapshots_602039;
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
  var query_602059 = newJObject()
  var formData_602060 = newJObject()
  add(formData_602060, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602060, "SnapshotType", newJString(SnapshotType))
  add(formData_602060, "Marker", newJString(Marker))
  add(formData_602060, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602059, "Action", newJString(Action))
  if Filters != nil:
    formData_602060.add "Filters", Filters
  add(formData_602060, "MaxRecords", newJInt(MaxRecords))
  add(query_602059, "Version", newJString(Version))
  result = call_602058.call(nil, query_602059, nil, formData_602060, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602039(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602040, base: "/",
    url: url_PostDescribeDBSnapshots_602041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602018 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSnapshots_602020(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_602019(path: JsonNode; query: JsonNode;
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
  var valid_602021 = query.getOrDefault("MaxRecords")
  valid_602021 = validateParameter(valid_602021, JInt, required = false, default = nil)
  if valid_602021 != nil:
    section.add "MaxRecords", valid_602021
  var valid_602022 = query.getOrDefault("Filters")
  valid_602022 = validateParameter(valid_602022, JArray, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "Filters", valid_602022
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602023 = query.getOrDefault("Action")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602023 != nil:
    section.add "Action", valid_602023
  var valid_602024 = query.getOrDefault("Marker")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "Marker", valid_602024
  var valid_602025 = query.getOrDefault("SnapshotType")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "SnapshotType", valid_602025
  var valid_602026 = query.getOrDefault("Version")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602026 != nil:
    section.add "Version", valid_602026
  var valid_602027 = query.getOrDefault("DBInstanceIdentifier")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "DBInstanceIdentifier", valid_602027
  var valid_602028 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "DBSnapshotIdentifier", valid_602028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Security-Token")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Security-Token", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-SignedHeaders", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Credential")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Credential", valid_602035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602036: Call_GetDescribeDBSnapshots_602018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602036.validator(path, query, header, formData, body)
  let scheme = call_602036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602036.url(scheme.get, call_602036.host, call_602036.base,
                         call_602036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602036, url, valid)

proc call*(call_602037: Call_GetDescribeDBSnapshots_602018; MaxRecords: int = 0;
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
  var query_602038 = newJObject()
  add(query_602038, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602038.add "Filters", Filters
  add(query_602038, "Action", newJString(Action))
  add(query_602038, "Marker", newJString(Marker))
  add(query_602038, "SnapshotType", newJString(SnapshotType))
  add(query_602038, "Version", newJString(Version))
  add(query_602038, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602038, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602037.call(nil, query_602038, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602018(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602019, base: "/",
    url: url_GetDescribeDBSnapshots_602020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602080 = ref object of OpenApiRestCall_600421
proc url_PostDescribeDBSubnetGroups_602082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_602081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602083 = query.getOrDefault("Action")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602083 != nil:
    section.add "Action", valid_602083
  var valid_602084 = query.getOrDefault("Version")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602084 != nil:
    section.add "Version", valid_602084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Security-Token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Security-Token", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Content-Sha256", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Signature")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Signature", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-SignedHeaders", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Credential")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Credential", valid_602091
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602092 = formData.getOrDefault("DBSubnetGroupName")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "DBSubnetGroupName", valid_602092
  var valid_602093 = formData.getOrDefault("Marker")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "Marker", valid_602093
  var valid_602094 = formData.getOrDefault("Filters")
  valid_602094 = validateParameter(valid_602094, JArray, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "Filters", valid_602094
  var valid_602095 = formData.getOrDefault("MaxRecords")
  valid_602095 = validateParameter(valid_602095, JInt, required = false, default = nil)
  if valid_602095 != nil:
    section.add "MaxRecords", valid_602095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602096: Call_PostDescribeDBSubnetGroups_602080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602096.validator(path, query, header, formData, body)
  let scheme = call_602096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602096.url(scheme.get, call_602096.host, call_602096.base,
                         call_602096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602096, url, valid)

proc call*(call_602097: Call_PostDescribeDBSubnetGroups_602080;
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
  var query_602098 = newJObject()
  var formData_602099 = newJObject()
  add(formData_602099, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602099, "Marker", newJString(Marker))
  add(query_602098, "Action", newJString(Action))
  if Filters != nil:
    formData_602099.add "Filters", Filters
  add(formData_602099, "MaxRecords", newJInt(MaxRecords))
  add(query_602098, "Version", newJString(Version))
  result = call_602097.call(nil, query_602098, nil, formData_602099, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602080(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602081, base: "/",
    url: url_PostDescribeDBSubnetGroups_602082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602061 = ref object of OpenApiRestCall_600421
proc url_GetDescribeDBSubnetGroups_602063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_602062(path: JsonNode; query: JsonNode;
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
  var valid_602064 = query.getOrDefault("MaxRecords")
  valid_602064 = validateParameter(valid_602064, JInt, required = false, default = nil)
  if valid_602064 != nil:
    section.add "MaxRecords", valid_602064
  var valid_602065 = query.getOrDefault("Filters")
  valid_602065 = validateParameter(valid_602065, JArray, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "Filters", valid_602065
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602066 = query.getOrDefault("Action")
  valid_602066 = validateParameter(valid_602066, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602066 != nil:
    section.add "Action", valid_602066
  var valid_602067 = query.getOrDefault("Marker")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "Marker", valid_602067
  var valid_602068 = query.getOrDefault("DBSubnetGroupName")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "DBSubnetGroupName", valid_602068
  var valid_602069 = query.getOrDefault("Version")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602069 != nil:
    section.add "Version", valid_602069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Security-Token")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Security-Token", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Content-Sha256", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Signature")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Signature", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-SignedHeaders", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Credential")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Credential", valid_602076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_GetDescribeDBSubnetGroups_602061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602077, url, valid)

proc call*(call_602078: Call_GetDescribeDBSubnetGroups_602061; MaxRecords: int = 0;
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
  var query_602079 = newJObject()
  add(query_602079, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602079.add "Filters", Filters
  add(query_602079, "Action", newJString(Action))
  add(query_602079, "Marker", newJString(Marker))
  add(query_602079, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602079, "Version", newJString(Version))
  result = call_602078.call(nil, query_602079, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602061(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602062, base: "/",
    url: url_GetDescribeDBSubnetGroups_602063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602119 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEngineDefaultParameters_602121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_602120(path: JsonNode;
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
  var valid_602122 = query.getOrDefault("Action")
  valid_602122 = validateParameter(valid_602122, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602122 != nil:
    section.add "Action", valid_602122
  var valid_602123 = query.getOrDefault("Version")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602123 != nil:
    section.add "Version", valid_602123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Content-Sha256", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Signature", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602131 = formData.getOrDefault("Marker")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "Marker", valid_602131
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602132 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "DBParameterGroupFamily", valid_602132
  var valid_602133 = formData.getOrDefault("Filters")
  valid_602133 = validateParameter(valid_602133, JArray, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Filters", valid_602133
  var valid_602134 = formData.getOrDefault("MaxRecords")
  valid_602134 = validateParameter(valid_602134, JInt, required = false, default = nil)
  if valid_602134 != nil:
    section.add "MaxRecords", valid_602134
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602135: Call_PostDescribeEngineDefaultParameters_602119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602135.validator(path, query, header, formData, body)
  let scheme = call_602135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602135.url(scheme.get, call_602135.host, call_602135.base,
                         call_602135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602135, url, valid)

proc call*(call_602136: Call_PostDescribeEngineDefaultParameters_602119;
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
  var query_602137 = newJObject()
  var formData_602138 = newJObject()
  add(formData_602138, "Marker", newJString(Marker))
  add(query_602137, "Action", newJString(Action))
  add(formData_602138, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_602138.add "Filters", Filters
  add(formData_602138, "MaxRecords", newJInt(MaxRecords))
  add(query_602137, "Version", newJString(Version))
  result = call_602136.call(nil, query_602137, nil, formData_602138, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602119(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602120, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602100 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEngineDefaultParameters_602102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_602101(path: JsonNode;
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
  var valid_602103 = query.getOrDefault("MaxRecords")
  valid_602103 = validateParameter(valid_602103, JInt, required = false, default = nil)
  if valid_602103 != nil:
    section.add "MaxRecords", valid_602103
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602104 = query.getOrDefault("DBParameterGroupFamily")
  valid_602104 = validateParameter(valid_602104, JString, required = true,
                                 default = nil)
  if valid_602104 != nil:
    section.add "DBParameterGroupFamily", valid_602104
  var valid_602105 = query.getOrDefault("Filters")
  valid_602105 = validateParameter(valid_602105, JArray, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "Filters", valid_602105
  var valid_602106 = query.getOrDefault("Action")
  valid_602106 = validateParameter(valid_602106, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602106 != nil:
    section.add "Action", valid_602106
  var valid_602107 = query.getOrDefault("Marker")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "Marker", valid_602107
  var valid_602108 = query.getOrDefault("Version")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602108 != nil:
    section.add "Version", valid_602108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Security-Token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Security-Token", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Content-Sha256", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Credential")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Credential", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_GetDescribeEngineDefaultParameters_602100;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602116, url, valid)

proc call*(call_602117: Call_GetDescribeEngineDefaultParameters_602100;
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
  var query_602118 = newJObject()
  add(query_602118, "MaxRecords", newJInt(MaxRecords))
  add(query_602118, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_602118.add "Filters", Filters
  add(query_602118, "Action", newJString(Action))
  add(query_602118, "Marker", newJString(Marker))
  add(query_602118, "Version", newJString(Version))
  result = call_602117.call(nil, query_602118, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602100(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602101, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602156 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventCategories_602158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_602157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602159 = query.getOrDefault("Action")
  valid_602159 = validateParameter(valid_602159, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602159 != nil:
    section.add "Action", valid_602159
  var valid_602160 = query.getOrDefault("Version")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602160 != nil:
    section.add "Version", valid_602160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602161 = header.getOrDefault("X-Amz-Date")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Date", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Algorithm")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Algorithm", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-SignedHeaders", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Credential")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Credential", valid_602167
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_602168 = formData.getOrDefault("Filters")
  valid_602168 = validateParameter(valid_602168, JArray, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "Filters", valid_602168
  var valid_602169 = formData.getOrDefault("SourceType")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "SourceType", valid_602169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602170: Call_PostDescribeEventCategories_602156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602170.validator(path, query, header, formData, body)
  let scheme = call_602170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602170.url(scheme.get, call_602170.host, call_602170.base,
                         call_602170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602170, url, valid)

proc call*(call_602171: Call_PostDescribeEventCategories_602156;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_602172 = newJObject()
  var formData_602173 = newJObject()
  add(query_602172, "Action", newJString(Action))
  if Filters != nil:
    formData_602173.add "Filters", Filters
  add(query_602172, "Version", newJString(Version))
  add(formData_602173, "SourceType", newJString(SourceType))
  result = call_602171.call(nil, query_602172, nil, formData_602173, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602156(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602157, base: "/",
    url: url_PostDescribeEventCategories_602158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602139 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventCategories_602141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_602140(path: JsonNode; query: JsonNode;
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
  var valid_602142 = query.getOrDefault("SourceType")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "SourceType", valid_602142
  var valid_602143 = query.getOrDefault("Filters")
  valid_602143 = validateParameter(valid_602143, JArray, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "Filters", valid_602143
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602144 = query.getOrDefault("Action")
  valid_602144 = validateParameter(valid_602144, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602144 != nil:
    section.add "Action", valid_602144
  var valid_602145 = query.getOrDefault("Version")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602145 != nil:
    section.add "Version", valid_602145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Content-Sha256", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-SignedHeaders", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Credential")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Credential", valid_602152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602153: Call_GetDescribeEventCategories_602139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602153.validator(path, query, header, formData, body)
  let scheme = call_602153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602153.url(scheme.get, call_602153.host, call_602153.base,
                         call_602153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602153, url, valid)

proc call*(call_602154: Call_GetDescribeEventCategories_602139;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602155 = newJObject()
  add(query_602155, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_602155.add "Filters", Filters
  add(query_602155, "Action", newJString(Action))
  add(query_602155, "Version", newJString(Version))
  result = call_602154.call(nil, query_602155, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602139(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602140, base: "/",
    url: url_GetDescribeEventCategories_602141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602193 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEventSubscriptions_602195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_602194(path: JsonNode;
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
  var valid_602196 = query.getOrDefault("Action")
  valid_602196 = validateParameter(valid_602196, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602196 != nil:
    section.add "Action", valid_602196
  var valid_602197 = query.getOrDefault("Version")
  valid_602197 = validateParameter(valid_602197, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602197 != nil:
    section.add "Version", valid_602197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602198 = header.getOrDefault("X-Amz-Date")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Date", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Content-Sha256", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Algorithm")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Algorithm", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Signature")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Signature", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-SignedHeaders", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Credential")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Credential", valid_602204
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602205 = formData.getOrDefault("Marker")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "Marker", valid_602205
  var valid_602206 = formData.getOrDefault("SubscriptionName")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "SubscriptionName", valid_602206
  var valid_602207 = formData.getOrDefault("Filters")
  valid_602207 = validateParameter(valid_602207, JArray, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "Filters", valid_602207
  var valid_602208 = formData.getOrDefault("MaxRecords")
  valid_602208 = validateParameter(valid_602208, JInt, required = false, default = nil)
  if valid_602208 != nil:
    section.add "MaxRecords", valid_602208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602209: Call_PostDescribeEventSubscriptions_602193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602209.validator(path, query, header, formData, body)
  let scheme = call_602209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602209.url(scheme.get, call_602209.host, call_602209.base,
                         call_602209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602209, url, valid)

proc call*(call_602210: Call_PostDescribeEventSubscriptions_602193;
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
  var query_602211 = newJObject()
  var formData_602212 = newJObject()
  add(formData_602212, "Marker", newJString(Marker))
  add(formData_602212, "SubscriptionName", newJString(SubscriptionName))
  add(query_602211, "Action", newJString(Action))
  if Filters != nil:
    formData_602212.add "Filters", Filters
  add(formData_602212, "MaxRecords", newJInt(MaxRecords))
  add(query_602211, "Version", newJString(Version))
  result = call_602210.call(nil, query_602211, nil, formData_602212, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602193(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602194, base: "/",
    url: url_PostDescribeEventSubscriptions_602195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602174 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEventSubscriptions_602176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_602175(path: JsonNode; query: JsonNode;
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
  var valid_602177 = query.getOrDefault("MaxRecords")
  valid_602177 = validateParameter(valid_602177, JInt, required = false, default = nil)
  if valid_602177 != nil:
    section.add "MaxRecords", valid_602177
  var valid_602178 = query.getOrDefault("Filters")
  valid_602178 = validateParameter(valid_602178, JArray, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "Filters", valid_602178
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602179 = query.getOrDefault("Action")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602179 != nil:
    section.add "Action", valid_602179
  var valid_602180 = query.getOrDefault("Marker")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Marker", valid_602180
  var valid_602181 = query.getOrDefault("SubscriptionName")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "SubscriptionName", valid_602181
  var valid_602182 = query.getOrDefault("Version")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602182 != nil:
    section.add "Version", valid_602182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602183 = header.getOrDefault("X-Amz-Date")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Date", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Content-Sha256", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Algorithm")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Algorithm", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Signature")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Signature", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-SignedHeaders", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Credential")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Credential", valid_602189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602190: Call_GetDescribeEventSubscriptions_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602190.validator(path, query, header, formData, body)
  let scheme = call_602190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602190.url(scheme.get, call_602190.host, call_602190.base,
                         call_602190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602190, url, valid)

proc call*(call_602191: Call_GetDescribeEventSubscriptions_602174;
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
  var query_602192 = newJObject()
  add(query_602192, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602192.add "Filters", Filters
  add(query_602192, "Action", newJString(Action))
  add(query_602192, "Marker", newJString(Marker))
  add(query_602192, "SubscriptionName", newJString(SubscriptionName))
  add(query_602192, "Version", newJString(Version))
  result = call_602191.call(nil, query_602192, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602174(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602175, base: "/",
    url: url_GetDescribeEventSubscriptions_602176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602237 = ref object of OpenApiRestCall_600421
proc url_PostDescribeEvents_602239(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_602238(path: JsonNode; query: JsonNode;
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
  var valid_602240 = query.getOrDefault("Action")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602240 != nil:
    section.add "Action", valid_602240
  var valid_602241 = query.getOrDefault("Version")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602241 != nil:
    section.add "Version", valid_602241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Security-Token")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Security-Token", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Content-Sha256", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Signature")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Signature", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
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
  var valid_602249 = formData.getOrDefault("SourceIdentifier")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "SourceIdentifier", valid_602249
  var valid_602250 = formData.getOrDefault("EventCategories")
  valid_602250 = validateParameter(valid_602250, JArray, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "EventCategories", valid_602250
  var valid_602251 = formData.getOrDefault("Marker")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "Marker", valid_602251
  var valid_602252 = formData.getOrDefault("StartTime")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "StartTime", valid_602252
  var valid_602253 = formData.getOrDefault("Duration")
  valid_602253 = validateParameter(valid_602253, JInt, required = false, default = nil)
  if valid_602253 != nil:
    section.add "Duration", valid_602253
  var valid_602254 = formData.getOrDefault("Filters")
  valid_602254 = validateParameter(valid_602254, JArray, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "Filters", valid_602254
  var valid_602255 = formData.getOrDefault("EndTime")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "EndTime", valid_602255
  var valid_602256 = formData.getOrDefault("MaxRecords")
  valid_602256 = validateParameter(valid_602256, JInt, required = false, default = nil)
  if valid_602256 != nil:
    section.add "MaxRecords", valid_602256
  var valid_602257 = formData.getOrDefault("SourceType")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602257 != nil:
    section.add "SourceType", valid_602257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_PostDescribeEvents_602237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602258, url, valid)

proc call*(call_602259: Call_PostDescribeEvents_602237;
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
  var query_602260 = newJObject()
  var formData_602261 = newJObject()
  add(formData_602261, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602261.add "EventCategories", EventCategories
  add(formData_602261, "Marker", newJString(Marker))
  add(formData_602261, "StartTime", newJString(StartTime))
  add(query_602260, "Action", newJString(Action))
  add(formData_602261, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_602261.add "Filters", Filters
  add(formData_602261, "EndTime", newJString(EndTime))
  add(formData_602261, "MaxRecords", newJInt(MaxRecords))
  add(query_602260, "Version", newJString(Version))
  add(formData_602261, "SourceType", newJString(SourceType))
  result = call_602259.call(nil, query_602260, nil, formData_602261, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602237(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602238, base: "/",
    url: url_PostDescribeEvents_602239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602213 = ref object of OpenApiRestCall_600421
proc url_GetDescribeEvents_602215(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_602214(path: JsonNode; query: JsonNode;
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
  var valid_602216 = query.getOrDefault("SourceType")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602216 != nil:
    section.add "SourceType", valid_602216
  var valid_602217 = query.getOrDefault("MaxRecords")
  valid_602217 = validateParameter(valid_602217, JInt, required = false, default = nil)
  if valid_602217 != nil:
    section.add "MaxRecords", valid_602217
  var valid_602218 = query.getOrDefault("StartTime")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "StartTime", valid_602218
  var valid_602219 = query.getOrDefault("Filters")
  valid_602219 = validateParameter(valid_602219, JArray, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "Filters", valid_602219
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602220 = query.getOrDefault("Action")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602220 != nil:
    section.add "Action", valid_602220
  var valid_602221 = query.getOrDefault("SourceIdentifier")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "SourceIdentifier", valid_602221
  var valid_602222 = query.getOrDefault("Marker")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "Marker", valid_602222
  var valid_602223 = query.getOrDefault("EventCategories")
  valid_602223 = validateParameter(valid_602223, JArray, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "EventCategories", valid_602223
  var valid_602224 = query.getOrDefault("Duration")
  valid_602224 = validateParameter(valid_602224, JInt, required = false, default = nil)
  if valid_602224 != nil:
    section.add "Duration", valid_602224
  var valid_602225 = query.getOrDefault("EndTime")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "EndTime", valid_602225
  var valid_602226 = query.getOrDefault("Version")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602226 != nil:
    section.add "Version", valid_602226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Security-Token")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Security-Token", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Content-Sha256", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Credential")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Credential", valid_602233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602234: Call_GetDescribeEvents_602213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602234.validator(path, query, header, formData, body)
  let scheme = call_602234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602234.url(scheme.get, call_602234.host, call_602234.base,
                         call_602234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602234, url, valid)

proc call*(call_602235: Call_GetDescribeEvents_602213;
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
  var query_602236 = newJObject()
  add(query_602236, "SourceType", newJString(SourceType))
  add(query_602236, "MaxRecords", newJInt(MaxRecords))
  add(query_602236, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_602236.add "Filters", Filters
  add(query_602236, "Action", newJString(Action))
  add(query_602236, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602236, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602236.add "EventCategories", EventCategories
  add(query_602236, "Duration", newJInt(Duration))
  add(query_602236, "EndTime", newJString(EndTime))
  add(query_602236, "Version", newJString(Version))
  result = call_602235.call(nil, query_602236, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602213(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602214,
    base: "/", url: url_GetDescribeEvents_602215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602282 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroupOptions_602284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_602283(path: JsonNode;
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
  var valid_602285 = query.getOrDefault("Action")
  valid_602285 = validateParameter(valid_602285, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602285 != nil:
    section.add "Action", valid_602285
  var valid_602286 = query.getOrDefault("Version")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602286 != nil:
    section.add "Version", valid_602286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602287 = header.getOrDefault("X-Amz-Date")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Date", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Content-Sha256", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Algorithm")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Algorithm", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Signature")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Signature", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Credential")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Credential", valid_602293
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602294 = formData.getOrDefault("MajorEngineVersion")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "MajorEngineVersion", valid_602294
  var valid_602295 = formData.getOrDefault("Marker")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "Marker", valid_602295
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602296 = formData.getOrDefault("EngineName")
  valid_602296 = validateParameter(valid_602296, JString, required = true,
                                 default = nil)
  if valid_602296 != nil:
    section.add "EngineName", valid_602296
  var valid_602297 = formData.getOrDefault("Filters")
  valid_602297 = validateParameter(valid_602297, JArray, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "Filters", valid_602297
  var valid_602298 = formData.getOrDefault("MaxRecords")
  valid_602298 = validateParameter(valid_602298, JInt, required = false, default = nil)
  if valid_602298 != nil:
    section.add "MaxRecords", valid_602298
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602299: Call_PostDescribeOptionGroupOptions_602282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602299.validator(path, query, header, formData, body)
  let scheme = call_602299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602299.url(scheme.get, call_602299.host, call_602299.base,
                         call_602299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602299, url, valid)

proc call*(call_602300: Call_PostDescribeOptionGroupOptions_602282;
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
  var query_602301 = newJObject()
  var formData_602302 = newJObject()
  add(formData_602302, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602302, "Marker", newJString(Marker))
  add(query_602301, "Action", newJString(Action))
  add(formData_602302, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602302.add "Filters", Filters
  add(formData_602302, "MaxRecords", newJInt(MaxRecords))
  add(query_602301, "Version", newJString(Version))
  result = call_602300.call(nil, query_602301, nil, formData_602302, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602282(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602283, base: "/",
    url: url_PostDescribeOptionGroupOptions_602284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602262 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroupOptions_602264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_602263(path: JsonNode; query: JsonNode;
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
  var valid_602265 = query.getOrDefault("MaxRecords")
  valid_602265 = validateParameter(valid_602265, JInt, required = false, default = nil)
  if valid_602265 != nil:
    section.add "MaxRecords", valid_602265
  var valid_602266 = query.getOrDefault("Filters")
  valid_602266 = validateParameter(valid_602266, JArray, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "Filters", valid_602266
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602267 = query.getOrDefault("Action")
  valid_602267 = validateParameter(valid_602267, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602267 != nil:
    section.add "Action", valid_602267
  var valid_602268 = query.getOrDefault("Marker")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "Marker", valid_602268
  var valid_602269 = query.getOrDefault("Version")
  valid_602269 = validateParameter(valid_602269, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602269 != nil:
    section.add "Version", valid_602269
  var valid_602270 = query.getOrDefault("EngineName")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "EngineName", valid_602270
  var valid_602271 = query.getOrDefault("MajorEngineVersion")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "MajorEngineVersion", valid_602271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602272 = header.getOrDefault("X-Amz-Date")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Date", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Security-Token")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Security-Token", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Content-Sha256", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Signature")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Signature", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Credential")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Credential", valid_602278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602279: Call_GetDescribeOptionGroupOptions_602262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602279.validator(path, query, header, formData, body)
  let scheme = call_602279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602279.url(scheme.get, call_602279.host, call_602279.base,
                         call_602279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602279, url, valid)

proc call*(call_602280: Call_GetDescribeOptionGroupOptions_602262;
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
  var query_602281 = newJObject()
  add(query_602281, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602281.add "Filters", Filters
  add(query_602281, "Action", newJString(Action))
  add(query_602281, "Marker", newJString(Marker))
  add(query_602281, "Version", newJString(Version))
  add(query_602281, "EngineName", newJString(EngineName))
  add(query_602281, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602280.call(nil, query_602281, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602262(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602263, base: "/",
    url: url_GetDescribeOptionGroupOptions_602264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602324 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOptionGroups_602326(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_602325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602327 = query.getOrDefault("Action")
  valid_602327 = validateParameter(valid_602327, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602327 != nil:
    section.add "Action", valid_602327
  var valid_602328 = query.getOrDefault("Version")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602328 != nil:
    section.add "Version", valid_602328
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602329 = header.getOrDefault("X-Amz-Date")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Date", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Security-Token")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Security-Token", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Algorithm")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Algorithm", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Signature")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Signature", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Credential")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Credential", valid_602335
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602336 = formData.getOrDefault("MajorEngineVersion")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "MajorEngineVersion", valid_602336
  var valid_602337 = formData.getOrDefault("OptionGroupName")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "OptionGroupName", valid_602337
  var valid_602338 = formData.getOrDefault("Marker")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "Marker", valid_602338
  var valid_602339 = formData.getOrDefault("EngineName")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "EngineName", valid_602339
  var valid_602340 = formData.getOrDefault("Filters")
  valid_602340 = validateParameter(valid_602340, JArray, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "Filters", valid_602340
  var valid_602341 = formData.getOrDefault("MaxRecords")
  valid_602341 = validateParameter(valid_602341, JInt, required = false, default = nil)
  if valid_602341 != nil:
    section.add "MaxRecords", valid_602341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602342: Call_PostDescribeOptionGroups_602324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602342.validator(path, query, header, formData, body)
  let scheme = call_602342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602342.url(scheme.get, call_602342.host, call_602342.base,
                         call_602342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602342, url, valid)

proc call*(call_602343: Call_PostDescribeOptionGroups_602324;
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
  var query_602344 = newJObject()
  var formData_602345 = newJObject()
  add(formData_602345, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602345, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602345, "Marker", newJString(Marker))
  add(query_602344, "Action", newJString(Action))
  add(formData_602345, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602345.add "Filters", Filters
  add(formData_602345, "MaxRecords", newJInt(MaxRecords))
  add(query_602344, "Version", newJString(Version))
  result = call_602343.call(nil, query_602344, nil, formData_602345, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602324(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602325, base: "/",
    url: url_PostDescribeOptionGroups_602326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602303 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOptionGroups_602305(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_602304(path: JsonNode; query: JsonNode;
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
  var valid_602306 = query.getOrDefault("MaxRecords")
  valid_602306 = validateParameter(valid_602306, JInt, required = false, default = nil)
  if valid_602306 != nil:
    section.add "MaxRecords", valid_602306
  var valid_602307 = query.getOrDefault("OptionGroupName")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "OptionGroupName", valid_602307
  var valid_602308 = query.getOrDefault("Filters")
  valid_602308 = validateParameter(valid_602308, JArray, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "Filters", valid_602308
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602309 = query.getOrDefault("Action")
  valid_602309 = validateParameter(valid_602309, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602309 != nil:
    section.add "Action", valid_602309
  var valid_602310 = query.getOrDefault("Marker")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "Marker", valid_602310
  var valid_602311 = query.getOrDefault("Version")
  valid_602311 = validateParameter(valid_602311, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602311 != nil:
    section.add "Version", valid_602311
  var valid_602312 = query.getOrDefault("EngineName")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "EngineName", valid_602312
  var valid_602313 = query.getOrDefault("MajorEngineVersion")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "MajorEngineVersion", valid_602313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602314 = header.getOrDefault("X-Amz-Date")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Date", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Security-Token")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Security-Token", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Algorithm")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Algorithm", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Signature")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Signature", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-SignedHeaders", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Credential")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Credential", valid_602320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_GetDescribeOptionGroups_602303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602321, url, valid)

proc call*(call_602322: Call_GetDescribeOptionGroups_602303; MaxRecords: int = 0;
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
  var query_602323 = newJObject()
  add(query_602323, "MaxRecords", newJInt(MaxRecords))
  add(query_602323, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_602323.add "Filters", Filters
  add(query_602323, "Action", newJString(Action))
  add(query_602323, "Marker", newJString(Marker))
  add(query_602323, "Version", newJString(Version))
  add(query_602323, "EngineName", newJString(EngineName))
  add(query_602323, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602322.call(nil, query_602323, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602303(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602304, base: "/",
    url: url_GetDescribeOptionGroups_602305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602369 = ref object of OpenApiRestCall_600421
proc url_PostDescribeOrderableDBInstanceOptions_602371(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602370(path: JsonNode;
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
  var valid_602372 = query.getOrDefault("Action")
  valid_602372 = validateParameter(valid_602372, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602372 != nil:
    section.add "Action", valid_602372
  var valid_602373 = query.getOrDefault("Version")
  valid_602373 = validateParameter(valid_602373, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602373 != nil:
    section.add "Version", valid_602373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602374 = header.getOrDefault("X-Amz-Date")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Date", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Security-Token")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Security-Token", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Content-Sha256", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Algorithm")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Algorithm", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Signature")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Signature", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-SignedHeaders", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Credential")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Credential", valid_602380
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
  var valid_602381 = formData.getOrDefault("Engine")
  valid_602381 = validateParameter(valid_602381, JString, required = true,
                                 default = nil)
  if valid_602381 != nil:
    section.add "Engine", valid_602381
  var valid_602382 = formData.getOrDefault("Marker")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "Marker", valid_602382
  var valid_602383 = formData.getOrDefault("Vpc")
  valid_602383 = validateParameter(valid_602383, JBool, required = false, default = nil)
  if valid_602383 != nil:
    section.add "Vpc", valid_602383
  var valid_602384 = formData.getOrDefault("DBInstanceClass")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "DBInstanceClass", valid_602384
  var valid_602385 = formData.getOrDefault("Filters")
  valid_602385 = validateParameter(valid_602385, JArray, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "Filters", valid_602385
  var valid_602386 = formData.getOrDefault("LicenseModel")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "LicenseModel", valid_602386
  var valid_602387 = formData.getOrDefault("MaxRecords")
  valid_602387 = validateParameter(valid_602387, JInt, required = false, default = nil)
  if valid_602387 != nil:
    section.add "MaxRecords", valid_602387
  var valid_602388 = formData.getOrDefault("EngineVersion")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "EngineVersion", valid_602388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_PostDescribeOrderableDBInstanceOptions_602369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602389, url, valid)

proc call*(call_602390: Call_PostDescribeOrderableDBInstanceOptions_602369;
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
  var query_602391 = newJObject()
  var formData_602392 = newJObject()
  add(formData_602392, "Engine", newJString(Engine))
  add(formData_602392, "Marker", newJString(Marker))
  add(query_602391, "Action", newJString(Action))
  add(formData_602392, "Vpc", newJBool(Vpc))
  add(formData_602392, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602392.add "Filters", Filters
  add(formData_602392, "LicenseModel", newJString(LicenseModel))
  add(formData_602392, "MaxRecords", newJInt(MaxRecords))
  add(formData_602392, "EngineVersion", newJString(EngineVersion))
  add(query_602391, "Version", newJString(Version))
  result = call_602390.call(nil, query_602391, nil, formData_602392, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602369(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602370, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602346 = ref object of OpenApiRestCall_600421
proc url_GetDescribeOrderableDBInstanceOptions_602348(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602347(path: JsonNode;
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
  var valid_602349 = query.getOrDefault("Engine")
  valid_602349 = validateParameter(valid_602349, JString, required = true,
                                 default = nil)
  if valid_602349 != nil:
    section.add "Engine", valid_602349
  var valid_602350 = query.getOrDefault("MaxRecords")
  valid_602350 = validateParameter(valid_602350, JInt, required = false, default = nil)
  if valid_602350 != nil:
    section.add "MaxRecords", valid_602350
  var valid_602351 = query.getOrDefault("Filters")
  valid_602351 = validateParameter(valid_602351, JArray, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "Filters", valid_602351
  var valid_602352 = query.getOrDefault("LicenseModel")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "LicenseModel", valid_602352
  var valid_602353 = query.getOrDefault("Vpc")
  valid_602353 = validateParameter(valid_602353, JBool, required = false, default = nil)
  if valid_602353 != nil:
    section.add "Vpc", valid_602353
  var valid_602354 = query.getOrDefault("DBInstanceClass")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "DBInstanceClass", valid_602354
  var valid_602355 = query.getOrDefault("Action")
  valid_602355 = validateParameter(valid_602355, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602355 != nil:
    section.add "Action", valid_602355
  var valid_602356 = query.getOrDefault("Marker")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "Marker", valid_602356
  var valid_602357 = query.getOrDefault("EngineVersion")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "EngineVersion", valid_602357
  var valid_602358 = query.getOrDefault("Version")
  valid_602358 = validateParameter(valid_602358, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602358 != nil:
    section.add "Version", valid_602358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602359 = header.getOrDefault("X-Amz-Date")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Date", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Security-Token")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Security-Token", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Signature")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Signature", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-SignedHeaders", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602366: Call_GetDescribeOrderableDBInstanceOptions_602346;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602366.validator(path, query, header, formData, body)
  let scheme = call_602366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602366.url(scheme.get, call_602366.host, call_602366.base,
                         call_602366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602366, url, valid)

proc call*(call_602367: Call_GetDescribeOrderableDBInstanceOptions_602346;
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
  var query_602368 = newJObject()
  add(query_602368, "Engine", newJString(Engine))
  add(query_602368, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602368.add "Filters", Filters
  add(query_602368, "LicenseModel", newJString(LicenseModel))
  add(query_602368, "Vpc", newJBool(Vpc))
  add(query_602368, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602368, "Action", newJString(Action))
  add(query_602368, "Marker", newJString(Marker))
  add(query_602368, "EngineVersion", newJString(EngineVersion))
  add(query_602368, "Version", newJString(Version))
  result = call_602367.call(nil, query_602368, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602346(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602347, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602418 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstances_602420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_602419(path: JsonNode;
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
  var valid_602421 = query.getOrDefault("Action")
  valid_602421 = validateParameter(valid_602421, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602421 != nil:
    section.add "Action", valid_602421
  var valid_602422 = query.getOrDefault("Version")
  valid_602422 = validateParameter(valid_602422, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602422 != nil:
    section.add "Version", valid_602422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602423 = header.getOrDefault("X-Amz-Date")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Date", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Algorithm")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Algorithm", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-SignedHeaders", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Credential")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Credential", valid_602429
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
  var valid_602430 = formData.getOrDefault("OfferingType")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "OfferingType", valid_602430
  var valid_602431 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "ReservedDBInstanceId", valid_602431
  var valid_602432 = formData.getOrDefault("Marker")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "Marker", valid_602432
  var valid_602433 = formData.getOrDefault("MultiAZ")
  valid_602433 = validateParameter(valid_602433, JBool, required = false, default = nil)
  if valid_602433 != nil:
    section.add "MultiAZ", valid_602433
  var valid_602434 = formData.getOrDefault("Duration")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "Duration", valid_602434
  var valid_602435 = formData.getOrDefault("DBInstanceClass")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "DBInstanceClass", valid_602435
  var valid_602436 = formData.getOrDefault("Filters")
  valid_602436 = validateParameter(valid_602436, JArray, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "Filters", valid_602436
  var valid_602437 = formData.getOrDefault("ProductDescription")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "ProductDescription", valid_602437
  var valid_602438 = formData.getOrDefault("MaxRecords")
  valid_602438 = validateParameter(valid_602438, JInt, required = false, default = nil)
  if valid_602438 != nil:
    section.add "MaxRecords", valid_602438
  var valid_602439 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602439
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602440: Call_PostDescribeReservedDBInstances_602418;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602440.validator(path, query, header, formData, body)
  let scheme = call_602440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602440.url(scheme.get, call_602440.host, call_602440.base,
                         call_602440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602440, url, valid)

proc call*(call_602441: Call_PostDescribeReservedDBInstances_602418;
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
  var query_602442 = newJObject()
  var formData_602443 = newJObject()
  add(formData_602443, "OfferingType", newJString(OfferingType))
  add(formData_602443, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602443, "Marker", newJString(Marker))
  add(formData_602443, "MultiAZ", newJBool(MultiAZ))
  add(query_602442, "Action", newJString(Action))
  add(formData_602443, "Duration", newJString(Duration))
  add(formData_602443, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602443.add "Filters", Filters
  add(formData_602443, "ProductDescription", newJString(ProductDescription))
  add(formData_602443, "MaxRecords", newJInt(MaxRecords))
  add(formData_602443, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602442, "Version", newJString(Version))
  result = call_602441.call(nil, query_602442, nil, formData_602443, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602418(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602419, base: "/",
    url: url_PostDescribeReservedDBInstances_602420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602393 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstances_602395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_602394(path: JsonNode;
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
  var valid_602396 = query.getOrDefault("ProductDescription")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "ProductDescription", valid_602396
  var valid_602397 = query.getOrDefault("MaxRecords")
  valid_602397 = validateParameter(valid_602397, JInt, required = false, default = nil)
  if valid_602397 != nil:
    section.add "MaxRecords", valid_602397
  var valid_602398 = query.getOrDefault("OfferingType")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "OfferingType", valid_602398
  var valid_602399 = query.getOrDefault("Filters")
  valid_602399 = validateParameter(valid_602399, JArray, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "Filters", valid_602399
  var valid_602400 = query.getOrDefault("MultiAZ")
  valid_602400 = validateParameter(valid_602400, JBool, required = false, default = nil)
  if valid_602400 != nil:
    section.add "MultiAZ", valid_602400
  var valid_602401 = query.getOrDefault("ReservedDBInstanceId")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "ReservedDBInstanceId", valid_602401
  var valid_602402 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602402
  var valid_602403 = query.getOrDefault("DBInstanceClass")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "DBInstanceClass", valid_602403
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602404 = query.getOrDefault("Action")
  valid_602404 = validateParameter(valid_602404, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602404 != nil:
    section.add "Action", valid_602404
  var valid_602405 = query.getOrDefault("Marker")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "Marker", valid_602405
  var valid_602406 = query.getOrDefault("Duration")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "Duration", valid_602406
  var valid_602407 = query.getOrDefault("Version")
  valid_602407 = validateParameter(valid_602407, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602407 != nil:
    section.add "Version", valid_602407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602408 = header.getOrDefault("X-Amz-Date")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Date", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Security-Token")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Security-Token", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Content-Sha256", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Algorithm")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Algorithm", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Signature")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Signature", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-SignedHeaders", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Credential")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Credential", valid_602414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602415: Call_GetDescribeReservedDBInstances_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602415.validator(path, query, header, formData, body)
  let scheme = call_602415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602415.url(scheme.get, call_602415.host, call_602415.base,
                         call_602415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602415, url, valid)

proc call*(call_602416: Call_GetDescribeReservedDBInstances_602393;
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
  var query_602417 = newJObject()
  add(query_602417, "ProductDescription", newJString(ProductDescription))
  add(query_602417, "MaxRecords", newJInt(MaxRecords))
  add(query_602417, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602417.add "Filters", Filters
  add(query_602417, "MultiAZ", newJBool(MultiAZ))
  add(query_602417, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602417, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602417, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602417, "Action", newJString(Action))
  add(query_602417, "Marker", newJString(Marker))
  add(query_602417, "Duration", newJString(Duration))
  add(query_602417, "Version", newJString(Version))
  result = call_602416.call(nil, query_602417, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602393(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602394, base: "/",
    url: url_GetDescribeReservedDBInstances_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602468 = ref object of OpenApiRestCall_600421
proc url_PostDescribeReservedDBInstancesOfferings_602470(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602469(path: JsonNode;
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
  var valid_602471 = query.getOrDefault("Action")
  valid_602471 = validateParameter(valid_602471, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602471 != nil:
    section.add "Action", valid_602471
  var valid_602472 = query.getOrDefault("Version")
  valid_602472 = validateParameter(valid_602472, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602472 != nil:
    section.add "Version", valid_602472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602473 = header.getOrDefault("X-Amz-Date")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Date", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Security-Token")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Security-Token", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Content-Sha256", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Signature")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Signature", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-SignedHeaders", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Credential")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Credential", valid_602479
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
  var valid_602480 = formData.getOrDefault("OfferingType")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "OfferingType", valid_602480
  var valid_602481 = formData.getOrDefault("Marker")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "Marker", valid_602481
  var valid_602482 = formData.getOrDefault("MultiAZ")
  valid_602482 = validateParameter(valid_602482, JBool, required = false, default = nil)
  if valid_602482 != nil:
    section.add "MultiAZ", valid_602482
  var valid_602483 = formData.getOrDefault("Duration")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "Duration", valid_602483
  var valid_602484 = formData.getOrDefault("DBInstanceClass")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "DBInstanceClass", valid_602484
  var valid_602485 = formData.getOrDefault("Filters")
  valid_602485 = validateParameter(valid_602485, JArray, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "Filters", valid_602485
  var valid_602486 = formData.getOrDefault("ProductDescription")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "ProductDescription", valid_602486
  var valid_602487 = formData.getOrDefault("MaxRecords")
  valid_602487 = validateParameter(valid_602487, JInt, required = false, default = nil)
  if valid_602487 != nil:
    section.add "MaxRecords", valid_602487
  var valid_602488 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602488
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602489: Call_PostDescribeReservedDBInstancesOfferings_602468;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602489.validator(path, query, header, formData, body)
  let scheme = call_602489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602489.url(scheme.get, call_602489.host, call_602489.base,
                         call_602489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602489, url, valid)

proc call*(call_602490: Call_PostDescribeReservedDBInstancesOfferings_602468;
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
  var query_602491 = newJObject()
  var formData_602492 = newJObject()
  add(formData_602492, "OfferingType", newJString(OfferingType))
  add(formData_602492, "Marker", newJString(Marker))
  add(formData_602492, "MultiAZ", newJBool(MultiAZ))
  add(query_602491, "Action", newJString(Action))
  add(formData_602492, "Duration", newJString(Duration))
  add(formData_602492, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602492.add "Filters", Filters
  add(formData_602492, "ProductDescription", newJString(ProductDescription))
  add(formData_602492, "MaxRecords", newJInt(MaxRecords))
  add(formData_602492, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602491, "Version", newJString(Version))
  result = call_602490.call(nil, query_602491, nil, formData_602492, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602468(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602469,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602444 = ref object of OpenApiRestCall_600421
proc url_GetDescribeReservedDBInstancesOfferings_602446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602445(path: JsonNode;
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
  var valid_602447 = query.getOrDefault("ProductDescription")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "ProductDescription", valid_602447
  var valid_602448 = query.getOrDefault("MaxRecords")
  valid_602448 = validateParameter(valid_602448, JInt, required = false, default = nil)
  if valid_602448 != nil:
    section.add "MaxRecords", valid_602448
  var valid_602449 = query.getOrDefault("OfferingType")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "OfferingType", valid_602449
  var valid_602450 = query.getOrDefault("Filters")
  valid_602450 = validateParameter(valid_602450, JArray, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "Filters", valid_602450
  var valid_602451 = query.getOrDefault("MultiAZ")
  valid_602451 = validateParameter(valid_602451, JBool, required = false, default = nil)
  if valid_602451 != nil:
    section.add "MultiAZ", valid_602451
  var valid_602452 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602452
  var valid_602453 = query.getOrDefault("DBInstanceClass")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "DBInstanceClass", valid_602453
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602454 = query.getOrDefault("Action")
  valid_602454 = validateParameter(valid_602454, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602454 != nil:
    section.add "Action", valid_602454
  var valid_602455 = query.getOrDefault("Marker")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "Marker", valid_602455
  var valid_602456 = query.getOrDefault("Duration")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "Duration", valid_602456
  var valid_602457 = query.getOrDefault("Version")
  valid_602457 = validateParameter(valid_602457, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602457 != nil:
    section.add "Version", valid_602457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602458 = header.getOrDefault("X-Amz-Date")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Date", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Security-Token")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Security-Token", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Content-Sha256", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Algorithm")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Algorithm", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Signature")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Signature", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-SignedHeaders", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Credential")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Credential", valid_602464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602465: Call_GetDescribeReservedDBInstancesOfferings_602444;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602465.validator(path, query, header, formData, body)
  let scheme = call_602465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602465.url(scheme.get, call_602465.host, call_602465.base,
                         call_602465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602465, url, valid)

proc call*(call_602466: Call_GetDescribeReservedDBInstancesOfferings_602444;
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
  var query_602467 = newJObject()
  add(query_602467, "ProductDescription", newJString(ProductDescription))
  add(query_602467, "MaxRecords", newJInt(MaxRecords))
  add(query_602467, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602467.add "Filters", Filters
  add(query_602467, "MultiAZ", newJBool(MultiAZ))
  add(query_602467, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602467, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602467, "Action", newJString(Action))
  add(query_602467, "Marker", newJString(Marker))
  add(query_602467, "Duration", newJString(Duration))
  add(query_602467, "Version", newJString(Version))
  result = call_602466.call(nil, query_602467, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602444(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602445, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602512 = ref object of OpenApiRestCall_600421
proc url_PostDownloadDBLogFilePortion_602514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDownloadDBLogFilePortion_602513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602515 = query.getOrDefault("Action")
  valid_602515 = validateParameter(valid_602515, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602515 != nil:
    section.add "Action", valid_602515
  var valid_602516 = query.getOrDefault("Version")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602516 != nil:
    section.add "Version", valid_602516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602517 = header.getOrDefault("X-Amz-Date")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Date", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Security-Token")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Security-Token", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Content-Sha256", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Algorithm")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Algorithm", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Signature")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Signature", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-SignedHeaders", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Credential")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Credential", valid_602523
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602524 = formData.getOrDefault("NumberOfLines")
  valid_602524 = validateParameter(valid_602524, JInt, required = false, default = nil)
  if valid_602524 != nil:
    section.add "NumberOfLines", valid_602524
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602525 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = nil)
  if valid_602525 != nil:
    section.add "DBInstanceIdentifier", valid_602525
  var valid_602526 = formData.getOrDefault("Marker")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "Marker", valid_602526
  var valid_602527 = formData.getOrDefault("LogFileName")
  valid_602527 = validateParameter(valid_602527, JString, required = true,
                                 default = nil)
  if valid_602527 != nil:
    section.add "LogFileName", valid_602527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602528: Call_PostDownloadDBLogFilePortion_602512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602528.validator(path, query, header, formData, body)
  let scheme = call_602528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602528.url(scheme.get, call_602528.host, call_602528.base,
                         call_602528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602528, url, valid)

proc call*(call_602529: Call_PostDownloadDBLogFilePortion_602512;
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
  var query_602530 = newJObject()
  var formData_602531 = newJObject()
  add(formData_602531, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602531, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602531, "Marker", newJString(Marker))
  add(query_602530, "Action", newJString(Action))
  add(formData_602531, "LogFileName", newJString(LogFileName))
  add(query_602530, "Version", newJString(Version))
  result = call_602529.call(nil, query_602530, nil, formData_602531, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602512(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602513, base: "/",
    url: url_PostDownloadDBLogFilePortion_602514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602493 = ref object of OpenApiRestCall_600421
proc url_GetDownloadDBLogFilePortion_602495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDownloadDBLogFilePortion_602494(path: JsonNode; query: JsonNode;
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
  var valid_602496 = query.getOrDefault("NumberOfLines")
  valid_602496 = validateParameter(valid_602496, JInt, required = false, default = nil)
  if valid_602496 != nil:
    section.add "NumberOfLines", valid_602496
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602497 = query.getOrDefault("LogFileName")
  valid_602497 = validateParameter(valid_602497, JString, required = true,
                                 default = nil)
  if valid_602497 != nil:
    section.add "LogFileName", valid_602497
  var valid_602498 = query.getOrDefault("Action")
  valid_602498 = validateParameter(valid_602498, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602498 != nil:
    section.add "Action", valid_602498
  var valid_602499 = query.getOrDefault("Marker")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "Marker", valid_602499
  var valid_602500 = query.getOrDefault("Version")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602500 != nil:
    section.add "Version", valid_602500
  var valid_602501 = query.getOrDefault("DBInstanceIdentifier")
  valid_602501 = validateParameter(valid_602501, JString, required = true,
                                 default = nil)
  if valid_602501 != nil:
    section.add "DBInstanceIdentifier", valid_602501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602502 = header.getOrDefault("X-Amz-Date")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Date", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Security-Token")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Security-Token", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Content-Sha256", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Algorithm")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Algorithm", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Signature")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Signature", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-SignedHeaders", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Credential")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Credential", valid_602508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602509: Call_GetDownloadDBLogFilePortion_602493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602509.validator(path, query, header, formData, body)
  let scheme = call_602509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602509.url(scheme.get, call_602509.host, call_602509.base,
                         call_602509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602509, url, valid)

proc call*(call_602510: Call_GetDownloadDBLogFilePortion_602493;
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
  var query_602511 = newJObject()
  add(query_602511, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602511, "LogFileName", newJString(LogFileName))
  add(query_602511, "Action", newJString(Action))
  add(query_602511, "Marker", newJString(Marker))
  add(query_602511, "Version", newJString(Version))
  add(query_602511, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602510.call(nil, query_602511, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602493(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602494, base: "/",
    url: url_GetDownloadDBLogFilePortion_602495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602549 = ref object of OpenApiRestCall_600421
proc url_PostListTagsForResource_602551(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_602550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602552 = query.getOrDefault("Action")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602552 != nil:
    section.add "Action", valid_602552
  var valid_602553 = query.getOrDefault("Version")
  valid_602553 = validateParameter(valid_602553, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602553 != nil:
    section.add "Version", valid_602553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602554 = header.getOrDefault("X-Amz-Date")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Date", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Security-Token")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Security-Token", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Content-Sha256", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Algorithm")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Algorithm", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Signature")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Signature", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-SignedHeaders", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Credential")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Credential", valid_602560
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_602561 = formData.getOrDefault("Filters")
  valid_602561 = validateParameter(valid_602561, JArray, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "Filters", valid_602561
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602562 = formData.getOrDefault("ResourceName")
  valid_602562 = validateParameter(valid_602562, JString, required = true,
                                 default = nil)
  if valid_602562 != nil:
    section.add "ResourceName", valid_602562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_PostListTagsForResource_602549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602563, url, valid)

proc call*(call_602564: Call_PostListTagsForResource_602549; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602565 = newJObject()
  var formData_602566 = newJObject()
  add(query_602565, "Action", newJString(Action))
  if Filters != nil:
    formData_602566.add "Filters", Filters
  add(formData_602566, "ResourceName", newJString(ResourceName))
  add(query_602565, "Version", newJString(Version))
  result = call_602564.call(nil, query_602565, nil, formData_602566, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602549(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602550, base: "/",
    url: url_PostListTagsForResource_602551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602532 = ref object of OpenApiRestCall_600421
proc url_GetListTagsForResource_602534(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_602533(path: JsonNode; query: JsonNode;
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
  var valid_602535 = query.getOrDefault("Filters")
  valid_602535 = validateParameter(valid_602535, JArray, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "Filters", valid_602535
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_602536 = query.getOrDefault("ResourceName")
  valid_602536 = validateParameter(valid_602536, JString, required = true,
                                 default = nil)
  if valid_602536 != nil:
    section.add "ResourceName", valid_602536
  var valid_602537 = query.getOrDefault("Action")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602537 != nil:
    section.add "Action", valid_602537
  var valid_602538 = query.getOrDefault("Version")
  valid_602538 = validateParameter(valid_602538, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602538 != nil:
    section.add "Version", valid_602538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602539 = header.getOrDefault("X-Amz-Date")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Date", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Security-Token")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Security-Token", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Content-Sha256", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Algorithm")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Algorithm", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Signature")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Signature", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-SignedHeaders", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Credential")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Credential", valid_602545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602546: Call_GetListTagsForResource_602532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602546.validator(path, query, header, formData, body)
  let scheme = call_602546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602546.url(scheme.get, call_602546.host, call_602546.base,
                         call_602546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602546, url, valid)

proc call*(call_602547: Call_GetListTagsForResource_602532; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602548 = newJObject()
  if Filters != nil:
    query_602548.add "Filters", Filters
  add(query_602548, "ResourceName", newJString(ResourceName))
  add(query_602548, "Action", newJString(Action))
  add(query_602548, "Version", newJString(Version))
  result = call_602547.call(nil, query_602548, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602532(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602533, base: "/",
    url: url_GetListTagsForResource_602534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602600 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBInstance_602602(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_602601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602603 = query.getOrDefault("Action")
  valid_602603 = validateParameter(valid_602603, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602603 != nil:
    section.add "Action", valid_602603
  var valid_602604 = query.getOrDefault("Version")
  valid_602604 = validateParameter(valid_602604, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602604 != nil:
    section.add "Version", valid_602604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602605 = header.getOrDefault("X-Amz-Date")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Date", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Security-Token")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Security-Token", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Content-Sha256", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Algorithm")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Algorithm", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-SignedHeaders", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Credential")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Credential", valid_602611
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
  var valid_602612 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "PreferredMaintenanceWindow", valid_602612
  var valid_602613 = formData.getOrDefault("DBSecurityGroups")
  valid_602613 = validateParameter(valid_602613, JArray, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "DBSecurityGroups", valid_602613
  var valid_602614 = formData.getOrDefault("ApplyImmediately")
  valid_602614 = validateParameter(valid_602614, JBool, required = false, default = nil)
  if valid_602614 != nil:
    section.add "ApplyImmediately", valid_602614
  var valid_602615 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602615 = validateParameter(valid_602615, JArray, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "VpcSecurityGroupIds", valid_602615
  var valid_602616 = formData.getOrDefault("Iops")
  valid_602616 = validateParameter(valid_602616, JInt, required = false, default = nil)
  if valid_602616 != nil:
    section.add "Iops", valid_602616
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602617 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602617 = validateParameter(valid_602617, JString, required = true,
                                 default = nil)
  if valid_602617 != nil:
    section.add "DBInstanceIdentifier", valid_602617
  var valid_602618 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602618 = validateParameter(valid_602618, JInt, required = false, default = nil)
  if valid_602618 != nil:
    section.add "BackupRetentionPeriod", valid_602618
  var valid_602619 = formData.getOrDefault("DBParameterGroupName")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "DBParameterGroupName", valid_602619
  var valid_602620 = formData.getOrDefault("OptionGroupName")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "OptionGroupName", valid_602620
  var valid_602621 = formData.getOrDefault("MasterUserPassword")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "MasterUserPassword", valid_602621
  var valid_602622 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "NewDBInstanceIdentifier", valid_602622
  var valid_602623 = formData.getOrDefault("MultiAZ")
  valid_602623 = validateParameter(valid_602623, JBool, required = false, default = nil)
  if valid_602623 != nil:
    section.add "MultiAZ", valid_602623
  var valid_602624 = formData.getOrDefault("AllocatedStorage")
  valid_602624 = validateParameter(valid_602624, JInt, required = false, default = nil)
  if valid_602624 != nil:
    section.add "AllocatedStorage", valid_602624
  var valid_602625 = formData.getOrDefault("DBInstanceClass")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "DBInstanceClass", valid_602625
  var valid_602626 = formData.getOrDefault("PreferredBackupWindow")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "PreferredBackupWindow", valid_602626
  var valid_602627 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602627 = validateParameter(valid_602627, JBool, required = false, default = nil)
  if valid_602627 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602627
  var valid_602628 = formData.getOrDefault("EngineVersion")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "EngineVersion", valid_602628
  var valid_602629 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602629 = validateParameter(valid_602629, JBool, required = false, default = nil)
  if valid_602629 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602629
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602630: Call_PostModifyDBInstance_602600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602630.validator(path, query, header, formData, body)
  let scheme = call_602630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602630.url(scheme.get, call_602630.host, call_602630.base,
                         call_602630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602630, url, valid)

proc call*(call_602631: Call_PostModifyDBInstance_602600;
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
  var query_602632 = newJObject()
  var formData_602633 = newJObject()
  add(formData_602633, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602633.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602633, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602633.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602633, "Iops", newJInt(Iops))
  add(formData_602633, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602633, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602633, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602633, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602633, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602633, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602633, "MultiAZ", newJBool(MultiAZ))
  add(query_602632, "Action", newJString(Action))
  add(formData_602633, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602633, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602633, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602633, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602633, "EngineVersion", newJString(EngineVersion))
  add(query_602632, "Version", newJString(Version))
  add(formData_602633, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602631.call(nil, query_602632, nil, formData_602633, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602600(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602601, base: "/",
    url: url_PostModifyDBInstance_602602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602567 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBInstance_602569(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_602568(path: JsonNode; query: JsonNode;
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
  var valid_602570 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "PreferredMaintenanceWindow", valid_602570
  var valid_602571 = query.getOrDefault("AllocatedStorage")
  valid_602571 = validateParameter(valid_602571, JInt, required = false, default = nil)
  if valid_602571 != nil:
    section.add "AllocatedStorage", valid_602571
  var valid_602572 = query.getOrDefault("OptionGroupName")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "OptionGroupName", valid_602572
  var valid_602573 = query.getOrDefault("DBSecurityGroups")
  valid_602573 = validateParameter(valid_602573, JArray, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "DBSecurityGroups", valid_602573
  var valid_602574 = query.getOrDefault("MasterUserPassword")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "MasterUserPassword", valid_602574
  var valid_602575 = query.getOrDefault("Iops")
  valid_602575 = validateParameter(valid_602575, JInt, required = false, default = nil)
  if valid_602575 != nil:
    section.add "Iops", valid_602575
  var valid_602576 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602576 = validateParameter(valid_602576, JArray, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "VpcSecurityGroupIds", valid_602576
  var valid_602577 = query.getOrDefault("MultiAZ")
  valid_602577 = validateParameter(valid_602577, JBool, required = false, default = nil)
  if valid_602577 != nil:
    section.add "MultiAZ", valid_602577
  var valid_602578 = query.getOrDefault("BackupRetentionPeriod")
  valid_602578 = validateParameter(valid_602578, JInt, required = false, default = nil)
  if valid_602578 != nil:
    section.add "BackupRetentionPeriod", valid_602578
  var valid_602579 = query.getOrDefault("DBParameterGroupName")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "DBParameterGroupName", valid_602579
  var valid_602580 = query.getOrDefault("DBInstanceClass")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "DBInstanceClass", valid_602580
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602581 = query.getOrDefault("Action")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602581 != nil:
    section.add "Action", valid_602581
  var valid_602582 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602582 = validateParameter(valid_602582, JBool, required = false, default = nil)
  if valid_602582 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602582
  var valid_602583 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "NewDBInstanceIdentifier", valid_602583
  var valid_602584 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602584 = validateParameter(valid_602584, JBool, required = false, default = nil)
  if valid_602584 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602584
  var valid_602585 = query.getOrDefault("EngineVersion")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "EngineVersion", valid_602585
  var valid_602586 = query.getOrDefault("PreferredBackupWindow")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "PreferredBackupWindow", valid_602586
  var valid_602587 = query.getOrDefault("Version")
  valid_602587 = validateParameter(valid_602587, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602587 != nil:
    section.add "Version", valid_602587
  var valid_602588 = query.getOrDefault("DBInstanceIdentifier")
  valid_602588 = validateParameter(valid_602588, JString, required = true,
                                 default = nil)
  if valid_602588 != nil:
    section.add "DBInstanceIdentifier", valid_602588
  var valid_602589 = query.getOrDefault("ApplyImmediately")
  valid_602589 = validateParameter(valid_602589, JBool, required = false, default = nil)
  if valid_602589 != nil:
    section.add "ApplyImmediately", valid_602589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602590 = header.getOrDefault("X-Amz-Date")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Date", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Security-Token")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Security-Token", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Content-Sha256", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Algorithm")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Algorithm", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Signature")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Signature", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-SignedHeaders", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Credential")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Credential", valid_602596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602597: Call_GetModifyDBInstance_602567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602597.validator(path, query, header, formData, body)
  let scheme = call_602597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602597.url(scheme.get, call_602597.host, call_602597.base,
                         call_602597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602597, url, valid)

proc call*(call_602598: Call_GetModifyDBInstance_602567;
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
  var query_602599 = newJObject()
  add(query_602599, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602599, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602599, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602599.add "DBSecurityGroups", DBSecurityGroups
  add(query_602599, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602599, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602599.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602599, "MultiAZ", newJBool(MultiAZ))
  add(query_602599, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602599, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602599, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602599, "Action", newJString(Action))
  add(query_602599, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602599, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602599, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602599, "EngineVersion", newJString(EngineVersion))
  add(query_602599, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602599, "Version", newJString(Version))
  add(query_602599, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602599, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602598.call(nil, query_602599, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602567(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602568, base: "/",
    url: url_GetModifyDBInstance_602569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602651 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBParameterGroup_602653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_602652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602654 = query.getOrDefault("Action")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602654 != nil:
    section.add "Action", valid_602654
  var valid_602655 = query.getOrDefault("Version")
  valid_602655 = validateParameter(valid_602655, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602655 != nil:
    section.add "Version", valid_602655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602656 = header.getOrDefault("X-Amz-Date")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Date", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Security-Token")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Security-Token", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Content-Sha256", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Algorithm")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Algorithm", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-SignedHeaders", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Credential")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Credential", valid_602662
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602663 = formData.getOrDefault("DBParameterGroupName")
  valid_602663 = validateParameter(valid_602663, JString, required = true,
                                 default = nil)
  if valid_602663 != nil:
    section.add "DBParameterGroupName", valid_602663
  var valid_602664 = formData.getOrDefault("Parameters")
  valid_602664 = validateParameter(valid_602664, JArray, required = true, default = nil)
  if valid_602664 != nil:
    section.add "Parameters", valid_602664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602665: Call_PostModifyDBParameterGroup_602651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602665.validator(path, query, header, formData, body)
  let scheme = call_602665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602665.url(scheme.get, call_602665.host, call_602665.base,
                         call_602665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602665, url, valid)

proc call*(call_602666: Call_PostModifyDBParameterGroup_602651;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602667 = newJObject()
  var formData_602668 = newJObject()
  add(formData_602668, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602668.add "Parameters", Parameters
  add(query_602667, "Action", newJString(Action))
  add(query_602667, "Version", newJString(Version))
  result = call_602666.call(nil, query_602667, nil, formData_602668, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602651(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602652, base: "/",
    url: url_PostModifyDBParameterGroup_602653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602634 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBParameterGroup_602636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_602635(path: JsonNode; query: JsonNode;
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
  var valid_602637 = query.getOrDefault("DBParameterGroupName")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = nil)
  if valid_602637 != nil:
    section.add "DBParameterGroupName", valid_602637
  var valid_602638 = query.getOrDefault("Parameters")
  valid_602638 = validateParameter(valid_602638, JArray, required = true, default = nil)
  if valid_602638 != nil:
    section.add "Parameters", valid_602638
  var valid_602639 = query.getOrDefault("Action")
  valid_602639 = validateParameter(valid_602639, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602639 != nil:
    section.add "Action", valid_602639
  var valid_602640 = query.getOrDefault("Version")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602640 != nil:
    section.add "Version", valid_602640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Security-Token")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Security-Token", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Content-Sha256", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-SignedHeaders", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Credential")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Credential", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_GetModifyDBParameterGroup_602634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602648, url, valid)

proc call*(call_602649: Call_GetModifyDBParameterGroup_602634;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602650 = newJObject()
  add(query_602650, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602650.add "Parameters", Parameters
  add(query_602650, "Action", newJString(Action))
  add(query_602650, "Version", newJString(Version))
  result = call_602649.call(nil, query_602650, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602634(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602635, base: "/",
    url: url_GetModifyDBParameterGroup_602636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602687 = ref object of OpenApiRestCall_600421
proc url_PostModifyDBSubnetGroup_602689(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_602688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602690 = query.getOrDefault("Action")
  valid_602690 = validateParameter(valid_602690, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602690 != nil:
    section.add "Action", valid_602690
  var valid_602691 = query.getOrDefault("Version")
  valid_602691 = validateParameter(valid_602691, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602691 != nil:
    section.add "Version", valid_602691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602692 = header.getOrDefault("X-Amz-Date")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Date", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Security-Token")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Security-Token", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Content-Sha256", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Algorithm")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Algorithm", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Signature")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Signature", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-SignedHeaders", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Credential")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Credential", valid_602698
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602699 = formData.getOrDefault("DBSubnetGroupName")
  valid_602699 = validateParameter(valid_602699, JString, required = true,
                                 default = nil)
  if valid_602699 != nil:
    section.add "DBSubnetGroupName", valid_602699
  var valid_602700 = formData.getOrDefault("SubnetIds")
  valid_602700 = validateParameter(valid_602700, JArray, required = true, default = nil)
  if valid_602700 != nil:
    section.add "SubnetIds", valid_602700
  var valid_602701 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "DBSubnetGroupDescription", valid_602701
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602702: Call_PostModifyDBSubnetGroup_602687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602702.validator(path, query, header, formData, body)
  let scheme = call_602702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602702.url(scheme.get, call_602702.host, call_602702.base,
                         call_602702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602702, url, valid)

proc call*(call_602703: Call_PostModifyDBSubnetGroup_602687;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602704 = newJObject()
  var formData_602705 = newJObject()
  add(formData_602705, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602705.add "SubnetIds", SubnetIds
  add(query_602704, "Action", newJString(Action))
  add(formData_602705, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602704, "Version", newJString(Version))
  result = call_602703.call(nil, query_602704, nil, formData_602705, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602687(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602688, base: "/",
    url: url_PostModifyDBSubnetGroup_602689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602669 = ref object of OpenApiRestCall_600421
proc url_GetModifyDBSubnetGroup_602671(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_602670(path: JsonNode; query: JsonNode;
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
  var valid_602672 = query.getOrDefault("Action")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602672 != nil:
    section.add "Action", valid_602672
  var valid_602673 = query.getOrDefault("DBSubnetGroupName")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = nil)
  if valid_602673 != nil:
    section.add "DBSubnetGroupName", valid_602673
  var valid_602674 = query.getOrDefault("SubnetIds")
  valid_602674 = validateParameter(valid_602674, JArray, required = true, default = nil)
  if valid_602674 != nil:
    section.add "SubnetIds", valid_602674
  var valid_602675 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "DBSubnetGroupDescription", valid_602675
  var valid_602676 = query.getOrDefault("Version")
  valid_602676 = validateParameter(valid_602676, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602676 != nil:
    section.add "Version", valid_602676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602677 = header.getOrDefault("X-Amz-Date")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Date", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Content-Sha256", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Algorithm")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Algorithm", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-SignedHeaders", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Credential")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Credential", valid_602683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602684: Call_GetModifyDBSubnetGroup_602669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602684.validator(path, query, header, formData, body)
  let scheme = call_602684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602684.url(scheme.get, call_602684.host, call_602684.base,
                         call_602684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602684, url, valid)

proc call*(call_602685: Call_GetModifyDBSubnetGroup_602669;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602686 = newJObject()
  add(query_602686, "Action", newJString(Action))
  add(query_602686, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602686.add "SubnetIds", SubnetIds
  add(query_602686, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602686, "Version", newJString(Version))
  result = call_602685.call(nil, query_602686, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602669(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602670, base: "/",
    url: url_GetModifyDBSubnetGroup_602671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602726 = ref object of OpenApiRestCall_600421
proc url_PostModifyEventSubscription_602728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_602727(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602729 = query.getOrDefault("Action")
  valid_602729 = validateParameter(valid_602729, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602729 != nil:
    section.add "Action", valid_602729
  var valid_602730 = query.getOrDefault("Version")
  valid_602730 = validateParameter(valid_602730, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602730 != nil:
    section.add "Version", valid_602730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602731 = header.getOrDefault("X-Amz-Date")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Date", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Security-Token")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Security-Token", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Content-Sha256", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Algorithm")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Algorithm", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Signature")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Signature", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-SignedHeaders", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Credential")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Credential", valid_602737
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602738 = formData.getOrDefault("Enabled")
  valid_602738 = validateParameter(valid_602738, JBool, required = false, default = nil)
  if valid_602738 != nil:
    section.add "Enabled", valid_602738
  var valid_602739 = formData.getOrDefault("EventCategories")
  valid_602739 = validateParameter(valid_602739, JArray, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "EventCategories", valid_602739
  var valid_602740 = formData.getOrDefault("SnsTopicArn")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "SnsTopicArn", valid_602740
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602741 = formData.getOrDefault("SubscriptionName")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = nil)
  if valid_602741 != nil:
    section.add "SubscriptionName", valid_602741
  var valid_602742 = formData.getOrDefault("SourceType")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "SourceType", valid_602742
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602743: Call_PostModifyEventSubscription_602726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602743.validator(path, query, header, formData, body)
  let scheme = call_602743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602743.url(scheme.get, call_602743.host, call_602743.base,
                         call_602743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602743, url, valid)

proc call*(call_602744: Call_PostModifyEventSubscription_602726;
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
  var query_602745 = newJObject()
  var formData_602746 = newJObject()
  add(formData_602746, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602746.add "EventCategories", EventCategories
  add(formData_602746, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602746, "SubscriptionName", newJString(SubscriptionName))
  add(query_602745, "Action", newJString(Action))
  add(query_602745, "Version", newJString(Version))
  add(formData_602746, "SourceType", newJString(SourceType))
  result = call_602744.call(nil, query_602745, nil, formData_602746, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602726(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602727, base: "/",
    url: url_PostModifyEventSubscription_602728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602706 = ref object of OpenApiRestCall_600421
proc url_GetModifyEventSubscription_602708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_602707(path: JsonNode; query: JsonNode;
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
  var valid_602709 = query.getOrDefault("SourceType")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "SourceType", valid_602709
  var valid_602710 = query.getOrDefault("Enabled")
  valid_602710 = validateParameter(valid_602710, JBool, required = false, default = nil)
  if valid_602710 != nil:
    section.add "Enabled", valid_602710
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602711 = query.getOrDefault("Action")
  valid_602711 = validateParameter(valid_602711, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602711 != nil:
    section.add "Action", valid_602711
  var valid_602712 = query.getOrDefault("SnsTopicArn")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "SnsTopicArn", valid_602712
  var valid_602713 = query.getOrDefault("EventCategories")
  valid_602713 = validateParameter(valid_602713, JArray, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "EventCategories", valid_602713
  var valid_602714 = query.getOrDefault("SubscriptionName")
  valid_602714 = validateParameter(valid_602714, JString, required = true,
                                 default = nil)
  if valid_602714 != nil:
    section.add "SubscriptionName", valid_602714
  var valid_602715 = query.getOrDefault("Version")
  valid_602715 = validateParameter(valid_602715, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602715 != nil:
    section.add "Version", valid_602715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602716 = header.getOrDefault("X-Amz-Date")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Date", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Security-Token")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Security-Token", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Content-Sha256", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Algorithm")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Algorithm", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Signature")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Signature", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-SignedHeaders", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Credential")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Credential", valid_602722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602723: Call_GetModifyEventSubscription_602706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602723.validator(path, query, header, formData, body)
  let scheme = call_602723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602723.url(scheme.get, call_602723.host, call_602723.base,
                         call_602723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602723, url, valid)

proc call*(call_602724: Call_GetModifyEventSubscription_602706;
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
  var query_602725 = newJObject()
  add(query_602725, "SourceType", newJString(SourceType))
  add(query_602725, "Enabled", newJBool(Enabled))
  add(query_602725, "Action", newJString(Action))
  add(query_602725, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602725.add "EventCategories", EventCategories
  add(query_602725, "SubscriptionName", newJString(SubscriptionName))
  add(query_602725, "Version", newJString(Version))
  result = call_602724.call(nil, query_602725, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602706(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602707, base: "/",
    url: url_GetModifyEventSubscription_602708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602766 = ref object of OpenApiRestCall_600421
proc url_PostModifyOptionGroup_602768(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_602767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602769 = query.getOrDefault("Action")
  valid_602769 = validateParameter(valid_602769, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602769 != nil:
    section.add "Action", valid_602769
  var valid_602770 = query.getOrDefault("Version")
  valid_602770 = validateParameter(valid_602770, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602770 != nil:
    section.add "Version", valid_602770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602771 = header.getOrDefault("X-Amz-Date")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Date", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Security-Token")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Security-Token", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Content-Sha256", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Algorithm")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Algorithm", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Signature")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Signature", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-SignedHeaders", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Credential")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Credential", valid_602777
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602778 = formData.getOrDefault("OptionsToRemove")
  valid_602778 = validateParameter(valid_602778, JArray, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "OptionsToRemove", valid_602778
  var valid_602779 = formData.getOrDefault("ApplyImmediately")
  valid_602779 = validateParameter(valid_602779, JBool, required = false, default = nil)
  if valid_602779 != nil:
    section.add "ApplyImmediately", valid_602779
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602780 = formData.getOrDefault("OptionGroupName")
  valid_602780 = validateParameter(valid_602780, JString, required = true,
                                 default = nil)
  if valid_602780 != nil:
    section.add "OptionGroupName", valid_602780
  var valid_602781 = formData.getOrDefault("OptionsToInclude")
  valid_602781 = validateParameter(valid_602781, JArray, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "OptionsToInclude", valid_602781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602782: Call_PostModifyOptionGroup_602766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602782.validator(path, query, header, formData, body)
  let scheme = call_602782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602782.url(scheme.get, call_602782.host, call_602782.base,
                         call_602782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602782, url, valid)

proc call*(call_602783: Call_PostModifyOptionGroup_602766; OptionGroupName: string;
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
  var query_602784 = newJObject()
  var formData_602785 = newJObject()
  if OptionsToRemove != nil:
    formData_602785.add "OptionsToRemove", OptionsToRemove
  add(formData_602785, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602785, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602785.add "OptionsToInclude", OptionsToInclude
  add(query_602784, "Action", newJString(Action))
  add(query_602784, "Version", newJString(Version))
  result = call_602783.call(nil, query_602784, nil, formData_602785, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602766(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602767, base: "/",
    url: url_PostModifyOptionGroup_602768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602747 = ref object of OpenApiRestCall_600421
proc url_GetModifyOptionGroup_602749(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_602748(path: JsonNode; query: JsonNode;
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
  var valid_602750 = query.getOrDefault("OptionGroupName")
  valid_602750 = validateParameter(valid_602750, JString, required = true,
                                 default = nil)
  if valid_602750 != nil:
    section.add "OptionGroupName", valid_602750
  var valid_602751 = query.getOrDefault("OptionsToRemove")
  valid_602751 = validateParameter(valid_602751, JArray, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "OptionsToRemove", valid_602751
  var valid_602752 = query.getOrDefault("Action")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602752 != nil:
    section.add "Action", valid_602752
  var valid_602753 = query.getOrDefault("Version")
  valid_602753 = validateParameter(valid_602753, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602753 != nil:
    section.add "Version", valid_602753
  var valid_602754 = query.getOrDefault("ApplyImmediately")
  valid_602754 = validateParameter(valid_602754, JBool, required = false, default = nil)
  if valid_602754 != nil:
    section.add "ApplyImmediately", valid_602754
  var valid_602755 = query.getOrDefault("OptionsToInclude")
  valid_602755 = validateParameter(valid_602755, JArray, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "OptionsToInclude", valid_602755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602756 = header.getOrDefault("X-Amz-Date")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Date", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Security-Token")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Security-Token", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Content-Sha256", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Algorithm")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Algorithm", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Signature")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Signature", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-SignedHeaders", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Credential")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Credential", valid_602762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602763: Call_GetModifyOptionGroup_602747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602763.validator(path, query, header, formData, body)
  let scheme = call_602763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602763.url(scheme.get, call_602763.host, call_602763.base,
                         call_602763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602763, url, valid)

proc call*(call_602764: Call_GetModifyOptionGroup_602747; OptionGroupName: string;
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
  var query_602765 = newJObject()
  add(query_602765, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602765.add "OptionsToRemove", OptionsToRemove
  add(query_602765, "Action", newJString(Action))
  add(query_602765, "Version", newJString(Version))
  add(query_602765, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602765.add "OptionsToInclude", OptionsToInclude
  result = call_602764.call(nil, query_602765, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602747(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602748, base: "/",
    url: url_GetModifyOptionGroup_602749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602804 = ref object of OpenApiRestCall_600421
proc url_PostPromoteReadReplica_602806(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_602805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602807 = query.getOrDefault("Action")
  valid_602807 = validateParameter(valid_602807, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602807 != nil:
    section.add "Action", valid_602807
  var valid_602808 = query.getOrDefault("Version")
  valid_602808 = validateParameter(valid_602808, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602808 != nil:
    section.add "Version", valid_602808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602809 = header.getOrDefault("X-Amz-Date")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Date", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Security-Token")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Security-Token", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Content-Sha256", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Algorithm")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Algorithm", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Signature")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Signature", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-SignedHeaders", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Credential")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Credential", valid_602815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602816 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = nil)
  if valid_602816 != nil:
    section.add "DBInstanceIdentifier", valid_602816
  var valid_602817 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602817 = validateParameter(valid_602817, JInt, required = false, default = nil)
  if valid_602817 != nil:
    section.add "BackupRetentionPeriod", valid_602817
  var valid_602818 = formData.getOrDefault("PreferredBackupWindow")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "PreferredBackupWindow", valid_602818
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602819: Call_PostPromoteReadReplica_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602819.validator(path, query, header, formData, body)
  let scheme = call_602819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602819.url(scheme.get, call_602819.host, call_602819.base,
                         call_602819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602819, url, valid)

proc call*(call_602820: Call_PostPromoteReadReplica_602804;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602821 = newJObject()
  var formData_602822 = newJObject()
  add(formData_602822, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602822, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602821, "Action", newJString(Action))
  add(formData_602822, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602821, "Version", newJString(Version))
  result = call_602820.call(nil, query_602821, nil, formData_602822, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602804(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602805, base: "/",
    url: url_PostPromoteReadReplica_602806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602786 = ref object of OpenApiRestCall_600421
proc url_GetPromoteReadReplica_602788(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_602787(path: JsonNode; query: JsonNode;
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
  var valid_602789 = query.getOrDefault("BackupRetentionPeriod")
  valid_602789 = validateParameter(valid_602789, JInt, required = false, default = nil)
  if valid_602789 != nil:
    section.add "BackupRetentionPeriod", valid_602789
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602790 = query.getOrDefault("Action")
  valid_602790 = validateParameter(valid_602790, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602790 != nil:
    section.add "Action", valid_602790
  var valid_602791 = query.getOrDefault("PreferredBackupWindow")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "PreferredBackupWindow", valid_602791
  var valid_602792 = query.getOrDefault("Version")
  valid_602792 = validateParameter(valid_602792, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602792 != nil:
    section.add "Version", valid_602792
  var valid_602793 = query.getOrDefault("DBInstanceIdentifier")
  valid_602793 = validateParameter(valid_602793, JString, required = true,
                                 default = nil)
  if valid_602793 != nil:
    section.add "DBInstanceIdentifier", valid_602793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602794 = header.getOrDefault("X-Amz-Date")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Date", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Security-Token")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Security-Token", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Content-Sha256", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Algorithm")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Algorithm", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Signature")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Signature", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-SignedHeaders", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Credential")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Credential", valid_602800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602801: Call_GetPromoteReadReplica_602786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602801.validator(path, query, header, formData, body)
  let scheme = call_602801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602801.url(scheme.get, call_602801.host, call_602801.base,
                         call_602801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602801, url, valid)

proc call*(call_602802: Call_GetPromoteReadReplica_602786;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602803 = newJObject()
  add(query_602803, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602803, "Action", newJString(Action))
  add(query_602803, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602803, "Version", newJString(Version))
  add(query_602803, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602802.call(nil, query_602803, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602786(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602787, base: "/",
    url: url_GetPromoteReadReplica_602788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602842 = ref object of OpenApiRestCall_600421
proc url_PostPurchaseReservedDBInstancesOffering_602844(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602843(path: JsonNode;
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
  var valid_602845 = query.getOrDefault("Action")
  valid_602845 = validateParameter(valid_602845, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602845 != nil:
    section.add "Action", valid_602845
  var valid_602846 = query.getOrDefault("Version")
  valid_602846 = validateParameter(valid_602846, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602846 != nil:
    section.add "Version", valid_602846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602847 = header.getOrDefault("X-Amz-Date")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Date", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Security-Token")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Security-Token", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Content-Sha256", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Algorithm")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Algorithm", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-Signature")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-Signature", valid_602851
  var valid_602852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "X-Amz-SignedHeaders", valid_602852
  var valid_602853 = header.getOrDefault("X-Amz-Credential")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "X-Amz-Credential", valid_602853
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602854 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "ReservedDBInstanceId", valid_602854
  var valid_602855 = formData.getOrDefault("Tags")
  valid_602855 = validateParameter(valid_602855, JArray, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "Tags", valid_602855
  var valid_602856 = formData.getOrDefault("DBInstanceCount")
  valid_602856 = validateParameter(valid_602856, JInt, required = false, default = nil)
  if valid_602856 != nil:
    section.add "DBInstanceCount", valid_602856
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602857 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602857 = validateParameter(valid_602857, JString, required = true,
                                 default = nil)
  if valid_602857 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602858: Call_PostPurchaseReservedDBInstancesOffering_602842;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602858.validator(path, query, header, formData, body)
  let scheme = call_602858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602858.url(scheme.get, call_602858.host, call_602858.base,
                         call_602858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602858, url, valid)

proc call*(call_602859: Call_PostPurchaseReservedDBInstancesOffering_602842;
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
  var query_602860 = newJObject()
  var formData_602861 = newJObject()
  add(formData_602861, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_602861.add "Tags", Tags
  add(formData_602861, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602860, "Action", newJString(Action))
  add(formData_602861, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602860, "Version", newJString(Version))
  result = call_602859.call(nil, query_602860, nil, formData_602861, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602842(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602843, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602823 = ref object of OpenApiRestCall_600421
proc url_GetPurchaseReservedDBInstancesOffering_602825(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602824(path: JsonNode;
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
  var valid_602826 = query.getOrDefault("DBInstanceCount")
  valid_602826 = validateParameter(valid_602826, JInt, required = false, default = nil)
  if valid_602826 != nil:
    section.add "DBInstanceCount", valid_602826
  var valid_602827 = query.getOrDefault("Tags")
  valid_602827 = validateParameter(valid_602827, JArray, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "Tags", valid_602827
  var valid_602828 = query.getOrDefault("ReservedDBInstanceId")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "ReservedDBInstanceId", valid_602828
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602829 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602829 = validateParameter(valid_602829, JString, required = true,
                                 default = nil)
  if valid_602829 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602829
  var valid_602830 = query.getOrDefault("Action")
  valid_602830 = validateParameter(valid_602830, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602830 != nil:
    section.add "Action", valid_602830
  var valid_602831 = query.getOrDefault("Version")
  valid_602831 = validateParameter(valid_602831, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602831 != nil:
    section.add "Version", valid_602831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602832 = header.getOrDefault("X-Amz-Date")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Date", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Security-Token")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Security-Token", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Content-Sha256", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Algorithm")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Algorithm", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Signature")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Signature", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-SignedHeaders", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Credential")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Credential", valid_602838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602839: Call_GetPurchaseReservedDBInstancesOffering_602823;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602839.validator(path, query, header, formData, body)
  let scheme = call_602839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602839.url(scheme.get, call_602839.host, call_602839.base,
                         call_602839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602839, url, valid)

proc call*(call_602840: Call_GetPurchaseReservedDBInstancesOffering_602823;
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
  var query_602841 = newJObject()
  add(query_602841, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_602841.add "Tags", Tags
  add(query_602841, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602841, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602841, "Action", newJString(Action))
  add(query_602841, "Version", newJString(Version))
  result = call_602840.call(nil, query_602841, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602823(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602824, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602879 = ref object of OpenApiRestCall_600421
proc url_PostRebootDBInstance_602881(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_602880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602882 = query.getOrDefault("Action")
  valid_602882 = validateParameter(valid_602882, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602882 != nil:
    section.add "Action", valid_602882
  var valid_602883 = query.getOrDefault("Version")
  valid_602883 = validateParameter(valid_602883, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602883 != nil:
    section.add "Version", valid_602883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Signature")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Signature", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602891 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = nil)
  if valid_602891 != nil:
    section.add "DBInstanceIdentifier", valid_602891
  var valid_602892 = formData.getOrDefault("ForceFailover")
  valid_602892 = validateParameter(valid_602892, JBool, required = false, default = nil)
  if valid_602892 != nil:
    section.add "ForceFailover", valid_602892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602893: Call_PostRebootDBInstance_602879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602893.validator(path, query, header, formData, body)
  let scheme = call_602893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602893.url(scheme.get, call_602893.host, call_602893.base,
                         call_602893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602893, url, valid)

proc call*(call_602894: Call_PostRebootDBInstance_602879;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602895 = newJObject()
  var formData_602896 = newJObject()
  add(formData_602896, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602895, "Action", newJString(Action))
  add(formData_602896, "ForceFailover", newJBool(ForceFailover))
  add(query_602895, "Version", newJString(Version))
  result = call_602894.call(nil, query_602895, nil, formData_602896, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602879(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602880, base: "/",
    url: url_PostRebootDBInstance_602881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602862 = ref object of OpenApiRestCall_600421
proc url_GetRebootDBInstance_602864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_602863(path: JsonNode; query: JsonNode;
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
  var valid_602865 = query.getOrDefault("Action")
  valid_602865 = validateParameter(valid_602865, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602865 != nil:
    section.add "Action", valid_602865
  var valid_602866 = query.getOrDefault("ForceFailover")
  valid_602866 = validateParameter(valid_602866, JBool, required = false, default = nil)
  if valid_602866 != nil:
    section.add "ForceFailover", valid_602866
  var valid_602867 = query.getOrDefault("Version")
  valid_602867 = validateParameter(valid_602867, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602867 != nil:
    section.add "Version", valid_602867
  var valid_602868 = query.getOrDefault("DBInstanceIdentifier")
  valid_602868 = validateParameter(valid_602868, JString, required = true,
                                 default = nil)
  if valid_602868 != nil:
    section.add "DBInstanceIdentifier", valid_602868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602869 = header.getOrDefault("X-Amz-Date")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Date", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Security-Token")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Security-Token", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Content-Sha256", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Algorithm")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Algorithm", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Signature")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Signature", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-SignedHeaders", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602876: Call_GetRebootDBInstance_602862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602876.validator(path, query, header, formData, body)
  let scheme = call_602876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602876.url(scheme.get, call_602876.host, call_602876.base,
                         call_602876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602876, url, valid)

proc call*(call_602877: Call_GetRebootDBInstance_602862;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602878 = newJObject()
  add(query_602878, "Action", newJString(Action))
  add(query_602878, "ForceFailover", newJBool(ForceFailover))
  add(query_602878, "Version", newJString(Version))
  add(query_602878, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602877.call(nil, query_602878, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602862(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602863, base: "/",
    url: url_GetRebootDBInstance_602864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_602914 = ref object of OpenApiRestCall_600421
proc url_PostRemoveSourceIdentifierFromSubscription_602916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_602915(path: JsonNode;
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
  var valid_602917 = query.getOrDefault("Action")
  valid_602917 = validateParameter(valid_602917, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602917 != nil:
    section.add "Action", valid_602917
  var valid_602918 = query.getOrDefault("Version")
  valid_602918 = validateParameter(valid_602918, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602918 != nil:
    section.add "Version", valid_602918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602919 = header.getOrDefault("X-Amz-Date")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Date", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Algorithm")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Algorithm", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Signature")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Signature", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-SignedHeaders", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Credential")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Credential", valid_602925
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_602926 = formData.getOrDefault("SourceIdentifier")
  valid_602926 = validateParameter(valid_602926, JString, required = true,
                                 default = nil)
  if valid_602926 != nil:
    section.add "SourceIdentifier", valid_602926
  var valid_602927 = formData.getOrDefault("SubscriptionName")
  valid_602927 = validateParameter(valid_602927, JString, required = true,
                                 default = nil)
  if valid_602927 != nil:
    section.add "SubscriptionName", valid_602927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_PostRemoveSourceIdentifierFromSubscription_602914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602928, url, valid)

proc call*(call_602929: Call_PostRemoveSourceIdentifierFromSubscription_602914;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602930 = newJObject()
  var formData_602931 = newJObject()
  add(formData_602931, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_602931, "SubscriptionName", newJString(SubscriptionName))
  add(query_602930, "Action", newJString(Action))
  add(query_602930, "Version", newJString(Version))
  result = call_602929.call(nil, query_602930, nil, formData_602931, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_602914(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_602915,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_602916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602897 = ref object of OpenApiRestCall_600421
proc url_GetRemoveSourceIdentifierFromSubscription_602899(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602898(path: JsonNode;
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
  var valid_602900 = query.getOrDefault("Action")
  valid_602900 = validateParameter(valid_602900, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602900 != nil:
    section.add "Action", valid_602900
  var valid_602901 = query.getOrDefault("SourceIdentifier")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = nil)
  if valid_602901 != nil:
    section.add "SourceIdentifier", valid_602901
  var valid_602902 = query.getOrDefault("SubscriptionName")
  valid_602902 = validateParameter(valid_602902, JString, required = true,
                                 default = nil)
  if valid_602902 != nil:
    section.add "SubscriptionName", valid_602902
  var valid_602903 = query.getOrDefault("Version")
  valid_602903 = validateParameter(valid_602903, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602903 != nil:
    section.add "Version", valid_602903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602904 = header.getOrDefault("X-Amz-Date")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Date", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Security-Token")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Security-Token", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Content-Sha256", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Algorithm")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Algorithm", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Signature")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Signature", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-SignedHeaders", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Credential")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Credential", valid_602910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602911: Call_GetRemoveSourceIdentifierFromSubscription_602897;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602911.validator(path, query, header, formData, body)
  let scheme = call_602911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602911.url(scheme.get, call_602911.host, call_602911.base,
                         call_602911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602911, url, valid)

proc call*(call_602912: Call_GetRemoveSourceIdentifierFromSubscription_602897;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602913 = newJObject()
  add(query_602913, "Action", newJString(Action))
  add(query_602913, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602913, "SubscriptionName", newJString(SubscriptionName))
  add(query_602913, "Version", newJString(Version))
  result = call_602912.call(nil, query_602913, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602897(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602898,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602949 = ref object of OpenApiRestCall_600421
proc url_PostRemoveTagsFromResource_602951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_602950(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602952 = query.getOrDefault("Action")
  valid_602952 = validateParameter(valid_602952, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602952 != nil:
    section.add "Action", valid_602952
  var valid_602953 = query.getOrDefault("Version")
  valid_602953 = validateParameter(valid_602953, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602953 != nil:
    section.add "Version", valid_602953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602954 = header.getOrDefault("X-Amz-Date")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Date", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Security-Token")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Security-Token", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Content-Sha256", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Algorithm")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Algorithm", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Signature")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Signature", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-SignedHeaders", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Credential")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Credential", valid_602960
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602961 = formData.getOrDefault("TagKeys")
  valid_602961 = validateParameter(valid_602961, JArray, required = true, default = nil)
  if valid_602961 != nil:
    section.add "TagKeys", valid_602961
  var valid_602962 = formData.getOrDefault("ResourceName")
  valid_602962 = validateParameter(valid_602962, JString, required = true,
                                 default = nil)
  if valid_602962 != nil:
    section.add "ResourceName", valid_602962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602963: Call_PostRemoveTagsFromResource_602949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602963.validator(path, query, header, formData, body)
  let scheme = call_602963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602963.url(scheme.get, call_602963.host, call_602963.base,
                         call_602963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602963, url, valid)

proc call*(call_602964: Call_PostRemoveTagsFromResource_602949; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602965 = newJObject()
  var formData_602966 = newJObject()
  add(query_602965, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602966.add "TagKeys", TagKeys
  add(formData_602966, "ResourceName", newJString(ResourceName))
  add(query_602965, "Version", newJString(Version))
  result = call_602964.call(nil, query_602965, nil, formData_602966, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602949(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602950, base: "/",
    url: url_PostRemoveTagsFromResource_602951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602932 = ref object of OpenApiRestCall_600421
proc url_GetRemoveTagsFromResource_602934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_602933(path: JsonNode; query: JsonNode;
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
  var valid_602935 = query.getOrDefault("ResourceName")
  valid_602935 = validateParameter(valid_602935, JString, required = true,
                                 default = nil)
  if valid_602935 != nil:
    section.add "ResourceName", valid_602935
  var valid_602936 = query.getOrDefault("Action")
  valid_602936 = validateParameter(valid_602936, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602936 != nil:
    section.add "Action", valid_602936
  var valid_602937 = query.getOrDefault("TagKeys")
  valid_602937 = validateParameter(valid_602937, JArray, required = true, default = nil)
  if valid_602937 != nil:
    section.add "TagKeys", valid_602937
  var valid_602938 = query.getOrDefault("Version")
  valid_602938 = validateParameter(valid_602938, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602946: Call_GetRemoveTagsFromResource_602932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602946.validator(path, query, header, formData, body)
  let scheme = call_602946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602946.url(scheme.get, call_602946.host, call_602946.base,
                         call_602946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602946, url, valid)

proc call*(call_602947: Call_GetRemoveTagsFromResource_602932;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_602948 = newJObject()
  add(query_602948, "ResourceName", newJString(ResourceName))
  add(query_602948, "Action", newJString(Action))
  if TagKeys != nil:
    query_602948.add "TagKeys", TagKeys
  add(query_602948, "Version", newJString(Version))
  result = call_602947.call(nil, query_602948, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602932(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602933, base: "/",
    url: url_GetRemoveTagsFromResource_602934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602985 = ref object of OpenApiRestCall_600421
proc url_PostResetDBParameterGroup_602987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_602986(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602988 = query.getOrDefault("Action")
  valid_602988 = validateParameter(valid_602988, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602988 != nil:
    section.add "Action", valid_602988
  var valid_602989 = query.getOrDefault("Version")
  valid_602989 = validateParameter(valid_602989, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602989 != nil:
    section.add "Version", valid_602989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602990 = header.getOrDefault("X-Amz-Date")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Date", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Security-Token")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Security-Token", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Content-Sha256", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Algorithm")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Algorithm", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Signature")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Signature", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-SignedHeaders", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Credential")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Credential", valid_602996
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602997 = formData.getOrDefault("DBParameterGroupName")
  valid_602997 = validateParameter(valid_602997, JString, required = true,
                                 default = nil)
  if valid_602997 != nil:
    section.add "DBParameterGroupName", valid_602997
  var valid_602998 = formData.getOrDefault("Parameters")
  valid_602998 = validateParameter(valid_602998, JArray, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "Parameters", valid_602998
  var valid_602999 = formData.getOrDefault("ResetAllParameters")
  valid_602999 = validateParameter(valid_602999, JBool, required = false, default = nil)
  if valid_602999 != nil:
    section.add "ResetAllParameters", valid_602999
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603000: Call_PostResetDBParameterGroup_602985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603000.validator(path, query, header, formData, body)
  let scheme = call_603000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603000.url(scheme.get, call_603000.host, call_603000.base,
                         call_603000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603000, url, valid)

proc call*(call_603001: Call_PostResetDBParameterGroup_602985;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_603002 = newJObject()
  var formData_603003 = newJObject()
  add(formData_603003, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_603003.add "Parameters", Parameters
  add(query_603002, "Action", newJString(Action))
  add(formData_603003, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603002, "Version", newJString(Version))
  result = call_603001.call(nil, query_603002, nil, formData_603003, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602985(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602986, base: "/",
    url: url_PostResetDBParameterGroup_602987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_602967 = ref object of OpenApiRestCall_600421
proc url_GetResetDBParameterGroup_602969(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_602968(path: JsonNode; query: JsonNode;
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
  var valid_602970 = query.getOrDefault("DBParameterGroupName")
  valid_602970 = validateParameter(valid_602970, JString, required = true,
                                 default = nil)
  if valid_602970 != nil:
    section.add "DBParameterGroupName", valid_602970
  var valid_602971 = query.getOrDefault("Parameters")
  valid_602971 = validateParameter(valid_602971, JArray, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "Parameters", valid_602971
  var valid_602972 = query.getOrDefault("Action")
  valid_602972 = validateParameter(valid_602972, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602972 != nil:
    section.add "Action", valid_602972
  var valid_602973 = query.getOrDefault("ResetAllParameters")
  valid_602973 = validateParameter(valid_602973, JBool, required = false, default = nil)
  if valid_602973 != nil:
    section.add "ResetAllParameters", valid_602973
  var valid_602974 = query.getOrDefault("Version")
  valid_602974 = validateParameter(valid_602974, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602974 != nil:
    section.add "Version", valid_602974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602975 = header.getOrDefault("X-Amz-Date")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Date", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Security-Token")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Security-Token", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Content-Sha256", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Algorithm")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Algorithm", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Signature")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Signature", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-SignedHeaders", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-Credential")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Credential", valid_602981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602982: Call_GetResetDBParameterGroup_602967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602982.validator(path, query, header, formData, body)
  let scheme = call_602982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602982.url(scheme.get, call_602982.host, call_602982.base,
                         call_602982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602982, url, valid)

proc call*(call_602983: Call_GetResetDBParameterGroup_602967;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602984 = newJObject()
  add(query_602984, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602984.add "Parameters", Parameters
  add(query_602984, "Action", newJString(Action))
  add(query_602984, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602984, "Version", newJString(Version))
  result = call_602983.call(nil, query_602984, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_602967(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_602968, base: "/",
    url: url_GetResetDBParameterGroup_602969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603034 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceFromDBSnapshot_603036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_603035(path: JsonNode;
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
  var valid_603037 = query.getOrDefault("Action")
  valid_603037 = validateParameter(valid_603037, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603037 != nil:
    section.add "Action", valid_603037
  var valid_603038 = query.getOrDefault("Version")
  valid_603038 = validateParameter(valid_603038, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603038 != nil:
    section.add "Version", valid_603038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603039 = header.getOrDefault("X-Amz-Date")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Date", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Security-Token")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Security-Token", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Content-Sha256", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Algorithm")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Algorithm", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Signature")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Signature", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-SignedHeaders", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Credential")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Credential", valid_603045
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
  var valid_603046 = formData.getOrDefault("Port")
  valid_603046 = validateParameter(valid_603046, JInt, required = false, default = nil)
  if valid_603046 != nil:
    section.add "Port", valid_603046
  var valid_603047 = formData.getOrDefault("Engine")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "Engine", valid_603047
  var valid_603048 = formData.getOrDefault("Iops")
  valid_603048 = validateParameter(valid_603048, JInt, required = false, default = nil)
  if valid_603048 != nil:
    section.add "Iops", valid_603048
  var valid_603049 = formData.getOrDefault("DBName")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "DBName", valid_603049
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603050 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = nil)
  if valid_603050 != nil:
    section.add "DBInstanceIdentifier", valid_603050
  var valid_603051 = formData.getOrDefault("OptionGroupName")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "OptionGroupName", valid_603051
  var valid_603052 = formData.getOrDefault("Tags")
  valid_603052 = validateParameter(valid_603052, JArray, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "Tags", valid_603052
  var valid_603053 = formData.getOrDefault("DBSubnetGroupName")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "DBSubnetGroupName", valid_603053
  var valid_603054 = formData.getOrDefault("AvailabilityZone")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "AvailabilityZone", valid_603054
  var valid_603055 = formData.getOrDefault("MultiAZ")
  valid_603055 = validateParameter(valid_603055, JBool, required = false, default = nil)
  if valid_603055 != nil:
    section.add "MultiAZ", valid_603055
  var valid_603056 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "DBSnapshotIdentifier", valid_603056
  var valid_603057 = formData.getOrDefault("PubliclyAccessible")
  valid_603057 = validateParameter(valid_603057, JBool, required = false, default = nil)
  if valid_603057 != nil:
    section.add "PubliclyAccessible", valid_603057
  var valid_603058 = formData.getOrDefault("DBInstanceClass")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "DBInstanceClass", valid_603058
  var valid_603059 = formData.getOrDefault("LicenseModel")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "LicenseModel", valid_603059
  var valid_603060 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603060 = validateParameter(valid_603060, JBool, required = false, default = nil)
  if valid_603060 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603061: Call_PostRestoreDBInstanceFromDBSnapshot_603034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603061.validator(path, query, header, formData, body)
  let scheme = call_603061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603061.url(scheme.get, call_603061.host, call_603061.base,
                         call_603061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603061, url, valid)

proc call*(call_603062: Call_PostRestoreDBInstanceFromDBSnapshot_603034;
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
  var query_603063 = newJObject()
  var formData_603064 = newJObject()
  add(formData_603064, "Port", newJInt(Port))
  add(formData_603064, "Engine", newJString(Engine))
  add(formData_603064, "Iops", newJInt(Iops))
  add(formData_603064, "DBName", newJString(DBName))
  add(formData_603064, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603064, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603064.add "Tags", Tags
  add(formData_603064, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603064, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603064, "MultiAZ", newJBool(MultiAZ))
  add(formData_603064, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603063, "Action", newJString(Action))
  add(formData_603064, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603064, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603064, "LicenseModel", newJString(LicenseModel))
  add(formData_603064, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603063, "Version", newJString(Version))
  result = call_603062.call(nil, query_603063, nil, formData_603064, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603034(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603035, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603004 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceFromDBSnapshot_603006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_603005(path: JsonNode;
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
  var valid_603007 = query.getOrDefault("Engine")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "Engine", valid_603007
  var valid_603008 = query.getOrDefault("OptionGroupName")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "OptionGroupName", valid_603008
  var valid_603009 = query.getOrDefault("AvailabilityZone")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "AvailabilityZone", valid_603009
  var valid_603010 = query.getOrDefault("Iops")
  valid_603010 = validateParameter(valid_603010, JInt, required = false, default = nil)
  if valid_603010 != nil:
    section.add "Iops", valid_603010
  var valid_603011 = query.getOrDefault("MultiAZ")
  valid_603011 = validateParameter(valid_603011, JBool, required = false, default = nil)
  if valid_603011 != nil:
    section.add "MultiAZ", valid_603011
  var valid_603012 = query.getOrDefault("LicenseModel")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "LicenseModel", valid_603012
  var valid_603013 = query.getOrDefault("Tags")
  valid_603013 = validateParameter(valid_603013, JArray, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "Tags", valid_603013
  var valid_603014 = query.getOrDefault("DBName")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "DBName", valid_603014
  var valid_603015 = query.getOrDefault("DBInstanceClass")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "DBInstanceClass", valid_603015
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603016 = query.getOrDefault("Action")
  valid_603016 = validateParameter(valid_603016, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603016 != nil:
    section.add "Action", valid_603016
  var valid_603017 = query.getOrDefault("DBSubnetGroupName")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "DBSubnetGroupName", valid_603017
  var valid_603018 = query.getOrDefault("PubliclyAccessible")
  valid_603018 = validateParameter(valid_603018, JBool, required = false, default = nil)
  if valid_603018 != nil:
    section.add "PubliclyAccessible", valid_603018
  var valid_603019 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603019 = validateParameter(valid_603019, JBool, required = false, default = nil)
  if valid_603019 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603019
  var valid_603020 = query.getOrDefault("Port")
  valid_603020 = validateParameter(valid_603020, JInt, required = false, default = nil)
  if valid_603020 != nil:
    section.add "Port", valid_603020
  var valid_603021 = query.getOrDefault("Version")
  valid_603021 = validateParameter(valid_603021, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603021 != nil:
    section.add "Version", valid_603021
  var valid_603022 = query.getOrDefault("DBInstanceIdentifier")
  valid_603022 = validateParameter(valid_603022, JString, required = true,
                                 default = nil)
  if valid_603022 != nil:
    section.add "DBInstanceIdentifier", valid_603022
  var valid_603023 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603023 = validateParameter(valid_603023, JString, required = true,
                                 default = nil)
  if valid_603023 != nil:
    section.add "DBSnapshotIdentifier", valid_603023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603024 = header.getOrDefault("X-Amz-Date")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Date", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Security-Token")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Security-Token", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Content-Sha256", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Algorithm")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Algorithm", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Signature")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Signature", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-SignedHeaders", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Credential")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Credential", valid_603030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603031: Call_GetRestoreDBInstanceFromDBSnapshot_603004;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603031.validator(path, query, header, formData, body)
  let scheme = call_603031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603031.url(scheme.get, call_603031.host, call_603031.base,
                         call_603031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603031, url, valid)

proc call*(call_603032: Call_GetRestoreDBInstanceFromDBSnapshot_603004;
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
  var query_603033 = newJObject()
  add(query_603033, "Engine", newJString(Engine))
  add(query_603033, "OptionGroupName", newJString(OptionGroupName))
  add(query_603033, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603033, "Iops", newJInt(Iops))
  add(query_603033, "MultiAZ", newJBool(MultiAZ))
  add(query_603033, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603033.add "Tags", Tags
  add(query_603033, "DBName", newJString(DBName))
  add(query_603033, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603033, "Action", newJString(Action))
  add(query_603033, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603033, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603033, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603033, "Port", newJInt(Port))
  add(query_603033, "Version", newJString(Version))
  add(query_603033, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603033, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603032.call(nil, query_603033, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603004(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603005, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603097 = ref object of OpenApiRestCall_600421
proc url_PostRestoreDBInstanceToPointInTime_603099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_603098(path: JsonNode;
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
  var valid_603100 = query.getOrDefault("Action")
  valid_603100 = validateParameter(valid_603100, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603100 != nil:
    section.add "Action", valid_603100
  var valid_603101 = query.getOrDefault("Version")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603101 != nil:
    section.add "Version", valid_603101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Content-Sha256", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Signature")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Signature", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
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
  var valid_603109 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603109 = validateParameter(valid_603109, JBool, required = false, default = nil)
  if valid_603109 != nil:
    section.add "UseLatestRestorableTime", valid_603109
  var valid_603110 = formData.getOrDefault("Port")
  valid_603110 = validateParameter(valid_603110, JInt, required = false, default = nil)
  if valid_603110 != nil:
    section.add "Port", valid_603110
  var valid_603111 = formData.getOrDefault("Engine")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "Engine", valid_603111
  var valid_603112 = formData.getOrDefault("Iops")
  valid_603112 = validateParameter(valid_603112, JInt, required = false, default = nil)
  if valid_603112 != nil:
    section.add "Iops", valid_603112
  var valid_603113 = formData.getOrDefault("DBName")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "DBName", valid_603113
  var valid_603114 = formData.getOrDefault("OptionGroupName")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "OptionGroupName", valid_603114
  var valid_603115 = formData.getOrDefault("Tags")
  valid_603115 = validateParameter(valid_603115, JArray, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "Tags", valid_603115
  var valid_603116 = formData.getOrDefault("DBSubnetGroupName")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "DBSubnetGroupName", valid_603116
  var valid_603117 = formData.getOrDefault("AvailabilityZone")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "AvailabilityZone", valid_603117
  var valid_603118 = formData.getOrDefault("MultiAZ")
  valid_603118 = validateParameter(valid_603118, JBool, required = false, default = nil)
  if valid_603118 != nil:
    section.add "MultiAZ", valid_603118
  var valid_603119 = formData.getOrDefault("RestoreTime")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "RestoreTime", valid_603119
  var valid_603120 = formData.getOrDefault("PubliclyAccessible")
  valid_603120 = validateParameter(valid_603120, JBool, required = false, default = nil)
  if valid_603120 != nil:
    section.add "PubliclyAccessible", valid_603120
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603121 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603121
  var valid_603122 = formData.getOrDefault("DBInstanceClass")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "DBInstanceClass", valid_603122
  var valid_603123 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = nil)
  if valid_603123 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603123
  var valid_603124 = formData.getOrDefault("LicenseModel")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "LicenseModel", valid_603124
  var valid_603125 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603125 = validateParameter(valid_603125, JBool, required = false, default = nil)
  if valid_603125 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_PostRestoreDBInstanceToPointInTime_603097;
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

proc call*(call_603127: Call_PostRestoreDBInstanceToPointInTime_603097;
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
  var query_603128 = newJObject()
  var formData_603129 = newJObject()
  add(formData_603129, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603129, "Port", newJInt(Port))
  add(formData_603129, "Engine", newJString(Engine))
  add(formData_603129, "Iops", newJInt(Iops))
  add(formData_603129, "DBName", newJString(DBName))
  add(formData_603129, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603129.add "Tags", Tags
  add(formData_603129, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603129, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603129, "MultiAZ", newJBool(MultiAZ))
  add(query_603128, "Action", newJString(Action))
  add(formData_603129, "RestoreTime", newJString(RestoreTime))
  add(formData_603129, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603129, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603129, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603129, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603129, "LicenseModel", newJString(LicenseModel))
  add(formData_603129, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603128, "Version", newJString(Version))
  result = call_603127.call(nil, query_603128, nil, formData_603129, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603097(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603098, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603065 = ref object of OpenApiRestCall_600421
proc url_GetRestoreDBInstanceToPointInTime_603067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_603066(path: JsonNode;
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
  var valid_603068 = query.getOrDefault("Engine")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "Engine", valid_603068
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603069 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603069 = validateParameter(valid_603069, JString, required = true,
                                 default = nil)
  if valid_603069 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603069
  var valid_603070 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603070 = validateParameter(valid_603070, JString, required = true,
                                 default = nil)
  if valid_603070 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603070
  var valid_603071 = query.getOrDefault("AvailabilityZone")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "AvailabilityZone", valid_603071
  var valid_603072 = query.getOrDefault("Iops")
  valid_603072 = validateParameter(valid_603072, JInt, required = false, default = nil)
  if valid_603072 != nil:
    section.add "Iops", valid_603072
  var valid_603073 = query.getOrDefault("OptionGroupName")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "OptionGroupName", valid_603073
  var valid_603074 = query.getOrDefault("RestoreTime")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "RestoreTime", valid_603074
  var valid_603075 = query.getOrDefault("MultiAZ")
  valid_603075 = validateParameter(valid_603075, JBool, required = false, default = nil)
  if valid_603075 != nil:
    section.add "MultiAZ", valid_603075
  var valid_603076 = query.getOrDefault("LicenseModel")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "LicenseModel", valid_603076
  var valid_603077 = query.getOrDefault("Tags")
  valid_603077 = validateParameter(valid_603077, JArray, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "Tags", valid_603077
  var valid_603078 = query.getOrDefault("DBName")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "DBName", valid_603078
  var valid_603079 = query.getOrDefault("DBInstanceClass")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "DBInstanceClass", valid_603079
  var valid_603080 = query.getOrDefault("Action")
  valid_603080 = validateParameter(valid_603080, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603080 != nil:
    section.add "Action", valid_603080
  var valid_603081 = query.getOrDefault("UseLatestRestorableTime")
  valid_603081 = validateParameter(valid_603081, JBool, required = false, default = nil)
  if valid_603081 != nil:
    section.add "UseLatestRestorableTime", valid_603081
  var valid_603082 = query.getOrDefault("DBSubnetGroupName")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "DBSubnetGroupName", valid_603082
  var valid_603083 = query.getOrDefault("PubliclyAccessible")
  valid_603083 = validateParameter(valid_603083, JBool, required = false, default = nil)
  if valid_603083 != nil:
    section.add "PubliclyAccessible", valid_603083
  var valid_603084 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603084 = validateParameter(valid_603084, JBool, required = false, default = nil)
  if valid_603084 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603084
  var valid_603085 = query.getOrDefault("Port")
  valid_603085 = validateParameter(valid_603085, JInt, required = false, default = nil)
  if valid_603085 != nil:
    section.add "Port", valid_603085
  var valid_603086 = query.getOrDefault("Version")
  valid_603086 = validateParameter(valid_603086, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603086 != nil:
    section.add "Version", valid_603086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Content-Sha256", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Algorithm")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Algorithm", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Signature")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Signature", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-SignedHeaders", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Credential")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Credential", valid_603093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_GetRestoreDBInstanceToPointInTime_603065;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_GetRestoreDBInstanceToPointInTime_603065;
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
  var query_603096 = newJObject()
  add(query_603096, "Engine", newJString(Engine))
  add(query_603096, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603096, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603096, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603096, "Iops", newJInt(Iops))
  add(query_603096, "OptionGroupName", newJString(OptionGroupName))
  add(query_603096, "RestoreTime", newJString(RestoreTime))
  add(query_603096, "MultiAZ", newJBool(MultiAZ))
  add(query_603096, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603096.add "Tags", Tags
  add(query_603096, "DBName", newJString(DBName))
  add(query_603096, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603096, "Action", newJString(Action))
  add(query_603096, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603096, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603096, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603096, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603096, "Port", newJInt(Port))
  add(query_603096, "Version", newJString(Version))
  result = call_603095.call(nil, query_603096, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603065(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603066, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603150 = ref object of OpenApiRestCall_600421
proc url_PostRevokeDBSecurityGroupIngress_603152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_603151(path: JsonNode;
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
  var valid_603153 = query.getOrDefault("Action")
  valid_603153 = validateParameter(valid_603153, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603153 != nil:
    section.add "Action", valid_603153
  var valid_603154 = query.getOrDefault("Version")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603154 != nil:
    section.add "Version", valid_603154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603155 = header.getOrDefault("X-Amz-Date")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Date", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Content-Sha256", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Algorithm")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Algorithm", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Signature")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Signature", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-SignedHeaders", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Credential")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Credential", valid_603161
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603162 = formData.getOrDefault("DBSecurityGroupName")
  valid_603162 = validateParameter(valid_603162, JString, required = true,
                                 default = nil)
  if valid_603162 != nil:
    section.add "DBSecurityGroupName", valid_603162
  var valid_603163 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "EC2SecurityGroupName", valid_603163
  var valid_603164 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "EC2SecurityGroupId", valid_603164
  var valid_603165 = formData.getOrDefault("CIDRIP")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "CIDRIP", valid_603165
  var valid_603166 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_PostRevokeDBSecurityGroupIngress_603150;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_PostRevokeDBSecurityGroupIngress_603150;
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
  var query_603169 = newJObject()
  var formData_603170 = newJObject()
  add(formData_603170, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603169, "Action", newJString(Action))
  add(formData_603170, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603170, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603170, "CIDRIP", newJString(CIDRIP))
  add(query_603169, "Version", newJString(Version))
  add(formData_603170, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603168.call(nil, query_603169, nil, formData_603170, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603150(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603151, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603130 = ref object of OpenApiRestCall_600421
proc url_GetRevokeDBSecurityGroupIngress_603132(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_603131(path: JsonNode;
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
  var valid_603133 = query.getOrDefault("EC2SecurityGroupId")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "EC2SecurityGroupId", valid_603133
  var valid_603134 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603134
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603135 = query.getOrDefault("DBSecurityGroupName")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = nil)
  if valid_603135 != nil:
    section.add "DBSecurityGroupName", valid_603135
  var valid_603136 = query.getOrDefault("Action")
  valid_603136 = validateParameter(valid_603136, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603136 != nil:
    section.add "Action", valid_603136
  var valid_603137 = query.getOrDefault("CIDRIP")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "CIDRIP", valid_603137
  var valid_603138 = query.getOrDefault("EC2SecurityGroupName")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "EC2SecurityGroupName", valid_603138
  var valid_603139 = query.getOrDefault("Version")
  valid_603139 = validateParameter(valid_603139, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603139 != nil:
    section.add "Version", valid_603139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603140 = header.getOrDefault("X-Amz-Date")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Date", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Security-Token")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Security-Token", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Content-Sha256", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Algorithm")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Algorithm", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Signature")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Signature", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-SignedHeaders", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Credential")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Credential", valid_603146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603147: Call_GetRevokeDBSecurityGroupIngress_603130;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603147.validator(path, query, header, formData, body)
  let scheme = call_603147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603147.url(scheme.get, call_603147.host, call_603147.base,
                         call_603147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603147, url, valid)

proc call*(call_603148: Call_GetRevokeDBSecurityGroupIngress_603130;
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
  var query_603149 = newJObject()
  add(query_603149, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603149, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603149, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603149, "Action", newJString(Action))
  add(query_603149, "CIDRIP", newJString(CIDRIP))
  add(query_603149, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603149, "Version", newJString(Version))
  result = call_603148.call(nil, query_603149, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603130(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603131, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603132,
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

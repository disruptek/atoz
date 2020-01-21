
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_606183 = ref object of OpenApiRestCall_605573
proc url_PostAddSourceIdentifierToSubscription_606185(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_606184(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606186 = query.getOrDefault("Action")
  valid_606186 = validateParameter(valid_606186, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_606186 != nil:
    section.add "Action", valid_606186
  var valid_606187 = query.getOrDefault("Version")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606187 != nil:
    section.add "Version", valid_606187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606188 = header.getOrDefault("X-Amz-Signature")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Signature", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Content-Sha256", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Date")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Date", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Credential")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Credential", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Security-Token")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Security-Token", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Algorithm")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Algorithm", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-SignedHeaders", valid_606194
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_606195 = formData.getOrDefault("SubscriptionName")
  valid_606195 = validateParameter(valid_606195, JString, required = true,
                                 default = nil)
  if valid_606195 != nil:
    section.add "SubscriptionName", valid_606195
  var valid_606196 = formData.getOrDefault("SourceIdentifier")
  valid_606196 = validateParameter(valid_606196, JString, required = true,
                                 default = nil)
  if valid_606196 != nil:
    section.add "SourceIdentifier", valid_606196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_PostAddSourceIdentifierToSubscription_606183;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_PostAddSourceIdentifierToSubscription_606183;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606199 = newJObject()
  var formData_606200 = newJObject()
  add(formData_606200, "SubscriptionName", newJString(SubscriptionName))
  add(formData_606200, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_606199, "Action", newJString(Action))
  add(query_606199, "Version", newJString(Version))
  result = call_606198.call(nil, query_606199, nil, formData_606200, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_606183(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_606184, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_606185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_605911 = ref object of OpenApiRestCall_605573
proc url_GetAddSourceIdentifierToSubscription_605913(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_605912(path: JsonNode;
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
  var valid_606025 = query.getOrDefault("SourceIdentifier")
  valid_606025 = validateParameter(valid_606025, JString, required = true,
                                 default = nil)
  if valid_606025 != nil:
    section.add "SourceIdentifier", valid_606025
  var valid_606026 = query.getOrDefault("SubscriptionName")
  valid_606026 = validateParameter(valid_606026, JString, required = true,
                                 default = nil)
  if valid_606026 != nil:
    section.add "SubscriptionName", valid_606026
  var valid_606040 = query.getOrDefault("Action")
  valid_606040 = validateParameter(valid_606040, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_606040 != nil:
    section.add "Action", valid_606040
  var valid_606041 = query.getOrDefault("Version")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606041 != nil:
    section.add "Version", valid_606041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606042 = header.getOrDefault("X-Amz-Signature")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Signature", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Content-Sha256", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Date")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Date", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Credential")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Credential", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Security-Token")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Security-Token", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Algorithm")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Algorithm", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-SignedHeaders", valid_606048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_GetAddSourceIdentifierToSubscription_605911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_GetAddSourceIdentifierToSubscription_605911;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606143 = newJObject()
  add(query_606143, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_606143, "SubscriptionName", newJString(SubscriptionName))
  add(query_606143, "Action", newJString(Action))
  add(query_606143, "Version", newJString(Version))
  result = call_606142.call(nil, query_606143, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_605911(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_605912, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_605913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_606218 = ref object of OpenApiRestCall_605573
proc url_PostAddTagsToResource_606220(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_606219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606221 = query.getOrDefault("Action")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606221 != nil:
    section.add "Action", valid_606221
  var valid_606222 = query.getOrDefault("Version")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606222 != nil:
    section.add "Version", valid_606222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_606230 = formData.getOrDefault("Tags")
  valid_606230 = validateParameter(valid_606230, JArray, required = true, default = nil)
  if valid_606230 != nil:
    section.add "Tags", valid_606230
  var valid_606231 = formData.getOrDefault("ResourceName")
  valid_606231 = validateParameter(valid_606231, JString, required = true,
                                 default = nil)
  if valid_606231 != nil:
    section.add "ResourceName", valid_606231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606232: Call_PostAddTagsToResource_606218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606232.validator(path, query, header, formData, body)
  let scheme = call_606232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606232.url(scheme.get, call_606232.host, call_606232.base,
                         call_606232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606232, url, valid)

proc call*(call_606233: Call_PostAddTagsToResource_606218; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_606234 = newJObject()
  var formData_606235 = newJObject()
  add(query_606234, "Action", newJString(Action))
  if Tags != nil:
    formData_606235.add "Tags", Tags
  add(query_606234, "Version", newJString(Version))
  add(formData_606235, "ResourceName", newJString(ResourceName))
  result = call_606233.call(nil, query_606234, nil, formData_606235, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_606218(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_606219, base: "/",
    url: url_PostAddTagsToResource_606220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_606201 = ref object of OpenApiRestCall_605573
proc url_GetAddTagsToResource_606203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_606202(path: JsonNode; query: JsonNode;
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
  var valid_606204 = query.getOrDefault("Tags")
  valid_606204 = validateParameter(valid_606204, JArray, required = true, default = nil)
  if valid_606204 != nil:
    section.add "Tags", valid_606204
  var valid_606205 = query.getOrDefault("ResourceName")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "ResourceName", valid_606205
  var valid_606206 = query.getOrDefault("Action")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606206 != nil:
    section.add "Action", valid_606206
  var valid_606207 = query.getOrDefault("Version")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606207 != nil:
    section.add "Version", valid_606207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606208 = header.getOrDefault("X-Amz-Signature")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Signature", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Content-Sha256", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Date")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Date", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Credential")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Credential", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Security-Token")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Security-Token", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Algorithm")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Algorithm", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-SignedHeaders", valid_606214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_GetAddTagsToResource_606201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_GetAddTagsToResource_606201; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606217 = newJObject()
  if Tags != nil:
    query_606217.add "Tags", Tags
  add(query_606217, "ResourceName", newJString(ResourceName))
  add(query_606217, "Action", newJString(Action))
  add(query_606217, "Version", newJString(Version))
  result = call_606216.call(nil, query_606217, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_606201(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_606202, base: "/",
    url: url_GetAddTagsToResource_606203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_606256 = ref object of OpenApiRestCall_605573
proc url_PostAuthorizeDBSecurityGroupIngress_606258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_606257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Version")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606260 != nil:
    section.add "Version", valid_606260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606268 = formData.getOrDefault("DBSecurityGroupName")
  valid_606268 = validateParameter(valid_606268, JString, required = true,
                                 default = nil)
  if valid_606268 != nil:
    section.add "DBSecurityGroupName", valid_606268
  var valid_606269 = formData.getOrDefault("EC2SecurityGroupName")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "EC2SecurityGroupName", valid_606269
  var valid_606270 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_606270
  var valid_606271 = formData.getOrDefault("EC2SecurityGroupId")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "EC2SecurityGroupId", valid_606271
  var valid_606272 = formData.getOrDefault("CIDRIP")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "CIDRIP", valid_606272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_PostAuthorizeDBSecurityGroupIngress_606256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_PostAuthorizeDBSecurityGroupIngress_606256;
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
  var query_606275 = newJObject()
  var formData_606276 = newJObject()
  add(formData_606276, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_606276, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_606276, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_606276, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_606276, "CIDRIP", newJString(CIDRIP))
  add(query_606275, "Action", newJString(Action))
  add(query_606275, "Version", newJString(Version))
  result = call_606274.call(nil, query_606275, nil, formData_606276, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_606256(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_606257, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_606236 = ref object of OpenApiRestCall_605573
proc url_GetAuthorizeDBSecurityGroupIngress_606238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_606237(path: JsonNode;
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
  var valid_606239 = query.getOrDefault("EC2SecurityGroupName")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "EC2SecurityGroupName", valid_606239
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606240 = query.getOrDefault("DBSecurityGroupName")
  valid_606240 = validateParameter(valid_606240, JString, required = true,
                                 default = nil)
  if valid_606240 != nil:
    section.add "DBSecurityGroupName", valid_606240
  var valid_606241 = query.getOrDefault("EC2SecurityGroupId")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "EC2SecurityGroupId", valid_606241
  var valid_606242 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_606242
  var valid_606243 = query.getOrDefault("Action")
  valid_606243 = validateParameter(valid_606243, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_606243 != nil:
    section.add "Action", valid_606243
  var valid_606244 = query.getOrDefault("Version")
  valid_606244 = validateParameter(valid_606244, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606244 != nil:
    section.add "Version", valid_606244
  var valid_606245 = query.getOrDefault("CIDRIP")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "CIDRIP", valid_606245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_GetAuthorizeDBSecurityGroupIngress_606236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_GetAuthorizeDBSecurityGroupIngress_606236;
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
  var query_606255 = newJObject()
  add(query_606255, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_606255, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606255, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_606255, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_606255, "Action", newJString(Action))
  add(query_606255, "Version", newJString(Version))
  add(query_606255, "CIDRIP", newJString(CIDRIP))
  result = call_606254.call(nil, query_606255, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_606236(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_606237, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_606238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_606296 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBParameterGroup_606298(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBParameterGroup_606297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606299 = query.getOrDefault("Action")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_606299 != nil:
    section.add "Action", valid_606299
  var valid_606300 = query.getOrDefault("Version")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606300 != nil:
    section.add "Version", valid_606300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_606308 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_606308 = validateParameter(valid_606308, JString, required = true,
                                 default = nil)
  if valid_606308 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_606308
  var valid_606309 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = nil)
  if valid_606309 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_606309
  var valid_606310 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = nil)
  if valid_606310 != nil:
    section.add "TargetDBParameterGroupDescription", valid_606310
  var valid_606311 = formData.getOrDefault("Tags")
  valid_606311 = validateParameter(valid_606311, JArray, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "Tags", valid_606311
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606312: Call_PostCopyDBParameterGroup_606296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606312.validator(path, query, header, formData, body)
  let scheme = call_606312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606312.url(scheme.get, call_606312.host, call_606312.base,
                         call_606312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606312, url, valid)

proc call*(call_606313: Call_PostCopyDBParameterGroup_606296;
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
  var query_606314 = newJObject()
  var formData_606315 = newJObject()
  add(formData_606315, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(formData_606315, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_606315, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_606314, "Action", newJString(Action))
  if Tags != nil:
    formData_606315.add "Tags", Tags
  add(query_606314, "Version", newJString(Version))
  result = call_606313.call(nil, query_606314, nil, formData_606315, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_606296(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_606297, base: "/",
    url: url_PostCopyDBParameterGroup_606298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_606277 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBParameterGroup_606279(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBParameterGroup_606278(path: JsonNode; query: JsonNode;
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
  var valid_606280 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_606280
  var valid_606281 = query.getOrDefault("Tags")
  valid_606281 = validateParameter(valid_606281, JArray, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "Tags", valid_606281
  var valid_606282 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "TargetDBParameterGroupDescription", valid_606282
  var valid_606283 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_606283
  var valid_606284 = query.getOrDefault("Action")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_606284 != nil:
    section.add "Action", valid_606284
  var valid_606285 = query.getOrDefault("Version")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606285 != nil:
    section.add "Version", valid_606285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606286 = header.getOrDefault("X-Amz-Signature")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Signature", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Content-Sha256", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Date")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Date", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Credential")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Credential", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Security-Token")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Security-Token", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Algorithm")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Algorithm", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-SignedHeaders", valid_606292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606293: Call_GetCopyDBParameterGroup_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606293.validator(path, query, header, formData, body)
  let scheme = call_606293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606293.url(scheme.get, call_606293.host, call_606293.base,
                         call_606293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606293, url, valid)

proc call*(call_606294: Call_GetCopyDBParameterGroup_606277;
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
  var query_606295 = newJObject()
  add(query_606295, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    query_606295.add "Tags", Tags
  add(query_606295, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_606295, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_606295, "Action", newJString(Action))
  add(query_606295, "Version", newJString(Version))
  result = call_606294.call(nil, query_606295, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_606277(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_606278, base: "/",
    url: url_GetCopyDBParameterGroup_606279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_606334 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBSnapshot_606336(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_606335(path: JsonNode; query: JsonNode;
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
  var valid_606337 = query.getOrDefault("Action")
  valid_606337 = validateParameter(valid_606337, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606337 != nil:
    section.add "Action", valid_606337
  var valid_606338 = query.getOrDefault("Version")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606338 != nil:
    section.add "Version", valid_606338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606339 = header.getOrDefault("X-Amz-Signature")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Signature", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Content-Sha256", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Date")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Date", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Credential")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Credential", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Security-Token")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Security-Token", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Algorithm")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Algorithm", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-SignedHeaders", valid_606345
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_606346 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606346
  var valid_606347 = formData.getOrDefault("Tags")
  valid_606347 = validateParameter(valid_606347, JArray, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "Tags", valid_606347
  var valid_606348 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = nil)
  if valid_606348 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_PostCopyDBSnapshot_606334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_PostCopyDBSnapshot_606334;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606351 = newJObject()
  var formData_606352 = newJObject()
  add(formData_606352, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_606351, "Action", newJString(Action))
  if Tags != nil:
    formData_606352.add "Tags", Tags
  add(formData_606352, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606351, "Version", newJString(Version))
  result = call_606350.call(nil, query_606351, nil, formData_606352, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_606334(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_606335, base: "/",
    url: url_PostCopyDBSnapshot_606336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_606316 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBSnapshot_606318(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_606317(path: JsonNode; query: JsonNode;
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
  var valid_606319 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606319 = validateParameter(valid_606319, JString, required = true,
                                 default = nil)
  if valid_606319 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606319
  var valid_606320 = query.getOrDefault("Tags")
  valid_606320 = validateParameter(valid_606320, JArray, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "Tags", valid_606320
  var valid_606321 = query.getOrDefault("Action")
  valid_606321 = validateParameter(valid_606321, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606321 != nil:
    section.add "Action", valid_606321
  var valid_606322 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606322 = validateParameter(valid_606322, JString, required = true,
                                 default = nil)
  if valid_606322 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606322
  var valid_606323 = query.getOrDefault("Version")
  valid_606323 = validateParameter(valid_606323, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606323 != nil:
    section.add "Version", valid_606323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606324 = header.getOrDefault("X-Amz-Signature")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Signature", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Content-Sha256", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Date")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Date", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Credential")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Credential", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Security-Token")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Security-Token", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Algorithm")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Algorithm", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-SignedHeaders", valid_606330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606331: Call_GetCopyDBSnapshot_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606331.validator(path, query, header, formData, body)
  let scheme = call_606331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606331.url(scheme.get, call_606331.host, call_606331.base,
                         call_606331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606331, url, valid)

proc call*(call_606332: Call_GetCopyDBSnapshot_606316;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606333 = newJObject()
  add(query_606333, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_606333.add "Tags", Tags
  add(query_606333, "Action", newJString(Action))
  add(query_606333, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606333, "Version", newJString(Version))
  result = call_606332.call(nil, query_606333, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_606316(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_606317,
    base: "/", url: url_GetCopyDBSnapshot_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_606372 = ref object of OpenApiRestCall_605573
proc url_PostCopyOptionGroup_606374(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyOptionGroup_606373(path: JsonNode; query: JsonNode;
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
  var valid_606375 = query.getOrDefault("Action")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_606375 != nil:
    section.add "Action", valid_606375
  var valid_606376 = query.getOrDefault("Version")
  valid_606376 = validateParameter(valid_606376, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606376 != nil:
    section.add "Version", valid_606376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606377 = header.getOrDefault("X-Amz-Signature")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Signature", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Content-Sha256", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Date")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Date", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Credential")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Credential", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Security-Token")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Security-Token", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Algorithm")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Algorithm", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-SignedHeaders", valid_606383
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_606384 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = nil)
  if valid_606384 != nil:
    section.add "TargetOptionGroupIdentifier", valid_606384
  var valid_606385 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_606385 = validateParameter(valid_606385, JString, required = true,
                                 default = nil)
  if valid_606385 != nil:
    section.add "TargetOptionGroupDescription", valid_606385
  var valid_606386 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_606386 = validateParameter(valid_606386, JString, required = true,
                                 default = nil)
  if valid_606386 != nil:
    section.add "SourceOptionGroupIdentifier", valid_606386
  var valid_606387 = formData.getOrDefault("Tags")
  valid_606387 = validateParameter(valid_606387, JArray, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "Tags", valid_606387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_PostCopyOptionGroup_606372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_PostCopyOptionGroup_606372;
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
  var query_606390 = newJObject()
  var formData_606391 = newJObject()
  add(formData_606391, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(formData_606391, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(formData_606391, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_606390, "Action", newJString(Action))
  if Tags != nil:
    formData_606391.add "Tags", Tags
  add(query_606390, "Version", newJString(Version))
  result = call_606389.call(nil, query_606390, nil, formData_606391, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_606372(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_606373, base: "/",
    url: url_PostCopyOptionGroup_606374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_606353 = ref object of OpenApiRestCall_605573
proc url_GetCopyOptionGroup_606355(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyOptionGroup_606354(path: JsonNode; query: JsonNode;
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
  var valid_606356 = query.getOrDefault("Tags")
  valid_606356 = validateParameter(valid_606356, JArray, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "Tags", valid_606356
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_606357 = query.getOrDefault("TargetOptionGroupDescription")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "TargetOptionGroupDescription", valid_606357
  var valid_606358 = query.getOrDefault("Action")
  valid_606358 = validateParameter(valid_606358, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_606358 != nil:
    section.add "Action", valid_606358
  var valid_606359 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "TargetOptionGroupIdentifier", valid_606359
  var valid_606360 = query.getOrDefault("Version")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606360 != nil:
    section.add "Version", valid_606360
  var valid_606361 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_606361 = validateParameter(valid_606361, JString, required = true,
                                 default = nil)
  if valid_606361 != nil:
    section.add "SourceOptionGroupIdentifier", valid_606361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606362 = header.getOrDefault("X-Amz-Signature")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Signature", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Content-Sha256", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Date")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Date", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Credential")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Credential", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Security-Token")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Security-Token", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Algorithm")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Algorithm", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-SignedHeaders", valid_606368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606369: Call_GetCopyOptionGroup_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606369.validator(path, query, header, formData, body)
  let scheme = call_606369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606369.url(scheme.get, call_606369.host, call_606369.base,
                         call_606369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606369, url, valid)

proc call*(call_606370: Call_GetCopyOptionGroup_606353;
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
  var query_606371 = newJObject()
  if Tags != nil:
    query_606371.add "Tags", Tags
  add(query_606371, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_606371, "Action", newJString(Action))
  add(query_606371, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_606371, "Version", newJString(Version))
  add(query_606371, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  result = call_606370.call(nil, query_606371, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_606353(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_606354,
    base: "/", url: url_GetCopyOptionGroup_606355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_606435 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstance_606437(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_606436(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606438 = query.getOrDefault("Action")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606438 != nil:
    section.add "Action", valid_606438
  var valid_606439 = query.getOrDefault("Version")
  valid_606439 = validateParameter(valid_606439, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606439 != nil:
    section.add "Version", valid_606439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
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
  var valid_606447 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "PreferredMaintenanceWindow", valid_606447
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_606448 = formData.getOrDefault("DBInstanceClass")
  valid_606448 = validateParameter(valid_606448, JString, required = true,
                                 default = nil)
  if valid_606448 != nil:
    section.add "DBInstanceClass", valid_606448
  var valid_606449 = formData.getOrDefault("Port")
  valid_606449 = validateParameter(valid_606449, JInt, required = false, default = nil)
  if valid_606449 != nil:
    section.add "Port", valid_606449
  var valid_606450 = formData.getOrDefault("PreferredBackupWindow")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "PreferredBackupWindow", valid_606450
  var valid_606451 = formData.getOrDefault("MasterUserPassword")
  valid_606451 = validateParameter(valid_606451, JString, required = true,
                                 default = nil)
  if valid_606451 != nil:
    section.add "MasterUserPassword", valid_606451
  var valid_606452 = formData.getOrDefault("MultiAZ")
  valid_606452 = validateParameter(valid_606452, JBool, required = false, default = nil)
  if valid_606452 != nil:
    section.add "MultiAZ", valid_606452
  var valid_606453 = formData.getOrDefault("MasterUsername")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = nil)
  if valid_606453 != nil:
    section.add "MasterUsername", valid_606453
  var valid_606454 = formData.getOrDefault("DBParameterGroupName")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "DBParameterGroupName", valid_606454
  var valid_606455 = formData.getOrDefault("EngineVersion")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "EngineVersion", valid_606455
  var valid_606456 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_606456 = validateParameter(valid_606456, JArray, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "VpcSecurityGroupIds", valid_606456
  var valid_606457 = formData.getOrDefault("AvailabilityZone")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "AvailabilityZone", valid_606457
  var valid_606458 = formData.getOrDefault("BackupRetentionPeriod")
  valid_606458 = validateParameter(valid_606458, JInt, required = false, default = nil)
  if valid_606458 != nil:
    section.add "BackupRetentionPeriod", valid_606458
  var valid_606459 = formData.getOrDefault("Engine")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = nil)
  if valid_606459 != nil:
    section.add "Engine", valid_606459
  var valid_606460 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606460 = validateParameter(valid_606460, JBool, required = false, default = nil)
  if valid_606460 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606460
  var valid_606461 = formData.getOrDefault("TdeCredentialPassword")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "TdeCredentialPassword", valid_606461
  var valid_606462 = formData.getOrDefault("DBName")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "DBName", valid_606462
  var valid_606463 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606463 = validateParameter(valid_606463, JString, required = true,
                                 default = nil)
  if valid_606463 != nil:
    section.add "DBInstanceIdentifier", valid_606463
  var valid_606464 = formData.getOrDefault("Iops")
  valid_606464 = validateParameter(valid_606464, JInt, required = false, default = nil)
  if valid_606464 != nil:
    section.add "Iops", valid_606464
  var valid_606465 = formData.getOrDefault("TdeCredentialArn")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "TdeCredentialArn", valid_606465
  var valid_606466 = formData.getOrDefault("PubliclyAccessible")
  valid_606466 = validateParameter(valid_606466, JBool, required = false, default = nil)
  if valid_606466 != nil:
    section.add "PubliclyAccessible", valid_606466
  var valid_606467 = formData.getOrDefault("LicenseModel")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "LicenseModel", valid_606467
  var valid_606468 = formData.getOrDefault("Tags")
  valid_606468 = validateParameter(valid_606468, JArray, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "Tags", valid_606468
  var valid_606469 = formData.getOrDefault("DBSubnetGroupName")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "DBSubnetGroupName", valid_606469
  var valid_606470 = formData.getOrDefault("OptionGroupName")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "OptionGroupName", valid_606470
  var valid_606471 = formData.getOrDefault("CharacterSetName")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "CharacterSetName", valid_606471
  var valid_606472 = formData.getOrDefault("DBSecurityGroups")
  valid_606472 = validateParameter(valid_606472, JArray, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "DBSecurityGroups", valid_606472
  var valid_606473 = formData.getOrDefault("StorageType")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "StorageType", valid_606473
  var valid_606474 = formData.getOrDefault("AllocatedStorage")
  valid_606474 = validateParameter(valid_606474, JInt, required = true, default = nil)
  if valid_606474 != nil:
    section.add "AllocatedStorage", valid_606474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606475: Call_PostCreateDBInstance_606435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606475.validator(path, query, header, formData, body)
  let scheme = call_606475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606475.url(scheme.get, call_606475.host, call_606475.base,
                         call_606475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606475, url, valid)

proc call*(call_606476: Call_PostCreateDBInstance_606435; DBInstanceClass: string;
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
  var query_606477 = newJObject()
  var formData_606478 = newJObject()
  add(formData_606478, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_606478, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606478, "Port", newJInt(Port))
  add(formData_606478, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_606478, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_606478, "MultiAZ", newJBool(MultiAZ))
  add(formData_606478, "MasterUsername", newJString(MasterUsername))
  add(formData_606478, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_606478, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_606478.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_606478, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606478, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_606478, "Engine", newJString(Engine))
  add(formData_606478, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606478, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_606478, "DBName", newJString(DBName))
  add(formData_606478, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606478, "Iops", newJInt(Iops))
  add(formData_606478, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_606478, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606477, "Action", newJString(Action))
  add(formData_606478, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_606478.add "Tags", Tags
  add(formData_606478, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606478, "OptionGroupName", newJString(OptionGroupName))
  add(formData_606478, "CharacterSetName", newJString(CharacterSetName))
  add(query_606477, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_606478.add "DBSecurityGroups", DBSecurityGroups
  add(formData_606478, "StorageType", newJString(StorageType))
  add(formData_606478, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_606476.call(nil, query_606477, nil, formData_606478, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_606435(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_606436, base: "/",
    url: url_PostCreateDBInstance_606437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_606392 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstance_606394(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_606393(path: JsonNode; query: JsonNode;
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
  var valid_606395 = query.getOrDefault("Version")
  valid_606395 = validateParameter(valid_606395, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606395 != nil:
    section.add "Version", valid_606395
  var valid_606396 = query.getOrDefault("DBName")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "DBName", valid_606396
  var valid_606397 = query.getOrDefault("TdeCredentialPassword")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "TdeCredentialPassword", valid_606397
  var valid_606398 = query.getOrDefault("Engine")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = nil)
  if valid_606398 != nil:
    section.add "Engine", valid_606398
  var valid_606399 = query.getOrDefault("DBParameterGroupName")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "DBParameterGroupName", valid_606399
  var valid_606400 = query.getOrDefault("CharacterSetName")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "CharacterSetName", valid_606400
  var valid_606401 = query.getOrDefault("Tags")
  valid_606401 = validateParameter(valid_606401, JArray, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "Tags", valid_606401
  var valid_606402 = query.getOrDefault("LicenseModel")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "LicenseModel", valid_606402
  var valid_606403 = query.getOrDefault("DBInstanceIdentifier")
  valid_606403 = validateParameter(valid_606403, JString, required = true,
                                 default = nil)
  if valid_606403 != nil:
    section.add "DBInstanceIdentifier", valid_606403
  var valid_606404 = query.getOrDefault("TdeCredentialArn")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "TdeCredentialArn", valid_606404
  var valid_606405 = query.getOrDefault("MasterUsername")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = nil)
  if valid_606405 != nil:
    section.add "MasterUsername", valid_606405
  var valid_606406 = query.getOrDefault("BackupRetentionPeriod")
  valid_606406 = validateParameter(valid_606406, JInt, required = false, default = nil)
  if valid_606406 != nil:
    section.add "BackupRetentionPeriod", valid_606406
  var valid_606407 = query.getOrDefault("StorageType")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "StorageType", valid_606407
  var valid_606408 = query.getOrDefault("EngineVersion")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "EngineVersion", valid_606408
  var valid_606409 = query.getOrDefault("Action")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606409 != nil:
    section.add "Action", valid_606409
  var valid_606410 = query.getOrDefault("MultiAZ")
  valid_606410 = validateParameter(valid_606410, JBool, required = false, default = nil)
  if valid_606410 != nil:
    section.add "MultiAZ", valid_606410
  var valid_606411 = query.getOrDefault("DBSecurityGroups")
  valid_606411 = validateParameter(valid_606411, JArray, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "DBSecurityGroups", valid_606411
  var valid_606412 = query.getOrDefault("Port")
  valid_606412 = validateParameter(valid_606412, JInt, required = false, default = nil)
  if valid_606412 != nil:
    section.add "Port", valid_606412
  var valid_606413 = query.getOrDefault("VpcSecurityGroupIds")
  valid_606413 = validateParameter(valid_606413, JArray, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "VpcSecurityGroupIds", valid_606413
  var valid_606414 = query.getOrDefault("MasterUserPassword")
  valid_606414 = validateParameter(valid_606414, JString, required = true,
                                 default = nil)
  if valid_606414 != nil:
    section.add "MasterUserPassword", valid_606414
  var valid_606415 = query.getOrDefault("AvailabilityZone")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "AvailabilityZone", valid_606415
  var valid_606416 = query.getOrDefault("OptionGroupName")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "OptionGroupName", valid_606416
  var valid_606417 = query.getOrDefault("DBSubnetGroupName")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "DBSubnetGroupName", valid_606417
  var valid_606418 = query.getOrDefault("AllocatedStorage")
  valid_606418 = validateParameter(valid_606418, JInt, required = true, default = nil)
  if valid_606418 != nil:
    section.add "AllocatedStorage", valid_606418
  var valid_606419 = query.getOrDefault("DBInstanceClass")
  valid_606419 = validateParameter(valid_606419, JString, required = true,
                                 default = nil)
  if valid_606419 != nil:
    section.add "DBInstanceClass", valid_606419
  var valid_606420 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "PreferredMaintenanceWindow", valid_606420
  var valid_606421 = query.getOrDefault("PreferredBackupWindow")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "PreferredBackupWindow", valid_606421
  var valid_606422 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606422 = validateParameter(valid_606422, JBool, required = false, default = nil)
  if valid_606422 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606422
  var valid_606423 = query.getOrDefault("Iops")
  valid_606423 = validateParameter(valid_606423, JInt, required = false, default = nil)
  if valid_606423 != nil:
    section.add "Iops", valid_606423
  var valid_606424 = query.getOrDefault("PubliclyAccessible")
  valid_606424 = validateParameter(valid_606424, JBool, required = false, default = nil)
  if valid_606424 != nil:
    section.add "PubliclyAccessible", valid_606424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606432: Call_GetCreateDBInstance_606392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606432.validator(path, query, header, formData, body)
  let scheme = call_606432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606432.url(scheme.get, call_606432.host, call_606432.base,
                         call_606432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606432, url, valid)

proc call*(call_606433: Call_GetCreateDBInstance_606392; Engine: string;
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
  var query_606434 = newJObject()
  add(query_606434, "Version", newJString(Version))
  add(query_606434, "DBName", newJString(DBName))
  add(query_606434, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_606434, "Engine", newJString(Engine))
  add(query_606434, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606434, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_606434.add "Tags", Tags
  add(query_606434, "LicenseModel", newJString(LicenseModel))
  add(query_606434, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606434, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_606434, "MasterUsername", newJString(MasterUsername))
  add(query_606434, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_606434, "StorageType", newJString(StorageType))
  add(query_606434, "EngineVersion", newJString(EngineVersion))
  add(query_606434, "Action", newJString(Action))
  add(query_606434, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_606434.add "DBSecurityGroups", DBSecurityGroups
  add(query_606434, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_606434.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_606434, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_606434, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606434, "OptionGroupName", newJString(OptionGroupName))
  add(query_606434, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606434, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_606434, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606434, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_606434, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_606434, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606434, "Iops", newJInt(Iops))
  add(query_606434, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_606433.call(nil, query_606434, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_606392(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_606393, base: "/",
    url: url_GetCreateDBInstance_606394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_606506 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstanceReadReplica_606508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_606507(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606509 = query.getOrDefault("Action")
  valid_606509 = validateParameter(valid_606509, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606509 != nil:
    section.add "Action", valid_606509
  var valid_606510 = query.getOrDefault("Version")
  valid_606510 = validateParameter(valid_606510, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606510 != nil:
    section.add "Version", valid_606510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606511 = header.getOrDefault("X-Amz-Signature")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Signature", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Content-Sha256", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Date")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Date", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Credential")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Credential", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Security-Token")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Security-Token", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Algorithm")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Algorithm", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-SignedHeaders", valid_606517
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
  var valid_606518 = formData.getOrDefault("Port")
  valid_606518 = validateParameter(valid_606518, JInt, required = false, default = nil)
  if valid_606518 != nil:
    section.add "Port", valid_606518
  var valid_606519 = formData.getOrDefault("DBInstanceClass")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "DBInstanceClass", valid_606519
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_606520 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = nil)
  if valid_606520 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606520
  var valid_606521 = formData.getOrDefault("AvailabilityZone")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "AvailabilityZone", valid_606521
  var valid_606522 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606522 = validateParameter(valid_606522, JBool, required = false, default = nil)
  if valid_606522 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606522
  var valid_606523 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606523 = validateParameter(valid_606523, JString, required = true,
                                 default = nil)
  if valid_606523 != nil:
    section.add "DBInstanceIdentifier", valid_606523
  var valid_606524 = formData.getOrDefault("Iops")
  valid_606524 = validateParameter(valid_606524, JInt, required = false, default = nil)
  if valid_606524 != nil:
    section.add "Iops", valid_606524
  var valid_606525 = formData.getOrDefault("PubliclyAccessible")
  valid_606525 = validateParameter(valid_606525, JBool, required = false, default = nil)
  if valid_606525 != nil:
    section.add "PubliclyAccessible", valid_606525
  var valid_606526 = formData.getOrDefault("Tags")
  valid_606526 = validateParameter(valid_606526, JArray, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "Tags", valid_606526
  var valid_606527 = formData.getOrDefault("DBSubnetGroupName")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "DBSubnetGroupName", valid_606527
  var valid_606528 = formData.getOrDefault("OptionGroupName")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "OptionGroupName", valid_606528
  var valid_606529 = formData.getOrDefault("StorageType")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "StorageType", valid_606529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606530: Call_PostCreateDBInstanceReadReplica_606506;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606530.validator(path, query, header, formData, body)
  let scheme = call_606530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606530.url(scheme.get, call_606530.host, call_606530.base,
                         call_606530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606530, url, valid)

proc call*(call_606531: Call_PostCreateDBInstanceReadReplica_606506;
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
  var query_606532 = newJObject()
  var formData_606533 = newJObject()
  add(formData_606533, "Port", newJInt(Port))
  add(formData_606533, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606533, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_606533, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606533, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606533, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606533, "Iops", newJInt(Iops))
  add(formData_606533, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606532, "Action", newJString(Action))
  if Tags != nil:
    formData_606533.add "Tags", Tags
  add(formData_606533, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606533, "OptionGroupName", newJString(OptionGroupName))
  add(query_606532, "Version", newJString(Version))
  add(formData_606533, "StorageType", newJString(StorageType))
  result = call_606531.call(nil, query_606532, nil, formData_606533, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_606506(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_606507, base: "/",
    url: url_PostCreateDBInstanceReadReplica_606508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_606479 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstanceReadReplica_606481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_606480(path: JsonNode;
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
  var valid_606482 = query.getOrDefault("Tags")
  valid_606482 = validateParameter(valid_606482, JArray, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "Tags", valid_606482
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606483 = query.getOrDefault("DBInstanceIdentifier")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = nil)
  if valid_606483 != nil:
    section.add "DBInstanceIdentifier", valid_606483
  var valid_606484 = query.getOrDefault("StorageType")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "StorageType", valid_606484
  var valid_606485 = query.getOrDefault("Action")
  valid_606485 = validateParameter(valid_606485, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606485 != nil:
    section.add "Action", valid_606485
  var valid_606486 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_606486 = validateParameter(valid_606486, JString, required = true,
                                 default = nil)
  if valid_606486 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606486
  var valid_606487 = query.getOrDefault("Port")
  valid_606487 = validateParameter(valid_606487, JInt, required = false, default = nil)
  if valid_606487 != nil:
    section.add "Port", valid_606487
  var valid_606488 = query.getOrDefault("AvailabilityZone")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "AvailabilityZone", valid_606488
  var valid_606489 = query.getOrDefault("OptionGroupName")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "OptionGroupName", valid_606489
  var valid_606490 = query.getOrDefault("DBSubnetGroupName")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "DBSubnetGroupName", valid_606490
  var valid_606491 = query.getOrDefault("Version")
  valid_606491 = validateParameter(valid_606491, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606491 != nil:
    section.add "Version", valid_606491
  var valid_606492 = query.getOrDefault("DBInstanceClass")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "DBInstanceClass", valid_606492
  var valid_606493 = query.getOrDefault("PubliclyAccessible")
  valid_606493 = validateParameter(valid_606493, JBool, required = false, default = nil)
  if valid_606493 != nil:
    section.add "PubliclyAccessible", valid_606493
  var valid_606494 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606494 = validateParameter(valid_606494, JBool, required = false, default = nil)
  if valid_606494 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606494
  var valid_606495 = query.getOrDefault("Iops")
  valid_606495 = validateParameter(valid_606495, JInt, required = false, default = nil)
  if valid_606495 != nil:
    section.add "Iops", valid_606495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606496 = header.getOrDefault("X-Amz-Signature")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Signature", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Content-Sha256", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Date")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Date", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Credential")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Credential", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Security-Token")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Security-Token", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Algorithm")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Algorithm", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-SignedHeaders", valid_606502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606503: Call_GetCreateDBInstanceReadReplica_606479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606503.validator(path, query, header, formData, body)
  let scheme = call_606503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606503.url(scheme.get, call_606503.host, call_606503.base,
                         call_606503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606503, url, valid)

proc call*(call_606504: Call_GetCreateDBInstanceReadReplica_606479;
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
  var query_606505 = newJObject()
  if Tags != nil:
    query_606505.add "Tags", Tags
  add(query_606505, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606505, "StorageType", newJString(StorageType))
  add(query_606505, "Action", newJString(Action))
  add(query_606505, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_606505, "Port", newJInt(Port))
  add(query_606505, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606505, "OptionGroupName", newJString(OptionGroupName))
  add(query_606505, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606505, "Version", newJString(Version))
  add(query_606505, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606505, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606505, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606505, "Iops", newJInt(Iops))
  result = call_606504.call(nil, query_606505, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_606479(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_606480, base: "/",
    url: url_GetCreateDBInstanceReadReplica_606481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_606553 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBParameterGroup_606555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_606554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606556 = query.getOrDefault("Action")
  valid_606556 = validateParameter(valid_606556, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606556 != nil:
    section.add "Action", valid_606556
  var valid_606557 = query.getOrDefault("Version")
  valid_606557 = validateParameter(valid_606557, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606557 != nil:
    section.add "Version", valid_606557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606558 = header.getOrDefault("X-Amz-Signature")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Signature", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Content-Sha256", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Date")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Date", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Credential")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Credential", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Security-Token")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Security-Token", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Algorithm")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Algorithm", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-SignedHeaders", valid_606564
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_606565 = formData.getOrDefault("Description")
  valid_606565 = validateParameter(valid_606565, JString, required = true,
                                 default = nil)
  if valid_606565 != nil:
    section.add "Description", valid_606565
  var valid_606566 = formData.getOrDefault("DBParameterGroupName")
  valid_606566 = validateParameter(valid_606566, JString, required = true,
                                 default = nil)
  if valid_606566 != nil:
    section.add "DBParameterGroupName", valid_606566
  var valid_606567 = formData.getOrDefault("Tags")
  valid_606567 = validateParameter(valid_606567, JArray, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "Tags", valid_606567
  var valid_606568 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606568 = validateParameter(valid_606568, JString, required = true,
                                 default = nil)
  if valid_606568 != nil:
    section.add "DBParameterGroupFamily", valid_606568
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_PostCreateDBParameterGroup_606553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_PostCreateDBParameterGroup_606553;
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
  var query_606571 = newJObject()
  var formData_606572 = newJObject()
  add(formData_606572, "Description", newJString(Description))
  add(formData_606572, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606571, "Action", newJString(Action))
  if Tags != nil:
    formData_606572.add "Tags", Tags
  add(query_606571, "Version", newJString(Version))
  add(formData_606572, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606570.call(nil, query_606571, nil, formData_606572, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_606553(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_606554, base: "/",
    url: url_PostCreateDBParameterGroup_606555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_606534 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBParameterGroup_606536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_606535(path: JsonNode; query: JsonNode;
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
  var valid_606537 = query.getOrDefault("DBParameterGroupFamily")
  valid_606537 = validateParameter(valid_606537, JString, required = true,
                                 default = nil)
  if valid_606537 != nil:
    section.add "DBParameterGroupFamily", valid_606537
  var valid_606538 = query.getOrDefault("DBParameterGroupName")
  valid_606538 = validateParameter(valid_606538, JString, required = true,
                                 default = nil)
  if valid_606538 != nil:
    section.add "DBParameterGroupName", valid_606538
  var valid_606539 = query.getOrDefault("Tags")
  valid_606539 = validateParameter(valid_606539, JArray, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "Tags", valid_606539
  var valid_606540 = query.getOrDefault("Action")
  valid_606540 = validateParameter(valid_606540, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606540 != nil:
    section.add "Action", valid_606540
  var valid_606541 = query.getOrDefault("Description")
  valid_606541 = validateParameter(valid_606541, JString, required = true,
                                 default = nil)
  if valid_606541 != nil:
    section.add "Description", valid_606541
  var valid_606542 = query.getOrDefault("Version")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606542 != nil:
    section.add "Version", valid_606542
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606543 = header.getOrDefault("X-Amz-Signature")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Signature", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Content-Sha256", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Date")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Date", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Credential")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Credential", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Security-Token")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Security-Token", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Algorithm")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Algorithm", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-SignedHeaders", valid_606549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606550: Call_GetCreateDBParameterGroup_606534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606550.validator(path, query, header, formData, body)
  let scheme = call_606550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606550.url(scheme.get, call_606550.host, call_606550.base,
                         call_606550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606550, url, valid)

proc call*(call_606551: Call_GetCreateDBParameterGroup_606534;
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
  var query_606552 = newJObject()
  add(query_606552, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606552, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_606552.add "Tags", Tags
  add(query_606552, "Action", newJString(Action))
  add(query_606552, "Description", newJString(Description))
  add(query_606552, "Version", newJString(Version))
  result = call_606551.call(nil, query_606552, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_606534(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_606535, base: "/",
    url: url_GetCreateDBParameterGroup_606536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_606591 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSecurityGroup_606593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_606592(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606594 = query.getOrDefault("Action")
  valid_606594 = validateParameter(valid_606594, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606594 != nil:
    section.add "Action", valid_606594
  var valid_606595 = query.getOrDefault("Version")
  valid_606595 = validateParameter(valid_606595, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606595 != nil:
    section.add "Version", valid_606595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606596 = header.getOrDefault("X-Amz-Signature")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Signature", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Content-Sha256", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Date")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Date", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Credential")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Credential", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Security-Token")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Security-Token", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Algorithm")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Algorithm", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-SignedHeaders", valid_606602
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_606603 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_606603 = validateParameter(valid_606603, JString, required = true,
                                 default = nil)
  if valid_606603 != nil:
    section.add "DBSecurityGroupDescription", valid_606603
  var valid_606604 = formData.getOrDefault("DBSecurityGroupName")
  valid_606604 = validateParameter(valid_606604, JString, required = true,
                                 default = nil)
  if valid_606604 != nil:
    section.add "DBSecurityGroupName", valid_606604
  var valid_606605 = formData.getOrDefault("Tags")
  valid_606605 = validateParameter(valid_606605, JArray, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "Tags", valid_606605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606606: Call_PostCreateDBSecurityGroup_606591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606606.validator(path, query, header, formData, body)
  let scheme = call_606606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606606.url(scheme.get, call_606606.host, call_606606.base,
                         call_606606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606606, url, valid)

proc call*(call_606607: Call_PostCreateDBSecurityGroup_606591;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_606608 = newJObject()
  var formData_606609 = newJObject()
  add(formData_606609, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_606609, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606608, "Action", newJString(Action))
  if Tags != nil:
    formData_606609.add "Tags", Tags
  add(query_606608, "Version", newJString(Version))
  result = call_606607.call(nil, query_606608, nil, formData_606609, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_606591(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_606592, base: "/",
    url: url_PostCreateDBSecurityGroup_606593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_606573 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSecurityGroup_606575(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_606574(path: JsonNode; query: JsonNode;
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
  var valid_606576 = query.getOrDefault("DBSecurityGroupName")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "DBSecurityGroupName", valid_606576
  var valid_606577 = query.getOrDefault("Tags")
  valid_606577 = validateParameter(valid_606577, JArray, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "Tags", valid_606577
  var valid_606578 = query.getOrDefault("DBSecurityGroupDescription")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = nil)
  if valid_606578 != nil:
    section.add "DBSecurityGroupDescription", valid_606578
  var valid_606579 = query.getOrDefault("Action")
  valid_606579 = validateParameter(valid_606579, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606579 != nil:
    section.add "Action", valid_606579
  var valid_606580 = query.getOrDefault("Version")
  valid_606580 = validateParameter(valid_606580, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606580 != nil:
    section.add "Version", valid_606580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606588: Call_GetCreateDBSecurityGroup_606573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606588.validator(path, query, header, formData, body)
  let scheme = call_606588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606588.url(scheme.get, call_606588.host, call_606588.base,
                         call_606588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606588, url, valid)

proc call*(call_606589: Call_GetCreateDBSecurityGroup_606573;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606590 = newJObject()
  add(query_606590, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_606590.add "Tags", Tags
  add(query_606590, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_606590, "Action", newJString(Action))
  add(query_606590, "Version", newJString(Version))
  result = call_606589.call(nil, query_606590, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_606573(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_606574, base: "/",
    url: url_GetCreateDBSecurityGroup_606575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_606628 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSnapshot_606630(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_606629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606631 = query.getOrDefault("Action")
  valid_606631 = validateParameter(valid_606631, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606631 != nil:
    section.add "Action", valid_606631
  var valid_606632 = query.getOrDefault("Version")
  valid_606632 = validateParameter(valid_606632, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606632 != nil:
    section.add "Version", valid_606632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606633 = header.getOrDefault("X-Amz-Signature")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Signature", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Content-Sha256", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Date")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Date", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Credential")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Credential", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Security-Token")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Security-Token", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Algorithm")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Algorithm", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-SignedHeaders", valid_606639
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606640 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606640 = validateParameter(valid_606640, JString, required = true,
                                 default = nil)
  if valid_606640 != nil:
    section.add "DBInstanceIdentifier", valid_606640
  var valid_606641 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606641 = validateParameter(valid_606641, JString, required = true,
                                 default = nil)
  if valid_606641 != nil:
    section.add "DBSnapshotIdentifier", valid_606641
  var valid_606642 = formData.getOrDefault("Tags")
  valid_606642 = validateParameter(valid_606642, JArray, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "Tags", valid_606642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_PostCreateDBSnapshot_606628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_PostCreateDBSnapshot_606628;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_606645 = newJObject()
  var formData_606646 = newJObject()
  add(formData_606646, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606646, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606645, "Action", newJString(Action))
  if Tags != nil:
    formData_606646.add "Tags", Tags
  add(query_606645, "Version", newJString(Version))
  result = call_606644.call(nil, query_606645, nil, formData_606646, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_606628(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_606629, base: "/",
    url: url_PostCreateDBSnapshot_606630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_606610 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSnapshot_606612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_606611(path: JsonNode; query: JsonNode;
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
  var valid_606613 = query.getOrDefault("Tags")
  valid_606613 = validateParameter(valid_606613, JArray, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "Tags", valid_606613
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606614 = query.getOrDefault("DBInstanceIdentifier")
  valid_606614 = validateParameter(valid_606614, JString, required = true,
                                 default = nil)
  if valid_606614 != nil:
    section.add "DBInstanceIdentifier", valid_606614
  var valid_606615 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606615 = validateParameter(valid_606615, JString, required = true,
                                 default = nil)
  if valid_606615 != nil:
    section.add "DBSnapshotIdentifier", valid_606615
  var valid_606616 = query.getOrDefault("Action")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606616 != nil:
    section.add "Action", valid_606616
  var valid_606617 = query.getOrDefault("Version")
  valid_606617 = validateParameter(valid_606617, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606617 != nil:
    section.add "Version", valid_606617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606618 = header.getOrDefault("X-Amz-Signature")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Signature", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Content-Sha256", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Date")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Date", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Credential")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Credential", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Security-Token")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Security-Token", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Algorithm")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Algorithm", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-SignedHeaders", valid_606624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_GetCreateDBSnapshot_606610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_GetCreateDBSnapshot_606610;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606627 = newJObject()
  if Tags != nil:
    query_606627.add "Tags", Tags
  add(query_606627, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606627, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606627, "Action", newJString(Action))
  add(query_606627, "Version", newJString(Version))
  result = call_606626.call(nil, query_606627, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_606610(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_606611, base: "/",
    url: url_GetCreateDBSnapshot_606612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_606666 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSubnetGroup_606668(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_606667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606669 = query.getOrDefault("Action")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606669 != nil:
    section.add "Action", valid_606669
  var valid_606670 = query.getOrDefault("Version")
  valid_606670 = validateParameter(valid_606670, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606670 != nil:
    section.add "Version", valid_606670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606671 = header.getOrDefault("X-Amz-Signature")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Signature", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Content-Sha256", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Date")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Date", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Credential")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Credential", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Security-Token")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Security-Token", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_606678 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_606678 = validateParameter(valid_606678, JString, required = true,
                                 default = nil)
  if valid_606678 != nil:
    section.add "DBSubnetGroupDescription", valid_606678
  var valid_606679 = formData.getOrDefault("Tags")
  valid_606679 = validateParameter(valid_606679, JArray, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "Tags", valid_606679
  var valid_606680 = formData.getOrDefault("DBSubnetGroupName")
  valid_606680 = validateParameter(valid_606680, JString, required = true,
                                 default = nil)
  if valid_606680 != nil:
    section.add "DBSubnetGroupName", valid_606680
  var valid_606681 = formData.getOrDefault("SubnetIds")
  valid_606681 = validateParameter(valid_606681, JArray, required = true, default = nil)
  if valid_606681 != nil:
    section.add "SubnetIds", valid_606681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606682: Call_PostCreateDBSubnetGroup_606666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606682.validator(path, query, header, formData, body)
  let scheme = call_606682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606682.url(scheme.get, call_606682.host, call_606682.base,
                         call_606682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606682, url, valid)

proc call*(call_606683: Call_PostCreateDBSubnetGroup_606666;
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
  var query_606684 = newJObject()
  var formData_606685 = newJObject()
  add(formData_606685, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606684, "Action", newJString(Action))
  if Tags != nil:
    formData_606685.add "Tags", Tags
  add(formData_606685, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606684, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_606685.add "SubnetIds", SubnetIds
  result = call_606683.call(nil, query_606684, nil, formData_606685, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_606666(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_606667, base: "/",
    url: url_PostCreateDBSubnetGroup_606668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_606647 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSubnetGroup_606649(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_606648(path: JsonNode; query: JsonNode;
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
  var valid_606650 = query.getOrDefault("Tags")
  valid_606650 = validateParameter(valid_606650, JArray, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "Tags", valid_606650
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_606651 = query.getOrDefault("SubnetIds")
  valid_606651 = validateParameter(valid_606651, JArray, required = true, default = nil)
  if valid_606651 != nil:
    section.add "SubnetIds", valid_606651
  var valid_606652 = query.getOrDefault("Action")
  valid_606652 = validateParameter(valid_606652, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606652 != nil:
    section.add "Action", valid_606652
  var valid_606653 = query.getOrDefault("DBSubnetGroupDescription")
  valid_606653 = validateParameter(valid_606653, JString, required = true,
                                 default = nil)
  if valid_606653 != nil:
    section.add "DBSubnetGroupDescription", valid_606653
  var valid_606654 = query.getOrDefault("DBSubnetGroupName")
  valid_606654 = validateParameter(valid_606654, JString, required = true,
                                 default = nil)
  if valid_606654 != nil:
    section.add "DBSubnetGroupName", valid_606654
  var valid_606655 = query.getOrDefault("Version")
  valid_606655 = validateParameter(valid_606655, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606655 != nil:
    section.add "Version", valid_606655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606656 = header.getOrDefault("X-Amz-Signature")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Signature", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Content-Sha256", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Date")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Date", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Credential")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Credential", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Security-Token")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Security-Token", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Algorithm")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Algorithm", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-SignedHeaders", valid_606662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606663: Call_GetCreateDBSubnetGroup_606647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606663.validator(path, query, header, formData, body)
  let scheme = call_606663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606663.url(scheme.get, call_606663.host, call_606663.base,
                         call_606663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606663, url, valid)

proc call*(call_606664: Call_GetCreateDBSubnetGroup_606647; SubnetIds: JsonNode;
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
  var query_606665 = newJObject()
  if Tags != nil:
    query_606665.add "Tags", Tags
  if SubnetIds != nil:
    query_606665.add "SubnetIds", SubnetIds
  add(query_606665, "Action", newJString(Action))
  add(query_606665, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606665, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606665, "Version", newJString(Version))
  result = call_606664.call(nil, query_606665, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_606647(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_606648, base: "/",
    url: url_GetCreateDBSubnetGroup_606649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_606708 = ref object of OpenApiRestCall_605573
proc url_PostCreateEventSubscription_606710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_606709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606711 = query.getOrDefault("Action")
  valid_606711 = validateParameter(valid_606711, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606711 != nil:
    section.add "Action", valid_606711
  var valid_606712 = query.getOrDefault("Version")
  valid_606712 = validateParameter(valid_606712, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606712 != nil:
    section.add "Version", valid_606712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606713 = header.getOrDefault("X-Amz-Signature")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Signature", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Content-Sha256", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Date")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Date", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Credential")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Credential", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Security-Token")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Security-Token", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Algorithm")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Algorithm", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-SignedHeaders", valid_606719
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
  var valid_606720 = formData.getOrDefault("SourceIds")
  valid_606720 = validateParameter(valid_606720, JArray, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "SourceIds", valid_606720
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_606721 = formData.getOrDefault("SnsTopicArn")
  valid_606721 = validateParameter(valid_606721, JString, required = true,
                                 default = nil)
  if valid_606721 != nil:
    section.add "SnsTopicArn", valid_606721
  var valid_606722 = formData.getOrDefault("Enabled")
  valid_606722 = validateParameter(valid_606722, JBool, required = false, default = nil)
  if valid_606722 != nil:
    section.add "Enabled", valid_606722
  var valid_606723 = formData.getOrDefault("SubscriptionName")
  valid_606723 = validateParameter(valid_606723, JString, required = true,
                                 default = nil)
  if valid_606723 != nil:
    section.add "SubscriptionName", valid_606723
  var valid_606724 = formData.getOrDefault("SourceType")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "SourceType", valid_606724
  var valid_606725 = formData.getOrDefault("EventCategories")
  valid_606725 = validateParameter(valid_606725, JArray, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "EventCategories", valid_606725
  var valid_606726 = formData.getOrDefault("Tags")
  valid_606726 = validateParameter(valid_606726, JArray, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "Tags", valid_606726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606727: Call_PostCreateEventSubscription_606708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606727.validator(path, query, header, formData, body)
  let scheme = call_606727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606727.url(scheme.get, call_606727.host, call_606727.base,
                         call_606727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606727, url, valid)

proc call*(call_606728: Call_PostCreateEventSubscription_606708;
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
  var query_606729 = newJObject()
  var formData_606730 = newJObject()
  if SourceIds != nil:
    formData_606730.add "SourceIds", SourceIds
  add(formData_606730, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_606730, "Enabled", newJBool(Enabled))
  add(formData_606730, "SubscriptionName", newJString(SubscriptionName))
  add(formData_606730, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_606730.add "EventCategories", EventCategories
  add(query_606729, "Action", newJString(Action))
  if Tags != nil:
    formData_606730.add "Tags", Tags
  add(query_606729, "Version", newJString(Version))
  result = call_606728.call(nil, query_606729, nil, formData_606730, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_606708(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_606709, base: "/",
    url: url_PostCreateEventSubscription_606710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_606686 = ref object of OpenApiRestCall_605573
proc url_GetCreateEventSubscription_606688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_606687(path: JsonNode; query: JsonNode;
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
  var valid_606689 = query.getOrDefault("Tags")
  valid_606689 = validateParameter(valid_606689, JArray, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "Tags", valid_606689
  var valid_606690 = query.getOrDefault("SourceType")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "SourceType", valid_606690
  var valid_606691 = query.getOrDefault("Enabled")
  valid_606691 = validateParameter(valid_606691, JBool, required = false, default = nil)
  if valid_606691 != nil:
    section.add "Enabled", valid_606691
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_606692 = query.getOrDefault("SubscriptionName")
  valid_606692 = validateParameter(valid_606692, JString, required = true,
                                 default = nil)
  if valid_606692 != nil:
    section.add "SubscriptionName", valid_606692
  var valid_606693 = query.getOrDefault("EventCategories")
  valid_606693 = validateParameter(valid_606693, JArray, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "EventCategories", valid_606693
  var valid_606694 = query.getOrDefault("SourceIds")
  valid_606694 = validateParameter(valid_606694, JArray, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "SourceIds", valid_606694
  var valid_606695 = query.getOrDefault("Action")
  valid_606695 = validateParameter(valid_606695, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606695 != nil:
    section.add "Action", valid_606695
  var valid_606696 = query.getOrDefault("SnsTopicArn")
  valid_606696 = validateParameter(valid_606696, JString, required = true,
                                 default = nil)
  if valid_606696 != nil:
    section.add "SnsTopicArn", valid_606696
  var valid_606697 = query.getOrDefault("Version")
  valid_606697 = validateParameter(valid_606697, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606697 != nil:
    section.add "Version", valid_606697
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606698 = header.getOrDefault("X-Amz-Signature")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Signature", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Content-Sha256", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Date")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Date", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Credential")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Credential", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Security-Token")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Security-Token", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Algorithm")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Algorithm", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-SignedHeaders", valid_606704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606705: Call_GetCreateEventSubscription_606686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606705.validator(path, query, header, formData, body)
  let scheme = call_606705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606705.url(scheme.get, call_606705.host, call_606705.base,
                         call_606705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606705, url, valid)

proc call*(call_606706: Call_GetCreateEventSubscription_606686;
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
  var query_606707 = newJObject()
  if Tags != nil:
    query_606707.add "Tags", Tags
  add(query_606707, "SourceType", newJString(SourceType))
  add(query_606707, "Enabled", newJBool(Enabled))
  add(query_606707, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_606707.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_606707.add "SourceIds", SourceIds
  add(query_606707, "Action", newJString(Action))
  add(query_606707, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_606707, "Version", newJString(Version))
  result = call_606706.call(nil, query_606707, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_606686(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_606687, base: "/",
    url: url_GetCreateEventSubscription_606688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_606751 = ref object of OpenApiRestCall_605573
proc url_PostCreateOptionGroup_606753(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_606752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606754 = query.getOrDefault("Action")
  valid_606754 = validateParameter(valid_606754, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606754 != nil:
    section.add "Action", valid_606754
  var valid_606755 = query.getOrDefault("Version")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606755 != nil:
    section.add "Version", valid_606755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606756 = header.getOrDefault("X-Amz-Signature")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Signature", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Content-Sha256", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Date")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Date", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Credential")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Credential", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Security-Token")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Security-Token", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Algorithm")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Algorithm", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-SignedHeaders", valid_606762
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_606763 = formData.getOrDefault("OptionGroupDescription")
  valid_606763 = validateParameter(valid_606763, JString, required = true,
                                 default = nil)
  if valid_606763 != nil:
    section.add "OptionGroupDescription", valid_606763
  var valid_606764 = formData.getOrDefault("EngineName")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "EngineName", valid_606764
  var valid_606765 = formData.getOrDefault("MajorEngineVersion")
  valid_606765 = validateParameter(valid_606765, JString, required = true,
                                 default = nil)
  if valid_606765 != nil:
    section.add "MajorEngineVersion", valid_606765
  var valid_606766 = formData.getOrDefault("Tags")
  valid_606766 = validateParameter(valid_606766, JArray, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "Tags", valid_606766
  var valid_606767 = formData.getOrDefault("OptionGroupName")
  valid_606767 = validateParameter(valid_606767, JString, required = true,
                                 default = nil)
  if valid_606767 != nil:
    section.add "OptionGroupName", valid_606767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606768: Call_PostCreateOptionGroup_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606768.validator(path, query, header, formData, body)
  let scheme = call_606768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606768.url(scheme.get, call_606768.host, call_606768.base,
                         call_606768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606768, url, valid)

proc call*(call_606769: Call_PostCreateOptionGroup_606751;
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
  var query_606770 = newJObject()
  var formData_606771 = newJObject()
  add(formData_606771, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_606771, "EngineName", newJString(EngineName))
  add(formData_606771, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_606770, "Action", newJString(Action))
  if Tags != nil:
    formData_606771.add "Tags", Tags
  add(formData_606771, "OptionGroupName", newJString(OptionGroupName))
  add(query_606770, "Version", newJString(Version))
  result = call_606769.call(nil, query_606770, nil, formData_606771, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_606751(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_606752, base: "/",
    url: url_PostCreateOptionGroup_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_606731 = ref object of OpenApiRestCall_605573
proc url_GetCreateOptionGroup_606733(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_606732(path: JsonNode; query: JsonNode;
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
  var valid_606734 = query.getOrDefault("EngineName")
  valid_606734 = validateParameter(valid_606734, JString, required = true,
                                 default = nil)
  if valid_606734 != nil:
    section.add "EngineName", valid_606734
  var valid_606735 = query.getOrDefault("OptionGroupDescription")
  valid_606735 = validateParameter(valid_606735, JString, required = true,
                                 default = nil)
  if valid_606735 != nil:
    section.add "OptionGroupDescription", valid_606735
  var valid_606736 = query.getOrDefault("Tags")
  valid_606736 = validateParameter(valid_606736, JArray, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "Tags", valid_606736
  var valid_606737 = query.getOrDefault("Action")
  valid_606737 = validateParameter(valid_606737, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606737 != nil:
    section.add "Action", valid_606737
  var valid_606738 = query.getOrDefault("OptionGroupName")
  valid_606738 = validateParameter(valid_606738, JString, required = true,
                                 default = nil)
  if valid_606738 != nil:
    section.add "OptionGroupName", valid_606738
  var valid_606739 = query.getOrDefault("Version")
  valid_606739 = validateParameter(valid_606739, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606739 != nil:
    section.add "Version", valid_606739
  var valid_606740 = query.getOrDefault("MajorEngineVersion")
  valid_606740 = validateParameter(valid_606740, JString, required = true,
                                 default = nil)
  if valid_606740 != nil:
    section.add "MajorEngineVersion", valid_606740
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606741 = header.getOrDefault("X-Amz-Signature")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Signature", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Content-Sha256", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Date")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Date", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Credential")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Credential", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Security-Token")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Security-Token", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Algorithm")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Algorithm", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-SignedHeaders", valid_606747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_GetCreateOptionGroup_606731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_GetCreateOptionGroup_606731; EngineName: string;
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
  var query_606750 = newJObject()
  add(query_606750, "EngineName", newJString(EngineName))
  add(query_606750, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_606750.add "Tags", Tags
  add(query_606750, "Action", newJString(Action))
  add(query_606750, "OptionGroupName", newJString(OptionGroupName))
  add(query_606750, "Version", newJString(Version))
  add(query_606750, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_606749.call(nil, query_606750, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_606731(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_606732, base: "/",
    url: url_GetCreateOptionGroup_606733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_606790 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBInstance_606792(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_606791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606793 = query.getOrDefault("Action")
  valid_606793 = validateParameter(valid_606793, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606793 != nil:
    section.add "Action", valid_606793
  var valid_606794 = query.getOrDefault("Version")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606794 != nil:
    section.add "Version", valid_606794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606795 = header.getOrDefault("X-Amz-Signature")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Signature", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Content-Sha256", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Date")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Date", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Credential")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Credential", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Security-Token")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Security-Token", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Algorithm")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Algorithm", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-SignedHeaders", valid_606801
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606802 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606802 = validateParameter(valid_606802, JString, required = true,
                                 default = nil)
  if valid_606802 != nil:
    section.add "DBInstanceIdentifier", valid_606802
  var valid_606803 = formData.getOrDefault("SkipFinalSnapshot")
  valid_606803 = validateParameter(valid_606803, JBool, required = false, default = nil)
  if valid_606803 != nil:
    section.add "SkipFinalSnapshot", valid_606803
  var valid_606804 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606805: Call_PostDeleteDBInstance_606790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606805.validator(path, query, header, formData, body)
  let scheme = call_606805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606805.url(scheme.get, call_606805.host, call_606805.base,
                         call_606805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606805, url, valid)

proc call*(call_606806: Call_PostDeleteDBInstance_606790;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_606807 = newJObject()
  var formData_606808 = newJObject()
  add(formData_606808, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606807, "Action", newJString(Action))
  add(formData_606808, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_606808, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_606807, "Version", newJString(Version))
  result = call_606806.call(nil, query_606807, nil, formData_606808, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_606790(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_606791, base: "/",
    url: url_PostDeleteDBInstance_606792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_606772 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBInstance_606774(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_606773(path: JsonNode; query: JsonNode;
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
  var valid_606775 = query.getOrDefault("DBInstanceIdentifier")
  valid_606775 = validateParameter(valid_606775, JString, required = true,
                                 default = nil)
  if valid_606775 != nil:
    section.add "DBInstanceIdentifier", valid_606775
  var valid_606776 = query.getOrDefault("SkipFinalSnapshot")
  valid_606776 = validateParameter(valid_606776, JBool, required = false, default = nil)
  if valid_606776 != nil:
    section.add "SkipFinalSnapshot", valid_606776
  var valid_606777 = query.getOrDefault("Action")
  valid_606777 = validateParameter(valid_606777, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606777 != nil:
    section.add "Action", valid_606777
  var valid_606778 = query.getOrDefault("Version")
  valid_606778 = validateParameter(valid_606778, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606778 != nil:
    section.add "Version", valid_606778
  var valid_606779 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606780 = header.getOrDefault("X-Amz-Signature")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Signature", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Content-Sha256", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Date")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Date", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Credential")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Credential", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Security-Token")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Security-Token", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Algorithm")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Algorithm", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-SignedHeaders", valid_606786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606787: Call_GetDeleteDBInstance_606772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606787.validator(path, query, header, formData, body)
  let scheme = call_606787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606787.url(scheme.get, call_606787.host, call_606787.base,
                         call_606787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606787, url, valid)

proc call*(call_606788: Call_GetDeleteDBInstance_606772;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_606789 = newJObject()
  add(query_606789, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606789, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_606789, "Action", newJString(Action))
  add(query_606789, "Version", newJString(Version))
  add(query_606789, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_606788.call(nil, query_606789, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_606772(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_606773, base: "/",
    url: url_GetDeleteDBInstance_606774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_606825 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBParameterGroup_606827(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_606826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606828 = query.getOrDefault("Action")
  valid_606828 = validateParameter(valid_606828, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606828 != nil:
    section.add "Action", valid_606828
  var valid_606829 = query.getOrDefault("Version")
  valid_606829 = validateParameter(valid_606829, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606829 != nil:
    section.add "Version", valid_606829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_606837 = formData.getOrDefault("DBParameterGroupName")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = nil)
  if valid_606837 != nil:
    section.add "DBParameterGroupName", valid_606837
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606838: Call_PostDeleteDBParameterGroup_606825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606838.validator(path, query, header, formData, body)
  let scheme = call_606838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606838.url(scheme.get, call_606838.host, call_606838.base,
                         call_606838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606838, url, valid)

proc call*(call_606839: Call_PostDeleteDBParameterGroup_606825;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606840 = newJObject()
  var formData_606841 = newJObject()
  add(formData_606841, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606840, "Action", newJString(Action))
  add(query_606840, "Version", newJString(Version))
  result = call_606839.call(nil, query_606840, nil, formData_606841, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_606825(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_606826, base: "/",
    url: url_PostDeleteDBParameterGroup_606827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_606809 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBParameterGroup_606811(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_606810(path: JsonNode; query: JsonNode;
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
  var valid_606812 = query.getOrDefault("DBParameterGroupName")
  valid_606812 = validateParameter(valid_606812, JString, required = true,
                                 default = nil)
  if valid_606812 != nil:
    section.add "DBParameterGroupName", valid_606812
  var valid_606813 = query.getOrDefault("Action")
  valid_606813 = validateParameter(valid_606813, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606813 != nil:
    section.add "Action", valid_606813
  var valid_606814 = query.getOrDefault("Version")
  valid_606814 = validateParameter(valid_606814, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606814 != nil:
    section.add "Version", valid_606814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606815 = header.getOrDefault("X-Amz-Signature")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Signature", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Content-Sha256", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Date")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Date", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Credential")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Credential", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Security-Token")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Security-Token", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Algorithm")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Algorithm", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-SignedHeaders", valid_606821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606822: Call_GetDeleteDBParameterGroup_606809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606822.validator(path, query, header, formData, body)
  let scheme = call_606822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606822.url(scheme.get, call_606822.host, call_606822.base,
                         call_606822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606822, url, valid)

proc call*(call_606823: Call_GetDeleteDBParameterGroup_606809;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606824 = newJObject()
  add(query_606824, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606824, "Action", newJString(Action))
  add(query_606824, "Version", newJString(Version))
  result = call_606823.call(nil, query_606824, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_606809(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_606810, base: "/",
    url: url_GetDeleteDBParameterGroup_606811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_606858 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSecurityGroup_606860(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_606859(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606861 = query.getOrDefault("Action")
  valid_606861 = validateParameter(valid_606861, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606861 != nil:
    section.add "Action", valid_606861
  var valid_606862 = query.getOrDefault("Version")
  valid_606862 = validateParameter(valid_606862, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606862 != nil:
    section.add "Version", valid_606862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606863 = header.getOrDefault("X-Amz-Signature")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Signature", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Content-Sha256", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Date")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Date", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-Credential")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Credential", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Security-Token")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Security-Token", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Algorithm")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Algorithm", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-SignedHeaders", valid_606869
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606870 = formData.getOrDefault("DBSecurityGroupName")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = nil)
  if valid_606870 != nil:
    section.add "DBSecurityGroupName", valid_606870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606871: Call_PostDeleteDBSecurityGroup_606858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606871.validator(path, query, header, formData, body)
  let scheme = call_606871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606871.url(scheme.get, call_606871.host, call_606871.base,
                         call_606871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606871, url, valid)

proc call*(call_606872: Call_PostDeleteDBSecurityGroup_606858;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606873 = newJObject()
  var formData_606874 = newJObject()
  add(formData_606874, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606873, "Action", newJString(Action))
  add(query_606873, "Version", newJString(Version))
  result = call_606872.call(nil, query_606873, nil, formData_606874, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_606858(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_606859, base: "/",
    url: url_PostDeleteDBSecurityGroup_606860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_606842 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSecurityGroup_606844(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_606843(path: JsonNode; query: JsonNode;
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
  var valid_606845 = query.getOrDefault("DBSecurityGroupName")
  valid_606845 = validateParameter(valid_606845, JString, required = true,
                                 default = nil)
  if valid_606845 != nil:
    section.add "DBSecurityGroupName", valid_606845
  var valid_606846 = query.getOrDefault("Action")
  valid_606846 = validateParameter(valid_606846, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606846 != nil:
    section.add "Action", valid_606846
  var valid_606847 = query.getOrDefault("Version")
  valid_606847 = validateParameter(valid_606847, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606847 != nil:
    section.add "Version", valid_606847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606848 = header.getOrDefault("X-Amz-Signature")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Signature", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Content-Sha256", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Date")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Date", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-Credential")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Credential", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Security-Token")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Security-Token", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Algorithm")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Algorithm", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-SignedHeaders", valid_606854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606855: Call_GetDeleteDBSecurityGroup_606842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606855.validator(path, query, header, formData, body)
  let scheme = call_606855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606855.url(scheme.get, call_606855.host, call_606855.base,
                         call_606855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606855, url, valid)

proc call*(call_606856: Call_GetDeleteDBSecurityGroup_606842;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606857 = newJObject()
  add(query_606857, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606857, "Action", newJString(Action))
  add(query_606857, "Version", newJString(Version))
  result = call_606856.call(nil, query_606857, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_606842(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_606843, base: "/",
    url: url_GetDeleteDBSecurityGroup_606844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_606891 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSnapshot_606893(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_606892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606894 = query.getOrDefault("Action")
  valid_606894 = validateParameter(valid_606894, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606894 != nil:
    section.add "Action", valid_606894
  var valid_606895 = query.getOrDefault("Version")
  valid_606895 = validateParameter(valid_606895, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606895 != nil:
    section.add "Version", valid_606895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606896 = header.getOrDefault("X-Amz-Signature")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Signature", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Content-Sha256", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Date")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Date", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Credential")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Credential", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Security-Token")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Security-Token", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Algorithm")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Algorithm", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-SignedHeaders", valid_606902
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_606903 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "DBSnapshotIdentifier", valid_606903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606904: Call_PostDeleteDBSnapshot_606891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606904.validator(path, query, header, formData, body)
  let scheme = call_606904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606904.url(scheme.get, call_606904.host, call_606904.base,
                         call_606904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606904, url, valid)

proc call*(call_606905: Call_PostDeleteDBSnapshot_606891;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606906 = newJObject()
  var formData_606907 = newJObject()
  add(formData_606907, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606906, "Action", newJString(Action))
  add(query_606906, "Version", newJString(Version))
  result = call_606905.call(nil, query_606906, nil, formData_606907, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_606891(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_606892, base: "/",
    url: url_PostDeleteDBSnapshot_606893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_606875 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSnapshot_606877(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_606876(path: JsonNode; query: JsonNode;
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
  var valid_606878 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606878 = validateParameter(valid_606878, JString, required = true,
                                 default = nil)
  if valid_606878 != nil:
    section.add "DBSnapshotIdentifier", valid_606878
  var valid_606879 = query.getOrDefault("Action")
  valid_606879 = validateParameter(valid_606879, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606879 != nil:
    section.add "Action", valid_606879
  var valid_606880 = query.getOrDefault("Version")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606880 != nil:
    section.add "Version", valid_606880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606881 = header.getOrDefault("X-Amz-Signature")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Signature", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Content-Sha256", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Date")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Date", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Credential")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Credential", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606888: Call_GetDeleteDBSnapshot_606875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606888.validator(path, query, header, formData, body)
  let scheme = call_606888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606888.url(scheme.get, call_606888.host, call_606888.base,
                         call_606888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606888, url, valid)

proc call*(call_606889: Call_GetDeleteDBSnapshot_606875;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606890 = newJObject()
  add(query_606890, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606890, "Action", newJString(Action))
  add(query_606890, "Version", newJString(Version))
  result = call_606889.call(nil, query_606890, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_606875(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_606876, base: "/",
    url: url_GetDeleteDBSnapshot_606877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_606924 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSubnetGroup_606926(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_606925(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606927 = query.getOrDefault("Action")
  valid_606927 = validateParameter(valid_606927, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606927 != nil:
    section.add "Action", valid_606927
  var valid_606928 = query.getOrDefault("Version")
  valid_606928 = validateParameter(valid_606928, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606928 != nil:
    section.add "Version", valid_606928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606929 = header.getOrDefault("X-Amz-Signature")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Signature", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Content-Sha256", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Date")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Date", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Credential")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Credential", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Security-Token")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Security-Token", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Algorithm")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Algorithm", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-SignedHeaders", valid_606935
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_606936 = formData.getOrDefault("DBSubnetGroupName")
  valid_606936 = validateParameter(valid_606936, JString, required = true,
                                 default = nil)
  if valid_606936 != nil:
    section.add "DBSubnetGroupName", valid_606936
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606937: Call_PostDeleteDBSubnetGroup_606924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606937.validator(path, query, header, formData, body)
  let scheme = call_606937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606937.url(scheme.get, call_606937.host, call_606937.base,
                         call_606937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606937, url, valid)

proc call*(call_606938: Call_PostDeleteDBSubnetGroup_606924;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606939 = newJObject()
  var formData_606940 = newJObject()
  add(query_606939, "Action", newJString(Action))
  add(formData_606940, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606939, "Version", newJString(Version))
  result = call_606938.call(nil, query_606939, nil, formData_606940, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_606924(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_606925, base: "/",
    url: url_PostDeleteDBSubnetGroup_606926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_606908 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSubnetGroup_606910(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_606909(path: JsonNode; query: JsonNode;
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
  var valid_606911 = query.getOrDefault("Action")
  valid_606911 = validateParameter(valid_606911, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606911 != nil:
    section.add "Action", valid_606911
  var valid_606912 = query.getOrDefault("DBSubnetGroupName")
  valid_606912 = validateParameter(valid_606912, JString, required = true,
                                 default = nil)
  if valid_606912 != nil:
    section.add "DBSubnetGroupName", valid_606912
  var valid_606913 = query.getOrDefault("Version")
  valid_606913 = validateParameter(valid_606913, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606913 != nil:
    section.add "Version", valid_606913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606914 = header.getOrDefault("X-Amz-Signature")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Signature", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Content-Sha256", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Date")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Date", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Credential")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Credential", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Security-Token")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Security-Token", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Algorithm")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Algorithm", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-SignedHeaders", valid_606920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606921: Call_GetDeleteDBSubnetGroup_606908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606921.validator(path, query, header, formData, body)
  let scheme = call_606921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606921.url(scheme.get, call_606921.host, call_606921.base,
                         call_606921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606921, url, valid)

proc call*(call_606922: Call_GetDeleteDBSubnetGroup_606908;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606923 = newJObject()
  add(query_606923, "Action", newJString(Action))
  add(query_606923, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606923, "Version", newJString(Version))
  result = call_606922.call(nil, query_606923, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_606908(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_606909, base: "/",
    url: url_GetDeleteDBSubnetGroup_606910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_606957 = ref object of OpenApiRestCall_605573
proc url_PostDeleteEventSubscription_606959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_606958(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606960 = query.getOrDefault("Action")
  valid_606960 = validateParameter(valid_606960, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606960 != nil:
    section.add "Action", valid_606960
  var valid_606961 = query.getOrDefault("Version")
  valid_606961 = validateParameter(valid_606961, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606961 != nil:
    section.add "Version", valid_606961
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606962 = header.getOrDefault("X-Amz-Signature")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Signature", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Content-Sha256", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Date")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Date", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Credential")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Credential", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Security-Token")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Security-Token", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-Algorithm")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-Algorithm", valid_606967
  var valid_606968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-SignedHeaders", valid_606968
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_606969 = formData.getOrDefault("SubscriptionName")
  valid_606969 = validateParameter(valid_606969, JString, required = true,
                                 default = nil)
  if valid_606969 != nil:
    section.add "SubscriptionName", valid_606969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606970: Call_PostDeleteEventSubscription_606957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606970.validator(path, query, header, formData, body)
  let scheme = call_606970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606970.url(scheme.get, call_606970.host, call_606970.base,
                         call_606970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606970, url, valid)

proc call*(call_606971: Call_PostDeleteEventSubscription_606957;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606972 = newJObject()
  var formData_606973 = newJObject()
  add(formData_606973, "SubscriptionName", newJString(SubscriptionName))
  add(query_606972, "Action", newJString(Action))
  add(query_606972, "Version", newJString(Version))
  result = call_606971.call(nil, query_606972, nil, formData_606973, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_606957(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_606958, base: "/",
    url: url_PostDeleteEventSubscription_606959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_606941 = ref object of OpenApiRestCall_605573
proc url_GetDeleteEventSubscription_606943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_606942(path: JsonNode; query: JsonNode;
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
  var valid_606944 = query.getOrDefault("SubscriptionName")
  valid_606944 = validateParameter(valid_606944, JString, required = true,
                                 default = nil)
  if valid_606944 != nil:
    section.add "SubscriptionName", valid_606944
  var valid_606945 = query.getOrDefault("Action")
  valid_606945 = validateParameter(valid_606945, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606945 != nil:
    section.add "Action", valid_606945
  var valid_606946 = query.getOrDefault("Version")
  valid_606946 = validateParameter(valid_606946, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606946 != nil:
    section.add "Version", valid_606946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606947 = header.getOrDefault("X-Amz-Signature")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Signature", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Content-Sha256", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Date")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Date", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Credential")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Credential", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Security-Token")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Security-Token", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Algorithm")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Algorithm", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-SignedHeaders", valid_606953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606954: Call_GetDeleteEventSubscription_606941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606954.validator(path, query, header, formData, body)
  let scheme = call_606954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606954.url(scheme.get, call_606954.host, call_606954.base,
                         call_606954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606954, url, valid)

proc call*(call_606955: Call_GetDeleteEventSubscription_606941;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606956 = newJObject()
  add(query_606956, "SubscriptionName", newJString(SubscriptionName))
  add(query_606956, "Action", newJString(Action))
  add(query_606956, "Version", newJString(Version))
  result = call_606955.call(nil, query_606956, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_606941(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_606942, base: "/",
    url: url_GetDeleteEventSubscription_606943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_606990 = ref object of OpenApiRestCall_605573
proc url_PostDeleteOptionGroup_606992(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_606991(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606993 = query.getOrDefault("Action")
  valid_606993 = validateParameter(valid_606993, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606993 != nil:
    section.add "Action", valid_606993
  var valid_606994 = query.getOrDefault("Version")
  valid_606994 = validateParameter(valid_606994, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606994 != nil:
    section.add "Version", valid_606994
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606995 = header.getOrDefault("X-Amz-Signature")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Signature", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Content-Sha256", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Date")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Date", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Credential")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Credential", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Security-Token")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Security-Token", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Algorithm")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Algorithm", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-SignedHeaders", valid_607001
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_607002 = formData.getOrDefault("OptionGroupName")
  valid_607002 = validateParameter(valid_607002, JString, required = true,
                                 default = nil)
  if valid_607002 != nil:
    section.add "OptionGroupName", valid_607002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607003: Call_PostDeleteOptionGroup_606990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607003.validator(path, query, header, formData, body)
  let scheme = call_607003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607003.url(scheme.get, call_607003.host, call_607003.base,
                         call_607003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607003, url, valid)

proc call*(call_607004: Call_PostDeleteOptionGroup_606990; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_607005 = newJObject()
  var formData_607006 = newJObject()
  add(query_607005, "Action", newJString(Action))
  add(formData_607006, "OptionGroupName", newJString(OptionGroupName))
  add(query_607005, "Version", newJString(Version))
  result = call_607004.call(nil, query_607005, nil, formData_607006, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_606990(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_606991, base: "/",
    url: url_PostDeleteOptionGroup_606992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_606974 = ref object of OpenApiRestCall_605573
proc url_GetDeleteOptionGroup_606976(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_606975(path: JsonNode; query: JsonNode;
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
  var valid_606977 = query.getOrDefault("Action")
  valid_606977 = validateParameter(valid_606977, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606977 != nil:
    section.add "Action", valid_606977
  var valid_606978 = query.getOrDefault("OptionGroupName")
  valid_606978 = validateParameter(valid_606978, JString, required = true,
                                 default = nil)
  if valid_606978 != nil:
    section.add "OptionGroupName", valid_606978
  var valid_606979 = query.getOrDefault("Version")
  valid_606979 = validateParameter(valid_606979, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_606979 != nil:
    section.add "Version", valid_606979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606980 = header.getOrDefault("X-Amz-Signature")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Signature", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Content-Sha256", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Date")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Date", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Credential")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Credential", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Security-Token")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Security-Token", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Algorithm")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Algorithm", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-SignedHeaders", valid_606986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606987: Call_GetDeleteOptionGroup_606974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606987.validator(path, query, header, formData, body)
  let scheme = call_606987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606987.url(scheme.get, call_606987.host, call_606987.base,
                         call_606987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606987, url, valid)

proc call*(call_606988: Call_GetDeleteOptionGroup_606974; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_606989 = newJObject()
  add(query_606989, "Action", newJString(Action))
  add(query_606989, "OptionGroupName", newJString(OptionGroupName))
  add(query_606989, "Version", newJString(Version))
  result = call_606988.call(nil, query_606989, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_606974(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_606975, base: "/",
    url: url_GetDeleteOptionGroup_606976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_607030 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBEngineVersions_607032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_607031(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607033 = query.getOrDefault("Action")
  valid_607033 = validateParameter(valid_607033, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_607033 != nil:
    section.add "Action", valid_607033
  var valid_607034 = query.getOrDefault("Version")
  valid_607034 = validateParameter(valid_607034, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607034 != nil:
    section.add "Version", valid_607034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607035 = header.getOrDefault("X-Amz-Signature")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Signature", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Content-Sha256", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Date")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Date", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Credential")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Credential", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Security-Token")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Security-Token", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-Algorithm")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-Algorithm", valid_607040
  var valid_607041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "X-Amz-SignedHeaders", valid_607041
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
  var valid_607042 = formData.getOrDefault("DefaultOnly")
  valid_607042 = validateParameter(valid_607042, JBool, required = false, default = nil)
  if valid_607042 != nil:
    section.add "DefaultOnly", valid_607042
  var valid_607043 = formData.getOrDefault("MaxRecords")
  valid_607043 = validateParameter(valid_607043, JInt, required = false, default = nil)
  if valid_607043 != nil:
    section.add "MaxRecords", valid_607043
  var valid_607044 = formData.getOrDefault("EngineVersion")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "EngineVersion", valid_607044
  var valid_607045 = formData.getOrDefault("Marker")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "Marker", valid_607045
  var valid_607046 = formData.getOrDefault("Engine")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "Engine", valid_607046
  var valid_607047 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_607047 = validateParameter(valid_607047, JBool, required = false, default = nil)
  if valid_607047 != nil:
    section.add "ListSupportedCharacterSets", valid_607047
  var valid_607048 = formData.getOrDefault("Filters")
  valid_607048 = validateParameter(valid_607048, JArray, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "Filters", valid_607048
  var valid_607049 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "DBParameterGroupFamily", valid_607049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607050: Call_PostDescribeDBEngineVersions_607030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607050.validator(path, query, header, formData, body)
  let scheme = call_607050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607050.url(scheme.get, call_607050.host, call_607050.base,
                         call_607050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607050, url, valid)

proc call*(call_607051: Call_PostDescribeDBEngineVersions_607030;
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
  var query_607052 = newJObject()
  var formData_607053 = newJObject()
  add(formData_607053, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_607053, "MaxRecords", newJInt(MaxRecords))
  add(formData_607053, "EngineVersion", newJString(EngineVersion))
  add(formData_607053, "Marker", newJString(Marker))
  add(formData_607053, "Engine", newJString(Engine))
  add(formData_607053, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_607052, "Action", newJString(Action))
  if Filters != nil:
    formData_607053.add "Filters", Filters
  add(query_607052, "Version", newJString(Version))
  add(formData_607053, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607051.call(nil, query_607052, nil, formData_607053, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_607030(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_607031, base: "/",
    url: url_PostDescribeDBEngineVersions_607032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_607007 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBEngineVersions_607009(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_607008(path: JsonNode; query: JsonNode;
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
  var valid_607010 = query.getOrDefault("Marker")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "Marker", valid_607010
  var valid_607011 = query.getOrDefault("DBParameterGroupFamily")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "DBParameterGroupFamily", valid_607011
  var valid_607012 = query.getOrDefault("Engine")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "Engine", valid_607012
  var valid_607013 = query.getOrDefault("EngineVersion")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "EngineVersion", valid_607013
  var valid_607014 = query.getOrDefault("Action")
  valid_607014 = validateParameter(valid_607014, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_607014 != nil:
    section.add "Action", valid_607014
  var valid_607015 = query.getOrDefault("ListSupportedCharacterSets")
  valid_607015 = validateParameter(valid_607015, JBool, required = false, default = nil)
  if valid_607015 != nil:
    section.add "ListSupportedCharacterSets", valid_607015
  var valid_607016 = query.getOrDefault("Version")
  valid_607016 = validateParameter(valid_607016, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607016 != nil:
    section.add "Version", valid_607016
  var valid_607017 = query.getOrDefault("Filters")
  valid_607017 = validateParameter(valid_607017, JArray, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "Filters", valid_607017
  var valid_607018 = query.getOrDefault("MaxRecords")
  valid_607018 = validateParameter(valid_607018, JInt, required = false, default = nil)
  if valid_607018 != nil:
    section.add "MaxRecords", valid_607018
  var valid_607019 = query.getOrDefault("DefaultOnly")
  valid_607019 = validateParameter(valid_607019, JBool, required = false, default = nil)
  if valid_607019 != nil:
    section.add "DefaultOnly", valid_607019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607020 = header.getOrDefault("X-Amz-Signature")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Signature", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Content-Sha256", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Date")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Date", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Credential")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Credential", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Security-Token")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Security-Token", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Algorithm")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Algorithm", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-SignedHeaders", valid_607026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607027: Call_GetDescribeDBEngineVersions_607007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607027.validator(path, query, header, formData, body)
  let scheme = call_607027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607027.url(scheme.get, call_607027.host, call_607027.base,
                         call_607027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607027, url, valid)

proc call*(call_607028: Call_GetDescribeDBEngineVersions_607007;
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
  var query_607029 = newJObject()
  add(query_607029, "Marker", newJString(Marker))
  add(query_607029, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607029, "Engine", newJString(Engine))
  add(query_607029, "EngineVersion", newJString(EngineVersion))
  add(query_607029, "Action", newJString(Action))
  add(query_607029, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_607029, "Version", newJString(Version))
  if Filters != nil:
    query_607029.add "Filters", Filters
  add(query_607029, "MaxRecords", newJInt(MaxRecords))
  add(query_607029, "DefaultOnly", newJBool(DefaultOnly))
  result = call_607028.call(nil, query_607029, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_607007(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_607008, base: "/",
    url: url_GetDescribeDBEngineVersions_607009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_607073 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBInstances_607075(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_607074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607076 = query.getOrDefault("Action")
  valid_607076 = validateParameter(valid_607076, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_607076 != nil:
    section.add "Action", valid_607076
  var valid_607077 = query.getOrDefault("Version")
  valid_607077 = validateParameter(valid_607077, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607077 != nil:
    section.add "Version", valid_607077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607078 = header.getOrDefault("X-Amz-Signature")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Signature", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Content-Sha256", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Date")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Date", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Credential")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Credential", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Security-Token")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Security-Token", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-Algorithm")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Algorithm", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-SignedHeaders", valid_607084
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607085 = formData.getOrDefault("MaxRecords")
  valid_607085 = validateParameter(valid_607085, JInt, required = false, default = nil)
  if valid_607085 != nil:
    section.add "MaxRecords", valid_607085
  var valid_607086 = formData.getOrDefault("Marker")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "Marker", valid_607086
  var valid_607087 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "DBInstanceIdentifier", valid_607087
  var valid_607088 = formData.getOrDefault("Filters")
  valid_607088 = validateParameter(valid_607088, JArray, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "Filters", valid_607088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607089: Call_PostDescribeDBInstances_607073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607089.validator(path, query, header, formData, body)
  let scheme = call_607089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607089.url(scheme.get, call_607089.host, call_607089.base,
                         call_607089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607089, url, valid)

proc call*(call_607090: Call_PostDescribeDBInstances_607073; MaxRecords: int = 0;
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
  var query_607091 = newJObject()
  var formData_607092 = newJObject()
  add(formData_607092, "MaxRecords", newJInt(MaxRecords))
  add(formData_607092, "Marker", newJString(Marker))
  add(formData_607092, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607091, "Action", newJString(Action))
  if Filters != nil:
    formData_607092.add "Filters", Filters
  add(query_607091, "Version", newJString(Version))
  result = call_607090.call(nil, query_607091, nil, formData_607092, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_607073(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_607074, base: "/",
    url: url_PostDescribeDBInstances_607075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_607054 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBInstances_607056(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_607055(path: JsonNode; query: JsonNode;
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
  var valid_607057 = query.getOrDefault("Marker")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "Marker", valid_607057
  var valid_607058 = query.getOrDefault("DBInstanceIdentifier")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "DBInstanceIdentifier", valid_607058
  var valid_607059 = query.getOrDefault("Action")
  valid_607059 = validateParameter(valid_607059, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_607059 != nil:
    section.add "Action", valid_607059
  var valid_607060 = query.getOrDefault("Version")
  valid_607060 = validateParameter(valid_607060, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607060 != nil:
    section.add "Version", valid_607060
  var valid_607061 = query.getOrDefault("Filters")
  valid_607061 = validateParameter(valid_607061, JArray, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "Filters", valid_607061
  var valid_607062 = query.getOrDefault("MaxRecords")
  valid_607062 = validateParameter(valid_607062, JInt, required = false, default = nil)
  if valid_607062 != nil:
    section.add "MaxRecords", valid_607062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607063 = header.getOrDefault("X-Amz-Signature")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Signature", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Content-Sha256", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Date")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Date", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Credential")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Credential", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Security-Token")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Security-Token", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-Algorithm")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Algorithm", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-SignedHeaders", valid_607069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607070: Call_GetDescribeDBInstances_607054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607070.validator(path, query, header, formData, body)
  let scheme = call_607070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607070.url(scheme.get, call_607070.host, call_607070.base,
                         call_607070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607070, url, valid)

proc call*(call_607071: Call_GetDescribeDBInstances_607054; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_607072 = newJObject()
  add(query_607072, "Marker", newJString(Marker))
  add(query_607072, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607072, "Action", newJString(Action))
  add(query_607072, "Version", newJString(Version))
  if Filters != nil:
    query_607072.add "Filters", Filters
  add(query_607072, "MaxRecords", newJInt(MaxRecords))
  result = call_607071.call(nil, query_607072, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_607054(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_607055, base: "/",
    url: url_GetDescribeDBInstances_607056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_607115 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBLogFiles_607117(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_607116(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607118 = query.getOrDefault("Action")
  valid_607118 = validateParameter(valid_607118, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_607118 != nil:
    section.add "Action", valid_607118
  var valid_607119 = query.getOrDefault("Version")
  valid_607119 = validateParameter(valid_607119, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607119 != nil:
    section.add "Version", valid_607119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607120 = header.getOrDefault("X-Amz-Signature")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "X-Amz-Signature", valid_607120
  var valid_607121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Content-Sha256", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Date")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Date", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Credential")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Credential", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Security-Token")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Security-Token", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Algorithm")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Algorithm", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-SignedHeaders", valid_607126
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
  var valid_607127 = formData.getOrDefault("FileSize")
  valid_607127 = validateParameter(valid_607127, JInt, required = false, default = nil)
  if valid_607127 != nil:
    section.add "FileSize", valid_607127
  var valid_607128 = formData.getOrDefault("MaxRecords")
  valid_607128 = validateParameter(valid_607128, JInt, required = false, default = nil)
  if valid_607128 != nil:
    section.add "MaxRecords", valid_607128
  var valid_607129 = formData.getOrDefault("Marker")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "Marker", valid_607129
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607130 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607130 = validateParameter(valid_607130, JString, required = true,
                                 default = nil)
  if valid_607130 != nil:
    section.add "DBInstanceIdentifier", valid_607130
  var valid_607131 = formData.getOrDefault("FilenameContains")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "FilenameContains", valid_607131
  var valid_607132 = formData.getOrDefault("Filters")
  valid_607132 = validateParameter(valid_607132, JArray, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "Filters", valid_607132
  var valid_607133 = formData.getOrDefault("FileLastWritten")
  valid_607133 = validateParameter(valid_607133, JInt, required = false, default = nil)
  if valid_607133 != nil:
    section.add "FileLastWritten", valid_607133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607134: Call_PostDescribeDBLogFiles_607115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607134.validator(path, query, header, formData, body)
  let scheme = call_607134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607134.url(scheme.get, call_607134.host, call_607134.base,
                         call_607134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607134, url, valid)

proc call*(call_607135: Call_PostDescribeDBLogFiles_607115;
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
  var query_607136 = newJObject()
  var formData_607137 = newJObject()
  add(formData_607137, "FileSize", newJInt(FileSize))
  add(formData_607137, "MaxRecords", newJInt(MaxRecords))
  add(formData_607137, "Marker", newJString(Marker))
  add(formData_607137, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607137, "FilenameContains", newJString(FilenameContains))
  add(query_607136, "Action", newJString(Action))
  if Filters != nil:
    formData_607137.add "Filters", Filters
  add(query_607136, "Version", newJString(Version))
  add(formData_607137, "FileLastWritten", newJInt(FileLastWritten))
  result = call_607135.call(nil, query_607136, nil, formData_607137, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_607115(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_607116, base: "/",
    url: url_PostDescribeDBLogFiles_607117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_607093 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBLogFiles_607095(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_607094(path: JsonNode; query: JsonNode;
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
  var valid_607096 = query.getOrDefault("Marker")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "Marker", valid_607096
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607097 = query.getOrDefault("DBInstanceIdentifier")
  valid_607097 = validateParameter(valid_607097, JString, required = true,
                                 default = nil)
  if valid_607097 != nil:
    section.add "DBInstanceIdentifier", valid_607097
  var valid_607098 = query.getOrDefault("FileLastWritten")
  valid_607098 = validateParameter(valid_607098, JInt, required = false, default = nil)
  if valid_607098 != nil:
    section.add "FileLastWritten", valid_607098
  var valid_607099 = query.getOrDefault("Action")
  valid_607099 = validateParameter(valid_607099, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_607099 != nil:
    section.add "Action", valid_607099
  var valid_607100 = query.getOrDefault("FilenameContains")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "FilenameContains", valid_607100
  var valid_607101 = query.getOrDefault("Version")
  valid_607101 = validateParameter(valid_607101, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607101 != nil:
    section.add "Version", valid_607101
  var valid_607102 = query.getOrDefault("Filters")
  valid_607102 = validateParameter(valid_607102, JArray, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "Filters", valid_607102
  var valid_607103 = query.getOrDefault("MaxRecords")
  valid_607103 = validateParameter(valid_607103, JInt, required = false, default = nil)
  if valid_607103 != nil:
    section.add "MaxRecords", valid_607103
  var valid_607104 = query.getOrDefault("FileSize")
  valid_607104 = validateParameter(valid_607104, JInt, required = false, default = nil)
  if valid_607104 != nil:
    section.add "FileSize", valid_607104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607105 = header.getOrDefault("X-Amz-Signature")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-Signature", valid_607105
  var valid_607106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-Content-Sha256", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-Date")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Date", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Credential")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Credential", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Security-Token")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Security-Token", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Algorithm")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Algorithm", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-SignedHeaders", valid_607111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607112: Call_GetDescribeDBLogFiles_607093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607112.validator(path, query, header, formData, body)
  let scheme = call_607112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607112.url(scheme.get, call_607112.host, call_607112.base,
                         call_607112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607112, url, valid)

proc call*(call_607113: Call_GetDescribeDBLogFiles_607093;
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
  var query_607114 = newJObject()
  add(query_607114, "Marker", newJString(Marker))
  add(query_607114, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607114, "FileLastWritten", newJInt(FileLastWritten))
  add(query_607114, "Action", newJString(Action))
  add(query_607114, "FilenameContains", newJString(FilenameContains))
  add(query_607114, "Version", newJString(Version))
  if Filters != nil:
    query_607114.add "Filters", Filters
  add(query_607114, "MaxRecords", newJInt(MaxRecords))
  add(query_607114, "FileSize", newJInt(FileSize))
  result = call_607113.call(nil, query_607114, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_607093(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_607094, base: "/",
    url: url_GetDescribeDBLogFiles_607095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_607157 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameterGroups_607159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_607158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607160 = query.getOrDefault("Action")
  valid_607160 = validateParameter(valid_607160, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607160 != nil:
    section.add "Action", valid_607160
  var valid_607161 = query.getOrDefault("Version")
  valid_607161 = validateParameter(valid_607161, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607161 != nil:
    section.add "Version", valid_607161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607162 = header.getOrDefault("X-Amz-Signature")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Signature", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Content-Sha256", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-Date")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Date", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-Credential")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Credential", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-Security-Token")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-Security-Token", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-Algorithm")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Algorithm", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-SignedHeaders", valid_607168
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607169 = formData.getOrDefault("MaxRecords")
  valid_607169 = validateParameter(valid_607169, JInt, required = false, default = nil)
  if valid_607169 != nil:
    section.add "MaxRecords", valid_607169
  var valid_607170 = formData.getOrDefault("DBParameterGroupName")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "DBParameterGroupName", valid_607170
  var valid_607171 = formData.getOrDefault("Marker")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "Marker", valid_607171
  var valid_607172 = formData.getOrDefault("Filters")
  valid_607172 = validateParameter(valid_607172, JArray, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "Filters", valid_607172
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607173: Call_PostDescribeDBParameterGroups_607157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607173.validator(path, query, header, formData, body)
  let scheme = call_607173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607173.url(scheme.get, call_607173.host, call_607173.base,
                         call_607173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607173, url, valid)

proc call*(call_607174: Call_PostDescribeDBParameterGroups_607157;
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
  var query_607175 = newJObject()
  var formData_607176 = newJObject()
  add(formData_607176, "MaxRecords", newJInt(MaxRecords))
  add(formData_607176, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607176, "Marker", newJString(Marker))
  add(query_607175, "Action", newJString(Action))
  if Filters != nil:
    formData_607176.add "Filters", Filters
  add(query_607175, "Version", newJString(Version))
  result = call_607174.call(nil, query_607175, nil, formData_607176, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_607157(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_607158, base: "/",
    url: url_PostDescribeDBParameterGroups_607159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_607138 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameterGroups_607140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_607139(path: JsonNode; query: JsonNode;
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
  var valid_607141 = query.getOrDefault("Marker")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "Marker", valid_607141
  var valid_607142 = query.getOrDefault("DBParameterGroupName")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "DBParameterGroupName", valid_607142
  var valid_607143 = query.getOrDefault("Action")
  valid_607143 = validateParameter(valid_607143, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607143 != nil:
    section.add "Action", valid_607143
  var valid_607144 = query.getOrDefault("Version")
  valid_607144 = validateParameter(valid_607144, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607144 != nil:
    section.add "Version", valid_607144
  var valid_607145 = query.getOrDefault("Filters")
  valid_607145 = validateParameter(valid_607145, JArray, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "Filters", valid_607145
  var valid_607146 = query.getOrDefault("MaxRecords")
  valid_607146 = validateParameter(valid_607146, JInt, required = false, default = nil)
  if valid_607146 != nil:
    section.add "MaxRecords", valid_607146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607147 = header.getOrDefault("X-Amz-Signature")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Signature", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Content-Sha256", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Date")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Date", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Credential")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Credential", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Security-Token")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Security-Token", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Algorithm")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Algorithm", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-SignedHeaders", valid_607153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607154: Call_GetDescribeDBParameterGroups_607138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607154.validator(path, query, header, formData, body)
  let scheme = call_607154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607154.url(scheme.get, call_607154.host, call_607154.base,
                         call_607154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607154, url, valid)

proc call*(call_607155: Call_GetDescribeDBParameterGroups_607138;
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
  var query_607156 = newJObject()
  add(query_607156, "Marker", newJString(Marker))
  add(query_607156, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607156, "Action", newJString(Action))
  add(query_607156, "Version", newJString(Version))
  if Filters != nil:
    query_607156.add "Filters", Filters
  add(query_607156, "MaxRecords", newJInt(MaxRecords))
  result = call_607155.call(nil, query_607156, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_607138(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_607139, base: "/",
    url: url_GetDescribeDBParameterGroups_607140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_607197 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameters_607199(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_607198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607200 = query.getOrDefault("Action")
  valid_607200 = validateParameter(valid_607200, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607200 != nil:
    section.add "Action", valid_607200
  var valid_607201 = query.getOrDefault("Version")
  valid_607201 = validateParameter(valid_607201, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607201 != nil:
    section.add "Version", valid_607201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607202 = header.getOrDefault("X-Amz-Signature")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Signature", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Content-Sha256", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Date")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Date", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Credential")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Credential", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Security-Token")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Security-Token", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Algorithm")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Algorithm", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-SignedHeaders", valid_607208
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607209 = formData.getOrDefault("Source")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "Source", valid_607209
  var valid_607210 = formData.getOrDefault("MaxRecords")
  valid_607210 = validateParameter(valid_607210, JInt, required = false, default = nil)
  if valid_607210 != nil:
    section.add "MaxRecords", valid_607210
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607211 = formData.getOrDefault("DBParameterGroupName")
  valid_607211 = validateParameter(valid_607211, JString, required = true,
                                 default = nil)
  if valid_607211 != nil:
    section.add "DBParameterGroupName", valid_607211
  var valid_607212 = formData.getOrDefault("Marker")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "Marker", valid_607212
  var valid_607213 = formData.getOrDefault("Filters")
  valid_607213 = validateParameter(valid_607213, JArray, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "Filters", valid_607213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607214: Call_PostDescribeDBParameters_607197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607214.validator(path, query, header, formData, body)
  let scheme = call_607214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607214.url(scheme.get, call_607214.host, call_607214.base,
                         call_607214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607214, url, valid)

proc call*(call_607215: Call_PostDescribeDBParameters_607197;
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
  var query_607216 = newJObject()
  var formData_607217 = newJObject()
  add(formData_607217, "Source", newJString(Source))
  add(formData_607217, "MaxRecords", newJInt(MaxRecords))
  add(formData_607217, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607217, "Marker", newJString(Marker))
  add(query_607216, "Action", newJString(Action))
  if Filters != nil:
    formData_607217.add "Filters", Filters
  add(query_607216, "Version", newJString(Version))
  result = call_607215.call(nil, query_607216, nil, formData_607217, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_607197(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_607198, base: "/",
    url: url_PostDescribeDBParameters_607199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_607177 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameters_607179(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_607178(path: JsonNode; query: JsonNode;
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
  var valid_607180 = query.getOrDefault("Marker")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "Marker", valid_607180
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_607181 = query.getOrDefault("DBParameterGroupName")
  valid_607181 = validateParameter(valid_607181, JString, required = true,
                                 default = nil)
  if valid_607181 != nil:
    section.add "DBParameterGroupName", valid_607181
  var valid_607182 = query.getOrDefault("Source")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "Source", valid_607182
  var valid_607183 = query.getOrDefault("Action")
  valid_607183 = validateParameter(valid_607183, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607183 != nil:
    section.add "Action", valid_607183
  var valid_607184 = query.getOrDefault("Version")
  valid_607184 = validateParameter(valid_607184, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607184 != nil:
    section.add "Version", valid_607184
  var valid_607185 = query.getOrDefault("Filters")
  valid_607185 = validateParameter(valid_607185, JArray, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "Filters", valid_607185
  var valid_607186 = query.getOrDefault("MaxRecords")
  valid_607186 = validateParameter(valid_607186, JInt, required = false, default = nil)
  if valid_607186 != nil:
    section.add "MaxRecords", valid_607186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607187 = header.getOrDefault("X-Amz-Signature")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Signature", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Content-Sha256", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Date")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Date", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Credential")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Credential", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Security-Token")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Security-Token", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Algorithm")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Algorithm", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-SignedHeaders", valid_607193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607194: Call_GetDescribeDBParameters_607177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607194.validator(path, query, header, formData, body)
  let scheme = call_607194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607194.url(scheme.get, call_607194.host, call_607194.base,
                         call_607194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607194, url, valid)

proc call*(call_607195: Call_GetDescribeDBParameters_607177;
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
  var query_607196 = newJObject()
  add(query_607196, "Marker", newJString(Marker))
  add(query_607196, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607196, "Source", newJString(Source))
  add(query_607196, "Action", newJString(Action))
  add(query_607196, "Version", newJString(Version))
  if Filters != nil:
    query_607196.add "Filters", Filters
  add(query_607196, "MaxRecords", newJInt(MaxRecords))
  result = call_607195.call(nil, query_607196, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_607177(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_607178, base: "/",
    url: url_GetDescribeDBParameters_607179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_607237 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSecurityGroups_607239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_607238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607240 = query.getOrDefault("Action")
  valid_607240 = validateParameter(valid_607240, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607240 != nil:
    section.add "Action", valid_607240
  var valid_607241 = query.getOrDefault("Version")
  valid_607241 = validateParameter(valid_607241, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607241 != nil:
    section.add "Version", valid_607241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607242 = header.getOrDefault("X-Amz-Signature")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Signature", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Content-Sha256", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-Date")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-Date", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Credential")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Credential", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Security-Token")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Security-Token", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Algorithm")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Algorithm", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-SignedHeaders", valid_607248
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607249 = formData.getOrDefault("DBSecurityGroupName")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "DBSecurityGroupName", valid_607249
  var valid_607250 = formData.getOrDefault("MaxRecords")
  valid_607250 = validateParameter(valid_607250, JInt, required = false, default = nil)
  if valid_607250 != nil:
    section.add "MaxRecords", valid_607250
  var valid_607251 = formData.getOrDefault("Marker")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "Marker", valid_607251
  var valid_607252 = formData.getOrDefault("Filters")
  valid_607252 = validateParameter(valid_607252, JArray, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "Filters", valid_607252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_PostDescribeDBSecurityGroups_607237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_PostDescribeDBSecurityGroups_607237;
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
  var query_607255 = newJObject()
  var formData_607256 = newJObject()
  add(formData_607256, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_607256, "MaxRecords", newJInt(MaxRecords))
  add(formData_607256, "Marker", newJString(Marker))
  add(query_607255, "Action", newJString(Action))
  if Filters != nil:
    formData_607256.add "Filters", Filters
  add(query_607255, "Version", newJString(Version))
  result = call_607254.call(nil, query_607255, nil, formData_607256, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_607237(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_607238, base: "/",
    url: url_PostDescribeDBSecurityGroups_607239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_607218 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSecurityGroups_607220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_607219(path: JsonNode; query: JsonNode;
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
  var valid_607221 = query.getOrDefault("Marker")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "Marker", valid_607221
  var valid_607222 = query.getOrDefault("DBSecurityGroupName")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "DBSecurityGroupName", valid_607222
  var valid_607223 = query.getOrDefault("Action")
  valid_607223 = validateParameter(valid_607223, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607223 != nil:
    section.add "Action", valid_607223
  var valid_607224 = query.getOrDefault("Version")
  valid_607224 = validateParameter(valid_607224, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607224 != nil:
    section.add "Version", valid_607224
  var valid_607225 = query.getOrDefault("Filters")
  valid_607225 = validateParameter(valid_607225, JArray, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "Filters", valid_607225
  var valid_607226 = query.getOrDefault("MaxRecords")
  valid_607226 = validateParameter(valid_607226, JInt, required = false, default = nil)
  if valid_607226 != nil:
    section.add "MaxRecords", valid_607226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607227 = header.getOrDefault("X-Amz-Signature")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Signature", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Content-Sha256", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-Date")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Date", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Credential")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Credential", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Security-Token")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Security-Token", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Algorithm")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Algorithm", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-SignedHeaders", valid_607233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607234: Call_GetDescribeDBSecurityGroups_607218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607234.validator(path, query, header, formData, body)
  let scheme = call_607234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607234.url(scheme.get, call_607234.host, call_607234.base,
                         call_607234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607234, url, valid)

proc call*(call_607235: Call_GetDescribeDBSecurityGroups_607218;
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
  var query_607236 = newJObject()
  add(query_607236, "Marker", newJString(Marker))
  add(query_607236, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_607236, "Action", newJString(Action))
  add(query_607236, "Version", newJString(Version))
  if Filters != nil:
    query_607236.add "Filters", Filters
  add(query_607236, "MaxRecords", newJInt(MaxRecords))
  result = call_607235.call(nil, query_607236, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_607218(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_607219, base: "/",
    url: url_GetDescribeDBSecurityGroups_607220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_607278 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSnapshots_607280(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_607279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607281 = query.getOrDefault("Action")
  valid_607281 = validateParameter(valid_607281, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607281 != nil:
    section.add "Action", valid_607281
  var valid_607282 = query.getOrDefault("Version")
  valid_607282 = validateParameter(valid_607282, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607282 != nil:
    section.add "Version", valid_607282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607283 = header.getOrDefault("X-Amz-Signature")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Signature", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Content-Sha256", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Date")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Date", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-Credential")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Credential", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-Security-Token")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-Security-Token", valid_607287
  var valid_607288 = header.getOrDefault("X-Amz-Algorithm")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "X-Amz-Algorithm", valid_607288
  var valid_607289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "X-Amz-SignedHeaders", valid_607289
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607290 = formData.getOrDefault("SnapshotType")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "SnapshotType", valid_607290
  var valid_607291 = formData.getOrDefault("MaxRecords")
  valid_607291 = validateParameter(valid_607291, JInt, required = false, default = nil)
  if valid_607291 != nil:
    section.add "MaxRecords", valid_607291
  var valid_607292 = formData.getOrDefault("Marker")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "Marker", valid_607292
  var valid_607293 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "DBInstanceIdentifier", valid_607293
  var valid_607294 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "DBSnapshotIdentifier", valid_607294
  var valid_607295 = formData.getOrDefault("Filters")
  valid_607295 = validateParameter(valid_607295, JArray, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "Filters", valid_607295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607296: Call_PostDescribeDBSnapshots_607278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607296.validator(path, query, header, formData, body)
  let scheme = call_607296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607296.url(scheme.get, call_607296.host, call_607296.base,
                         call_607296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607296, url, valid)

proc call*(call_607297: Call_PostDescribeDBSnapshots_607278;
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
  var query_607298 = newJObject()
  var formData_607299 = newJObject()
  add(formData_607299, "SnapshotType", newJString(SnapshotType))
  add(formData_607299, "MaxRecords", newJInt(MaxRecords))
  add(formData_607299, "Marker", newJString(Marker))
  add(formData_607299, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607299, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607298, "Action", newJString(Action))
  if Filters != nil:
    formData_607299.add "Filters", Filters
  add(query_607298, "Version", newJString(Version))
  result = call_607297.call(nil, query_607298, nil, formData_607299, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_607278(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_607279, base: "/",
    url: url_PostDescribeDBSnapshots_607280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_607257 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSnapshots_607259(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_607258(path: JsonNode; query: JsonNode;
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
  var valid_607260 = query.getOrDefault("Marker")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "Marker", valid_607260
  var valid_607261 = query.getOrDefault("DBInstanceIdentifier")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "DBInstanceIdentifier", valid_607261
  var valid_607262 = query.getOrDefault("DBSnapshotIdentifier")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "DBSnapshotIdentifier", valid_607262
  var valid_607263 = query.getOrDefault("SnapshotType")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "SnapshotType", valid_607263
  var valid_607264 = query.getOrDefault("Action")
  valid_607264 = validateParameter(valid_607264, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607264 != nil:
    section.add "Action", valid_607264
  var valid_607265 = query.getOrDefault("Version")
  valid_607265 = validateParameter(valid_607265, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607265 != nil:
    section.add "Version", valid_607265
  var valid_607266 = query.getOrDefault("Filters")
  valid_607266 = validateParameter(valid_607266, JArray, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "Filters", valid_607266
  var valid_607267 = query.getOrDefault("MaxRecords")
  valid_607267 = validateParameter(valid_607267, JInt, required = false, default = nil)
  if valid_607267 != nil:
    section.add "MaxRecords", valid_607267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607268 = header.getOrDefault("X-Amz-Signature")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Signature", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Content-Sha256", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Date")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Date", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Credential")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Credential", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-Security-Token")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-Security-Token", valid_607272
  var valid_607273 = header.getOrDefault("X-Amz-Algorithm")
  valid_607273 = validateParameter(valid_607273, JString, required = false,
                                 default = nil)
  if valid_607273 != nil:
    section.add "X-Amz-Algorithm", valid_607273
  var valid_607274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607274 = validateParameter(valid_607274, JString, required = false,
                                 default = nil)
  if valid_607274 != nil:
    section.add "X-Amz-SignedHeaders", valid_607274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607275: Call_GetDescribeDBSnapshots_607257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607275.validator(path, query, header, formData, body)
  let scheme = call_607275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607275.url(scheme.get, call_607275.host, call_607275.base,
                         call_607275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607275, url, valid)

proc call*(call_607276: Call_GetDescribeDBSnapshots_607257; Marker: string = "";
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
  var query_607277 = newJObject()
  add(query_607277, "Marker", newJString(Marker))
  add(query_607277, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607277, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607277, "SnapshotType", newJString(SnapshotType))
  add(query_607277, "Action", newJString(Action))
  add(query_607277, "Version", newJString(Version))
  if Filters != nil:
    query_607277.add "Filters", Filters
  add(query_607277, "MaxRecords", newJInt(MaxRecords))
  result = call_607276.call(nil, query_607277, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_607257(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_607258, base: "/",
    url: url_GetDescribeDBSnapshots_607259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_607319 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSubnetGroups_607321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_607320(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607322 = query.getOrDefault("Action")
  valid_607322 = validateParameter(valid_607322, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607322 != nil:
    section.add "Action", valid_607322
  var valid_607323 = query.getOrDefault("Version")
  valid_607323 = validateParameter(valid_607323, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607323 != nil:
    section.add "Version", valid_607323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607324 = header.getOrDefault("X-Amz-Signature")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Signature", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Content-Sha256", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Date")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Date", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-Credential")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-Credential", valid_607327
  var valid_607328 = header.getOrDefault("X-Amz-Security-Token")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "X-Amz-Security-Token", valid_607328
  var valid_607329 = header.getOrDefault("X-Amz-Algorithm")
  valid_607329 = validateParameter(valid_607329, JString, required = false,
                                 default = nil)
  if valid_607329 != nil:
    section.add "X-Amz-Algorithm", valid_607329
  var valid_607330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607330 = validateParameter(valid_607330, JString, required = false,
                                 default = nil)
  if valid_607330 != nil:
    section.add "X-Amz-SignedHeaders", valid_607330
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607331 = formData.getOrDefault("MaxRecords")
  valid_607331 = validateParameter(valid_607331, JInt, required = false, default = nil)
  if valid_607331 != nil:
    section.add "MaxRecords", valid_607331
  var valid_607332 = formData.getOrDefault("Marker")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "Marker", valid_607332
  var valid_607333 = formData.getOrDefault("DBSubnetGroupName")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "DBSubnetGroupName", valid_607333
  var valid_607334 = formData.getOrDefault("Filters")
  valid_607334 = validateParameter(valid_607334, JArray, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "Filters", valid_607334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607335: Call_PostDescribeDBSubnetGroups_607319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607335.validator(path, query, header, formData, body)
  let scheme = call_607335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607335.url(scheme.get, call_607335.host, call_607335.base,
                         call_607335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607335, url, valid)

proc call*(call_607336: Call_PostDescribeDBSubnetGroups_607319;
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
  var query_607337 = newJObject()
  var formData_607338 = newJObject()
  add(formData_607338, "MaxRecords", newJInt(MaxRecords))
  add(formData_607338, "Marker", newJString(Marker))
  add(query_607337, "Action", newJString(Action))
  add(formData_607338, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_607338.add "Filters", Filters
  add(query_607337, "Version", newJString(Version))
  result = call_607336.call(nil, query_607337, nil, formData_607338, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_607319(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_607320, base: "/",
    url: url_PostDescribeDBSubnetGroups_607321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_607300 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSubnetGroups_607302(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_607301(path: JsonNode; query: JsonNode;
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
  var valid_607303 = query.getOrDefault("Marker")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "Marker", valid_607303
  var valid_607304 = query.getOrDefault("Action")
  valid_607304 = validateParameter(valid_607304, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607304 != nil:
    section.add "Action", valid_607304
  var valid_607305 = query.getOrDefault("DBSubnetGroupName")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "DBSubnetGroupName", valid_607305
  var valid_607306 = query.getOrDefault("Version")
  valid_607306 = validateParameter(valid_607306, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607306 != nil:
    section.add "Version", valid_607306
  var valid_607307 = query.getOrDefault("Filters")
  valid_607307 = validateParameter(valid_607307, JArray, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "Filters", valid_607307
  var valid_607308 = query.getOrDefault("MaxRecords")
  valid_607308 = validateParameter(valid_607308, JInt, required = false, default = nil)
  if valid_607308 != nil:
    section.add "MaxRecords", valid_607308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607309 = header.getOrDefault("X-Amz-Signature")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Signature", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Content-Sha256", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-Date")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-Date", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Credential")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Credential", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Security-Token")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Security-Token", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-Algorithm")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Algorithm", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-SignedHeaders", valid_607315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607316: Call_GetDescribeDBSubnetGroups_607300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607316.validator(path, query, header, formData, body)
  let scheme = call_607316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607316.url(scheme.get, call_607316.host, call_607316.base,
                         call_607316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607316, url, valid)

proc call*(call_607317: Call_GetDescribeDBSubnetGroups_607300; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_607318 = newJObject()
  add(query_607318, "Marker", newJString(Marker))
  add(query_607318, "Action", newJString(Action))
  add(query_607318, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607318, "Version", newJString(Version))
  if Filters != nil:
    query_607318.add "Filters", Filters
  add(query_607318, "MaxRecords", newJInt(MaxRecords))
  result = call_607317.call(nil, query_607318, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_607300(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_607301, base: "/",
    url: url_GetDescribeDBSubnetGroups_607302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_607358 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEngineDefaultParameters_607360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_607359(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607361 = query.getOrDefault("Action")
  valid_607361 = validateParameter(valid_607361, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607361 != nil:
    section.add "Action", valid_607361
  var valid_607362 = query.getOrDefault("Version")
  valid_607362 = validateParameter(valid_607362, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607362 != nil:
    section.add "Version", valid_607362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607363 = header.getOrDefault("X-Amz-Signature")
  valid_607363 = validateParameter(valid_607363, JString, required = false,
                                 default = nil)
  if valid_607363 != nil:
    section.add "X-Amz-Signature", valid_607363
  var valid_607364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "X-Amz-Content-Sha256", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Date")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Date", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Credential")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Credential", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Security-Token")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Security-Token", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Algorithm")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Algorithm", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-SignedHeaders", valid_607369
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_607370 = formData.getOrDefault("MaxRecords")
  valid_607370 = validateParameter(valid_607370, JInt, required = false, default = nil)
  if valid_607370 != nil:
    section.add "MaxRecords", valid_607370
  var valid_607371 = formData.getOrDefault("Marker")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "Marker", valid_607371
  var valid_607372 = formData.getOrDefault("Filters")
  valid_607372 = validateParameter(valid_607372, JArray, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "Filters", valid_607372
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607373 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607373 = validateParameter(valid_607373, JString, required = true,
                                 default = nil)
  if valid_607373 != nil:
    section.add "DBParameterGroupFamily", valid_607373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607374: Call_PostDescribeEngineDefaultParameters_607358;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607374.validator(path, query, header, formData, body)
  let scheme = call_607374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607374.url(scheme.get, call_607374.host, call_607374.base,
                         call_607374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607374, url, valid)

proc call*(call_607375: Call_PostDescribeEngineDefaultParameters_607358;
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
  var query_607376 = newJObject()
  var formData_607377 = newJObject()
  add(formData_607377, "MaxRecords", newJInt(MaxRecords))
  add(formData_607377, "Marker", newJString(Marker))
  add(query_607376, "Action", newJString(Action))
  if Filters != nil:
    formData_607377.add "Filters", Filters
  add(query_607376, "Version", newJString(Version))
  add(formData_607377, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607375.call(nil, query_607376, nil, formData_607377, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_607358(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_607359, base: "/",
    url: url_PostDescribeEngineDefaultParameters_607360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_607339 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEngineDefaultParameters_607341(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_607340(path: JsonNode;
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
  var valid_607342 = query.getOrDefault("Marker")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "Marker", valid_607342
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607343 = query.getOrDefault("DBParameterGroupFamily")
  valid_607343 = validateParameter(valid_607343, JString, required = true,
                                 default = nil)
  if valid_607343 != nil:
    section.add "DBParameterGroupFamily", valid_607343
  var valid_607344 = query.getOrDefault("Action")
  valid_607344 = validateParameter(valid_607344, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607344 != nil:
    section.add "Action", valid_607344
  var valid_607345 = query.getOrDefault("Version")
  valid_607345 = validateParameter(valid_607345, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607345 != nil:
    section.add "Version", valid_607345
  var valid_607346 = query.getOrDefault("Filters")
  valid_607346 = validateParameter(valid_607346, JArray, required = false,
                                 default = nil)
  if valid_607346 != nil:
    section.add "Filters", valid_607346
  var valid_607347 = query.getOrDefault("MaxRecords")
  valid_607347 = validateParameter(valid_607347, JInt, required = false, default = nil)
  if valid_607347 != nil:
    section.add "MaxRecords", valid_607347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607348 = header.getOrDefault("X-Amz-Signature")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Signature", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Content-Sha256", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Date")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Date", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Credential")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Credential", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Security-Token")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Security-Token", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Algorithm")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Algorithm", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-SignedHeaders", valid_607354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607355: Call_GetDescribeEngineDefaultParameters_607339;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607355.validator(path, query, header, formData, body)
  let scheme = call_607355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607355.url(scheme.get, call_607355.host, call_607355.base,
                         call_607355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607355, url, valid)

proc call*(call_607356: Call_GetDescribeEngineDefaultParameters_607339;
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
  var query_607357 = newJObject()
  add(query_607357, "Marker", newJString(Marker))
  add(query_607357, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607357, "Action", newJString(Action))
  add(query_607357, "Version", newJString(Version))
  if Filters != nil:
    query_607357.add "Filters", Filters
  add(query_607357, "MaxRecords", newJInt(MaxRecords))
  result = call_607356.call(nil, query_607357, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_607339(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_607340, base: "/",
    url: url_GetDescribeEngineDefaultParameters_607341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_607395 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventCategories_607397(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_607396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607398 = query.getOrDefault("Action")
  valid_607398 = validateParameter(valid_607398, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607398 != nil:
    section.add "Action", valid_607398
  var valid_607399 = query.getOrDefault("Version")
  valid_607399 = validateParameter(valid_607399, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607399 != nil:
    section.add "Version", valid_607399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607400 = header.getOrDefault("X-Amz-Signature")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Signature", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Content-Sha256", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Date")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Date", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Credential")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Credential", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-Security-Token")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Security-Token", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Algorithm")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Algorithm", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-SignedHeaders", valid_607406
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607407 = formData.getOrDefault("SourceType")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "SourceType", valid_607407
  var valid_607408 = formData.getOrDefault("Filters")
  valid_607408 = validateParameter(valid_607408, JArray, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "Filters", valid_607408
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607409: Call_PostDescribeEventCategories_607395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607409.validator(path, query, header, formData, body)
  let scheme = call_607409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607409.url(scheme.get, call_607409.host, call_607409.base,
                         call_607409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607409, url, valid)

proc call*(call_607410: Call_PostDescribeEventCategories_607395;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_607411 = newJObject()
  var formData_607412 = newJObject()
  add(formData_607412, "SourceType", newJString(SourceType))
  add(query_607411, "Action", newJString(Action))
  if Filters != nil:
    formData_607412.add "Filters", Filters
  add(query_607411, "Version", newJString(Version))
  result = call_607410.call(nil, query_607411, nil, formData_607412, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_607395(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_607396, base: "/",
    url: url_PostDescribeEventCategories_607397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_607378 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventCategories_607380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_607379(path: JsonNode; query: JsonNode;
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
  var valid_607381 = query.getOrDefault("SourceType")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "SourceType", valid_607381
  var valid_607382 = query.getOrDefault("Action")
  valid_607382 = validateParameter(valid_607382, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607382 != nil:
    section.add "Action", valid_607382
  var valid_607383 = query.getOrDefault("Version")
  valid_607383 = validateParameter(valid_607383, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607383 != nil:
    section.add "Version", valid_607383
  var valid_607384 = query.getOrDefault("Filters")
  valid_607384 = validateParameter(valid_607384, JArray, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "Filters", valid_607384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607385 = header.getOrDefault("X-Amz-Signature")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Signature", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Content-Sha256", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Date")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Date", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Credential")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Credential", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-Security-Token")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Security-Token", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Algorithm")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Algorithm", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-SignedHeaders", valid_607391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607392: Call_GetDescribeEventCategories_607378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607392.validator(path, query, header, formData, body)
  let scheme = call_607392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607392.url(scheme.get, call_607392.host, call_607392.base,
                         call_607392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607392, url, valid)

proc call*(call_607393: Call_GetDescribeEventCategories_607378;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-09-01"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_607394 = newJObject()
  add(query_607394, "SourceType", newJString(SourceType))
  add(query_607394, "Action", newJString(Action))
  add(query_607394, "Version", newJString(Version))
  if Filters != nil:
    query_607394.add "Filters", Filters
  result = call_607393.call(nil, query_607394, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_607378(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_607379, base: "/",
    url: url_GetDescribeEventCategories_607380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_607432 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventSubscriptions_607434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_607433(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607435 = query.getOrDefault("Action")
  valid_607435 = validateParameter(valid_607435, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607435 != nil:
    section.add "Action", valid_607435
  var valid_607436 = query.getOrDefault("Version")
  valid_607436 = validateParameter(valid_607436, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607436 != nil:
    section.add "Version", valid_607436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607437 = header.getOrDefault("X-Amz-Signature")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Signature", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Content-Sha256", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Date")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Date", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Credential")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Credential", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Security-Token")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Security-Token", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Algorithm")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Algorithm", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-SignedHeaders", valid_607443
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607444 = formData.getOrDefault("MaxRecords")
  valid_607444 = validateParameter(valid_607444, JInt, required = false, default = nil)
  if valid_607444 != nil:
    section.add "MaxRecords", valid_607444
  var valid_607445 = formData.getOrDefault("Marker")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "Marker", valid_607445
  var valid_607446 = formData.getOrDefault("SubscriptionName")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "SubscriptionName", valid_607446
  var valid_607447 = formData.getOrDefault("Filters")
  valid_607447 = validateParameter(valid_607447, JArray, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "Filters", valid_607447
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607448: Call_PostDescribeEventSubscriptions_607432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607448.validator(path, query, header, formData, body)
  let scheme = call_607448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607448.url(scheme.get, call_607448.host, call_607448.base,
                         call_607448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607448, url, valid)

proc call*(call_607449: Call_PostDescribeEventSubscriptions_607432;
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
  var query_607450 = newJObject()
  var formData_607451 = newJObject()
  add(formData_607451, "MaxRecords", newJInt(MaxRecords))
  add(formData_607451, "Marker", newJString(Marker))
  add(formData_607451, "SubscriptionName", newJString(SubscriptionName))
  add(query_607450, "Action", newJString(Action))
  if Filters != nil:
    formData_607451.add "Filters", Filters
  add(query_607450, "Version", newJString(Version))
  result = call_607449.call(nil, query_607450, nil, formData_607451, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_607432(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_607433, base: "/",
    url: url_PostDescribeEventSubscriptions_607434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_607413 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventSubscriptions_607415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_607414(path: JsonNode; query: JsonNode;
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
  var valid_607416 = query.getOrDefault("Marker")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "Marker", valid_607416
  var valid_607417 = query.getOrDefault("SubscriptionName")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "SubscriptionName", valid_607417
  var valid_607418 = query.getOrDefault("Action")
  valid_607418 = validateParameter(valid_607418, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607418 != nil:
    section.add "Action", valid_607418
  var valid_607419 = query.getOrDefault("Version")
  valid_607419 = validateParameter(valid_607419, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607419 != nil:
    section.add "Version", valid_607419
  var valid_607420 = query.getOrDefault("Filters")
  valid_607420 = validateParameter(valid_607420, JArray, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "Filters", valid_607420
  var valid_607421 = query.getOrDefault("MaxRecords")
  valid_607421 = validateParameter(valid_607421, JInt, required = false, default = nil)
  if valid_607421 != nil:
    section.add "MaxRecords", valid_607421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607422 = header.getOrDefault("X-Amz-Signature")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Signature", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-Content-Sha256", valid_607423
  var valid_607424 = header.getOrDefault("X-Amz-Date")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "X-Amz-Date", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Credential")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Credential", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Security-Token")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Security-Token", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Algorithm")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Algorithm", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-SignedHeaders", valid_607428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607429: Call_GetDescribeEventSubscriptions_607413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607429.validator(path, query, header, formData, body)
  let scheme = call_607429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607429.url(scheme.get, call_607429.host, call_607429.base,
                         call_607429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607429, url, valid)

proc call*(call_607430: Call_GetDescribeEventSubscriptions_607413;
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
  var query_607431 = newJObject()
  add(query_607431, "Marker", newJString(Marker))
  add(query_607431, "SubscriptionName", newJString(SubscriptionName))
  add(query_607431, "Action", newJString(Action))
  add(query_607431, "Version", newJString(Version))
  if Filters != nil:
    query_607431.add "Filters", Filters
  add(query_607431, "MaxRecords", newJInt(MaxRecords))
  result = call_607430.call(nil, query_607431, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_607413(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_607414, base: "/",
    url: url_GetDescribeEventSubscriptions_607415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607476 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEvents_607478(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_607477(path: JsonNode; query: JsonNode;
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
  var valid_607479 = query.getOrDefault("Action")
  valid_607479 = validateParameter(valid_607479, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607479 != nil:
    section.add "Action", valid_607479
  var valid_607480 = query.getOrDefault("Version")
  valid_607480 = validateParameter(valid_607480, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607480 != nil:
    section.add "Version", valid_607480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607481 = header.getOrDefault("X-Amz-Signature")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-Signature", valid_607481
  var valid_607482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Content-Sha256", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Date")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Date", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-Credential")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-Credential", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Security-Token")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Security-Token", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Algorithm")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Algorithm", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-SignedHeaders", valid_607487
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
  var valid_607488 = formData.getOrDefault("MaxRecords")
  valid_607488 = validateParameter(valid_607488, JInt, required = false, default = nil)
  if valid_607488 != nil:
    section.add "MaxRecords", valid_607488
  var valid_607489 = formData.getOrDefault("Marker")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "Marker", valid_607489
  var valid_607490 = formData.getOrDefault("SourceIdentifier")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "SourceIdentifier", valid_607490
  var valid_607491 = formData.getOrDefault("SourceType")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607491 != nil:
    section.add "SourceType", valid_607491
  var valid_607492 = formData.getOrDefault("Duration")
  valid_607492 = validateParameter(valid_607492, JInt, required = false, default = nil)
  if valid_607492 != nil:
    section.add "Duration", valid_607492
  var valid_607493 = formData.getOrDefault("EndTime")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "EndTime", valid_607493
  var valid_607494 = formData.getOrDefault("StartTime")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "StartTime", valid_607494
  var valid_607495 = formData.getOrDefault("EventCategories")
  valid_607495 = validateParameter(valid_607495, JArray, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "EventCategories", valid_607495
  var valid_607496 = formData.getOrDefault("Filters")
  valid_607496 = validateParameter(valid_607496, JArray, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "Filters", valid_607496
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607497: Call_PostDescribeEvents_607476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607497.validator(path, query, header, formData, body)
  let scheme = call_607497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607497.url(scheme.get, call_607497.host, call_607497.base,
                         call_607497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607497, url, valid)

proc call*(call_607498: Call_PostDescribeEvents_607476; MaxRecords: int = 0;
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
  var query_607499 = newJObject()
  var formData_607500 = newJObject()
  add(formData_607500, "MaxRecords", newJInt(MaxRecords))
  add(formData_607500, "Marker", newJString(Marker))
  add(formData_607500, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_607500, "SourceType", newJString(SourceType))
  add(formData_607500, "Duration", newJInt(Duration))
  add(formData_607500, "EndTime", newJString(EndTime))
  add(formData_607500, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_607500.add "EventCategories", EventCategories
  add(query_607499, "Action", newJString(Action))
  if Filters != nil:
    formData_607500.add "Filters", Filters
  add(query_607499, "Version", newJString(Version))
  result = call_607498.call(nil, query_607499, nil, formData_607500, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607476(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607477, base: "/",
    url: url_PostDescribeEvents_607478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607452 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEvents_607454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_607453(path: JsonNode; query: JsonNode;
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
  var valid_607455 = query.getOrDefault("Marker")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "Marker", valid_607455
  var valid_607456 = query.getOrDefault("SourceType")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607456 != nil:
    section.add "SourceType", valid_607456
  var valid_607457 = query.getOrDefault("SourceIdentifier")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "SourceIdentifier", valid_607457
  var valid_607458 = query.getOrDefault("EventCategories")
  valid_607458 = validateParameter(valid_607458, JArray, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "EventCategories", valid_607458
  var valid_607459 = query.getOrDefault("Action")
  valid_607459 = validateParameter(valid_607459, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607459 != nil:
    section.add "Action", valid_607459
  var valid_607460 = query.getOrDefault("StartTime")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "StartTime", valid_607460
  var valid_607461 = query.getOrDefault("Duration")
  valid_607461 = validateParameter(valid_607461, JInt, required = false, default = nil)
  if valid_607461 != nil:
    section.add "Duration", valid_607461
  var valid_607462 = query.getOrDefault("EndTime")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "EndTime", valid_607462
  var valid_607463 = query.getOrDefault("Version")
  valid_607463 = validateParameter(valid_607463, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607463 != nil:
    section.add "Version", valid_607463
  var valid_607464 = query.getOrDefault("Filters")
  valid_607464 = validateParameter(valid_607464, JArray, required = false,
                                 default = nil)
  if valid_607464 != nil:
    section.add "Filters", valid_607464
  var valid_607465 = query.getOrDefault("MaxRecords")
  valid_607465 = validateParameter(valid_607465, JInt, required = false, default = nil)
  if valid_607465 != nil:
    section.add "MaxRecords", valid_607465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607466 = header.getOrDefault("X-Amz-Signature")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "X-Amz-Signature", valid_607466
  var valid_607467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Content-Sha256", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Date")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Date", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-Credential")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-Credential", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Security-Token")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Security-Token", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Algorithm")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Algorithm", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-SignedHeaders", valid_607472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607473: Call_GetDescribeEvents_607452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607473.validator(path, query, header, formData, body)
  let scheme = call_607473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607473.url(scheme.get, call_607473.host, call_607473.base,
                         call_607473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607473, url, valid)

proc call*(call_607474: Call_GetDescribeEvents_607452; Marker: string = "";
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
  var query_607475 = newJObject()
  add(query_607475, "Marker", newJString(Marker))
  add(query_607475, "SourceType", newJString(SourceType))
  add(query_607475, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_607475.add "EventCategories", EventCategories
  add(query_607475, "Action", newJString(Action))
  add(query_607475, "StartTime", newJString(StartTime))
  add(query_607475, "Duration", newJInt(Duration))
  add(query_607475, "EndTime", newJString(EndTime))
  add(query_607475, "Version", newJString(Version))
  if Filters != nil:
    query_607475.add "Filters", Filters
  add(query_607475, "MaxRecords", newJInt(MaxRecords))
  result = call_607474.call(nil, query_607475, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607452(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607453,
    base: "/", url: url_GetDescribeEvents_607454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_607521 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroupOptions_607523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_607522(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607524 = query.getOrDefault("Action")
  valid_607524 = validateParameter(valid_607524, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607524 != nil:
    section.add "Action", valid_607524
  var valid_607525 = query.getOrDefault("Version")
  valid_607525 = validateParameter(valid_607525, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607525 != nil:
    section.add "Version", valid_607525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607526 = header.getOrDefault("X-Amz-Signature")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Signature", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Content-Sha256", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Date")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Date", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Credential")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Credential", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Security-Token")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Security-Token", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Algorithm")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Algorithm", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-SignedHeaders", valid_607532
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607533 = formData.getOrDefault("MaxRecords")
  valid_607533 = validateParameter(valid_607533, JInt, required = false, default = nil)
  if valid_607533 != nil:
    section.add "MaxRecords", valid_607533
  var valid_607534 = formData.getOrDefault("Marker")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "Marker", valid_607534
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_607535 = formData.getOrDefault("EngineName")
  valid_607535 = validateParameter(valid_607535, JString, required = true,
                                 default = nil)
  if valid_607535 != nil:
    section.add "EngineName", valid_607535
  var valid_607536 = formData.getOrDefault("MajorEngineVersion")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "MajorEngineVersion", valid_607536
  var valid_607537 = formData.getOrDefault("Filters")
  valid_607537 = validateParameter(valid_607537, JArray, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "Filters", valid_607537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607538: Call_PostDescribeOptionGroupOptions_607521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607538.validator(path, query, header, formData, body)
  let scheme = call_607538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607538.url(scheme.get, call_607538.host, call_607538.base,
                         call_607538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607538, url, valid)

proc call*(call_607539: Call_PostDescribeOptionGroupOptions_607521;
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
  var query_607540 = newJObject()
  var formData_607541 = newJObject()
  add(formData_607541, "MaxRecords", newJInt(MaxRecords))
  add(formData_607541, "Marker", newJString(Marker))
  add(formData_607541, "EngineName", newJString(EngineName))
  add(formData_607541, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607540, "Action", newJString(Action))
  if Filters != nil:
    formData_607541.add "Filters", Filters
  add(query_607540, "Version", newJString(Version))
  result = call_607539.call(nil, query_607540, nil, formData_607541, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_607521(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_607522, base: "/",
    url: url_PostDescribeOptionGroupOptions_607523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_607501 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroupOptions_607503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_607502(path: JsonNode; query: JsonNode;
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
  var valid_607504 = query.getOrDefault("EngineName")
  valid_607504 = validateParameter(valid_607504, JString, required = true,
                                 default = nil)
  if valid_607504 != nil:
    section.add "EngineName", valid_607504
  var valid_607505 = query.getOrDefault("Marker")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "Marker", valid_607505
  var valid_607506 = query.getOrDefault("Action")
  valid_607506 = validateParameter(valid_607506, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607506 != nil:
    section.add "Action", valid_607506
  var valid_607507 = query.getOrDefault("Version")
  valid_607507 = validateParameter(valid_607507, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607507 != nil:
    section.add "Version", valid_607507
  var valid_607508 = query.getOrDefault("Filters")
  valid_607508 = validateParameter(valid_607508, JArray, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "Filters", valid_607508
  var valid_607509 = query.getOrDefault("MaxRecords")
  valid_607509 = validateParameter(valid_607509, JInt, required = false, default = nil)
  if valid_607509 != nil:
    section.add "MaxRecords", valid_607509
  var valid_607510 = query.getOrDefault("MajorEngineVersion")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "MajorEngineVersion", valid_607510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607511 = header.getOrDefault("X-Amz-Signature")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Signature", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Content-Sha256", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Date")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Date", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Credential")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Credential", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Security-Token")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Security-Token", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Algorithm")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Algorithm", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-SignedHeaders", valid_607517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607518: Call_GetDescribeOptionGroupOptions_607501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607518.validator(path, query, header, formData, body)
  let scheme = call_607518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607518.url(scheme.get, call_607518.host, call_607518.base,
                         call_607518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607518, url, valid)

proc call*(call_607519: Call_GetDescribeOptionGroupOptions_607501;
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
  var query_607520 = newJObject()
  add(query_607520, "EngineName", newJString(EngineName))
  add(query_607520, "Marker", newJString(Marker))
  add(query_607520, "Action", newJString(Action))
  add(query_607520, "Version", newJString(Version))
  if Filters != nil:
    query_607520.add "Filters", Filters
  add(query_607520, "MaxRecords", newJInt(MaxRecords))
  add(query_607520, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607519.call(nil, query_607520, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_607501(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_607502, base: "/",
    url: url_GetDescribeOptionGroupOptions_607503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_607563 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroups_607565(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_607564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607566 = query.getOrDefault("Action")
  valid_607566 = validateParameter(valid_607566, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607566 != nil:
    section.add "Action", valid_607566
  var valid_607567 = query.getOrDefault("Version")
  valid_607567 = validateParameter(valid_607567, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607567 != nil:
    section.add "Version", valid_607567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607568 = header.getOrDefault("X-Amz-Signature")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Signature", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Content-Sha256", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Date")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Date", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-Credential")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-Credential", valid_607571
  var valid_607572 = header.getOrDefault("X-Amz-Security-Token")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "X-Amz-Security-Token", valid_607572
  var valid_607573 = header.getOrDefault("X-Amz-Algorithm")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "X-Amz-Algorithm", valid_607573
  var valid_607574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = nil)
  if valid_607574 != nil:
    section.add "X-Amz-SignedHeaders", valid_607574
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607575 = formData.getOrDefault("MaxRecords")
  valid_607575 = validateParameter(valid_607575, JInt, required = false, default = nil)
  if valid_607575 != nil:
    section.add "MaxRecords", valid_607575
  var valid_607576 = formData.getOrDefault("Marker")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "Marker", valid_607576
  var valid_607577 = formData.getOrDefault("EngineName")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "EngineName", valid_607577
  var valid_607578 = formData.getOrDefault("MajorEngineVersion")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "MajorEngineVersion", valid_607578
  var valid_607579 = formData.getOrDefault("OptionGroupName")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "OptionGroupName", valid_607579
  var valid_607580 = formData.getOrDefault("Filters")
  valid_607580 = validateParameter(valid_607580, JArray, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "Filters", valid_607580
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607581: Call_PostDescribeOptionGroups_607563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607581.validator(path, query, header, formData, body)
  let scheme = call_607581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607581.url(scheme.get, call_607581.host, call_607581.base,
                         call_607581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607581, url, valid)

proc call*(call_607582: Call_PostDescribeOptionGroups_607563; MaxRecords: int = 0;
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
  var query_607583 = newJObject()
  var formData_607584 = newJObject()
  add(formData_607584, "MaxRecords", newJInt(MaxRecords))
  add(formData_607584, "Marker", newJString(Marker))
  add(formData_607584, "EngineName", newJString(EngineName))
  add(formData_607584, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607583, "Action", newJString(Action))
  add(formData_607584, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_607584.add "Filters", Filters
  add(query_607583, "Version", newJString(Version))
  result = call_607582.call(nil, query_607583, nil, formData_607584, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_607563(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_607564, base: "/",
    url: url_PostDescribeOptionGroups_607565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_607542 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroups_607544(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_607543(path: JsonNode; query: JsonNode;
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
  var valid_607545 = query.getOrDefault("EngineName")
  valid_607545 = validateParameter(valid_607545, JString, required = false,
                                 default = nil)
  if valid_607545 != nil:
    section.add "EngineName", valid_607545
  var valid_607546 = query.getOrDefault("Marker")
  valid_607546 = validateParameter(valid_607546, JString, required = false,
                                 default = nil)
  if valid_607546 != nil:
    section.add "Marker", valid_607546
  var valid_607547 = query.getOrDefault("Action")
  valid_607547 = validateParameter(valid_607547, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607547 != nil:
    section.add "Action", valid_607547
  var valid_607548 = query.getOrDefault("OptionGroupName")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "OptionGroupName", valid_607548
  var valid_607549 = query.getOrDefault("Version")
  valid_607549 = validateParameter(valid_607549, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607549 != nil:
    section.add "Version", valid_607549
  var valid_607550 = query.getOrDefault("Filters")
  valid_607550 = validateParameter(valid_607550, JArray, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "Filters", valid_607550
  var valid_607551 = query.getOrDefault("MaxRecords")
  valid_607551 = validateParameter(valid_607551, JInt, required = false, default = nil)
  if valid_607551 != nil:
    section.add "MaxRecords", valid_607551
  var valid_607552 = query.getOrDefault("MajorEngineVersion")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "MajorEngineVersion", valid_607552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607553 = header.getOrDefault("X-Amz-Signature")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Signature", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-Content-Sha256", valid_607554
  var valid_607555 = header.getOrDefault("X-Amz-Date")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-Date", valid_607555
  var valid_607556 = header.getOrDefault("X-Amz-Credential")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "X-Amz-Credential", valid_607556
  var valid_607557 = header.getOrDefault("X-Amz-Security-Token")
  valid_607557 = validateParameter(valid_607557, JString, required = false,
                                 default = nil)
  if valid_607557 != nil:
    section.add "X-Amz-Security-Token", valid_607557
  var valid_607558 = header.getOrDefault("X-Amz-Algorithm")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-Algorithm", valid_607558
  var valid_607559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607559 = validateParameter(valid_607559, JString, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "X-Amz-SignedHeaders", valid_607559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607560: Call_GetDescribeOptionGroups_607542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607560.validator(path, query, header, formData, body)
  let scheme = call_607560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607560.url(scheme.get, call_607560.host, call_607560.base,
                         call_607560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607560, url, valid)

proc call*(call_607561: Call_GetDescribeOptionGroups_607542;
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
  var query_607562 = newJObject()
  add(query_607562, "EngineName", newJString(EngineName))
  add(query_607562, "Marker", newJString(Marker))
  add(query_607562, "Action", newJString(Action))
  add(query_607562, "OptionGroupName", newJString(OptionGroupName))
  add(query_607562, "Version", newJString(Version))
  if Filters != nil:
    query_607562.add "Filters", Filters
  add(query_607562, "MaxRecords", newJInt(MaxRecords))
  add(query_607562, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607561.call(nil, query_607562, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_607542(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_607543, base: "/",
    url: url_GetDescribeOptionGroups_607544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_607608 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOrderableDBInstanceOptions_607610(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_607609(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607611 = query.getOrDefault("Action")
  valid_607611 = validateParameter(valid_607611, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607611 != nil:
    section.add "Action", valid_607611
  var valid_607612 = query.getOrDefault("Version")
  valid_607612 = validateParameter(valid_607612, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607612 != nil:
    section.add "Version", valid_607612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607613 = header.getOrDefault("X-Amz-Signature")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-Signature", valid_607613
  var valid_607614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607614 = validateParameter(valid_607614, JString, required = false,
                                 default = nil)
  if valid_607614 != nil:
    section.add "X-Amz-Content-Sha256", valid_607614
  var valid_607615 = header.getOrDefault("X-Amz-Date")
  valid_607615 = validateParameter(valid_607615, JString, required = false,
                                 default = nil)
  if valid_607615 != nil:
    section.add "X-Amz-Date", valid_607615
  var valid_607616 = header.getOrDefault("X-Amz-Credential")
  valid_607616 = validateParameter(valid_607616, JString, required = false,
                                 default = nil)
  if valid_607616 != nil:
    section.add "X-Amz-Credential", valid_607616
  var valid_607617 = header.getOrDefault("X-Amz-Security-Token")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "X-Amz-Security-Token", valid_607617
  var valid_607618 = header.getOrDefault("X-Amz-Algorithm")
  valid_607618 = validateParameter(valid_607618, JString, required = false,
                                 default = nil)
  if valid_607618 != nil:
    section.add "X-Amz-Algorithm", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-SignedHeaders", valid_607619
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
  var valid_607620 = formData.getOrDefault("DBInstanceClass")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "DBInstanceClass", valid_607620
  var valid_607621 = formData.getOrDefault("MaxRecords")
  valid_607621 = validateParameter(valid_607621, JInt, required = false, default = nil)
  if valid_607621 != nil:
    section.add "MaxRecords", valid_607621
  var valid_607622 = formData.getOrDefault("EngineVersion")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "EngineVersion", valid_607622
  var valid_607623 = formData.getOrDefault("Marker")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "Marker", valid_607623
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607624 = formData.getOrDefault("Engine")
  valid_607624 = validateParameter(valid_607624, JString, required = true,
                                 default = nil)
  if valid_607624 != nil:
    section.add "Engine", valid_607624
  var valid_607625 = formData.getOrDefault("Vpc")
  valid_607625 = validateParameter(valid_607625, JBool, required = false, default = nil)
  if valid_607625 != nil:
    section.add "Vpc", valid_607625
  var valid_607626 = formData.getOrDefault("LicenseModel")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "LicenseModel", valid_607626
  var valid_607627 = formData.getOrDefault("Filters")
  valid_607627 = validateParameter(valid_607627, JArray, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "Filters", valid_607627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607628: Call_PostDescribeOrderableDBInstanceOptions_607608;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607628.validator(path, query, header, formData, body)
  let scheme = call_607628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607628.url(scheme.get, call_607628.host, call_607628.base,
                         call_607628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607628, url, valid)

proc call*(call_607629: Call_PostDescribeOrderableDBInstanceOptions_607608;
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
  var query_607630 = newJObject()
  var formData_607631 = newJObject()
  add(formData_607631, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607631, "MaxRecords", newJInt(MaxRecords))
  add(formData_607631, "EngineVersion", newJString(EngineVersion))
  add(formData_607631, "Marker", newJString(Marker))
  add(formData_607631, "Engine", newJString(Engine))
  add(formData_607631, "Vpc", newJBool(Vpc))
  add(query_607630, "Action", newJString(Action))
  add(formData_607631, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_607631.add "Filters", Filters
  add(query_607630, "Version", newJString(Version))
  result = call_607629.call(nil, query_607630, nil, formData_607631, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_607608(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_607609, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_607610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_607585 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOrderableDBInstanceOptions_607587(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_607586(path: JsonNode;
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
  var valid_607588 = query.getOrDefault("Marker")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "Marker", valid_607588
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607589 = query.getOrDefault("Engine")
  valid_607589 = validateParameter(valid_607589, JString, required = true,
                                 default = nil)
  if valid_607589 != nil:
    section.add "Engine", valid_607589
  var valid_607590 = query.getOrDefault("LicenseModel")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "LicenseModel", valid_607590
  var valid_607591 = query.getOrDefault("Vpc")
  valid_607591 = validateParameter(valid_607591, JBool, required = false, default = nil)
  if valid_607591 != nil:
    section.add "Vpc", valid_607591
  var valid_607592 = query.getOrDefault("EngineVersion")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "EngineVersion", valid_607592
  var valid_607593 = query.getOrDefault("Action")
  valid_607593 = validateParameter(valid_607593, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607593 != nil:
    section.add "Action", valid_607593
  var valid_607594 = query.getOrDefault("Version")
  valid_607594 = validateParameter(valid_607594, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607594 != nil:
    section.add "Version", valid_607594
  var valid_607595 = query.getOrDefault("DBInstanceClass")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "DBInstanceClass", valid_607595
  var valid_607596 = query.getOrDefault("Filters")
  valid_607596 = validateParameter(valid_607596, JArray, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "Filters", valid_607596
  var valid_607597 = query.getOrDefault("MaxRecords")
  valid_607597 = validateParameter(valid_607597, JInt, required = false, default = nil)
  if valid_607597 != nil:
    section.add "MaxRecords", valid_607597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607598 = header.getOrDefault("X-Amz-Signature")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "X-Amz-Signature", valid_607598
  var valid_607599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "X-Amz-Content-Sha256", valid_607599
  var valid_607600 = header.getOrDefault("X-Amz-Date")
  valid_607600 = validateParameter(valid_607600, JString, required = false,
                                 default = nil)
  if valid_607600 != nil:
    section.add "X-Amz-Date", valid_607600
  var valid_607601 = header.getOrDefault("X-Amz-Credential")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "X-Amz-Credential", valid_607601
  var valid_607602 = header.getOrDefault("X-Amz-Security-Token")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Security-Token", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Algorithm")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Algorithm", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-SignedHeaders", valid_607604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607605: Call_GetDescribeOrderableDBInstanceOptions_607585;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607605.validator(path, query, header, formData, body)
  let scheme = call_607605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607605.url(scheme.get, call_607605.host, call_607605.base,
                         call_607605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607605, url, valid)

proc call*(call_607606: Call_GetDescribeOrderableDBInstanceOptions_607585;
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
  var query_607607 = newJObject()
  add(query_607607, "Marker", newJString(Marker))
  add(query_607607, "Engine", newJString(Engine))
  add(query_607607, "LicenseModel", newJString(LicenseModel))
  add(query_607607, "Vpc", newJBool(Vpc))
  add(query_607607, "EngineVersion", newJString(EngineVersion))
  add(query_607607, "Action", newJString(Action))
  add(query_607607, "Version", newJString(Version))
  add(query_607607, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607607.add "Filters", Filters
  add(query_607607, "MaxRecords", newJInt(MaxRecords))
  result = call_607606.call(nil, query_607607, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_607585(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_607586, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_607587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_607657 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstances_607659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_607658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607660 = query.getOrDefault("Action")
  valid_607660 = validateParameter(valid_607660, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607660 != nil:
    section.add "Action", valid_607660
  var valid_607661 = query.getOrDefault("Version")
  valid_607661 = validateParameter(valid_607661, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607661 != nil:
    section.add "Version", valid_607661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607662 = header.getOrDefault("X-Amz-Signature")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Signature", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Content-Sha256", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Date")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Date", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-Credential")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Credential", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Security-Token")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Security-Token", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Algorithm")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Algorithm", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-SignedHeaders", valid_607668
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
  var valid_607669 = formData.getOrDefault("DBInstanceClass")
  valid_607669 = validateParameter(valid_607669, JString, required = false,
                                 default = nil)
  if valid_607669 != nil:
    section.add "DBInstanceClass", valid_607669
  var valid_607670 = formData.getOrDefault("MultiAZ")
  valid_607670 = validateParameter(valid_607670, JBool, required = false, default = nil)
  if valid_607670 != nil:
    section.add "MultiAZ", valid_607670
  var valid_607671 = formData.getOrDefault("MaxRecords")
  valid_607671 = validateParameter(valid_607671, JInt, required = false, default = nil)
  if valid_607671 != nil:
    section.add "MaxRecords", valid_607671
  var valid_607672 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "ReservedDBInstanceId", valid_607672
  var valid_607673 = formData.getOrDefault("Marker")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "Marker", valid_607673
  var valid_607674 = formData.getOrDefault("Duration")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "Duration", valid_607674
  var valid_607675 = formData.getOrDefault("OfferingType")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "OfferingType", valid_607675
  var valid_607676 = formData.getOrDefault("ProductDescription")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "ProductDescription", valid_607676
  var valid_607677 = formData.getOrDefault("Filters")
  valid_607677 = validateParameter(valid_607677, JArray, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "Filters", valid_607677
  var valid_607678 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607678
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607679: Call_PostDescribeReservedDBInstances_607657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607679.validator(path, query, header, formData, body)
  let scheme = call_607679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607679.url(scheme.get, call_607679.host, call_607679.base,
                         call_607679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607679, url, valid)

proc call*(call_607680: Call_PostDescribeReservedDBInstances_607657;
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
  var query_607681 = newJObject()
  var formData_607682 = newJObject()
  add(formData_607682, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607682, "MultiAZ", newJBool(MultiAZ))
  add(formData_607682, "MaxRecords", newJInt(MaxRecords))
  add(formData_607682, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_607682, "Marker", newJString(Marker))
  add(formData_607682, "Duration", newJString(Duration))
  add(formData_607682, "OfferingType", newJString(OfferingType))
  add(formData_607682, "ProductDescription", newJString(ProductDescription))
  add(query_607681, "Action", newJString(Action))
  if Filters != nil:
    formData_607682.add "Filters", Filters
  add(formData_607682, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607681, "Version", newJString(Version))
  result = call_607680.call(nil, query_607681, nil, formData_607682, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_607657(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_607658, base: "/",
    url: url_PostDescribeReservedDBInstances_607659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_607632 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstances_607634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_607633(path: JsonNode;
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
  var valid_607635 = query.getOrDefault("Marker")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "Marker", valid_607635
  var valid_607636 = query.getOrDefault("ProductDescription")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "ProductDescription", valid_607636
  var valid_607637 = query.getOrDefault("OfferingType")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "OfferingType", valid_607637
  var valid_607638 = query.getOrDefault("ReservedDBInstanceId")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "ReservedDBInstanceId", valid_607638
  var valid_607639 = query.getOrDefault("Action")
  valid_607639 = validateParameter(valid_607639, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607639 != nil:
    section.add "Action", valid_607639
  var valid_607640 = query.getOrDefault("MultiAZ")
  valid_607640 = validateParameter(valid_607640, JBool, required = false, default = nil)
  if valid_607640 != nil:
    section.add "MultiAZ", valid_607640
  var valid_607641 = query.getOrDefault("Duration")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "Duration", valid_607641
  var valid_607642 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607642
  var valid_607643 = query.getOrDefault("Version")
  valid_607643 = validateParameter(valid_607643, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607643 != nil:
    section.add "Version", valid_607643
  var valid_607644 = query.getOrDefault("DBInstanceClass")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "DBInstanceClass", valid_607644
  var valid_607645 = query.getOrDefault("Filters")
  valid_607645 = validateParameter(valid_607645, JArray, required = false,
                                 default = nil)
  if valid_607645 != nil:
    section.add "Filters", valid_607645
  var valid_607646 = query.getOrDefault("MaxRecords")
  valid_607646 = validateParameter(valid_607646, JInt, required = false, default = nil)
  if valid_607646 != nil:
    section.add "MaxRecords", valid_607646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607647 = header.getOrDefault("X-Amz-Signature")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Signature", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-Content-Sha256", valid_607648
  var valid_607649 = header.getOrDefault("X-Amz-Date")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "X-Amz-Date", valid_607649
  var valid_607650 = header.getOrDefault("X-Amz-Credential")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-Credential", valid_607650
  var valid_607651 = header.getOrDefault("X-Amz-Security-Token")
  valid_607651 = validateParameter(valid_607651, JString, required = false,
                                 default = nil)
  if valid_607651 != nil:
    section.add "X-Amz-Security-Token", valid_607651
  var valid_607652 = header.getOrDefault("X-Amz-Algorithm")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "X-Amz-Algorithm", valid_607652
  var valid_607653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "X-Amz-SignedHeaders", valid_607653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607654: Call_GetDescribeReservedDBInstances_607632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607654.validator(path, query, header, formData, body)
  let scheme = call_607654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607654.url(scheme.get, call_607654.host, call_607654.base,
                         call_607654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607654, url, valid)

proc call*(call_607655: Call_GetDescribeReservedDBInstances_607632;
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
  var query_607656 = newJObject()
  add(query_607656, "Marker", newJString(Marker))
  add(query_607656, "ProductDescription", newJString(ProductDescription))
  add(query_607656, "OfferingType", newJString(OfferingType))
  add(query_607656, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607656, "Action", newJString(Action))
  add(query_607656, "MultiAZ", newJBool(MultiAZ))
  add(query_607656, "Duration", newJString(Duration))
  add(query_607656, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607656, "Version", newJString(Version))
  add(query_607656, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607656.add "Filters", Filters
  add(query_607656, "MaxRecords", newJInt(MaxRecords))
  result = call_607655.call(nil, query_607656, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_607632(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_607633, base: "/",
    url: url_GetDescribeReservedDBInstances_607634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_607707 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstancesOfferings_607709(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_607708(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607710 = query.getOrDefault("Action")
  valid_607710 = validateParameter(valid_607710, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607710 != nil:
    section.add "Action", valid_607710
  var valid_607711 = query.getOrDefault("Version")
  valid_607711 = validateParameter(valid_607711, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607711 != nil:
    section.add "Version", valid_607711
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607712 = header.getOrDefault("X-Amz-Signature")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Signature", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Content-Sha256", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Date")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Date", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-Credential")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-Credential", valid_607715
  var valid_607716 = header.getOrDefault("X-Amz-Security-Token")
  valid_607716 = validateParameter(valid_607716, JString, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "X-Amz-Security-Token", valid_607716
  var valid_607717 = header.getOrDefault("X-Amz-Algorithm")
  valid_607717 = validateParameter(valid_607717, JString, required = false,
                                 default = nil)
  if valid_607717 != nil:
    section.add "X-Amz-Algorithm", valid_607717
  var valid_607718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607718 = validateParameter(valid_607718, JString, required = false,
                                 default = nil)
  if valid_607718 != nil:
    section.add "X-Amz-SignedHeaders", valid_607718
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
  var valid_607719 = formData.getOrDefault("DBInstanceClass")
  valid_607719 = validateParameter(valid_607719, JString, required = false,
                                 default = nil)
  if valid_607719 != nil:
    section.add "DBInstanceClass", valid_607719
  var valid_607720 = formData.getOrDefault("MultiAZ")
  valid_607720 = validateParameter(valid_607720, JBool, required = false, default = nil)
  if valid_607720 != nil:
    section.add "MultiAZ", valid_607720
  var valid_607721 = formData.getOrDefault("MaxRecords")
  valid_607721 = validateParameter(valid_607721, JInt, required = false, default = nil)
  if valid_607721 != nil:
    section.add "MaxRecords", valid_607721
  var valid_607722 = formData.getOrDefault("Marker")
  valid_607722 = validateParameter(valid_607722, JString, required = false,
                                 default = nil)
  if valid_607722 != nil:
    section.add "Marker", valid_607722
  var valid_607723 = formData.getOrDefault("Duration")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "Duration", valid_607723
  var valid_607724 = formData.getOrDefault("OfferingType")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "OfferingType", valid_607724
  var valid_607725 = formData.getOrDefault("ProductDescription")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "ProductDescription", valid_607725
  var valid_607726 = formData.getOrDefault("Filters")
  valid_607726 = validateParameter(valid_607726, JArray, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "Filters", valid_607726
  var valid_607727 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607727
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607728: Call_PostDescribeReservedDBInstancesOfferings_607707;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607728.validator(path, query, header, formData, body)
  let scheme = call_607728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607728.url(scheme.get, call_607728.host, call_607728.base,
                         call_607728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607728, url, valid)

proc call*(call_607729: Call_PostDescribeReservedDBInstancesOfferings_607707;
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
  var query_607730 = newJObject()
  var formData_607731 = newJObject()
  add(formData_607731, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607731, "MultiAZ", newJBool(MultiAZ))
  add(formData_607731, "MaxRecords", newJInt(MaxRecords))
  add(formData_607731, "Marker", newJString(Marker))
  add(formData_607731, "Duration", newJString(Duration))
  add(formData_607731, "OfferingType", newJString(OfferingType))
  add(formData_607731, "ProductDescription", newJString(ProductDescription))
  add(query_607730, "Action", newJString(Action))
  if Filters != nil:
    formData_607731.add "Filters", Filters
  add(formData_607731, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607730, "Version", newJString(Version))
  result = call_607729.call(nil, query_607730, nil, formData_607731, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_607707(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_607708,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_607709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_607683 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstancesOfferings_607685(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_607684(path: JsonNode;
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
  var valid_607686 = query.getOrDefault("Marker")
  valid_607686 = validateParameter(valid_607686, JString, required = false,
                                 default = nil)
  if valid_607686 != nil:
    section.add "Marker", valid_607686
  var valid_607687 = query.getOrDefault("ProductDescription")
  valid_607687 = validateParameter(valid_607687, JString, required = false,
                                 default = nil)
  if valid_607687 != nil:
    section.add "ProductDescription", valid_607687
  var valid_607688 = query.getOrDefault("OfferingType")
  valid_607688 = validateParameter(valid_607688, JString, required = false,
                                 default = nil)
  if valid_607688 != nil:
    section.add "OfferingType", valid_607688
  var valid_607689 = query.getOrDefault("Action")
  valid_607689 = validateParameter(valid_607689, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607689 != nil:
    section.add "Action", valid_607689
  var valid_607690 = query.getOrDefault("MultiAZ")
  valid_607690 = validateParameter(valid_607690, JBool, required = false, default = nil)
  if valid_607690 != nil:
    section.add "MultiAZ", valid_607690
  var valid_607691 = query.getOrDefault("Duration")
  valid_607691 = validateParameter(valid_607691, JString, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "Duration", valid_607691
  var valid_607692 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607692
  var valid_607693 = query.getOrDefault("Version")
  valid_607693 = validateParameter(valid_607693, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607693 != nil:
    section.add "Version", valid_607693
  var valid_607694 = query.getOrDefault("DBInstanceClass")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "DBInstanceClass", valid_607694
  var valid_607695 = query.getOrDefault("Filters")
  valid_607695 = validateParameter(valid_607695, JArray, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "Filters", valid_607695
  var valid_607696 = query.getOrDefault("MaxRecords")
  valid_607696 = validateParameter(valid_607696, JInt, required = false, default = nil)
  if valid_607696 != nil:
    section.add "MaxRecords", valid_607696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607697 = header.getOrDefault("X-Amz-Signature")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Signature", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Content-Sha256", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Date")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Date", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Credential")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Credential", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-Security-Token")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-Security-Token", valid_607701
  var valid_607702 = header.getOrDefault("X-Amz-Algorithm")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Algorithm", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-SignedHeaders", valid_607703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607704: Call_GetDescribeReservedDBInstancesOfferings_607683;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607704.validator(path, query, header, formData, body)
  let scheme = call_607704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607704.url(scheme.get, call_607704.host, call_607704.base,
                         call_607704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607704, url, valid)

proc call*(call_607705: Call_GetDescribeReservedDBInstancesOfferings_607683;
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
  var query_607706 = newJObject()
  add(query_607706, "Marker", newJString(Marker))
  add(query_607706, "ProductDescription", newJString(ProductDescription))
  add(query_607706, "OfferingType", newJString(OfferingType))
  add(query_607706, "Action", newJString(Action))
  add(query_607706, "MultiAZ", newJBool(MultiAZ))
  add(query_607706, "Duration", newJString(Duration))
  add(query_607706, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607706, "Version", newJString(Version))
  add(query_607706, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607706.add "Filters", Filters
  add(query_607706, "MaxRecords", newJInt(MaxRecords))
  result = call_607705.call(nil, query_607706, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_607683(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_607684, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_607685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_607751 = ref object of OpenApiRestCall_605573
proc url_PostDownloadDBLogFilePortion_607753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_607752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607754 = query.getOrDefault("Action")
  valid_607754 = validateParameter(valid_607754, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607754 != nil:
    section.add "Action", valid_607754
  var valid_607755 = query.getOrDefault("Version")
  valid_607755 = validateParameter(valid_607755, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607755 != nil:
    section.add "Version", valid_607755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607756 = header.getOrDefault("X-Amz-Signature")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Signature", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Content-Sha256", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Date")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Date", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Credential")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Credential", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Security-Token")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Security-Token", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-Algorithm")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-Algorithm", valid_607761
  var valid_607762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607762 = validateParameter(valid_607762, JString, required = false,
                                 default = nil)
  if valid_607762 != nil:
    section.add "X-Amz-SignedHeaders", valid_607762
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607763 = formData.getOrDefault("NumberOfLines")
  valid_607763 = validateParameter(valid_607763, JInt, required = false, default = nil)
  if valid_607763 != nil:
    section.add "NumberOfLines", valid_607763
  var valid_607764 = formData.getOrDefault("Marker")
  valid_607764 = validateParameter(valid_607764, JString, required = false,
                                 default = nil)
  if valid_607764 != nil:
    section.add "Marker", valid_607764
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_607765 = formData.getOrDefault("LogFileName")
  valid_607765 = validateParameter(valid_607765, JString, required = true,
                                 default = nil)
  if valid_607765 != nil:
    section.add "LogFileName", valid_607765
  var valid_607766 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607766 = validateParameter(valid_607766, JString, required = true,
                                 default = nil)
  if valid_607766 != nil:
    section.add "DBInstanceIdentifier", valid_607766
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607767: Call_PostDownloadDBLogFilePortion_607751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607767.validator(path, query, header, formData, body)
  let scheme = call_607767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607767.url(scheme.get, call_607767.host, call_607767.base,
                         call_607767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607767, url, valid)

proc call*(call_607768: Call_PostDownloadDBLogFilePortion_607751;
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
  var query_607769 = newJObject()
  var formData_607770 = newJObject()
  add(formData_607770, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_607770, "Marker", newJString(Marker))
  add(formData_607770, "LogFileName", newJString(LogFileName))
  add(formData_607770, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607769, "Action", newJString(Action))
  add(query_607769, "Version", newJString(Version))
  result = call_607768.call(nil, query_607769, nil, formData_607770, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_607751(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_607752, base: "/",
    url: url_PostDownloadDBLogFilePortion_607753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_607732 = ref object of OpenApiRestCall_605573
proc url_GetDownloadDBLogFilePortion_607734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_607733(path: JsonNode; query: JsonNode;
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
  var valid_607735 = query.getOrDefault("Marker")
  valid_607735 = validateParameter(valid_607735, JString, required = false,
                                 default = nil)
  if valid_607735 != nil:
    section.add "Marker", valid_607735
  var valid_607736 = query.getOrDefault("NumberOfLines")
  valid_607736 = validateParameter(valid_607736, JInt, required = false, default = nil)
  if valid_607736 != nil:
    section.add "NumberOfLines", valid_607736
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607737 = query.getOrDefault("DBInstanceIdentifier")
  valid_607737 = validateParameter(valid_607737, JString, required = true,
                                 default = nil)
  if valid_607737 != nil:
    section.add "DBInstanceIdentifier", valid_607737
  var valid_607738 = query.getOrDefault("Action")
  valid_607738 = validateParameter(valid_607738, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607738 != nil:
    section.add "Action", valid_607738
  var valid_607739 = query.getOrDefault("LogFileName")
  valid_607739 = validateParameter(valid_607739, JString, required = true,
                                 default = nil)
  if valid_607739 != nil:
    section.add "LogFileName", valid_607739
  var valid_607740 = query.getOrDefault("Version")
  valid_607740 = validateParameter(valid_607740, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607740 != nil:
    section.add "Version", valid_607740
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607741 = header.getOrDefault("X-Amz-Signature")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Signature", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Content-Sha256", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Date")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Date", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Credential")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Credential", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Security-Token")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Security-Token", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-Algorithm")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Algorithm", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-SignedHeaders", valid_607747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607748: Call_GetDownloadDBLogFilePortion_607732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607748.validator(path, query, header, formData, body)
  let scheme = call_607748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607748.url(scheme.get, call_607748.host, call_607748.base,
                         call_607748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607748, url, valid)

proc call*(call_607749: Call_GetDownloadDBLogFilePortion_607732;
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
  var query_607750 = newJObject()
  add(query_607750, "Marker", newJString(Marker))
  add(query_607750, "NumberOfLines", newJInt(NumberOfLines))
  add(query_607750, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607750, "Action", newJString(Action))
  add(query_607750, "LogFileName", newJString(LogFileName))
  add(query_607750, "Version", newJString(Version))
  result = call_607749.call(nil, query_607750, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_607732(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_607733, base: "/",
    url: url_GetDownloadDBLogFilePortion_607734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607788 = ref object of OpenApiRestCall_605573
proc url_PostListTagsForResource_607790(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_607789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607791 = query.getOrDefault("Action")
  valid_607791 = validateParameter(valid_607791, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607791 != nil:
    section.add "Action", valid_607791
  var valid_607792 = query.getOrDefault("Version")
  valid_607792 = validateParameter(valid_607792, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607792 != nil:
    section.add "Version", valid_607792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607793 = header.getOrDefault("X-Amz-Signature")
  valid_607793 = validateParameter(valid_607793, JString, required = false,
                                 default = nil)
  if valid_607793 != nil:
    section.add "X-Amz-Signature", valid_607793
  var valid_607794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607794 = validateParameter(valid_607794, JString, required = false,
                                 default = nil)
  if valid_607794 != nil:
    section.add "X-Amz-Content-Sha256", valid_607794
  var valid_607795 = header.getOrDefault("X-Amz-Date")
  valid_607795 = validateParameter(valid_607795, JString, required = false,
                                 default = nil)
  if valid_607795 != nil:
    section.add "X-Amz-Date", valid_607795
  var valid_607796 = header.getOrDefault("X-Amz-Credential")
  valid_607796 = validateParameter(valid_607796, JString, required = false,
                                 default = nil)
  if valid_607796 != nil:
    section.add "X-Amz-Credential", valid_607796
  var valid_607797 = header.getOrDefault("X-Amz-Security-Token")
  valid_607797 = validateParameter(valid_607797, JString, required = false,
                                 default = nil)
  if valid_607797 != nil:
    section.add "X-Amz-Security-Token", valid_607797
  var valid_607798 = header.getOrDefault("X-Amz-Algorithm")
  valid_607798 = validateParameter(valid_607798, JString, required = false,
                                 default = nil)
  if valid_607798 != nil:
    section.add "X-Amz-Algorithm", valid_607798
  var valid_607799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607799 = validateParameter(valid_607799, JString, required = false,
                                 default = nil)
  if valid_607799 != nil:
    section.add "X-Amz-SignedHeaders", valid_607799
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_607800 = formData.getOrDefault("Filters")
  valid_607800 = validateParameter(valid_607800, JArray, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "Filters", valid_607800
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_607801 = formData.getOrDefault("ResourceName")
  valid_607801 = validateParameter(valid_607801, JString, required = true,
                                 default = nil)
  if valid_607801 != nil:
    section.add "ResourceName", valid_607801
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607802: Call_PostListTagsForResource_607788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607802.validator(path, query, header, formData, body)
  let scheme = call_607802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607802.url(scheme.get, call_607802.host, call_607802.base,
                         call_607802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607802, url, valid)

proc call*(call_607803: Call_PostListTagsForResource_607788; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_607804 = newJObject()
  var formData_607805 = newJObject()
  add(query_607804, "Action", newJString(Action))
  if Filters != nil:
    formData_607805.add "Filters", Filters
  add(query_607804, "Version", newJString(Version))
  add(formData_607805, "ResourceName", newJString(ResourceName))
  result = call_607803.call(nil, query_607804, nil, formData_607805, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607788(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607789, base: "/",
    url: url_PostListTagsForResource_607790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607771 = ref object of OpenApiRestCall_605573
proc url_GetListTagsForResource_607773(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_607772(path: JsonNode; query: JsonNode;
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
  var valid_607774 = query.getOrDefault("ResourceName")
  valid_607774 = validateParameter(valid_607774, JString, required = true,
                                 default = nil)
  if valid_607774 != nil:
    section.add "ResourceName", valid_607774
  var valid_607775 = query.getOrDefault("Action")
  valid_607775 = validateParameter(valid_607775, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607775 != nil:
    section.add "Action", valid_607775
  var valid_607776 = query.getOrDefault("Version")
  valid_607776 = validateParameter(valid_607776, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607776 != nil:
    section.add "Version", valid_607776
  var valid_607777 = query.getOrDefault("Filters")
  valid_607777 = validateParameter(valid_607777, JArray, required = false,
                                 default = nil)
  if valid_607777 != nil:
    section.add "Filters", valid_607777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607778 = header.getOrDefault("X-Amz-Signature")
  valid_607778 = validateParameter(valid_607778, JString, required = false,
                                 default = nil)
  if valid_607778 != nil:
    section.add "X-Amz-Signature", valid_607778
  var valid_607779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "X-Amz-Content-Sha256", valid_607779
  var valid_607780 = header.getOrDefault("X-Amz-Date")
  valid_607780 = validateParameter(valid_607780, JString, required = false,
                                 default = nil)
  if valid_607780 != nil:
    section.add "X-Amz-Date", valid_607780
  var valid_607781 = header.getOrDefault("X-Amz-Credential")
  valid_607781 = validateParameter(valid_607781, JString, required = false,
                                 default = nil)
  if valid_607781 != nil:
    section.add "X-Amz-Credential", valid_607781
  var valid_607782 = header.getOrDefault("X-Amz-Security-Token")
  valid_607782 = validateParameter(valid_607782, JString, required = false,
                                 default = nil)
  if valid_607782 != nil:
    section.add "X-Amz-Security-Token", valid_607782
  var valid_607783 = header.getOrDefault("X-Amz-Algorithm")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = nil)
  if valid_607783 != nil:
    section.add "X-Amz-Algorithm", valid_607783
  var valid_607784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "X-Amz-SignedHeaders", valid_607784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607785: Call_GetListTagsForResource_607771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607785.validator(path, query, header, formData, body)
  let scheme = call_607785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607785.url(scheme.get, call_607785.host, call_607785.base,
                         call_607785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607785, url, valid)

proc call*(call_607786: Call_GetListTagsForResource_607771; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_607787 = newJObject()
  add(query_607787, "ResourceName", newJString(ResourceName))
  add(query_607787, "Action", newJString(Action))
  add(query_607787, "Version", newJString(Version))
  if Filters != nil:
    query_607787.add "Filters", Filters
  result = call_607786.call(nil, query_607787, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607771(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607772, base: "/",
    url: url_GetListTagsForResource_607773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_607842 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBInstance_607844(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_607843(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607845 = query.getOrDefault("Action")
  valid_607845 = validateParameter(valid_607845, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607845 != nil:
    section.add "Action", valid_607845
  var valid_607846 = query.getOrDefault("Version")
  valid_607846 = validateParameter(valid_607846, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607846 != nil:
    section.add "Version", valid_607846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607847 = header.getOrDefault("X-Amz-Signature")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Signature", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Content-Sha256", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-Date")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Date", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Credential")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Credential", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-Security-Token")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-Security-Token", valid_607851
  var valid_607852 = header.getOrDefault("X-Amz-Algorithm")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-Algorithm", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-SignedHeaders", valid_607853
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
  var valid_607854 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "PreferredMaintenanceWindow", valid_607854
  var valid_607855 = formData.getOrDefault("DBInstanceClass")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "DBInstanceClass", valid_607855
  var valid_607856 = formData.getOrDefault("PreferredBackupWindow")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "PreferredBackupWindow", valid_607856
  var valid_607857 = formData.getOrDefault("MasterUserPassword")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "MasterUserPassword", valid_607857
  var valid_607858 = formData.getOrDefault("MultiAZ")
  valid_607858 = validateParameter(valid_607858, JBool, required = false, default = nil)
  if valid_607858 != nil:
    section.add "MultiAZ", valid_607858
  var valid_607859 = formData.getOrDefault("DBParameterGroupName")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "DBParameterGroupName", valid_607859
  var valid_607860 = formData.getOrDefault("EngineVersion")
  valid_607860 = validateParameter(valid_607860, JString, required = false,
                                 default = nil)
  if valid_607860 != nil:
    section.add "EngineVersion", valid_607860
  var valid_607861 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607861 = validateParameter(valid_607861, JArray, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "VpcSecurityGroupIds", valid_607861
  var valid_607862 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607862 = validateParameter(valid_607862, JInt, required = false, default = nil)
  if valid_607862 != nil:
    section.add "BackupRetentionPeriod", valid_607862
  var valid_607863 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_607863 = validateParameter(valid_607863, JBool, required = false, default = nil)
  if valid_607863 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607863
  var valid_607864 = formData.getOrDefault("TdeCredentialPassword")
  valid_607864 = validateParameter(valid_607864, JString, required = false,
                                 default = nil)
  if valid_607864 != nil:
    section.add "TdeCredentialPassword", valid_607864
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607865 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607865 = validateParameter(valid_607865, JString, required = true,
                                 default = nil)
  if valid_607865 != nil:
    section.add "DBInstanceIdentifier", valid_607865
  var valid_607866 = formData.getOrDefault("ApplyImmediately")
  valid_607866 = validateParameter(valid_607866, JBool, required = false, default = nil)
  if valid_607866 != nil:
    section.add "ApplyImmediately", valid_607866
  var valid_607867 = formData.getOrDefault("Iops")
  valid_607867 = validateParameter(valid_607867, JInt, required = false, default = nil)
  if valid_607867 != nil:
    section.add "Iops", valid_607867
  var valid_607868 = formData.getOrDefault("TdeCredentialArn")
  valid_607868 = validateParameter(valid_607868, JString, required = false,
                                 default = nil)
  if valid_607868 != nil:
    section.add "TdeCredentialArn", valid_607868
  var valid_607869 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_607869 = validateParameter(valid_607869, JBool, required = false, default = nil)
  if valid_607869 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607869
  var valid_607870 = formData.getOrDefault("OptionGroupName")
  valid_607870 = validateParameter(valid_607870, JString, required = false,
                                 default = nil)
  if valid_607870 != nil:
    section.add "OptionGroupName", valid_607870
  var valid_607871 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "NewDBInstanceIdentifier", valid_607871
  var valid_607872 = formData.getOrDefault("DBSecurityGroups")
  valid_607872 = validateParameter(valid_607872, JArray, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "DBSecurityGroups", valid_607872
  var valid_607873 = formData.getOrDefault("StorageType")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "StorageType", valid_607873
  var valid_607874 = formData.getOrDefault("AllocatedStorage")
  valid_607874 = validateParameter(valid_607874, JInt, required = false, default = nil)
  if valid_607874 != nil:
    section.add "AllocatedStorage", valid_607874
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607875: Call_PostModifyDBInstance_607842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607875.validator(path, query, header, formData, body)
  let scheme = call_607875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607875.url(scheme.get, call_607875.host, call_607875.base,
                         call_607875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607875, url, valid)

proc call*(call_607876: Call_PostModifyDBInstance_607842;
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
  var query_607877 = newJObject()
  var formData_607878 = newJObject()
  add(formData_607878, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607878, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607878, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607878, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_607878, "MultiAZ", newJBool(MultiAZ))
  add(formData_607878, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607878, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607878.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607878, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607878, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_607878, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_607878, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607878, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_607878, "Iops", newJInt(Iops))
  add(formData_607878, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_607877, "Action", newJString(Action))
  add(formData_607878, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_607878, "OptionGroupName", newJString(OptionGroupName))
  add(formData_607878, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_607877, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_607878.add "DBSecurityGroups", DBSecurityGroups
  add(formData_607878, "StorageType", newJString(StorageType))
  add(formData_607878, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_607876.call(nil, query_607877, nil, formData_607878, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_607842(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_607843, base: "/",
    url: url_PostModifyDBInstance_607844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_607806 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBInstance_607808(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_607807(path: JsonNode; query: JsonNode;
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
  var valid_607809 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "NewDBInstanceIdentifier", valid_607809
  var valid_607810 = query.getOrDefault("TdeCredentialPassword")
  valid_607810 = validateParameter(valid_607810, JString, required = false,
                                 default = nil)
  if valid_607810 != nil:
    section.add "TdeCredentialPassword", valid_607810
  var valid_607811 = query.getOrDefault("DBParameterGroupName")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "DBParameterGroupName", valid_607811
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607812 = query.getOrDefault("DBInstanceIdentifier")
  valid_607812 = validateParameter(valid_607812, JString, required = true,
                                 default = nil)
  if valid_607812 != nil:
    section.add "DBInstanceIdentifier", valid_607812
  var valid_607813 = query.getOrDefault("TdeCredentialArn")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "TdeCredentialArn", valid_607813
  var valid_607814 = query.getOrDefault("BackupRetentionPeriod")
  valid_607814 = validateParameter(valid_607814, JInt, required = false, default = nil)
  if valid_607814 != nil:
    section.add "BackupRetentionPeriod", valid_607814
  var valid_607815 = query.getOrDefault("StorageType")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "StorageType", valid_607815
  var valid_607816 = query.getOrDefault("EngineVersion")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "EngineVersion", valid_607816
  var valid_607817 = query.getOrDefault("Action")
  valid_607817 = validateParameter(valid_607817, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607817 != nil:
    section.add "Action", valid_607817
  var valid_607818 = query.getOrDefault("MultiAZ")
  valid_607818 = validateParameter(valid_607818, JBool, required = false, default = nil)
  if valid_607818 != nil:
    section.add "MultiAZ", valid_607818
  var valid_607819 = query.getOrDefault("DBSecurityGroups")
  valid_607819 = validateParameter(valid_607819, JArray, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "DBSecurityGroups", valid_607819
  var valid_607820 = query.getOrDefault("ApplyImmediately")
  valid_607820 = validateParameter(valid_607820, JBool, required = false, default = nil)
  if valid_607820 != nil:
    section.add "ApplyImmediately", valid_607820
  var valid_607821 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607821 = validateParameter(valid_607821, JArray, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "VpcSecurityGroupIds", valid_607821
  var valid_607822 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_607822 = validateParameter(valid_607822, JBool, required = false, default = nil)
  if valid_607822 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607822
  var valid_607823 = query.getOrDefault("MasterUserPassword")
  valid_607823 = validateParameter(valid_607823, JString, required = false,
                                 default = nil)
  if valid_607823 != nil:
    section.add "MasterUserPassword", valid_607823
  var valid_607824 = query.getOrDefault("OptionGroupName")
  valid_607824 = validateParameter(valid_607824, JString, required = false,
                                 default = nil)
  if valid_607824 != nil:
    section.add "OptionGroupName", valid_607824
  var valid_607825 = query.getOrDefault("Version")
  valid_607825 = validateParameter(valid_607825, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607825 != nil:
    section.add "Version", valid_607825
  var valid_607826 = query.getOrDefault("AllocatedStorage")
  valid_607826 = validateParameter(valid_607826, JInt, required = false, default = nil)
  if valid_607826 != nil:
    section.add "AllocatedStorage", valid_607826
  var valid_607827 = query.getOrDefault("DBInstanceClass")
  valid_607827 = validateParameter(valid_607827, JString, required = false,
                                 default = nil)
  if valid_607827 != nil:
    section.add "DBInstanceClass", valid_607827
  var valid_607828 = query.getOrDefault("PreferredBackupWindow")
  valid_607828 = validateParameter(valid_607828, JString, required = false,
                                 default = nil)
  if valid_607828 != nil:
    section.add "PreferredBackupWindow", valid_607828
  var valid_607829 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607829 = validateParameter(valid_607829, JString, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "PreferredMaintenanceWindow", valid_607829
  var valid_607830 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_607830 = validateParameter(valid_607830, JBool, required = false, default = nil)
  if valid_607830 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607830
  var valid_607831 = query.getOrDefault("Iops")
  valid_607831 = validateParameter(valid_607831, JInt, required = false, default = nil)
  if valid_607831 != nil:
    section.add "Iops", valid_607831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607832 = header.getOrDefault("X-Amz-Signature")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Signature", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Content-Sha256", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-Date")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Date", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Credential")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Credential", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-Security-Token")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Security-Token", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Algorithm")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Algorithm", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-SignedHeaders", valid_607838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607839: Call_GetModifyDBInstance_607806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607839.validator(path, query, header, formData, body)
  let scheme = call_607839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607839.url(scheme.get, call_607839.host, call_607839.base,
                         call_607839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607839, url, valid)

proc call*(call_607840: Call_GetModifyDBInstance_607806;
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
  var query_607841 = newJObject()
  add(query_607841, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_607841, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_607841, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607841, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607841, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_607841, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607841, "StorageType", newJString(StorageType))
  add(query_607841, "EngineVersion", newJString(EngineVersion))
  add(query_607841, "Action", newJString(Action))
  add(query_607841, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_607841.add "DBSecurityGroups", DBSecurityGroups
  add(query_607841, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_607841.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607841, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_607841, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_607841, "OptionGroupName", newJString(OptionGroupName))
  add(query_607841, "Version", newJString(Version))
  add(query_607841, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_607841, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607841, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_607841, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_607841, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_607841, "Iops", newJInt(Iops))
  result = call_607840.call(nil, query_607841, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_607806(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_607807, base: "/",
    url: url_GetModifyDBInstance_607808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_607896 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBParameterGroup_607898(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_607897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607899 = query.getOrDefault("Action")
  valid_607899 = validateParameter(valid_607899, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607899 != nil:
    section.add "Action", valid_607899
  var valid_607900 = query.getOrDefault("Version")
  valid_607900 = validateParameter(valid_607900, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607900 != nil:
    section.add "Version", valid_607900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607901 = header.getOrDefault("X-Amz-Signature")
  valid_607901 = validateParameter(valid_607901, JString, required = false,
                                 default = nil)
  if valid_607901 != nil:
    section.add "X-Amz-Signature", valid_607901
  var valid_607902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607902 = validateParameter(valid_607902, JString, required = false,
                                 default = nil)
  if valid_607902 != nil:
    section.add "X-Amz-Content-Sha256", valid_607902
  var valid_607903 = header.getOrDefault("X-Amz-Date")
  valid_607903 = validateParameter(valid_607903, JString, required = false,
                                 default = nil)
  if valid_607903 != nil:
    section.add "X-Amz-Date", valid_607903
  var valid_607904 = header.getOrDefault("X-Amz-Credential")
  valid_607904 = validateParameter(valid_607904, JString, required = false,
                                 default = nil)
  if valid_607904 != nil:
    section.add "X-Amz-Credential", valid_607904
  var valid_607905 = header.getOrDefault("X-Amz-Security-Token")
  valid_607905 = validateParameter(valid_607905, JString, required = false,
                                 default = nil)
  if valid_607905 != nil:
    section.add "X-Amz-Security-Token", valid_607905
  var valid_607906 = header.getOrDefault("X-Amz-Algorithm")
  valid_607906 = validateParameter(valid_607906, JString, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "X-Amz-Algorithm", valid_607906
  var valid_607907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "X-Amz-SignedHeaders", valid_607907
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607908 = formData.getOrDefault("DBParameterGroupName")
  valid_607908 = validateParameter(valid_607908, JString, required = true,
                                 default = nil)
  if valid_607908 != nil:
    section.add "DBParameterGroupName", valid_607908
  var valid_607909 = formData.getOrDefault("Parameters")
  valid_607909 = validateParameter(valid_607909, JArray, required = true, default = nil)
  if valid_607909 != nil:
    section.add "Parameters", valid_607909
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607910: Call_PostModifyDBParameterGroup_607896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607910.validator(path, query, header, formData, body)
  let scheme = call_607910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607910.url(scheme.get, call_607910.host, call_607910.base,
                         call_607910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607910, url, valid)

proc call*(call_607911: Call_PostModifyDBParameterGroup_607896;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_607912 = newJObject()
  var formData_607913 = newJObject()
  add(formData_607913, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607912, "Action", newJString(Action))
  if Parameters != nil:
    formData_607913.add "Parameters", Parameters
  add(query_607912, "Version", newJString(Version))
  result = call_607911.call(nil, query_607912, nil, formData_607913, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_607896(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_607897, base: "/",
    url: url_PostModifyDBParameterGroup_607898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_607879 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBParameterGroup_607881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_607880(path: JsonNode; query: JsonNode;
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
  var valid_607882 = query.getOrDefault("DBParameterGroupName")
  valid_607882 = validateParameter(valid_607882, JString, required = true,
                                 default = nil)
  if valid_607882 != nil:
    section.add "DBParameterGroupName", valid_607882
  var valid_607883 = query.getOrDefault("Parameters")
  valid_607883 = validateParameter(valid_607883, JArray, required = true, default = nil)
  if valid_607883 != nil:
    section.add "Parameters", valid_607883
  var valid_607884 = query.getOrDefault("Action")
  valid_607884 = validateParameter(valid_607884, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607884 != nil:
    section.add "Action", valid_607884
  var valid_607885 = query.getOrDefault("Version")
  valid_607885 = validateParameter(valid_607885, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607885 != nil:
    section.add "Version", valid_607885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607886 = header.getOrDefault("X-Amz-Signature")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "X-Amz-Signature", valid_607886
  var valid_607887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Content-Sha256", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-Date")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-Date", valid_607888
  var valid_607889 = header.getOrDefault("X-Amz-Credential")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "X-Amz-Credential", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Security-Token")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Security-Token", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Algorithm")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Algorithm", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-SignedHeaders", valid_607892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607893: Call_GetModifyDBParameterGroup_607879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607893.validator(path, query, header, formData, body)
  let scheme = call_607893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607893.url(scheme.get, call_607893.host, call_607893.base,
                         call_607893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607893, url, valid)

proc call*(call_607894: Call_GetModifyDBParameterGroup_607879;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607895 = newJObject()
  add(query_607895, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_607895.add "Parameters", Parameters
  add(query_607895, "Action", newJString(Action))
  add(query_607895, "Version", newJString(Version))
  result = call_607894.call(nil, query_607895, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_607879(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_607880, base: "/",
    url: url_GetModifyDBParameterGroup_607881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_607932 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBSubnetGroup_607934(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_607933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607935 = query.getOrDefault("Action")
  valid_607935 = validateParameter(valid_607935, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607935 != nil:
    section.add "Action", valid_607935
  var valid_607936 = query.getOrDefault("Version")
  valid_607936 = validateParameter(valid_607936, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607936 != nil:
    section.add "Version", valid_607936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607937 = header.getOrDefault("X-Amz-Signature")
  valid_607937 = validateParameter(valid_607937, JString, required = false,
                                 default = nil)
  if valid_607937 != nil:
    section.add "X-Amz-Signature", valid_607937
  var valid_607938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607938 = validateParameter(valid_607938, JString, required = false,
                                 default = nil)
  if valid_607938 != nil:
    section.add "X-Amz-Content-Sha256", valid_607938
  var valid_607939 = header.getOrDefault("X-Amz-Date")
  valid_607939 = validateParameter(valid_607939, JString, required = false,
                                 default = nil)
  if valid_607939 != nil:
    section.add "X-Amz-Date", valid_607939
  var valid_607940 = header.getOrDefault("X-Amz-Credential")
  valid_607940 = validateParameter(valid_607940, JString, required = false,
                                 default = nil)
  if valid_607940 != nil:
    section.add "X-Amz-Credential", valid_607940
  var valid_607941 = header.getOrDefault("X-Amz-Security-Token")
  valid_607941 = validateParameter(valid_607941, JString, required = false,
                                 default = nil)
  if valid_607941 != nil:
    section.add "X-Amz-Security-Token", valid_607941
  var valid_607942 = header.getOrDefault("X-Amz-Algorithm")
  valid_607942 = validateParameter(valid_607942, JString, required = false,
                                 default = nil)
  if valid_607942 != nil:
    section.add "X-Amz-Algorithm", valid_607942
  var valid_607943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607943 = validateParameter(valid_607943, JString, required = false,
                                 default = nil)
  if valid_607943 != nil:
    section.add "X-Amz-SignedHeaders", valid_607943
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_607944 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_607944 = validateParameter(valid_607944, JString, required = false,
                                 default = nil)
  if valid_607944 != nil:
    section.add "DBSubnetGroupDescription", valid_607944
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_607945 = formData.getOrDefault("DBSubnetGroupName")
  valid_607945 = validateParameter(valid_607945, JString, required = true,
                                 default = nil)
  if valid_607945 != nil:
    section.add "DBSubnetGroupName", valid_607945
  var valid_607946 = formData.getOrDefault("SubnetIds")
  valid_607946 = validateParameter(valid_607946, JArray, required = true, default = nil)
  if valid_607946 != nil:
    section.add "SubnetIds", valid_607946
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607947: Call_PostModifyDBSubnetGroup_607932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607947.validator(path, query, header, formData, body)
  let scheme = call_607947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607947.url(scheme.get, call_607947.host, call_607947.base,
                         call_607947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607947, url, valid)

proc call*(call_607948: Call_PostModifyDBSubnetGroup_607932;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_607949 = newJObject()
  var formData_607950 = newJObject()
  add(formData_607950, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607949, "Action", newJString(Action))
  add(formData_607950, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607949, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_607950.add "SubnetIds", SubnetIds
  result = call_607948.call(nil, query_607949, nil, formData_607950, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_607932(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_607933, base: "/",
    url: url_PostModifyDBSubnetGroup_607934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_607914 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBSubnetGroup_607916(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_607915(path: JsonNode; query: JsonNode;
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
  var valid_607917 = query.getOrDefault("SubnetIds")
  valid_607917 = validateParameter(valid_607917, JArray, required = true, default = nil)
  if valid_607917 != nil:
    section.add "SubnetIds", valid_607917
  var valid_607918 = query.getOrDefault("Action")
  valid_607918 = validateParameter(valid_607918, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607918 != nil:
    section.add "Action", valid_607918
  var valid_607919 = query.getOrDefault("DBSubnetGroupDescription")
  valid_607919 = validateParameter(valid_607919, JString, required = false,
                                 default = nil)
  if valid_607919 != nil:
    section.add "DBSubnetGroupDescription", valid_607919
  var valid_607920 = query.getOrDefault("DBSubnetGroupName")
  valid_607920 = validateParameter(valid_607920, JString, required = true,
                                 default = nil)
  if valid_607920 != nil:
    section.add "DBSubnetGroupName", valid_607920
  var valid_607921 = query.getOrDefault("Version")
  valid_607921 = validateParameter(valid_607921, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607921 != nil:
    section.add "Version", valid_607921
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607922 = header.getOrDefault("X-Amz-Signature")
  valid_607922 = validateParameter(valid_607922, JString, required = false,
                                 default = nil)
  if valid_607922 != nil:
    section.add "X-Amz-Signature", valid_607922
  var valid_607923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-Content-Sha256", valid_607923
  var valid_607924 = header.getOrDefault("X-Amz-Date")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "X-Amz-Date", valid_607924
  var valid_607925 = header.getOrDefault("X-Amz-Credential")
  valid_607925 = validateParameter(valid_607925, JString, required = false,
                                 default = nil)
  if valid_607925 != nil:
    section.add "X-Amz-Credential", valid_607925
  var valid_607926 = header.getOrDefault("X-Amz-Security-Token")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-Security-Token", valid_607926
  var valid_607927 = header.getOrDefault("X-Amz-Algorithm")
  valid_607927 = validateParameter(valid_607927, JString, required = false,
                                 default = nil)
  if valid_607927 != nil:
    section.add "X-Amz-Algorithm", valid_607927
  var valid_607928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607928 = validateParameter(valid_607928, JString, required = false,
                                 default = nil)
  if valid_607928 != nil:
    section.add "X-Amz-SignedHeaders", valid_607928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607929: Call_GetModifyDBSubnetGroup_607914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607929.validator(path, query, header, formData, body)
  let scheme = call_607929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607929.url(scheme.get, call_607929.host, call_607929.base,
                         call_607929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607929, url, valid)

proc call*(call_607930: Call_GetModifyDBSubnetGroup_607914; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_607931 = newJObject()
  if SubnetIds != nil:
    query_607931.add "SubnetIds", SubnetIds
  add(query_607931, "Action", newJString(Action))
  add(query_607931, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607931, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607931, "Version", newJString(Version))
  result = call_607930.call(nil, query_607931, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_607914(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_607915, base: "/",
    url: url_GetModifyDBSubnetGroup_607916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_607971 = ref object of OpenApiRestCall_605573
proc url_PostModifyEventSubscription_607973(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_607972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607974 = query.getOrDefault("Action")
  valid_607974 = validateParameter(valid_607974, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607974 != nil:
    section.add "Action", valid_607974
  var valid_607975 = query.getOrDefault("Version")
  valid_607975 = validateParameter(valid_607975, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607975 != nil:
    section.add "Version", valid_607975
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607976 = header.getOrDefault("X-Amz-Signature")
  valid_607976 = validateParameter(valid_607976, JString, required = false,
                                 default = nil)
  if valid_607976 != nil:
    section.add "X-Amz-Signature", valid_607976
  var valid_607977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607977 = validateParameter(valid_607977, JString, required = false,
                                 default = nil)
  if valid_607977 != nil:
    section.add "X-Amz-Content-Sha256", valid_607977
  var valid_607978 = header.getOrDefault("X-Amz-Date")
  valid_607978 = validateParameter(valid_607978, JString, required = false,
                                 default = nil)
  if valid_607978 != nil:
    section.add "X-Amz-Date", valid_607978
  var valid_607979 = header.getOrDefault("X-Amz-Credential")
  valid_607979 = validateParameter(valid_607979, JString, required = false,
                                 default = nil)
  if valid_607979 != nil:
    section.add "X-Amz-Credential", valid_607979
  var valid_607980 = header.getOrDefault("X-Amz-Security-Token")
  valid_607980 = validateParameter(valid_607980, JString, required = false,
                                 default = nil)
  if valid_607980 != nil:
    section.add "X-Amz-Security-Token", valid_607980
  var valid_607981 = header.getOrDefault("X-Amz-Algorithm")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "X-Amz-Algorithm", valid_607981
  var valid_607982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-SignedHeaders", valid_607982
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_607983 = formData.getOrDefault("SnsTopicArn")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "SnsTopicArn", valid_607983
  var valid_607984 = formData.getOrDefault("Enabled")
  valid_607984 = validateParameter(valid_607984, JBool, required = false, default = nil)
  if valid_607984 != nil:
    section.add "Enabled", valid_607984
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_607985 = formData.getOrDefault("SubscriptionName")
  valid_607985 = validateParameter(valid_607985, JString, required = true,
                                 default = nil)
  if valid_607985 != nil:
    section.add "SubscriptionName", valid_607985
  var valid_607986 = formData.getOrDefault("SourceType")
  valid_607986 = validateParameter(valid_607986, JString, required = false,
                                 default = nil)
  if valid_607986 != nil:
    section.add "SourceType", valid_607986
  var valid_607987 = formData.getOrDefault("EventCategories")
  valid_607987 = validateParameter(valid_607987, JArray, required = false,
                                 default = nil)
  if valid_607987 != nil:
    section.add "EventCategories", valid_607987
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607988: Call_PostModifyEventSubscription_607971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607988.validator(path, query, header, formData, body)
  let scheme = call_607988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607988.url(scheme.get, call_607988.host, call_607988.base,
                         call_607988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607988, url, valid)

proc call*(call_607989: Call_PostModifyEventSubscription_607971;
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
  var query_607990 = newJObject()
  var formData_607991 = newJObject()
  add(formData_607991, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_607991, "Enabled", newJBool(Enabled))
  add(formData_607991, "SubscriptionName", newJString(SubscriptionName))
  add(formData_607991, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_607991.add "EventCategories", EventCategories
  add(query_607990, "Action", newJString(Action))
  add(query_607990, "Version", newJString(Version))
  result = call_607989.call(nil, query_607990, nil, formData_607991, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_607971(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_607972, base: "/",
    url: url_PostModifyEventSubscription_607973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_607951 = ref object of OpenApiRestCall_605573
proc url_GetModifyEventSubscription_607953(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_607952(path: JsonNode; query: JsonNode;
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
  var valid_607954 = query.getOrDefault("SourceType")
  valid_607954 = validateParameter(valid_607954, JString, required = false,
                                 default = nil)
  if valid_607954 != nil:
    section.add "SourceType", valid_607954
  var valid_607955 = query.getOrDefault("Enabled")
  valid_607955 = validateParameter(valid_607955, JBool, required = false, default = nil)
  if valid_607955 != nil:
    section.add "Enabled", valid_607955
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_607956 = query.getOrDefault("SubscriptionName")
  valid_607956 = validateParameter(valid_607956, JString, required = true,
                                 default = nil)
  if valid_607956 != nil:
    section.add "SubscriptionName", valid_607956
  var valid_607957 = query.getOrDefault("EventCategories")
  valid_607957 = validateParameter(valid_607957, JArray, required = false,
                                 default = nil)
  if valid_607957 != nil:
    section.add "EventCategories", valid_607957
  var valid_607958 = query.getOrDefault("Action")
  valid_607958 = validateParameter(valid_607958, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607958 != nil:
    section.add "Action", valid_607958
  var valid_607959 = query.getOrDefault("SnsTopicArn")
  valid_607959 = validateParameter(valid_607959, JString, required = false,
                                 default = nil)
  if valid_607959 != nil:
    section.add "SnsTopicArn", valid_607959
  var valid_607960 = query.getOrDefault("Version")
  valid_607960 = validateParameter(valid_607960, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_607960 != nil:
    section.add "Version", valid_607960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607961 = header.getOrDefault("X-Amz-Signature")
  valid_607961 = validateParameter(valid_607961, JString, required = false,
                                 default = nil)
  if valid_607961 != nil:
    section.add "X-Amz-Signature", valid_607961
  var valid_607962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "X-Amz-Content-Sha256", valid_607962
  var valid_607963 = header.getOrDefault("X-Amz-Date")
  valid_607963 = validateParameter(valid_607963, JString, required = false,
                                 default = nil)
  if valid_607963 != nil:
    section.add "X-Amz-Date", valid_607963
  var valid_607964 = header.getOrDefault("X-Amz-Credential")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "X-Amz-Credential", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-Security-Token")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-Security-Token", valid_607965
  var valid_607966 = header.getOrDefault("X-Amz-Algorithm")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Algorithm", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-SignedHeaders", valid_607967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607968: Call_GetModifyEventSubscription_607951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607968.validator(path, query, header, formData, body)
  let scheme = call_607968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607968.url(scheme.get, call_607968.host, call_607968.base,
                         call_607968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607968, url, valid)

proc call*(call_607969: Call_GetModifyEventSubscription_607951;
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
  var query_607970 = newJObject()
  add(query_607970, "SourceType", newJString(SourceType))
  add(query_607970, "Enabled", newJBool(Enabled))
  add(query_607970, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_607970.add "EventCategories", EventCategories
  add(query_607970, "Action", newJString(Action))
  add(query_607970, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_607970, "Version", newJString(Version))
  result = call_607969.call(nil, query_607970, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_607951(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_607952, base: "/",
    url: url_GetModifyEventSubscription_607953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_608011 = ref object of OpenApiRestCall_605573
proc url_PostModifyOptionGroup_608013(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_608012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608014 = query.getOrDefault("Action")
  valid_608014 = validateParameter(valid_608014, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_608014 != nil:
    section.add "Action", valid_608014
  var valid_608015 = query.getOrDefault("Version")
  valid_608015 = validateParameter(valid_608015, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608015 != nil:
    section.add "Version", valid_608015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608016 = header.getOrDefault("X-Amz-Signature")
  valid_608016 = validateParameter(valid_608016, JString, required = false,
                                 default = nil)
  if valid_608016 != nil:
    section.add "X-Amz-Signature", valid_608016
  var valid_608017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608017 = validateParameter(valid_608017, JString, required = false,
                                 default = nil)
  if valid_608017 != nil:
    section.add "X-Amz-Content-Sha256", valid_608017
  var valid_608018 = header.getOrDefault("X-Amz-Date")
  valid_608018 = validateParameter(valid_608018, JString, required = false,
                                 default = nil)
  if valid_608018 != nil:
    section.add "X-Amz-Date", valid_608018
  var valid_608019 = header.getOrDefault("X-Amz-Credential")
  valid_608019 = validateParameter(valid_608019, JString, required = false,
                                 default = nil)
  if valid_608019 != nil:
    section.add "X-Amz-Credential", valid_608019
  var valid_608020 = header.getOrDefault("X-Amz-Security-Token")
  valid_608020 = validateParameter(valid_608020, JString, required = false,
                                 default = nil)
  if valid_608020 != nil:
    section.add "X-Amz-Security-Token", valid_608020
  var valid_608021 = header.getOrDefault("X-Amz-Algorithm")
  valid_608021 = validateParameter(valid_608021, JString, required = false,
                                 default = nil)
  if valid_608021 != nil:
    section.add "X-Amz-Algorithm", valid_608021
  var valid_608022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608022 = validateParameter(valid_608022, JString, required = false,
                                 default = nil)
  if valid_608022 != nil:
    section.add "X-Amz-SignedHeaders", valid_608022
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_608023 = formData.getOrDefault("OptionsToRemove")
  valid_608023 = validateParameter(valid_608023, JArray, required = false,
                                 default = nil)
  if valid_608023 != nil:
    section.add "OptionsToRemove", valid_608023
  var valid_608024 = formData.getOrDefault("ApplyImmediately")
  valid_608024 = validateParameter(valid_608024, JBool, required = false, default = nil)
  if valid_608024 != nil:
    section.add "ApplyImmediately", valid_608024
  var valid_608025 = formData.getOrDefault("OptionsToInclude")
  valid_608025 = validateParameter(valid_608025, JArray, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "OptionsToInclude", valid_608025
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_608026 = formData.getOrDefault("OptionGroupName")
  valid_608026 = validateParameter(valid_608026, JString, required = true,
                                 default = nil)
  if valid_608026 != nil:
    section.add "OptionGroupName", valid_608026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608027: Call_PostModifyOptionGroup_608011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608027.validator(path, query, header, formData, body)
  let scheme = call_608027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608027.url(scheme.get, call_608027.host, call_608027.base,
                         call_608027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608027, url, valid)

proc call*(call_608028: Call_PostModifyOptionGroup_608011; OptionGroupName: string;
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
  var query_608029 = newJObject()
  var formData_608030 = newJObject()
  if OptionsToRemove != nil:
    formData_608030.add "OptionsToRemove", OptionsToRemove
  add(formData_608030, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_608030.add "OptionsToInclude", OptionsToInclude
  add(query_608029, "Action", newJString(Action))
  add(formData_608030, "OptionGroupName", newJString(OptionGroupName))
  add(query_608029, "Version", newJString(Version))
  result = call_608028.call(nil, query_608029, nil, formData_608030, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_608011(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_608012, base: "/",
    url: url_PostModifyOptionGroup_608013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_607992 = ref object of OpenApiRestCall_605573
proc url_GetModifyOptionGroup_607994(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_607993(path: JsonNode; query: JsonNode;
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
  var valid_607995 = query.getOrDefault("Action")
  valid_607995 = validateParameter(valid_607995, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607995 != nil:
    section.add "Action", valid_607995
  var valid_607996 = query.getOrDefault("ApplyImmediately")
  valid_607996 = validateParameter(valid_607996, JBool, required = false, default = nil)
  if valid_607996 != nil:
    section.add "ApplyImmediately", valid_607996
  var valid_607997 = query.getOrDefault("OptionsToRemove")
  valid_607997 = validateParameter(valid_607997, JArray, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "OptionsToRemove", valid_607997
  var valid_607998 = query.getOrDefault("OptionsToInclude")
  valid_607998 = validateParameter(valid_607998, JArray, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "OptionsToInclude", valid_607998
  var valid_607999 = query.getOrDefault("OptionGroupName")
  valid_607999 = validateParameter(valid_607999, JString, required = true,
                                 default = nil)
  if valid_607999 != nil:
    section.add "OptionGroupName", valid_607999
  var valid_608000 = query.getOrDefault("Version")
  valid_608000 = validateParameter(valid_608000, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608000 != nil:
    section.add "Version", valid_608000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608001 = header.getOrDefault("X-Amz-Signature")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-Signature", valid_608001
  var valid_608002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608002 = validateParameter(valid_608002, JString, required = false,
                                 default = nil)
  if valid_608002 != nil:
    section.add "X-Amz-Content-Sha256", valid_608002
  var valid_608003 = header.getOrDefault("X-Amz-Date")
  valid_608003 = validateParameter(valid_608003, JString, required = false,
                                 default = nil)
  if valid_608003 != nil:
    section.add "X-Amz-Date", valid_608003
  var valid_608004 = header.getOrDefault("X-Amz-Credential")
  valid_608004 = validateParameter(valid_608004, JString, required = false,
                                 default = nil)
  if valid_608004 != nil:
    section.add "X-Amz-Credential", valid_608004
  var valid_608005 = header.getOrDefault("X-Amz-Security-Token")
  valid_608005 = validateParameter(valid_608005, JString, required = false,
                                 default = nil)
  if valid_608005 != nil:
    section.add "X-Amz-Security-Token", valid_608005
  var valid_608006 = header.getOrDefault("X-Amz-Algorithm")
  valid_608006 = validateParameter(valid_608006, JString, required = false,
                                 default = nil)
  if valid_608006 != nil:
    section.add "X-Amz-Algorithm", valid_608006
  var valid_608007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608007 = validateParameter(valid_608007, JString, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "X-Amz-SignedHeaders", valid_608007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608008: Call_GetModifyOptionGroup_607992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608008.validator(path, query, header, formData, body)
  let scheme = call_608008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608008.url(scheme.get, call_608008.host, call_608008.base,
                         call_608008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608008, url, valid)

proc call*(call_608009: Call_GetModifyOptionGroup_607992; OptionGroupName: string;
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
  var query_608010 = newJObject()
  add(query_608010, "Action", newJString(Action))
  add(query_608010, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_608010.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_608010.add "OptionsToInclude", OptionsToInclude
  add(query_608010, "OptionGroupName", newJString(OptionGroupName))
  add(query_608010, "Version", newJString(Version))
  result = call_608009.call(nil, query_608010, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_607992(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_607993, base: "/",
    url: url_GetModifyOptionGroup_607994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_608049 = ref object of OpenApiRestCall_605573
proc url_PostPromoteReadReplica_608051(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_608050(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608052 = query.getOrDefault("Action")
  valid_608052 = validateParameter(valid_608052, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_608052 != nil:
    section.add "Action", valid_608052
  var valid_608053 = query.getOrDefault("Version")
  valid_608053 = validateParameter(valid_608053, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608053 != nil:
    section.add "Version", valid_608053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608054 = header.getOrDefault("X-Amz-Signature")
  valid_608054 = validateParameter(valid_608054, JString, required = false,
                                 default = nil)
  if valid_608054 != nil:
    section.add "X-Amz-Signature", valid_608054
  var valid_608055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608055 = validateParameter(valid_608055, JString, required = false,
                                 default = nil)
  if valid_608055 != nil:
    section.add "X-Amz-Content-Sha256", valid_608055
  var valid_608056 = header.getOrDefault("X-Amz-Date")
  valid_608056 = validateParameter(valid_608056, JString, required = false,
                                 default = nil)
  if valid_608056 != nil:
    section.add "X-Amz-Date", valid_608056
  var valid_608057 = header.getOrDefault("X-Amz-Credential")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-Credential", valid_608057
  var valid_608058 = header.getOrDefault("X-Amz-Security-Token")
  valid_608058 = validateParameter(valid_608058, JString, required = false,
                                 default = nil)
  if valid_608058 != nil:
    section.add "X-Amz-Security-Token", valid_608058
  var valid_608059 = header.getOrDefault("X-Amz-Algorithm")
  valid_608059 = validateParameter(valid_608059, JString, required = false,
                                 default = nil)
  if valid_608059 != nil:
    section.add "X-Amz-Algorithm", valid_608059
  var valid_608060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608060 = validateParameter(valid_608060, JString, required = false,
                                 default = nil)
  if valid_608060 != nil:
    section.add "X-Amz-SignedHeaders", valid_608060
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_608061 = formData.getOrDefault("PreferredBackupWindow")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "PreferredBackupWindow", valid_608061
  var valid_608062 = formData.getOrDefault("BackupRetentionPeriod")
  valid_608062 = validateParameter(valid_608062, JInt, required = false, default = nil)
  if valid_608062 != nil:
    section.add "BackupRetentionPeriod", valid_608062
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608063 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608063 = validateParameter(valid_608063, JString, required = true,
                                 default = nil)
  if valid_608063 != nil:
    section.add "DBInstanceIdentifier", valid_608063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608064: Call_PostPromoteReadReplica_608049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608064.validator(path, query, header, formData, body)
  let scheme = call_608064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608064.url(scheme.get, call_608064.host, call_608064.base,
                         call_608064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608064, url, valid)

proc call*(call_608065: Call_PostPromoteReadReplica_608049;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608066 = newJObject()
  var formData_608067 = newJObject()
  add(formData_608067, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_608067, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_608067, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608066, "Action", newJString(Action))
  add(query_608066, "Version", newJString(Version))
  result = call_608065.call(nil, query_608066, nil, formData_608067, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_608049(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_608050, base: "/",
    url: url_PostPromoteReadReplica_608051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_608031 = ref object of OpenApiRestCall_605573
proc url_GetPromoteReadReplica_608033(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_608032(path: JsonNode; query: JsonNode;
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
  var valid_608034 = query.getOrDefault("DBInstanceIdentifier")
  valid_608034 = validateParameter(valid_608034, JString, required = true,
                                 default = nil)
  if valid_608034 != nil:
    section.add "DBInstanceIdentifier", valid_608034
  var valid_608035 = query.getOrDefault("BackupRetentionPeriod")
  valid_608035 = validateParameter(valid_608035, JInt, required = false, default = nil)
  if valid_608035 != nil:
    section.add "BackupRetentionPeriod", valid_608035
  var valid_608036 = query.getOrDefault("Action")
  valid_608036 = validateParameter(valid_608036, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_608036 != nil:
    section.add "Action", valid_608036
  var valid_608037 = query.getOrDefault("Version")
  valid_608037 = validateParameter(valid_608037, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608037 != nil:
    section.add "Version", valid_608037
  var valid_608038 = query.getOrDefault("PreferredBackupWindow")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "PreferredBackupWindow", valid_608038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608039 = header.getOrDefault("X-Amz-Signature")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Signature", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Content-Sha256", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Date")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Date", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-Credential")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-Credential", valid_608042
  var valid_608043 = header.getOrDefault("X-Amz-Security-Token")
  valid_608043 = validateParameter(valid_608043, JString, required = false,
                                 default = nil)
  if valid_608043 != nil:
    section.add "X-Amz-Security-Token", valid_608043
  var valid_608044 = header.getOrDefault("X-Amz-Algorithm")
  valid_608044 = validateParameter(valid_608044, JString, required = false,
                                 default = nil)
  if valid_608044 != nil:
    section.add "X-Amz-Algorithm", valid_608044
  var valid_608045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608045 = validateParameter(valid_608045, JString, required = false,
                                 default = nil)
  if valid_608045 != nil:
    section.add "X-Amz-SignedHeaders", valid_608045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608046: Call_GetPromoteReadReplica_608031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608046.validator(path, query, header, formData, body)
  let scheme = call_608046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608046.url(scheme.get, call_608046.host, call_608046.base,
                         call_608046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608046, url, valid)

proc call*(call_608047: Call_GetPromoteReadReplica_608031;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2014-09-01";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_608048 = newJObject()
  add(query_608048, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608048, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_608048, "Action", newJString(Action))
  add(query_608048, "Version", newJString(Version))
  add(query_608048, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_608047.call(nil, query_608048, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_608031(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_608032, base: "/",
    url: url_GetPromoteReadReplica_608033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_608087 = ref object of OpenApiRestCall_605573
proc url_PostPurchaseReservedDBInstancesOffering_608089(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_608088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608090 = query.getOrDefault("Action")
  valid_608090 = validateParameter(valid_608090, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_608090 != nil:
    section.add "Action", valid_608090
  var valid_608091 = query.getOrDefault("Version")
  valid_608091 = validateParameter(valid_608091, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608091 != nil:
    section.add "Version", valid_608091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608092 = header.getOrDefault("X-Amz-Signature")
  valid_608092 = validateParameter(valid_608092, JString, required = false,
                                 default = nil)
  if valid_608092 != nil:
    section.add "X-Amz-Signature", valid_608092
  var valid_608093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608093 = validateParameter(valid_608093, JString, required = false,
                                 default = nil)
  if valid_608093 != nil:
    section.add "X-Amz-Content-Sha256", valid_608093
  var valid_608094 = header.getOrDefault("X-Amz-Date")
  valid_608094 = validateParameter(valid_608094, JString, required = false,
                                 default = nil)
  if valid_608094 != nil:
    section.add "X-Amz-Date", valid_608094
  var valid_608095 = header.getOrDefault("X-Amz-Credential")
  valid_608095 = validateParameter(valid_608095, JString, required = false,
                                 default = nil)
  if valid_608095 != nil:
    section.add "X-Amz-Credential", valid_608095
  var valid_608096 = header.getOrDefault("X-Amz-Security-Token")
  valid_608096 = validateParameter(valid_608096, JString, required = false,
                                 default = nil)
  if valid_608096 != nil:
    section.add "X-Amz-Security-Token", valid_608096
  var valid_608097 = header.getOrDefault("X-Amz-Algorithm")
  valid_608097 = validateParameter(valid_608097, JString, required = false,
                                 default = nil)
  if valid_608097 != nil:
    section.add "X-Amz-Algorithm", valid_608097
  var valid_608098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608098 = validateParameter(valid_608098, JString, required = false,
                                 default = nil)
  if valid_608098 != nil:
    section.add "X-Amz-SignedHeaders", valid_608098
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_608099 = formData.getOrDefault("ReservedDBInstanceId")
  valid_608099 = validateParameter(valid_608099, JString, required = false,
                                 default = nil)
  if valid_608099 != nil:
    section.add "ReservedDBInstanceId", valid_608099
  var valid_608100 = formData.getOrDefault("Tags")
  valid_608100 = validateParameter(valid_608100, JArray, required = false,
                                 default = nil)
  if valid_608100 != nil:
    section.add "Tags", valid_608100
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_608101 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_608101 = validateParameter(valid_608101, JString, required = true,
                                 default = nil)
  if valid_608101 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_608101
  var valid_608102 = formData.getOrDefault("DBInstanceCount")
  valid_608102 = validateParameter(valid_608102, JInt, required = false, default = nil)
  if valid_608102 != nil:
    section.add "DBInstanceCount", valid_608102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608103: Call_PostPurchaseReservedDBInstancesOffering_608087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608103.validator(path, query, header, formData, body)
  let scheme = call_608103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608103.url(scheme.get, call_608103.host, call_608103.base,
                         call_608103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608103, url, valid)

proc call*(call_608104: Call_PostPurchaseReservedDBInstancesOffering_608087;
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
  var query_608105 = newJObject()
  var formData_608106 = newJObject()
  add(formData_608106, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_608105, "Action", newJString(Action))
  if Tags != nil:
    formData_608106.add "Tags", Tags
  add(formData_608106, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_608105, "Version", newJString(Version))
  add(formData_608106, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_608104.call(nil, query_608105, nil, formData_608106, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_608087(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_608088, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_608089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_608068 = ref object of OpenApiRestCall_605573
proc url_GetPurchaseReservedDBInstancesOffering_608070(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_608069(path: JsonNode;
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
  var valid_608071 = query.getOrDefault("Tags")
  valid_608071 = validateParameter(valid_608071, JArray, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "Tags", valid_608071
  var valid_608072 = query.getOrDefault("DBInstanceCount")
  valid_608072 = validateParameter(valid_608072, JInt, required = false, default = nil)
  if valid_608072 != nil:
    section.add "DBInstanceCount", valid_608072
  var valid_608073 = query.getOrDefault("ReservedDBInstanceId")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "ReservedDBInstanceId", valid_608073
  var valid_608074 = query.getOrDefault("Action")
  valid_608074 = validateParameter(valid_608074, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_608074 != nil:
    section.add "Action", valid_608074
  var valid_608075 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_608075 = validateParameter(valid_608075, JString, required = true,
                                 default = nil)
  if valid_608075 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_608075
  var valid_608076 = query.getOrDefault("Version")
  valid_608076 = validateParameter(valid_608076, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608076 != nil:
    section.add "Version", valid_608076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608077 = header.getOrDefault("X-Amz-Signature")
  valid_608077 = validateParameter(valid_608077, JString, required = false,
                                 default = nil)
  if valid_608077 != nil:
    section.add "X-Amz-Signature", valid_608077
  var valid_608078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608078 = validateParameter(valid_608078, JString, required = false,
                                 default = nil)
  if valid_608078 != nil:
    section.add "X-Amz-Content-Sha256", valid_608078
  var valid_608079 = header.getOrDefault("X-Amz-Date")
  valid_608079 = validateParameter(valid_608079, JString, required = false,
                                 default = nil)
  if valid_608079 != nil:
    section.add "X-Amz-Date", valid_608079
  var valid_608080 = header.getOrDefault("X-Amz-Credential")
  valid_608080 = validateParameter(valid_608080, JString, required = false,
                                 default = nil)
  if valid_608080 != nil:
    section.add "X-Amz-Credential", valid_608080
  var valid_608081 = header.getOrDefault("X-Amz-Security-Token")
  valid_608081 = validateParameter(valid_608081, JString, required = false,
                                 default = nil)
  if valid_608081 != nil:
    section.add "X-Amz-Security-Token", valid_608081
  var valid_608082 = header.getOrDefault("X-Amz-Algorithm")
  valid_608082 = validateParameter(valid_608082, JString, required = false,
                                 default = nil)
  if valid_608082 != nil:
    section.add "X-Amz-Algorithm", valid_608082
  var valid_608083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608083 = validateParameter(valid_608083, JString, required = false,
                                 default = nil)
  if valid_608083 != nil:
    section.add "X-Amz-SignedHeaders", valid_608083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608084: Call_GetPurchaseReservedDBInstancesOffering_608068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608084.validator(path, query, header, formData, body)
  let scheme = call_608084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608084.url(scheme.get, call_608084.host, call_608084.base,
                         call_608084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608084, url, valid)

proc call*(call_608085: Call_GetPurchaseReservedDBInstancesOffering_608068;
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
  var query_608086 = newJObject()
  if Tags != nil:
    query_608086.add "Tags", Tags
  add(query_608086, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_608086, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_608086, "Action", newJString(Action))
  add(query_608086, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_608086, "Version", newJString(Version))
  result = call_608085.call(nil, query_608086, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_608068(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_608069, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_608070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_608124 = ref object of OpenApiRestCall_605573
proc url_PostRebootDBInstance_608126(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_608125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608127 = query.getOrDefault("Action")
  valid_608127 = validateParameter(valid_608127, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_608127 != nil:
    section.add "Action", valid_608127
  var valid_608128 = query.getOrDefault("Version")
  valid_608128 = validateParameter(valid_608128, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608128 != nil:
    section.add "Version", valid_608128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608129 = header.getOrDefault("X-Amz-Signature")
  valid_608129 = validateParameter(valid_608129, JString, required = false,
                                 default = nil)
  if valid_608129 != nil:
    section.add "X-Amz-Signature", valid_608129
  var valid_608130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608130 = validateParameter(valid_608130, JString, required = false,
                                 default = nil)
  if valid_608130 != nil:
    section.add "X-Amz-Content-Sha256", valid_608130
  var valid_608131 = header.getOrDefault("X-Amz-Date")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "X-Amz-Date", valid_608131
  var valid_608132 = header.getOrDefault("X-Amz-Credential")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "X-Amz-Credential", valid_608132
  var valid_608133 = header.getOrDefault("X-Amz-Security-Token")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-Security-Token", valid_608133
  var valid_608134 = header.getOrDefault("X-Amz-Algorithm")
  valid_608134 = validateParameter(valid_608134, JString, required = false,
                                 default = nil)
  if valid_608134 != nil:
    section.add "X-Amz-Algorithm", valid_608134
  var valid_608135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608135 = validateParameter(valid_608135, JString, required = false,
                                 default = nil)
  if valid_608135 != nil:
    section.add "X-Amz-SignedHeaders", valid_608135
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_608136 = formData.getOrDefault("ForceFailover")
  valid_608136 = validateParameter(valid_608136, JBool, required = false, default = nil)
  if valid_608136 != nil:
    section.add "ForceFailover", valid_608136
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608137 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608137 = validateParameter(valid_608137, JString, required = true,
                                 default = nil)
  if valid_608137 != nil:
    section.add "DBInstanceIdentifier", valid_608137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608138: Call_PostRebootDBInstance_608124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608138.validator(path, query, header, formData, body)
  let scheme = call_608138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608138.url(scheme.get, call_608138.host, call_608138.base,
                         call_608138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608138, url, valid)

proc call*(call_608139: Call_PostRebootDBInstance_608124;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608140 = newJObject()
  var formData_608141 = newJObject()
  add(formData_608141, "ForceFailover", newJBool(ForceFailover))
  add(formData_608141, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608140, "Action", newJString(Action))
  add(query_608140, "Version", newJString(Version))
  result = call_608139.call(nil, query_608140, nil, formData_608141, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_608124(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_608125, base: "/",
    url: url_PostRebootDBInstance_608126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_608107 = ref object of OpenApiRestCall_605573
proc url_GetRebootDBInstance_608109(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_608108(path: JsonNode; query: JsonNode;
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
  var valid_608110 = query.getOrDefault("ForceFailover")
  valid_608110 = validateParameter(valid_608110, JBool, required = false, default = nil)
  if valid_608110 != nil:
    section.add "ForceFailover", valid_608110
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608111 = query.getOrDefault("DBInstanceIdentifier")
  valid_608111 = validateParameter(valid_608111, JString, required = true,
                                 default = nil)
  if valid_608111 != nil:
    section.add "DBInstanceIdentifier", valid_608111
  var valid_608112 = query.getOrDefault("Action")
  valid_608112 = validateParameter(valid_608112, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_608112 != nil:
    section.add "Action", valid_608112
  var valid_608113 = query.getOrDefault("Version")
  valid_608113 = validateParameter(valid_608113, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608113 != nil:
    section.add "Version", valid_608113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608114 = header.getOrDefault("X-Amz-Signature")
  valid_608114 = validateParameter(valid_608114, JString, required = false,
                                 default = nil)
  if valid_608114 != nil:
    section.add "X-Amz-Signature", valid_608114
  var valid_608115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608115 = validateParameter(valid_608115, JString, required = false,
                                 default = nil)
  if valid_608115 != nil:
    section.add "X-Amz-Content-Sha256", valid_608115
  var valid_608116 = header.getOrDefault("X-Amz-Date")
  valid_608116 = validateParameter(valid_608116, JString, required = false,
                                 default = nil)
  if valid_608116 != nil:
    section.add "X-Amz-Date", valid_608116
  var valid_608117 = header.getOrDefault("X-Amz-Credential")
  valid_608117 = validateParameter(valid_608117, JString, required = false,
                                 default = nil)
  if valid_608117 != nil:
    section.add "X-Amz-Credential", valid_608117
  var valid_608118 = header.getOrDefault("X-Amz-Security-Token")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-Security-Token", valid_608118
  var valid_608119 = header.getOrDefault("X-Amz-Algorithm")
  valid_608119 = validateParameter(valid_608119, JString, required = false,
                                 default = nil)
  if valid_608119 != nil:
    section.add "X-Amz-Algorithm", valid_608119
  var valid_608120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608120 = validateParameter(valid_608120, JString, required = false,
                                 default = nil)
  if valid_608120 != nil:
    section.add "X-Amz-SignedHeaders", valid_608120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608121: Call_GetRebootDBInstance_608107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608121.validator(path, query, header, formData, body)
  let scheme = call_608121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608121.url(scheme.get, call_608121.host, call_608121.base,
                         call_608121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608121, url, valid)

proc call*(call_608122: Call_GetRebootDBInstance_608107;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608123 = newJObject()
  add(query_608123, "ForceFailover", newJBool(ForceFailover))
  add(query_608123, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608123, "Action", newJString(Action))
  add(query_608123, "Version", newJString(Version))
  result = call_608122.call(nil, query_608123, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_608107(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_608108, base: "/",
    url: url_GetRebootDBInstance_608109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_608159 = ref object of OpenApiRestCall_605573
proc url_PostRemoveSourceIdentifierFromSubscription_608161(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_608160(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608162 = query.getOrDefault("Action")
  valid_608162 = validateParameter(valid_608162, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_608162 != nil:
    section.add "Action", valid_608162
  var valid_608163 = query.getOrDefault("Version")
  valid_608163 = validateParameter(valid_608163, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608163 != nil:
    section.add "Version", valid_608163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608164 = header.getOrDefault("X-Amz-Signature")
  valid_608164 = validateParameter(valid_608164, JString, required = false,
                                 default = nil)
  if valid_608164 != nil:
    section.add "X-Amz-Signature", valid_608164
  var valid_608165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608165 = validateParameter(valid_608165, JString, required = false,
                                 default = nil)
  if valid_608165 != nil:
    section.add "X-Amz-Content-Sha256", valid_608165
  var valid_608166 = header.getOrDefault("X-Amz-Date")
  valid_608166 = validateParameter(valid_608166, JString, required = false,
                                 default = nil)
  if valid_608166 != nil:
    section.add "X-Amz-Date", valid_608166
  var valid_608167 = header.getOrDefault("X-Amz-Credential")
  valid_608167 = validateParameter(valid_608167, JString, required = false,
                                 default = nil)
  if valid_608167 != nil:
    section.add "X-Amz-Credential", valid_608167
  var valid_608168 = header.getOrDefault("X-Amz-Security-Token")
  valid_608168 = validateParameter(valid_608168, JString, required = false,
                                 default = nil)
  if valid_608168 != nil:
    section.add "X-Amz-Security-Token", valid_608168
  var valid_608169 = header.getOrDefault("X-Amz-Algorithm")
  valid_608169 = validateParameter(valid_608169, JString, required = false,
                                 default = nil)
  if valid_608169 != nil:
    section.add "X-Amz-Algorithm", valid_608169
  var valid_608170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608170 = validateParameter(valid_608170, JString, required = false,
                                 default = nil)
  if valid_608170 != nil:
    section.add "X-Amz-SignedHeaders", valid_608170
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_608171 = formData.getOrDefault("SubscriptionName")
  valid_608171 = validateParameter(valid_608171, JString, required = true,
                                 default = nil)
  if valid_608171 != nil:
    section.add "SubscriptionName", valid_608171
  var valid_608172 = formData.getOrDefault("SourceIdentifier")
  valid_608172 = validateParameter(valid_608172, JString, required = true,
                                 default = nil)
  if valid_608172 != nil:
    section.add "SourceIdentifier", valid_608172
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608173: Call_PostRemoveSourceIdentifierFromSubscription_608159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608173.validator(path, query, header, formData, body)
  let scheme = call_608173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608173.url(scheme.get, call_608173.host, call_608173.base,
                         call_608173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608173, url, valid)

proc call*(call_608174: Call_PostRemoveSourceIdentifierFromSubscription_608159;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608175 = newJObject()
  var formData_608176 = newJObject()
  add(formData_608176, "SubscriptionName", newJString(SubscriptionName))
  add(formData_608176, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608175, "Action", newJString(Action))
  add(query_608175, "Version", newJString(Version))
  result = call_608174.call(nil, query_608175, nil, formData_608176, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_608159(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_608160,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_608161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_608142 = ref object of OpenApiRestCall_605573
proc url_GetRemoveSourceIdentifierFromSubscription_608144(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_608143(path: JsonNode;
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
  var valid_608145 = query.getOrDefault("SourceIdentifier")
  valid_608145 = validateParameter(valid_608145, JString, required = true,
                                 default = nil)
  if valid_608145 != nil:
    section.add "SourceIdentifier", valid_608145
  var valid_608146 = query.getOrDefault("SubscriptionName")
  valid_608146 = validateParameter(valid_608146, JString, required = true,
                                 default = nil)
  if valid_608146 != nil:
    section.add "SubscriptionName", valid_608146
  var valid_608147 = query.getOrDefault("Action")
  valid_608147 = validateParameter(valid_608147, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_608147 != nil:
    section.add "Action", valid_608147
  var valid_608148 = query.getOrDefault("Version")
  valid_608148 = validateParameter(valid_608148, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608148 != nil:
    section.add "Version", valid_608148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608149 = header.getOrDefault("X-Amz-Signature")
  valid_608149 = validateParameter(valid_608149, JString, required = false,
                                 default = nil)
  if valid_608149 != nil:
    section.add "X-Amz-Signature", valid_608149
  var valid_608150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608150 = validateParameter(valid_608150, JString, required = false,
                                 default = nil)
  if valid_608150 != nil:
    section.add "X-Amz-Content-Sha256", valid_608150
  var valid_608151 = header.getOrDefault("X-Amz-Date")
  valid_608151 = validateParameter(valid_608151, JString, required = false,
                                 default = nil)
  if valid_608151 != nil:
    section.add "X-Amz-Date", valid_608151
  var valid_608152 = header.getOrDefault("X-Amz-Credential")
  valid_608152 = validateParameter(valid_608152, JString, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "X-Amz-Credential", valid_608152
  var valid_608153 = header.getOrDefault("X-Amz-Security-Token")
  valid_608153 = validateParameter(valid_608153, JString, required = false,
                                 default = nil)
  if valid_608153 != nil:
    section.add "X-Amz-Security-Token", valid_608153
  var valid_608154 = header.getOrDefault("X-Amz-Algorithm")
  valid_608154 = validateParameter(valid_608154, JString, required = false,
                                 default = nil)
  if valid_608154 != nil:
    section.add "X-Amz-Algorithm", valid_608154
  var valid_608155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608155 = validateParameter(valid_608155, JString, required = false,
                                 default = nil)
  if valid_608155 != nil:
    section.add "X-Amz-SignedHeaders", valid_608155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608156: Call_GetRemoveSourceIdentifierFromSubscription_608142;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608156.validator(path, query, header, formData, body)
  let scheme = call_608156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608156.url(scheme.get, call_608156.host, call_608156.base,
                         call_608156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608156, url, valid)

proc call*(call_608157: Call_GetRemoveSourceIdentifierFromSubscription_608142;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608158 = newJObject()
  add(query_608158, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608158, "SubscriptionName", newJString(SubscriptionName))
  add(query_608158, "Action", newJString(Action))
  add(query_608158, "Version", newJString(Version))
  result = call_608157.call(nil, query_608158, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_608142(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_608143,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_608144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_608194 = ref object of OpenApiRestCall_605573
proc url_PostRemoveTagsFromResource_608196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_608195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608197 = query.getOrDefault("Action")
  valid_608197 = validateParameter(valid_608197, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608197 != nil:
    section.add "Action", valid_608197
  var valid_608198 = query.getOrDefault("Version")
  valid_608198 = validateParameter(valid_608198, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608198 != nil:
    section.add "Version", valid_608198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608199 = header.getOrDefault("X-Amz-Signature")
  valid_608199 = validateParameter(valid_608199, JString, required = false,
                                 default = nil)
  if valid_608199 != nil:
    section.add "X-Amz-Signature", valid_608199
  var valid_608200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608200 = validateParameter(valid_608200, JString, required = false,
                                 default = nil)
  if valid_608200 != nil:
    section.add "X-Amz-Content-Sha256", valid_608200
  var valid_608201 = header.getOrDefault("X-Amz-Date")
  valid_608201 = validateParameter(valid_608201, JString, required = false,
                                 default = nil)
  if valid_608201 != nil:
    section.add "X-Amz-Date", valid_608201
  var valid_608202 = header.getOrDefault("X-Amz-Credential")
  valid_608202 = validateParameter(valid_608202, JString, required = false,
                                 default = nil)
  if valid_608202 != nil:
    section.add "X-Amz-Credential", valid_608202
  var valid_608203 = header.getOrDefault("X-Amz-Security-Token")
  valid_608203 = validateParameter(valid_608203, JString, required = false,
                                 default = nil)
  if valid_608203 != nil:
    section.add "X-Amz-Security-Token", valid_608203
  var valid_608204 = header.getOrDefault("X-Amz-Algorithm")
  valid_608204 = validateParameter(valid_608204, JString, required = false,
                                 default = nil)
  if valid_608204 != nil:
    section.add "X-Amz-Algorithm", valid_608204
  var valid_608205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608205 = validateParameter(valid_608205, JString, required = false,
                                 default = nil)
  if valid_608205 != nil:
    section.add "X-Amz-SignedHeaders", valid_608205
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_608206 = formData.getOrDefault("TagKeys")
  valid_608206 = validateParameter(valid_608206, JArray, required = true, default = nil)
  if valid_608206 != nil:
    section.add "TagKeys", valid_608206
  var valid_608207 = formData.getOrDefault("ResourceName")
  valid_608207 = validateParameter(valid_608207, JString, required = true,
                                 default = nil)
  if valid_608207 != nil:
    section.add "ResourceName", valid_608207
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608208: Call_PostRemoveTagsFromResource_608194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608208.validator(path, query, header, formData, body)
  let scheme = call_608208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608208.url(scheme.get, call_608208.host, call_608208.base,
                         call_608208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608208, url, valid)

proc call*(call_608209: Call_PostRemoveTagsFromResource_608194; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_608210 = newJObject()
  var formData_608211 = newJObject()
  if TagKeys != nil:
    formData_608211.add "TagKeys", TagKeys
  add(query_608210, "Action", newJString(Action))
  add(query_608210, "Version", newJString(Version))
  add(formData_608211, "ResourceName", newJString(ResourceName))
  result = call_608209.call(nil, query_608210, nil, formData_608211, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_608194(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_608195, base: "/",
    url: url_PostRemoveTagsFromResource_608196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_608177 = ref object of OpenApiRestCall_605573
proc url_GetRemoveTagsFromResource_608179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_608178(path: JsonNode; query: JsonNode;
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
  var valid_608180 = query.getOrDefault("ResourceName")
  valid_608180 = validateParameter(valid_608180, JString, required = true,
                                 default = nil)
  if valid_608180 != nil:
    section.add "ResourceName", valid_608180
  var valid_608181 = query.getOrDefault("TagKeys")
  valid_608181 = validateParameter(valid_608181, JArray, required = true, default = nil)
  if valid_608181 != nil:
    section.add "TagKeys", valid_608181
  var valid_608182 = query.getOrDefault("Action")
  valid_608182 = validateParameter(valid_608182, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608182 != nil:
    section.add "Action", valid_608182
  var valid_608183 = query.getOrDefault("Version")
  valid_608183 = validateParameter(valid_608183, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608183 != nil:
    section.add "Version", valid_608183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608184 = header.getOrDefault("X-Amz-Signature")
  valid_608184 = validateParameter(valid_608184, JString, required = false,
                                 default = nil)
  if valid_608184 != nil:
    section.add "X-Amz-Signature", valid_608184
  var valid_608185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608185 = validateParameter(valid_608185, JString, required = false,
                                 default = nil)
  if valid_608185 != nil:
    section.add "X-Amz-Content-Sha256", valid_608185
  var valid_608186 = header.getOrDefault("X-Amz-Date")
  valid_608186 = validateParameter(valid_608186, JString, required = false,
                                 default = nil)
  if valid_608186 != nil:
    section.add "X-Amz-Date", valid_608186
  var valid_608187 = header.getOrDefault("X-Amz-Credential")
  valid_608187 = validateParameter(valid_608187, JString, required = false,
                                 default = nil)
  if valid_608187 != nil:
    section.add "X-Amz-Credential", valid_608187
  var valid_608188 = header.getOrDefault("X-Amz-Security-Token")
  valid_608188 = validateParameter(valid_608188, JString, required = false,
                                 default = nil)
  if valid_608188 != nil:
    section.add "X-Amz-Security-Token", valid_608188
  var valid_608189 = header.getOrDefault("X-Amz-Algorithm")
  valid_608189 = validateParameter(valid_608189, JString, required = false,
                                 default = nil)
  if valid_608189 != nil:
    section.add "X-Amz-Algorithm", valid_608189
  var valid_608190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608190 = validateParameter(valid_608190, JString, required = false,
                                 default = nil)
  if valid_608190 != nil:
    section.add "X-Amz-SignedHeaders", valid_608190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608191: Call_GetRemoveTagsFromResource_608177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608191.validator(path, query, header, formData, body)
  let scheme = call_608191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608191.url(scheme.get, call_608191.host, call_608191.base,
                         call_608191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608191, url, valid)

proc call*(call_608192: Call_GetRemoveTagsFromResource_608177;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608193 = newJObject()
  add(query_608193, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_608193.add "TagKeys", TagKeys
  add(query_608193, "Action", newJString(Action))
  add(query_608193, "Version", newJString(Version))
  result = call_608192.call(nil, query_608193, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_608177(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_608178, base: "/",
    url: url_GetRemoveTagsFromResource_608179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_608230 = ref object of OpenApiRestCall_605573
proc url_PostResetDBParameterGroup_608232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_608231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608233 = query.getOrDefault("Action")
  valid_608233 = validateParameter(valid_608233, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608233 != nil:
    section.add "Action", valid_608233
  var valid_608234 = query.getOrDefault("Version")
  valid_608234 = validateParameter(valid_608234, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608234 != nil:
    section.add "Version", valid_608234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608235 = header.getOrDefault("X-Amz-Signature")
  valid_608235 = validateParameter(valid_608235, JString, required = false,
                                 default = nil)
  if valid_608235 != nil:
    section.add "X-Amz-Signature", valid_608235
  var valid_608236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608236 = validateParameter(valid_608236, JString, required = false,
                                 default = nil)
  if valid_608236 != nil:
    section.add "X-Amz-Content-Sha256", valid_608236
  var valid_608237 = header.getOrDefault("X-Amz-Date")
  valid_608237 = validateParameter(valid_608237, JString, required = false,
                                 default = nil)
  if valid_608237 != nil:
    section.add "X-Amz-Date", valid_608237
  var valid_608238 = header.getOrDefault("X-Amz-Credential")
  valid_608238 = validateParameter(valid_608238, JString, required = false,
                                 default = nil)
  if valid_608238 != nil:
    section.add "X-Amz-Credential", valid_608238
  var valid_608239 = header.getOrDefault("X-Amz-Security-Token")
  valid_608239 = validateParameter(valid_608239, JString, required = false,
                                 default = nil)
  if valid_608239 != nil:
    section.add "X-Amz-Security-Token", valid_608239
  var valid_608240 = header.getOrDefault("X-Amz-Algorithm")
  valid_608240 = validateParameter(valid_608240, JString, required = false,
                                 default = nil)
  if valid_608240 != nil:
    section.add "X-Amz-Algorithm", valid_608240
  var valid_608241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608241 = validateParameter(valid_608241, JString, required = false,
                                 default = nil)
  if valid_608241 != nil:
    section.add "X-Amz-SignedHeaders", valid_608241
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_608242 = formData.getOrDefault("ResetAllParameters")
  valid_608242 = validateParameter(valid_608242, JBool, required = false, default = nil)
  if valid_608242 != nil:
    section.add "ResetAllParameters", valid_608242
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_608243 = formData.getOrDefault("DBParameterGroupName")
  valid_608243 = validateParameter(valid_608243, JString, required = true,
                                 default = nil)
  if valid_608243 != nil:
    section.add "DBParameterGroupName", valid_608243
  var valid_608244 = formData.getOrDefault("Parameters")
  valid_608244 = validateParameter(valid_608244, JArray, required = false,
                                 default = nil)
  if valid_608244 != nil:
    section.add "Parameters", valid_608244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608245: Call_PostResetDBParameterGroup_608230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608245.validator(path, query, header, formData, body)
  let scheme = call_608245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608245.url(scheme.get, call_608245.host, call_608245.base,
                         call_608245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608245, url, valid)

proc call*(call_608246: Call_PostResetDBParameterGroup_608230;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_608247 = newJObject()
  var formData_608248 = newJObject()
  add(formData_608248, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_608248, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_608247, "Action", newJString(Action))
  if Parameters != nil:
    formData_608248.add "Parameters", Parameters
  add(query_608247, "Version", newJString(Version))
  result = call_608246.call(nil, query_608247, nil, formData_608248, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_608230(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_608231, base: "/",
    url: url_PostResetDBParameterGroup_608232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_608212 = ref object of OpenApiRestCall_605573
proc url_GetResetDBParameterGroup_608214(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_608213(path: JsonNode; query: JsonNode;
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
  var valid_608215 = query.getOrDefault("DBParameterGroupName")
  valid_608215 = validateParameter(valid_608215, JString, required = true,
                                 default = nil)
  if valid_608215 != nil:
    section.add "DBParameterGroupName", valid_608215
  var valid_608216 = query.getOrDefault("Parameters")
  valid_608216 = validateParameter(valid_608216, JArray, required = false,
                                 default = nil)
  if valid_608216 != nil:
    section.add "Parameters", valid_608216
  var valid_608217 = query.getOrDefault("ResetAllParameters")
  valid_608217 = validateParameter(valid_608217, JBool, required = false, default = nil)
  if valid_608217 != nil:
    section.add "ResetAllParameters", valid_608217
  var valid_608218 = query.getOrDefault("Action")
  valid_608218 = validateParameter(valid_608218, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608218 != nil:
    section.add "Action", valid_608218
  var valid_608219 = query.getOrDefault("Version")
  valid_608219 = validateParameter(valid_608219, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608219 != nil:
    section.add "Version", valid_608219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608220 = header.getOrDefault("X-Amz-Signature")
  valid_608220 = validateParameter(valid_608220, JString, required = false,
                                 default = nil)
  if valid_608220 != nil:
    section.add "X-Amz-Signature", valid_608220
  var valid_608221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608221 = validateParameter(valid_608221, JString, required = false,
                                 default = nil)
  if valid_608221 != nil:
    section.add "X-Amz-Content-Sha256", valid_608221
  var valid_608222 = header.getOrDefault("X-Amz-Date")
  valid_608222 = validateParameter(valid_608222, JString, required = false,
                                 default = nil)
  if valid_608222 != nil:
    section.add "X-Amz-Date", valid_608222
  var valid_608223 = header.getOrDefault("X-Amz-Credential")
  valid_608223 = validateParameter(valid_608223, JString, required = false,
                                 default = nil)
  if valid_608223 != nil:
    section.add "X-Amz-Credential", valid_608223
  var valid_608224 = header.getOrDefault("X-Amz-Security-Token")
  valid_608224 = validateParameter(valid_608224, JString, required = false,
                                 default = nil)
  if valid_608224 != nil:
    section.add "X-Amz-Security-Token", valid_608224
  var valid_608225 = header.getOrDefault("X-Amz-Algorithm")
  valid_608225 = validateParameter(valid_608225, JString, required = false,
                                 default = nil)
  if valid_608225 != nil:
    section.add "X-Amz-Algorithm", valid_608225
  var valid_608226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608226 = validateParameter(valid_608226, JString, required = false,
                                 default = nil)
  if valid_608226 != nil:
    section.add "X-Amz-SignedHeaders", valid_608226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608227: Call_GetResetDBParameterGroup_608212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608227.validator(path, query, header, formData, body)
  let scheme = call_608227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608227.url(scheme.get, call_608227.host, call_608227.base,
                         call_608227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608227, url, valid)

proc call*(call_608228: Call_GetResetDBParameterGroup_608212;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608229 = newJObject()
  add(query_608229, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_608229.add "Parameters", Parameters
  add(query_608229, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_608229, "Action", newJString(Action))
  add(query_608229, "Version", newJString(Version))
  result = call_608228.call(nil, query_608229, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_608212(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_608213, base: "/",
    url: url_GetResetDBParameterGroup_608214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_608282 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceFromDBSnapshot_608284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_608283(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608285 = query.getOrDefault("Action")
  valid_608285 = validateParameter(valid_608285, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608285 != nil:
    section.add "Action", valid_608285
  var valid_608286 = query.getOrDefault("Version")
  valid_608286 = validateParameter(valid_608286, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608286 != nil:
    section.add "Version", valid_608286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608287 = header.getOrDefault("X-Amz-Signature")
  valid_608287 = validateParameter(valid_608287, JString, required = false,
                                 default = nil)
  if valid_608287 != nil:
    section.add "X-Amz-Signature", valid_608287
  var valid_608288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608288 = validateParameter(valid_608288, JString, required = false,
                                 default = nil)
  if valid_608288 != nil:
    section.add "X-Amz-Content-Sha256", valid_608288
  var valid_608289 = header.getOrDefault("X-Amz-Date")
  valid_608289 = validateParameter(valid_608289, JString, required = false,
                                 default = nil)
  if valid_608289 != nil:
    section.add "X-Amz-Date", valid_608289
  var valid_608290 = header.getOrDefault("X-Amz-Credential")
  valid_608290 = validateParameter(valid_608290, JString, required = false,
                                 default = nil)
  if valid_608290 != nil:
    section.add "X-Amz-Credential", valid_608290
  var valid_608291 = header.getOrDefault("X-Amz-Security-Token")
  valid_608291 = validateParameter(valid_608291, JString, required = false,
                                 default = nil)
  if valid_608291 != nil:
    section.add "X-Amz-Security-Token", valid_608291
  var valid_608292 = header.getOrDefault("X-Amz-Algorithm")
  valid_608292 = validateParameter(valid_608292, JString, required = false,
                                 default = nil)
  if valid_608292 != nil:
    section.add "X-Amz-Algorithm", valid_608292
  var valid_608293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608293 = validateParameter(valid_608293, JString, required = false,
                                 default = nil)
  if valid_608293 != nil:
    section.add "X-Amz-SignedHeaders", valid_608293
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
  var valid_608294 = formData.getOrDefault("Port")
  valid_608294 = validateParameter(valid_608294, JInt, required = false, default = nil)
  if valid_608294 != nil:
    section.add "Port", valid_608294
  var valid_608295 = formData.getOrDefault("DBInstanceClass")
  valid_608295 = validateParameter(valid_608295, JString, required = false,
                                 default = nil)
  if valid_608295 != nil:
    section.add "DBInstanceClass", valid_608295
  var valid_608296 = formData.getOrDefault("MultiAZ")
  valid_608296 = validateParameter(valid_608296, JBool, required = false, default = nil)
  if valid_608296 != nil:
    section.add "MultiAZ", valid_608296
  var valid_608297 = formData.getOrDefault("AvailabilityZone")
  valid_608297 = validateParameter(valid_608297, JString, required = false,
                                 default = nil)
  if valid_608297 != nil:
    section.add "AvailabilityZone", valid_608297
  var valid_608298 = formData.getOrDefault("Engine")
  valid_608298 = validateParameter(valid_608298, JString, required = false,
                                 default = nil)
  if valid_608298 != nil:
    section.add "Engine", valid_608298
  var valid_608299 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608299 = validateParameter(valid_608299, JBool, required = false, default = nil)
  if valid_608299 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608299
  var valid_608300 = formData.getOrDefault("TdeCredentialPassword")
  valid_608300 = validateParameter(valid_608300, JString, required = false,
                                 default = nil)
  if valid_608300 != nil:
    section.add "TdeCredentialPassword", valid_608300
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608301 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608301 = validateParameter(valid_608301, JString, required = true,
                                 default = nil)
  if valid_608301 != nil:
    section.add "DBInstanceIdentifier", valid_608301
  var valid_608302 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_608302 = validateParameter(valid_608302, JString, required = true,
                                 default = nil)
  if valid_608302 != nil:
    section.add "DBSnapshotIdentifier", valid_608302
  var valid_608303 = formData.getOrDefault("DBName")
  valid_608303 = validateParameter(valid_608303, JString, required = false,
                                 default = nil)
  if valid_608303 != nil:
    section.add "DBName", valid_608303
  var valid_608304 = formData.getOrDefault("Iops")
  valid_608304 = validateParameter(valid_608304, JInt, required = false, default = nil)
  if valid_608304 != nil:
    section.add "Iops", valid_608304
  var valid_608305 = formData.getOrDefault("TdeCredentialArn")
  valid_608305 = validateParameter(valid_608305, JString, required = false,
                                 default = nil)
  if valid_608305 != nil:
    section.add "TdeCredentialArn", valid_608305
  var valid_608306 = formData.getOrDefault("PubliclyAccessible")
  valid_608306 = validateParameter(valid_608306, JBool, required = false, default = nil)
  if valid_608306 != nil:
    section.add "PubliclyAccessible", valid_608306
  var valid_608307 = formData.getOrDefault("LicenseModel")
  valid_608307 = validateParameter(valid_608307, JString, required = false,
                                 default = nil)
  if valid_608307 != nil:
    section.add "LicenseModel", valid_608307
  var valid_608308 = formData.getOrDefault("Tags")
  valid_608308 = validateParameter(valid_608308, JArray, required = false,
                                 default = nil)
  if valid_608308 != nil:
    section.add "Tags", valid_608308
  var valid_608309 = formData.getOrDefault("DBSubnetGroupName")
  valid_608309 = validateParameter(valid_608309, JString, required = false,
                                 default = nil)
  if valid_608309 != nil:
    section.add "DBSubnetGroupName", valid_608309
  var valid_608310 = formData.getOrDefault("OptionGroupName")
  valid_608310 = validateParameter(valid_608310, JString, required = false,
                                 default = nil)
  if valid_608310 != nil:
    section.add "OptionGroupName", valid_608310
  var valid_608311 = formData.getOrDefault("StorageType")
  valid_608311 = validateParameter(valid_608311, JString, required = false,
                                 default = nil)
  if valid_608311 != nil:
    section.add "StorageType", valid_608311
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608312: Call_PostRestoreDBInstanceFromDBSnapshot_608282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608312.validator(path, query, header, formData, body)
  let scheme = call_608312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608312.url(scheme.get, call_608312.host, call_608312.base,
                         call_608312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608312, url, valid)

proc call*(call_608313: Call_PostRestoreDBInstanceFromDBSnapshot_608282;
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
  var query_608314 = newJObject()
  var formData_608315 = newJObject()
  add(formData_608315, "Port", newJInt(Port))
  add(formData_608315, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608315, "MultiAZ", newJBool(MultiAZ))
  add(formData_608315, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608315, "Engine", newJString(Engine))
  add(formData_608315, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608315, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_608315, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_608315, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_608315, "DBName", newJString(DBName))
  add(formData_608315, "Iops", newJInt(Iops))
  add(formData_608315, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_608315, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608314, "Action", newJString(Action))
  add(formData_608315, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_608315.add "Tags", Tags
  add(formData_608315, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608315, "OptionGroupName", newJString(OptionGroupName))
  add(query_608314, "Version", newJString(Version))
  add(formData_608315, "StorageType", newJString(StorageType))
  result = call_608313.call(nil, query_608314, nil, formData_608315, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_608282(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_608283, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_608284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_608249 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceFromDBSnapshot_608251(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_608250(path: JsonNode;
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
  var valid_608252 = query.getOrDefault("DBName")
  valid_608252 = validateParameter(valid_608252, JString, required = false,
                                 default = nil)
  if valid_608252 != nil:
    section.add "DBName", valid_608252
  var valid_608253 = query.getOrDefault("TdeCredentialPassword")
  valid_608253 = validateParameter(valid_608253, JString, required = false,
                                 default = nil)
  if valid_608253 != nil:
    section.add "TdeCredentialPassword", valid_608253
  var valid_608254 = query.getOrDefault("Engine")
  valid_608254 = validateParameter(valid_608254, JString, required = false,
                                 default = nil)
  if valid_608254 != nil:
    section.add "Engine", valid_608254
  var valid_608255 = query.getOrDefault("Tags")
  valid_608255 = validateParameter(valid_608255, JArray, required = false,
                                 default = nil)
  if valid_608255 != nil:
    section.add "Tags", valid_608255
  var valid_608256 = query.getOrDefault("LicenseModel")
  valid_608256 = validateParameter(valid_608256, JString, required = false,
                                 default = nil)
  if valid_608256 != nil:
    section.add "LicenseModel", valid_608256
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608257 = query.getOrDefault("DBInstanceIdentifier")
  valid_608257 = validateParameter(valid_608257, JString, required = true,
                                 default = nil)
  if valid_608257 != nil:
    section.add "DBInstanceIdentifier", valid_608257
  var valid_608258 = query.getOrDefault("DBSnapshotIdentifier")
  valid_608258 = validateParameter(valid_608258, JString, required = true,
                                 default = nil)
  if valid_608258 != nil:
    section.add "DBSnapshotIdentifier", valid_608258
  var valid_608259 = query.getOrDefault("TdeCredentialArn")
  valid_608259 = validateParameter(valid_608259, JString, required = false,
                                 default = nil)
  if valid_608259 != nil:
    section.add "TdeCredentialArn", valid_608259
  var valid_608260 = query.getOrDefault("StorageType")
  valid_608260 = validateParameter(valid_608260, JString, required = false,
                                 default = nil)
  if valid_608260 != nil:
    section.add "StorageType", valid_608260
  var valid_608261 = query.getOrDefault("Action")
  valid_608261 = validateParameter(valid_608261, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608261 != nil:
    section.add "Action", valid_608261
  var valid_608262 = query.getOrDefault("MultiAZ")
  valid_608262 = validateParameter(valid_608262, JBool, required = false, default = nil)
  if valid_608262 != nil:
    section.add "MultiAZ", valid_608262
  var valid_608263 = query.getOrDefault("Port")
  valid_608263 = validateParameter(valid_608263, JInt, required = false, default = nil)
  if valid_608263 != nil:
    section.add "Port", valid_608263
  var valid_608264 = query.getOrDefault("AvailabilityZone")
  valid_608264 = validateParameter(valid_608264, JString, required = false,
                                 default = nil)
  if valid_608264 != nil:
    section.add "AvailabilityZone", valid_608264
  var valid_608265 = query.getOrDefault("OptionGroupName")
  valid_608265 = validateParameter(valid_608265, JString, required = false,
                                 default = nil)
  if valid_608265 != nil:
    section.add "OptionGroupName", valid_608265
  var valid_608266 = query.getOrDefault("DBSubnetGroupName")
  valid_608266 = validateParameter(valid_608266, JString, required = false,
                                 default = nil)
  if valid_608266 != nil:
    section.add "DBSubnetGroupName", valid_608266
  var valid_608267 = query.getOrDefault("Version")
  valid_608267 = validateParameter(valid_608267, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608267 != nil:
    section.add "Version", valid_608267
  var valid_608268 = query.getOrDefault("DBInstanceClass")
  valid_608268 = validateParameter(valid_608268, JString, required = false,
                                 default = nil)
  if valid_608268 != nil:
    section.add "DBInstanceClass", valid_608268
  var valid_608269 = query.getOrDefault("PubliclyAccessible")
  valid_608269 = validateParameter(valid_608269, JBool, required = false, default = nil)
  if valid_608269 != nil:
    section.add "PubliclyAccessible", valid_608269
  var valid_608270 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608270 = validateParameter(valid_608270, JBool, required = false, default = nil)
  if valid_608270 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608270
  var valid_608271 = query.getOrDefault("Iops")
  valid_608271 = validateParameter(valid_608271, JInt, required = false, default = nil)
  if valid_608271 != nil:
    section.add "Iops", valid_608271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608272 = header.getOrDefault("X-Amz-Signature")
  valid_608272 = validateParameter(valid_608272, JString, required = false,
                                 default = nil)
  if valid_608272 != nil:
    section.add "X-Amz-Signature", valid_608272
  var valid_608273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608273 = validateParameter(valid_608273, JString, required = false,
                                 default = nil)
  if valid_608273 != nil:
    section.add "X-Amz-Content-Sha256", valid_608273
  var valid_608274 = header.getOrDefault("X-Amz-Date")
  valid_608274 = validateParameter(valid_608274, JString, required = false,
                                 default = nil)
  if valid_608274 != nil:
    section.add "X-Amz-Date", valid_608274
  var valid_608275 = header.getOrDefault("X-Amz-Credential")
  valid_608275 = validateParameter(valid_608275, JString, required = false,
                                 default = nil)
  if valid_608275 != nil:
    section.add "X-Amz-Credential", valid_608275
  var valid_608276 = header.getOrDefault("X-Amz-Security-Token")
  valid_608276 = validateParameter(valid_608276, JString, required = false,
                                 default = nil)
  if valid_608276 != nil:
    section.add "X-Amz-Security-Token", valid_608276
  var valid_608277 = header.getOrDefault("X-Amz-Algorithm")
  valid_608277 = validateParameter(valid_608277, JString, required = false,
                                 default = nil)
  if valid_608277 != nil:
    section.add "X-Amz-Algorithm", valid_608277
  var valid_608278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608278 = validateParameter(valid_608278, JString, required = false,
                                 default = nil)
  if valid_608278 != nil:
    section.add "X-Amz-SignedHeaders", valid_608278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608279: Call_GetRestoreDBInstanceFromDBSnapshot_608249;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608279.validator(path, query, header, formData, body)
  let scheme = call_608279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608279.url(scheme.get, call_608279.host, call_608279.base,
                         call_608279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608279, url, valid)

proc call*(call_608280: Call_GetRestoreDBInstanceFromDBSnapshot_608249;
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
  var query_608281 = newJObject()
  add(query_608281, "DBName", newJString(DBName))
  add(query_608281, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_608281, "Engine", newJString(Engine))
  if Tags != nil:
    query_608281.add "Tags", Tags
  add(query_608281, "LicenseModel", newJString(LicenseModel))
  add(query_608281, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608281, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_608281, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_608281, "StorageType", newJString(StorageType))
  add(query_608281, "Action", newJString(Action))
  add(query_608281, "MultiAZ", newJBool(MultiAZ))
  add(query_608281, "Port", newJInt(Port))
  add(query_608281, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608281, "OptionGroupName", newJString(OptionGroupName))
  add(query_608281, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608281, "Version", newJString(Version))
  add(query_608281, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608281, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608281, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608281, "Iops", newJInt(Iops))
  result = call_608280.call(nil, query_608281, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_608249(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_608250, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_608251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_608351 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceToPointInTime_608353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_608352(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608354 = query.getOrDefault("Action")
  valid_608354 = validateParameter(valid_608354, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608354 != nil:
    section.add "Action", valid_608354
  var valid_608355 = query.getOrDefault("Version")
  valid_608355 = validateParameter(valid_608355, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608355 != nil:
    section.add "Version", valid_608355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608356 = header.getOrDefault("X-Amz-Signature")
  valid_608356 = validateParameter(valid_608356, JString, required = false,
                                 default = nil)
  if valid_608356 != nil:
    section.add "X-Amz-Signature", valid_608356
  var valid_608357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608357 = validateParameter(valid_608357, JString, required = false,
                                 default = nil)
  if valid_608357 != nil:
    section.add "X-Amz-Content-Sha256", valid_608357
  var valid_608358 = header.getOrDefault("X-Amz-Date")
  valid_608358 = validateParameter(valid_608358, JString, required = false,
                                 default = nil)
  if valid_608358 != nil:
    section.add "X-Amz-Date", valid_608358
  var valid_608359 = header.getOrDefault("X-Amz-Credential")
  valid_608359 = validateParameter(valid_608359, JString, required = false,
                                 default = nil)
  if valid_608359 != nil:
    section.add "X-Amz-Credential", valid_608359
  var valid_608360 = header.getOrDefault("X-Amz-Security-Token")
  valid_608360 = validateParameter(valid_608360, JString, required = false,
                                 default = nil)
  if valid_608360 != nil:
    section.add "X-Amz-Security-Token", valid_608360
  var valid_608361 = header.getOrDefault("X-Amz-Algorithm")
  valid_608361 = validateParameter(valid_608361, JString, required = false,
                                 default = nil)
  if valid_608361 != nil:
    section.add "X-Amz-Algorithm", valid_608361
  var valid_608362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608362 = validateParameter(valid_608362, JString, required = false,
                                 default = nil)
  if valid_608362 != nil:
    section.add "X-Amz-SignedHeaders", valid_608362
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
  var valid_608363 = formData.getOrDefault("Port")
  valid_608363 = validateParameter(valid_608363, JInt, required = false, default = nil)
  if valid_608363 != nil:
    section.add "Port", valid_608363
  var valid_608364 = formData.getOrDefault("DBInstanceClass")
  valid_608364 = validateParameter(valid_608364, JString, required = false,
                                 default = nil)
  if valid_608364 != nil:
    section.add "DBInstanceClass", valid_608364
  var valid_608365 = formData.getOrDefault("MultiAZ")
  valid_608365 = validateParameter(valid_608365, JBool, required = false, default = nil)
  if valid_608365 != nil:
    section.add "MultiAZ", valid_608365
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_608366 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_608366 = validateParameter(valid_608366, JString, required = true,
                                 default = nil)
  if valid_608366 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608366
  var valid_608367 = formData.getOrDefault("AvailabilityZone")
  valid_608367 = validateParameter(valid_608367, JString, required = false,
                                 default = nil)
  if valid_608367 != nil:
    section.add "AvailabilityZone", valid_608367
  var valid_608368 = formData.getOrDefault("Engine")
  valid_608368 = validateParameter(valid_608368, JString, required = false,
                                 default = nil)
  if valid_608368 != nil:
    section.add "Engine", valid_608368
  var valid_608369 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608369 = validateParameter(valid_608369, JBool, required = false, default = nil)
  if valid_608369 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608369
  var valid_608370 = formData.getOrDefault("TdeCredentialPassword")
  valid_608370 = validateParameter(valid_608370, JString, required = false,
                                 default = nil)
  if valid_608370 != nil:
    section.add "TdeCredentialPassword", valid_608370
  var valid_608371 = formData.getOrDefault("UseLatestRestorableTime")
  valid_608371 = validateParameter(valid_608371, JBool, required = false, default = nil)
  if valid_608371 != nil:
    section.add "UseLatestRestorableTime", valid_608371
  var valid_608372 = formData.getOrDefault("DBName")
  valid_608372 = validateParameter(valid_608372, JString, required = false,
                                 default = nil)
  if valid_608372 != nil:
    section.add "DBName", valid_608372
  var valid_608373 = formData.getOrDefault("Iops")
  valid_608373 = validateParameter(valid_608373, JInt, required = false, default = nil)
  if valid_608373 != nil:
    section.add "Iops", valid_608373
  var valid_608374 = formData.getOrDefault("TdeCredentialArn")
  valid_608374 = validateParameter(valid_608374, JString, required = false,
                                 default = nil)
  if valid_608374 != nil:
    section.add "TdeCredentialArn", valid_608374
  var valid_608375 = formData.getOrDefault("PubliclyAccessible")
  valid_608375 = validateParameter(valid_608375, JBool, required = false, default = nil)
  if valid_608375 != nil:
    section.add "PubliclyAccessible", valid_608375
  var valid_608376 = formData.getOrDefault("LicenseModel")
  valid_608376 = validateParameter(valid_608376, JString, required = false,
                                 default = nil)
  if valid_608376 != nil:
    section.add "LicenseModel", valid_608376
  var valid_608377 = formData.getOrDefault("Tags")
  valid_608377 = validateParameter(valid_608377, JArray, required = false,
                                 default = nil)
  if valid_608377 != nil:
    section.add "Tags", valid_608377
  var valid_608378 = formData.getOrDefault("DBSubnetGroupName")
  valid_608378 = validateParameter(valid_608378, JString, required = false,
                                 default = nil)
  if valid_608378 != nil:
    section.add "DBSubnetGroupName", valid_608378
  var valid_608379 = formData.getOrDefault("OptionGroupName")
  valid_608379 = validateParameter(valid_608379, JString, required = false,
                                 default = nil)
  if valid_608379 != nil:
    section.add "OptionGroupName", valid_608379
  var valid_608380 = formData.getOrDefault("RestoreTime")
  valid_608380 = validateParameter(valid_608380, JString, required = false,
                                 default = nil)
  if valid_608380 != nil:
    section.add "RestoreTime", valid_608380
  var valid_608381 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_608381 = validateParameter(valid_608381, JString, required = true,
                                 default = nil)
  if valid_608381 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608381
  var valid_608382 = formData.getOrDefault("StorageType")
  valid_608382 = validateParameter(valid_608382, JString, required = false,
                                 default = nil)
  if valid_608382 != nil:
    section.add "StorageType", valid_608382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608383: Call_PostRestoreDBInstanceToPointInTime_608351;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608383.validator(path, query, header, formData, body)
  let scheme = call_608383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608383.url(scheme.get, call_608383.host, call_608383.base,
                         call_608383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608383, url, valid)

proc call*(call_608384: Call_PostRestoreDBInstanceToPointInTime_608351;
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
  var query_608385 = newJObject()
  var formData_608386 = newJObject()
  add(formData_608386, "Port", newJInt(Port))
  add(formData_608386, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608386, "MultiAZ", newJBool(MultiAZ))
  add(formData_608386, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_608386, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608386, "Engine", newJString(Engine))
  add(formData_608386, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608386, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_608386, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_608386, "DBName", newJString(DBName))
  add(formData_608386, "Iops", newJInt(Iops))
  add(formData_608386, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_608386, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608385, "Action", newJString(Action))
  add(formData_608386, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_608386.add "Tags", Tags
  add(formData_608386, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608386, "OptionGroupName", newJString(OptionGroupName))
  add(formData_608386, "RestoreTime", newJString(RestoreTime))
  add(formData_608386, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608385, "Version", newJString(Version))
  add(formData_608386, "StorageType", newJString(StorageType))
  result = call_608384.call(nil, query_608385, nil, formData_608386, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_608351(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_608352, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_608353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_608316 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceToPointInTime_608318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_608317(path: JsonNode;
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
  var valid_608319 = query.getOrDefault("DBName")
  valid_608319 = validateParameter(valid_608319, JString, required = false,
                                 default = nil)
  if valid_608319 != nil:
    section.add "DBName", valid_608319
  var valid_608320 = query.getOrDefault("TdeCredentialPassword")
  valid_608320 = validateParameter(valid_608320, JString, required = false,
                                 default = nil)
  if valid_608320 != nil:
    section.add "TdeCredentialPassword", valid_608320
  var valid_608321 = query.getOrDefault("Engine")
  valid_608321 = validateParameter(valid_608321, JString, required = false,
                                 default = nil)
  if valid_608321 != nil:
    section.add "Engine", valid_608321
  var valid_608322 = query.getOrDefault("UseLatestRestorableTime")
  valid_608322 = validateParameter(valid_608322, JBool, required = false, default = nil)
  if valid_608322 != nil:
    section.add "UseLatestRestorableTime", valid_608322
  var valid_608323 = query.getOrDefault("Tags")
  valid_608323 = validateParameter(valid_608323, JArray, required = false,
                                 default = nil)
  if valid_608323 != nil:
    section.add "Tags", valid_608323
  var valid_608324 = query.getOrDefault("LicenseModel")
  valid_608324 = validateParameter(valid_608324, JString, required = false,
                                 default = nil)
  if valid_608324 != nil:
    section.add "LicenseModel", valid_608324
  var valid_608325 = query.getOrDefault("TdeCredentialArn")
  valid_608325 = validateParameter(valid_608325, JString, required = false,
                                 default = nil)
  if valid_608325 != nil:
    section.add "TdeCredentialArn", valid_608325
  var valid_608326 = query.getOrDefault("StorageType")
  valid_608326 = validateParameter(valid_608326, JString, required = false,
                                 default = nil)
  if valid_608326 != nil:
    section.add "StorageType", valid_608326
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_608327 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_608327 = validateParameter(valid_608327, JString, required = true,
                                 default = nil)
  if valid_608327 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608327
  var valid_608328 = query.getOrDefault("Action")
  valid_608328 = validateParameter(valid_608328, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608328 != nil:
    section.add "Action", valid_608328
  var valid_608329 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_608329 = validateParameter(valid_608329, JString, required = true,
                                 default = nil)
  if valid_608329 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608329
  var valid_608330 = query.getOrDefault("MultiAZ")
  valid_608330 = validateParameter(valid_608330, JBool, required = false, default = nil)
  if valid_608330 != nil:
    section.add "MultiAZ", valid_608330
  var valid_608331 = query.getOrDefault("Port")
  valid_608331 = validateParameter(valid_608331, JInt, required = false, default = nil)
  if valid_608331 != nil:
    section.add "Port", valid_608331
  var valid_608332 = query.getOrDefault("AvailabilityZone")
  valid_608332 = validateParameter(valid_608332, JString, required = false,
                                 default = nil)
  if valid_608332 != nil:
    section.add "AvailabilityZone", valid_608332
  var valid_608333 = query.getOrDefault("OptionGroupName")
  valid_608333 = validateParameter(valid_608333, JString, required = false,
                                 default = nil)
  if valid_608333 != nil:
    section.add "OptionGroupName", valid_608333
  var valid_608334 = query.getOrDefault("DBSubnetGroupName")
  valid_608334 = validateParameter(valid_608334, JString, required = false,
                                 default = nil)
  if valid_608334 != nil:
    section.add "DBSubnetGroupName", valid_608334
  var valid_608335 = query.getOrDefault("RestoreTime")
  valid_608335 = validateParameter(valid_608335, JString, required = false,
                                 default = nil)
  if valid_608335 != nil:
    section.add "RestoreTime", valid_608335
  var valid_608336 = query.getOrDefault("DBInstanceClass")
  valid_608336 = validateParameter(valid_608336, JString, required = false,
                                 default = nil)
  if valid_608336 != nil:
    section.add "DBInstanceClass", valid_608336
  var valid_608337 = query.getOrDefault("PubliclyAccessible")
  valid_608337 = validateParameter(valid_608337, JBool, required = false, default = nil)
  if valid_608337 != nil:
    section.add "PubliclyAccessible", valid_608337
  var valid_608338 = query.getOrDefault("Version")
  valid_608338 = validateParameter(valid_608338, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608338 != nil:
    section.add "Version", valid_608338
  var valid_608339 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608339 = validateParameter(valid_608339, JBool, required = false, default = nil)
  if valid_608339 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608339
  var valid_608340 = query.getOrDefault("Iops")
  valid_608340 = validateParameter(valid_608340, JInt, required = false, default = nil)
  if valid_608340 != nil:
    section.add "Iops", valid_608340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608341 = header.getOrDefault("X-Amz-Signature")
  valid_608341 = validateParameter(valid_608341, JString, required = false,
                                 default = nil)
  if valid_608341 != nil:
    section.add "X-Amz-Signature", valid_608341
  var valid_608342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608342 = validateParameter(valid_608342, JString, required = false,
                                 default = nil)
  if valid_608342 != nil:
    section.add "X-Amz-Content-Sha256", valid_608342
  var valid_608343 = header.getOrDefault("X-Amz-Date")
  valid_608343 = validateParameter(valid_608343, JString, required = false,
                                 default = nil)
  if valid_608343 != nil:
    section.add "X-Amz-Date", valid_608343
  var valid_608344 = header.getOrDefault("X-Amz-Credential")
  valid_608344 = validateParameter(valid_608344, JString, required = false,
                                 default = nil)
  if valid_608344 != nil:
    section.add "X-Amz-Credential", valid_608344
  var valid_608345 = header.getOrDefault("X-Amz-Security-Token")
  valid_608345 = validateParameter(valid_608345, JString, required = false,
                                 default = nil)
  if valid_608345 != nil:
    section.add "X-Amz-Security-Token", valid_608345
  var valid_608346 = header.getOrDefault("X-Amz-Algorithm")
  valid_608346 = validateParameter(valid_608346, JString, required = false,
                                 default = nil)
  if valid_608346 != nil:
    section.add "X-Amz-Algorithm", valid_608346
  var valid_608347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608347 = validateParameter(valid_608347, JString, required = false,
                                 default = nil)
  if valid_608347 != nil:
    section.add "X-Amz-SignedHeaders", valid_608347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608348: Call_GetRestoreDBInstanceToPointInTime_608316;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608348.validator(path, query, header, formData, body)
  let scheme = call_608348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608348.url(scheme.get, call_608348.host, call_608348.base,
                         call_608348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608348, url, valid)

proc call*(call_608349: Call_GetRestoreDBInstanceToPointInTime_608316;
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
  var query_608350 = newJObject()
  add(query_608350, "DBName", newJString(DBName))
  add(query_608350, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_608350, "Engine", newJString(Engine))
  add(query_608350, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_608350.add "Tags", Tags
  add(query_608350, "LicenseModel", newJString(LicenseModel))
  add(query_608350, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_608350, "StorageType", newJString(StorageType))
  add(query_608350, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608350, "Action", newJString(Action))
  add(query_608350, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_608350, "MultiAZ", newJBool(MultiAZ))
  add(query_608350, "Port", newJInt(Port))
  add(query_608350, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608350, "OptionGroupName", newJString(OptionGroupName))
  add(query_608350, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608350, "RestoreTime", newJString(RestoreTime))
  add(query_608350, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608350, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608350, "Version", newJString(Version))
  add(query_608350, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608350, "Iops", newJInt(Iops))
  result = call_608349.call(nil, query_608350, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_608316(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_608317, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_608318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_608407 = ref object of OpenApiRestCall_605573
proc url_PostRevokeDBSecurityGroupIngress_608409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_608408(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608410 = query.getOrDefault("Action")
  valid_608410 = validateParameter(valid_608410, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608410 != nil:
    section.add "Action", valid_608410
  var valid_608411 = query.getOrDefault("Version")
  valid_608411 = validateParameter(valid_608411, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608411 != nil:
    section.add "Version", valid_608411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608412 = header.getOrDefault("X-Amz-Signature")
  valid_608412 = validateParameter(valid_608412, JString, required = false,
                                 default = nil)
  if valid_608412 != nil:
    section.add "X-Amz-Signature", valid_608412
  var valid_608413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608413 = validateParameter(valid_608413, JString, required = false,
                                 default = nil)
  if valid_608413 != nil:
    section.add "X-Amz-Content-Sha256", valid_608413
  var valid_608414 = header.getOrDefault("X-Amz-Date")
  valid_608414 = validateParameter(valid_608414, JString, required = false,
                                 default = nil)
  if valid_608414 != nil:
    section.add "X-Amz-Date", valid_608414
  var valid_608415 = header.getOrDefault("X-Amz-Credential")
  valid_608415 = validateParameter(valid_608415, JString, required = false,
                                 default = nil)
  if valid_608415 != nil:
    section.add "X-Amz-Credential", valid_608415
  var valid_608416 = header.getOrDefault("X-Amz-Security-Token")
  valid_608416 = validateParameter(valid_608416, JString, required = false,
                                 default = nil)
  if valid_608416 != nil:
    section.add "X-Amz-Security-Token", valid_608416
  var valid_608417 = header.getOrDefault("X-Amz-Algorithm")
  valid_608417 = validateParameter(valid_608417, JString, required = false,
                                 default = nil)
  if valid_608417 != nil:
    section.add "X-Amz-Algorithm", valid_608417
  var valid_608418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608418 = validateParameter(valid_608418, JString, required = false,
                                 default = nil)
  if valid_608418 != nil:
    section.add "X-Amz-SignedHeaders", valid_608418
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608419 = formData.getOrDefault("DBSecurityGroupName")
  valid_608419 = validateParameter(valid_608419, JString, required = true,
                                 default = nil)
  if valid_608419 != nil:
    section.add "DBSecurityGroupName", valid_608419
  var valid_608420 = formData.getOrDefault("EC2SecurityGroupName")
  valid_608420 = validateParameter(valid_608420, JString, required = false,
                                 default = nil)
  if valid_608420 != nil:
    section.add "EC2SecurityGroupName", valid_608420
  var valid_608421 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608421 = validateParameter(valid_608421, JString, required = false,
                                 default = nil)
  if valid_608421 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608421
  var valid_608422 = formData.getOrDefault("EC2SecurityGroupId")
  valid_608422 = validateParameter(valid_608422, JString, required = false,
                                 default = nil)
  if valid_608422 != nil:
    section.add "EC2SecurityGroupId", valid_608422
  var valid_608423 = formData.getOrDefault("CIDRIP")
  valid_608423 = validateParameter(valid_608423, JString, required = false,
                                 default = nil)
  if valid_608423 != nil:
    section.add "CIDRIP", valid_608423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608424: Call_PostRevokeDBSecurityGroupIngress_608407;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608424.validator(path, query, header, formData, body)
  let scheme = call_608424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608424.url(scheme.get, call_608424.host, call_608424.base,
                         call_608424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608424, url, valid)

proc call*(call_608425: Call_PostRevokeDBSecurityGroupIngress_608407;
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
  var query_608426 = newJObject()
  var formData_608427 = newJObject()
  add(formData_608427, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_608427, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_608427, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_608427, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_608427, "CIDRIP", newJString(CIDRIP))
  add(query_608426, "Action", newJString(Action))
  add(query_608426, "Version", newJString(Version))
  result = call_608425.call(nil, query_608426, nil, formData_608427, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_608407(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_608408, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_608409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_608387 = ref object of OpenApiRestCall_605573
proc url_GetRevokeDBSecurityGroupIngress_608389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_608388(path: JsonNode;
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
  var valid_608390 = query.getOrDefault("EC2SecurityGroupName")
  valid_608390 = validateParameter(valid_608390, JString, required = false,
                                 default = nil)
  if valid_608390 != nil:
    section.add "EC2SecurityGroupName", valid_608390
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608391 = query.getOrDefault("DBSecurityGroupName")
  valid_608391 = validateParameter(valid_608391, JString, required = true,
                                 default = nil)
  if valid_608391 != nil:
    section.add "DBSecurityGroupName", valid_608391
  var valid_608392 = query.getOrDefault("EC2SecurityGroupId")
  valid_608392 = validateParameter(valid_608392, JString, required = false,
                                 default = nil)
  if valid_608392 != nil:
    section.add "EC2SecurityGroupId", valid_608392
  var valid_608393 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608393 = validateParameter(valid_608393, JString, required = false,
                                 default = nil)
  if valid_608393 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608393
  var valid_608394 = query.getOrDefault("Action")
  valid_608394 = validateParameter(valid_608394, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608394 != nil:
    section.add "Action", valid_608394
  var valid_608395 = query.getOrDefault("Version")
  valid_608395 = validateParameter(valid_608395, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_608395 != nil:
    section.add "Version", valid_608395
  var valid_608396 = query.getOrDefault("CIDRIP")
  valid_608396 = validateParameter(valid_608396, JString, required = false,
                                 default = nil)
  if valid_608396 != nil:
    section.add "CIDRIP", valid_608396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608397 = header.getOrDefault("X-Amz-Signature")
  valid_608397 = validateParameter(valid_608397, JString, required = false,
                                 default = nil)
  if valid_608397 != nil:
    section.add "X-Amz-Signature", valid_608397
  var valid_608398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608398 = validateParameter(valid_608398, JString, required = false,
                                 default = nil)
  if valid_608398 != nil:
    section.add "X-Amz-Content-Sha256", valid_608398
  var valid_608399 = header.getOrDefault("X-Amz-Date")
  valid_608399 = validateParameter(valid_608399, JString, required = false,
                                 default = nil)
  if valid_608399 != nil:
    section.add "X-Amz-Date", valid_608399
  var valid_608400 = header.getOrDefault("X-Amz-Credential")
  valid_608400 = validateParameter(valid_608400, JString, required = false,
                                 default = nil)
  if valid_608400 != nil:
    section.add "X-Amz-Credential", valid_608400
  var valid_608401 = header.getOrDefault("X-Amz-Security-Token")
  valid_608401 = validateParameter(valid_608401, JString, required = false,
                                 default = nil)
  if valid_608401 != nil:
    section.add "X-Amz-Security-Token", valid_608401
  var valid_608402 = header.getOrDefault("X-Amz-Algorithm")
  valid_608402 = validateParameter(valid_608402, JString, required = false,
                                 default = nil)
  if valid_608402 != nil:
    section.add "X-Amz-Algorithm", valid_608402
  var valid_608403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608403 = validateParameter(valid_608403, JString, required = false,
                                 default = nil)
  if valid_608403 != nil:
    section.add "X-Amz-SignedHeaders", valid_608403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608404: Call_GetRevokeDBSecurityGroupIngress_608387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608404.validator(path, query, header, formData, body)
  let scheme = call_608404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608404.url(scheme.get, call_608404.host, call_608404.base,
                         call_608404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608404, url, valid)

proc call*(call_608405: Call_GetRevokeDBSecurityGroupIngress_608387;
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
  var query_608406 = newJObject()
  add(query_608406, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_608406, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_608406, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_608406, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_608406, "Action", newJString(Action))
  add(query_608406, "Version", newJString(Version))
  add(query_608406, "CIDRIP", newJString(CIDRIP))
  result = call_608405.call(nil, query_608406, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_608387(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_608388, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_608389,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

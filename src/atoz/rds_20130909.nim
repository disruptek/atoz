
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_606295 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBSnapshot_606297(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_606296(path: JsonNode; query: JsonNode;
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
  var valid_606298 = query.getOrDefault("Action")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606298 != nil:
    section.add "Action", valid_606298
  var valid_606299 = query.getOrDefault("Version")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606299 != nil:
    section.add "Version", valid_606299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606300 = header.getOrDefault("X-Amz-Signature")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Signature", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Content-Sha256", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Date")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Date", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Credential")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Credential", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Security-Token")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Security-Token", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Algorithm")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Algorithm", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-SignedHeaders", valid_606306
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_606307 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606307 = validateParameter(valid_606307, JString, required = true,
                                 default = nil)
  if valid_606307 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606307
  var valid_606308 = formData.getOrDefault("Tags")
  valid_606308 = validateParameter(valid_606308, JArray, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "Tags", valid_606308
  var valid_606309 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = nil)
  if valid_606309 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606310: Call_PostCopyDBSnapshot_606295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606310.validator(path, query, header, formData, body)
  let scheme = call_606310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606310.url(scheme.get, call_606310.host, call_606310.base,
                         call_606310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606310, url, valid)

proc call*(call_606311: Call_PostCopyDBSnapshot_606295;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606312 = newJObject()
  var formData_606313 = newJObject()
  add(formData_606313, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_606312, "Action", newJString(Action))
  if Tags != nil:
    formData_606313.add "Tags", Tags
  add(formData_606313, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606312, "Version", newJString(Version))
  result = call_606311.call(nil, query_606312, nil, formData_606313, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_606295(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_606296, base: "/",
    url: url_PostCopyDBSnapshot_606297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_606277 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBSnapshot_606279(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_606278(path: JsonNode; query: JsonNode;
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
  var valid_606280 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_606280
  var valid_606281 = query.getOrDefault("Tags")
  valid_606281 = validateParameter(valid_606281, JArray, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "Tags", valid_606281
  var valid_606282 = query.getOrDefault("Action")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_606282 != nil:
    section.add "Action", valid_606282
  var valid_606283 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_606283
  var valid_606284 = query.getOrDefault("Version")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606284 != nil:
    section.add "Version", valid_606284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606285 = header.getOrDefault("X-Amz-Signature")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Signature", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Content-Sha256", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Date")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Date", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Credential")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Credential", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Security-Token")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Security-Token", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Algorithm")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Algorithm", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-SignedHeaders", valid_606291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_GetCopyDBSnapshot_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_GetCopyDBSnapshot_606277;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_606294 = newJObject()
  add(query_606294, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_606294.add "Tags", Tags
  add(query_606294, "Action", newJString(Action))
  add(query_606294, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_606294, "Version", newJString(Version))
  result = call_606293.call(nil, query_606294, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_606277(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_606278,
    base: "/", url: url_GetCopyDBSnapshot_606279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_606354 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstance_606356(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_606355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606357 = query.getOrDefault("Action")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606357 != nil:
    section.add "Action", valid_606357
  var valid_606358 = query.getOrDefault("Version")
  valid_606358 = validateParameter(valid_606358, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606358 != nil:
    section.add "Version", valid_606358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606359 = header.getOrDefault("X-Amz-Signature")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Signature", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Content-Sha256", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Date")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Date", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Credential")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Credential", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Security-Token")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Security-Token", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Algorithm")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Algorithm", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-SignedHeaders", valid_606365
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
  var valid_606366 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "PreferredMaintenanceWindow", valid_606366
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_606367 = formData.getOrDefault("DBInstanceClass")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = nil)
  if valid_606367 != nil:
    section.add "DBInstanceClass", valid_606367
  var valid_606368 = formData.getOrDefault("Port")
  valid_606368 = validateParameter(valid_606368, JInt, required = false, default = nil)
  if valid_606368 != nil:
    section.add "Port", valid_606368
  var valid_606369 = formData.getOrDefault("PreferredBackupWindow")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "PreferredBackupWindow", valid_606369
  var valid_606370 = formData.getOrDefault("MasterUserPassword")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = nil)
  if valid_606370 != nil:
    section.add "MasterUserPassword", valid_606370
  var valid_606371 = formData.getOrDefault("MultiAZ")
  valid_606371 = validateParameter(valid_606371, JBool, required = false, default = nil)
  if valid_606371 != nil:
    section.add "MultiAZ", valid_606371
  var valid_606372 = formData.getOrDefault("MasterUsername")
  valid_606372 = validateParameter(valid_606372, JString, required = true,
                                 default = nil)
  if valid_606372 != nil:
    section.add "MasterUsername", valid_606372
  var valid_606373 = formData.getOrDefault("DBParameterGroupName")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "DBParameterGroupName", valid_606373
  var valid_606374 = formData.getOrDefault("EngineVersion")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "EngineVersion", valid_606374
  var valid_606375 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_606375 = validateParameter(valid_606375, JArray, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "VpcSecurityGroupIds", valid_606375
  var valid_606376 = formData.getOrDefault("AvailabilityZone")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "AvailabilityZone", valid_606376
  var valid_606377 = formData.getOrDefault("BackupRetentionPeriod")
  valid_606377 = validateParameter(valid_606377, JInt, required = false, default = nil)
  if valid_606377 != nil:
    section.add "BackupRetentionPeriod", valid_606377
  var valid_606378 = formData.getOrDefault("Engine")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = nil)
  if valid_606378 != nil:
    section.add "Engine", valid_606378
  var valid_606379 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606379 = validateParameter(valid_606379, JBool, required = false, default = nil)
  if valid_606379 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606379
  var valid_606380 = formData.getOrDefault("DBName")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "DBName", valid_606380
  var valid_606381 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606381 = validateParameter(valid_606381, JString, required = true,
                                 default = nil)
  if valid_606381 != nil:
    section.add "DBInstanceIdentifier", valid_606381
  var valid_606382 = formData.getOrDefault("Iops")
  valid_606382 = validateParameter(valid_606382, JInt, required = false, default = nil)
  if valid_606382 != nil:
    section.add "Iops", valid_606382
  var valid_606383 = formData.getOrDefault("PubliclyAccessible")
  valid_606383 = validateParameter(valid_606383, JBool, required = false, default = nil)
  if valid_606383 != nil:
    section.add "PubliclyAccessible", valid_606383
  var valid_606384 = formData.getOrDefault("LicenseModel")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "LicenseModel", valid_606384
  var valid_606385 = formData.getOrDefault("Tags")
  valid_606385 = validateParameter(valid_606385, JArray, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "Tags", valid_606385
  var valid_606386 = formData.getOrDefault("DBSubnetGroupName")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "DBSubnetGroupName", valid_606386
  var valid_606387 = formData.getOrDefault("OptionGroupName")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "OptionGroupName", valid_606387
  var valid_606388 = formData.getOrDefault("CharacterSetName")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "CharacterSetName", valid_606388
  var valid_606389 = formData.getOrDefault("DBSecurityGroups")
  valid_606389 = validateParameter(valid_606389, JArray, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "DBSecurityGroups", valid_606389
  var valid_606390 = formData.getOrDefault("AllocatedStorage")
  valid_606390 = validateParameter(valid_606390, JInt, required = true, default = nil)
  if valid_606390 != nil:
    section.add "AllocatedStorage", valid_606390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606391: Call_PostCreateDBInstance_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606391.validator(path, query, header, formData, body)
  let scheme = call_606391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606391.url(scheme.get, call_606391.host, call_606391.base,
                         call_606391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606391, url, valid)

proc call*(call_606392: Call_PostCreateDBInstance_606354; DBInstanceClass: string;
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
  var query_606393 = newJObject()
  var formData_606394 = newJObject()
  add(formData_606394, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_606394, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606394, "Port", newJInt(Port))
  add(formData_606394, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_606394, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_606394, "MultiAZ", newJBool(MultiAZ))
  add(formData_606394, "MasterUsername", newJString(MasterUsername))
  add(formData_606394, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_606394, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_606394.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_606394, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606394, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_606394, "Engine", newJString(Engine))
  add(formData_606394, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606394, "DBName", newJString(DBName))
  add(formData_606394, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606394, "Iops", newJInt(Iops))
  add(formData_606394, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606393, "Action", newJString(Action))
  add(formData_606394, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_606394.add "Tags", Tags
  add(formData_606394, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606394, "OptionGroupName", newJString(OptionGroupName))
  add(formData_606394, "CharacterSetName", newJString(CharacterSetName))
  add(query_606393, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_606394.add "DBSecurityGroups", DBSecurityGroups
  add(formData_606394, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_606392.call(nil, query_606393, nil, formData_606394, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_606354(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_606355, base: "/",
    url: url_PostCreateDBInstance_606356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_606314 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstance_606316(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_606315(path: JsonNode; query: JsonNode;
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
  var valid_606317 = query.getOrDefault("Version")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606317 != nil:
    section.add "Version", valid_606317
  var valid_606318 = query.getOrDefault("DBName")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "DBName", valid_606318
  var valid_606319 = query.getOrDefault("Engine")
  valid_606319 = validateParameter(valid_606319, JString, required = true,
                                 default = nil)
  if valid_606319 != nil:
    section.add "Engine", valid_606319
  var valid_606320 = query.getOrDefault("DBParameterGroupName")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "DBParameterGroupName", valid_606320
  var valid_606321 = query.getOrDefault("CharacterSetName")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "CharacterSetName", valid_606321
  var valid_606322 = query.getOrDefault("Tags")
  valid_606322 = validateParameter(valid_606322, JArray, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "Tags", valid_606322
  var valid_606323 = query.getOrDefault("LicenseModel")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "LicenseModel", valid_606323
  var valid_606324 = query.getOrDefault("DBInstanceIdentifier")
  valid_606324 = validateParameter(valid_606324, JString, required = true,
                                 default = nil)
  if valid_606324 != nil:
    section.add "DBInstanceIdentifier", valid_606324
  var valid_606325 = query.getOrDefault("MasterUsername")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "MasterUsername", valid_606325
  var valid_606326 = query.getOrDefault("BackupRetentionPeriod")
  valid_606326 = validateParameter(valid_606326, JInt, required = false, default = nil)
  if valid_606326 != nil:
    section.add "BackupRetentionPeriod", valid_606326
  var valid_606327 = query.getOrDefault("EngineVersion")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "EngineVersion", valid_606327
  var valid_606328 = query.getOrDefault("Action")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606328 != nil:
    section.add "Action", valid_606328
  var valid_606329 = query.getOrDefault("MultiAZ")
  valid_606329 = validateParameter(valid_606329, JBool, required = false, default = nil)
  if valid_606329 != nil:
    section.add "MultiAZ", valid_606329
  var valid_606330 = query.getOrDefault("DBSecurityGroups")
  valid_606330 = validateParameter(valid_606330, JArray, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "DBSecurityGroups", valid_606330
  var valid_606331 = query.getOrDefault("Port")
  valid_606331 = validateParameter(valid_606331, JInt, required = false, default = nil)
  if valid_606331 != nil:
    section.add "Port", valid_606331
  var valid_606332 = query.getOrDefault("VpcSecurityGroupIds")
  valid_606332 = validateParameter(valid_606332, JArray, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "VpcSecurityGroupIds", valid_606332
  var valid_606333 = query.getOrDefault("MasterUserPassword")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "MasterUserPassword", valid_606333
  var valid_606334 = query.getOrDefault("AvailabilityZone")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "AvailabilityZone", valid_606334
  var valid_606335 = query.getOrDefault("OptionGroupName")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "OptionGroupName", valid_606335
  var valid_606336 = query.getOrDefault("DBSubnetGroupName")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "DBSubnetGroupName", valid_606336
  var valid_606337 = query.getOrDefault("AllocatedStorage")
  valid_606337 = validateParameter(valid_606337, JInt, required = true, default = nil)
  if valid_606337 != nil:
    section.add "AllocatedStorage", valid_606337
  var valid_606338 = query.getOrDefault("DBInstanceClass")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = nil)
  if valid_606338 != nil:
    section.add "DBInstanceClass", valid_606338
  var valid_606339 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "PreferredMaintenanceWindow", valid_606339
  var valid_606340 = query.getOrDefault("PreferredBackupWindow")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "PreferredBackupWindow", valid_606340
  var valid_606341 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606341 = validateParameter(valid_606341, JBool, required = false, default = nil)
  if valid_606341 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606341
  var valid_606342 = query.getOrDefault("Iops")
  valid_606342 = validateParameter(valid_606342, JInt, required = false, default = nil)
  if valid_606342 != nil:
    section.add "Iops", valid_606342
  var valid_606343 = query.getOrDefault("PubliclyAccessible")
  valid_606343 = validateParameter(valid_606343, JBool, required = false, default = nil)
  if valid_606343 != nil:
    section.add "PubliclyAccessible", valid_606343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606344 = header.getOrDefault("X-Amz-Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Signature", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Content-Sha256", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Date")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Date", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Credential")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Credential", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Security-Token")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Security-Token", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Algorithm")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Algorithm", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-SignedHeaders", valid_606350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606351: Call_GetCreateDBInstance_606314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606351.validator(path, query, header, formData, body)
  let scheme = call_606351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606351.url(scheme.get, call_606351.host, call_606351.base,
                         call_606351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606351, url, valid)

proc call*(call_606352: Call_GetCreateDBInstance_606314; Engine: string;
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
  var query_606353 = newJObject()
  add(query_606353, "Version", newJString(Version))
  add(query_606353, "DBName", newJString(DBName))
  add(query_606353, "Engine", newJString(Engine))
  add(query_606353, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606353, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_606353.add "Tags", Tags
  add(query_606353, "LicenseModel", newJString(LicenseModel))
  add(query_606353, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606353, "MasterUsername", newJString(MasterUsername))
  add(query_606353, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_606353, "EngineVersion", newJString(EngineVersion))
  add(query_606353, "Action", newJString(Action))
  add(query_606353, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_606353.add "DBSecurityGroups", DBSecurityGroups
  add(query_606353, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_606353.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_606353, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_606353, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606353, "OptionGroupName", newJString(OptionGroupName))
  add(query_606353, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606353, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_606353, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606353, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_606353, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_606353, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606353, "Iops", newJInt(Iops))
  add(query_606353, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_606352.call(nil, query_606353, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_606314(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_606315, base: "/",
    url: url_GetCreateDBInstance_606316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_606421 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstanceReadReplica_606423(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_606422(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606424 = query.getOrDefault("Action")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606424 != nil:
    section.add "Action", valid_606424
  var valid_606425 = query.getOrDefault("Version")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606425 != nil:
    section.add "Version", valid_606425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606426 = header.getOrDefault("X-Amz-Signature")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Signature", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Content-Sha256", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Date")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Date", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Credential")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Credential", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Security-Token")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Security-Token", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Algorithm")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Algorithm", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-SignedHeaders", valid_606432
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
  var valid_606433 = formData.getOrDefault("Port")
  valid_606433 = validateParameter(valid_606433, JInt, required = false, default = nil)
  if valid_606433 != nil:
    section.add "Port", valid_606433
  var valid_606434 = formData.getOrDefault("DBInstanceClass")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "DBInstanceClass", valid_606434
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_606435 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_606435 = validateParameter(valid_606435, JString, required = true,
                                 default = nil)
  if valid_606435 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606435
  var valid_606436 = formData.getOrDefault("AvailabilityZone")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "AvailabilityZone", valid_606436
  var valid_606437 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606437 = validateParameter(valid_606437, JBool, required = false, default = nil)
  if valid_606437 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606437
  var valid_606438 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "DBInstanceIdentifier", valid_606438
  var valid_606439 = formData.getOrDefault("Iops")
  valid_606439 = validateParameter(valid_606439, JInt, required = false, default = nil)
  if valid_606439 != nil:
    section.add "Iops", valid_606439
  var valid_606440 = formData.getOrDefault("PubliclyAccessible")
  valid_606440 = validateParameter(valid_606440, JBool, required = false, default = nil)
  if valid_606440 != nil:
    section.add "PubliclyAccessible", valid_606440
  var valid_606441 = formData.getOrDefault("Tags")
  valid_606441 = validateParameter(valid_606441, JArray, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "Tags", valid_606441
  var valid_606442 = formData.getOrDefault("DBSubnetGroupName")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "DBSubnetGroupName", valid_606442
  var valid_606443 = formData.getOrDefault("OptionGroupName")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "OptionGroupName", valid_606443
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606444: Call_PostCreateDBInstanceReadReplica_606421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_606444.validator(path, query, header, formData, body)
  let scheme = call_606444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606444.url(scheme.get, call_606444.host, call_606444.base,
                         call_606444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606444, url, valid)

proc call*(call_606445: Call_PostCreateDBInstanceReadReplica_606421;
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
  var query_606446 = newJObject()
  var formData_606447 = newJObject()
  add(formData_606447, "Port", newJInt(Port))
  add(formData_606447, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606447, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_606447, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606447, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606447, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606447, "Iops", newJInt(Iops))
  add(formData_606447, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606446, "Action", newJString(Action))
  if Tags != nil:
    formData_606447.add "Tags", Tags
  add(formData_606447, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606447, "OptionGroupName", newJString(OptionGroupName))
  add(query_606446, "Version", newJString(Version))
  result = call_606445.call(nil, query_606446, nil, formData_606447, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_606421(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_606422, base: "/",
    url: url_PostCreateDBInstanceReadReplica_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_606395 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstanceReadReplica_606397(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_606396(path: JsonNode;
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
  var valid_606398 = query.getOrDefault("Tags")
  valid_606398 = validateParameter(valid_606398, JArray, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "Tags", valid_606398
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606399 = query.getOrDefault("DBInstanceIdentifier")
  valid_606399 = validateParameter(valid_606399, JString, required = true,
                                 default = nil)
  if valid_606399 != nil:
    section.add "DBInstanceIdentifier", valid_606399
  var valid_606400 = query.getOrDefault("Action")
  valid_606400 = validateParameter(valid_606400, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_606400 != nil:
    section.add "Action", valid_606400
  var valid_606401 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_606401 = validateParameter(valid_606401, JString, required = true,
                                 default = nil)
  if valid_606401 != nil:
    section.add "SourceDBInstanceIdentifier", valid_606401
  var valid_606402 = query.getOrDefault("Port")
  valid_606402 = validateParameter(valid_606402, JInt, required = false, default = nil)
  if valid_606402 != nil:
    section.add "Port", valid_606402
  var valid_606403 = query.getOrDefault("AvailabilityZone")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "AvailabilityZone", valid_606403
  var valid_606404 = query.getOrDefault("OptionGroupName")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "OptionGroupName", valid_606404
  var valid_606405 = query.getOrDefault("DBSubnetGroupName")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "DBSubnetGroupName", valid_606405
  var valid_606406 = query.getOrDefault("Version")
  valid_606406 = validateParameter(valid_606406, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606406 != nil:
    section.add "Version", valid_606406
  var valid_606407 = query.getOrDefault("DBInstanceClass")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "DBInstanceClass", valid_606407
  var valid_606408 = query.getOrDefault("PubliclyAccessible")
  valid_606408 = validateParameter(valid_606408, JBool, required = false, default = nil)
  if valid_606408 != nil:
    section.add "PubliclyAccessible", valid_606408
  var valid_606409 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606409 = validateParameter(valid_606409, JBool, required = false, default = nil)
  if valid_606409 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606409
  var valid_606410 = query.getOrDefault("Iops")
  valid_606410 = validateParameter(valid_606410, JInt, required = false, default = nil)
  if valid_606410 != nil:
    section.add "Iops", valid_606410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Security-Token")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Security-Token", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Algorithm")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Algorithm", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-SignedHeaders", valid_606417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_GetCreateDBInstanceReadReplica_606395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_GetCreateDBInstanceReadReplica_606395;
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
  var query_606420 = newJObject()
  if Tags != nil:
    query_606420.add "Tags", Tags
  add(query_606420, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606420, "Action", newJString(Action))
  add(query_606420, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_606420, "Port", newJInt(Port))
  add(query_606420, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606420, "OptionGroupName", newJString(OptionGroupName))
  add(query_606420, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606420, "Version", newJString(Version))
  add(query_606420, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606420, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_606420, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_606420, "Iops", newJInt(Iops))
  result = call_606419.call(nil, query_606420, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_606395(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_606396, base: "/",
    url: url_GetCreateDBInstanceReadReplica_606397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_606467 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBParameterGroup_606469(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_606468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606470 = query.getOrDefault("Action")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606470 != nil:
    section.add "Action", valid_606470
  var valid_606471 = query.getOrDefault("Version")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606471 != nil:
    section.add "Version", valid_606471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606472 = header.getOrDefault("X-Amz-Signature")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Signature", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Content-Sha256", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Date")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Date", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Credential")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Credential", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Security-Token")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Security-Token", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Algorithm")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Algorithm", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-SignedHeaders", valid_606478
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_606479 = formData.getOrDefault("Description")
  valid_606479 = validateParameter(valid_606479, JString, required = true,
                                 default = nil)
  if valid_606479 != nil:
    section.add "Description", valid_606479
  var valid_606480 = formData.getOrDefault("DBParameterGroupName")
  valid_606480 = validateParameter(valid_606480, JString, required = true,
                                 default = nil)
  if valid_606480 != nil:
    section.add "DBParameterGroupName", valid_606480
  var valid_606481 = formData.getOrDefault("Tags")
  valid_606481 = validateParameter(valid_606481, JArray, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "Tags", valid_606481
  var valid_606482 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = nil)
  if valid_606482 != nil:
    section.add "DBParameterGroupFamily", valid_606482
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606483: Call_PostCreateDBParameterGroup_606467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606483.validator(path, query, header, formData, body)
  let scheme = call_606483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606483.url(scheme.get, call_606483.host, call_606483.base,
                         call_606483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606483, url, valid)

proc call*(call_606484: Call_PostCreateDBParameterGroup_606467;
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
  var query_606485 = newJObject()
  var formData_606486 = newJObject()
  add(formData_606486, "Description", newJString(Description))
  add(formData_606486, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606485, "Action", newJString(Action))
  if Tags != nil:
    formData_606486.add "Tags", Tags
  add(query_606485, "Version", newJString(Version))
  add(formData_606486, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606484.call(nil, query_606485, nil, formData_606486, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_606467(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_606468, base: "/",
    url: url_PostCreateDBParameterGroup_606469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_606448 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBParameterGroup_606450(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_606449(path: JsonNode; query: JsonNode;
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
  var valid_606451 = query.getOrDefault("DBParameterGroupFamily")
  valid_606451 = validateParameter(valid_606451, JString, required = true,
                                 default = nil)
  if valid_606451 != nil:
    section.add "DBParameterGroupFamily", valid_606451
  var valid_606452 = query.getOrDefault("DBParameterGroupName")
  valid_606452 = validateParameter(valid_606452, JString, required = true,
                                 default = nil)
  if valid_606452 != nil:
    section.add "DBParameterGroupName", valid_606452
  var valid_606453 = query.getOrDefault("Tags")
  valid_606453 = validateParameter(valid_606453, JArray, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "Tags", valid_606453
  var valid_606454 = query.getOrDefault("Action")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_606454 != nil:
    section.add "Action", valid_606454
  var valid_606455 = query.getOrDefault("Description")
  valid_606455 = validateParameter(valid_606455, JString, required = true,
                                 default = nil)
  if valid_606455 != nil:
    section.add "Description", valid_606455
  var valid_606456 = query.getOrDefault("Version")
  valid_606456 = validateParameter(valid_606456, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606456 != nil:
    section.add "Version", valid_606456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606457 = header.getOrDefault("X-Amz-Signature")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Signature", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Content-Sha256", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Date")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Date", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Credential")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Credential", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Security-Token")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Security-Token", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Algorithm")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Algorithm", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-SignedHeaders", valid_606463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606464: Call_GetCreateDBParameterGroup_606448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606464.validator(path, query, header, formData, body)
  let scheme = call_606464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606464.url(scheme.get, call_606464.host, call_606464.base,
                         call_606464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606464, url, valid)

proc call*(call_606465: Call_GetCreateDBParameterGroup_606448;
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
  var query_606466 = newJObject()
  add(query_606466, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606466, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_606466.add "Tags", Tags
  add(query_606466, "Action", newJString(Action))
  add(query_606466, "Description", newJString(Description))
  add(query_606466, "Version", newJString(Version))
  result = call_606465.call(nil, query_606466, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_606448(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_606449, base: "/",
    url: url_GetCreateDBParameterGroup_606450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_606505 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSecurityGroup_606507(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_606506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606508 = query.getOrDefault("Action")
  valid_606508 = validateParameter(valid_606508, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606508 != nil:
    section.add "Action", valid_606508
  var valid_606509 = query.getOrDefault("Version")
  valid_606509 = validateParameter(valid_606509, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606509 != nil:
    section.add "Version", valid_606509
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606510 = header.getOrDefault("X-Amz-Signature")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Signature", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Content-Sha256", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Date")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Date", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Credential")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Credential", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Security-Token")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Security-Token", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Algorithm")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Algorithm", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-SignedHeaders", valid_606516
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_606517 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_606517 = validateParameter(valid_606517, JString, required = true,
                                 default = nil)
  if valid_606517 != nil:
    section.add "DBSecurityGroupDescription", valid_606517
  var valid_606518 = formData.getOrDefault("DBSecurityGroupName")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = nil)
  if valid_606518 != nil:
    section.add "DBSecurityGroupName", valid_606518
  var valid_606519 = formData.getOrDefault("Tags")
  valid_606519 = validateParameter(valid_606519, JArray, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "Tags", valid_606519
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606520: Call_PostCreateDBSecurityGroup_606505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606520.validator(path, query, header, formData, body)
  let scheme = call_606520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606520.url(scheme.get, call_606520.host, call_606520.base,
                         call_606520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606520, url, valid)

proc call*(call_606521: Call_PostCreateDBSecurityGroup_606505;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_606522 = newJObject()
  var formData_606523 = newJObject()
  add(formData_606523, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_606523, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606522, "Action", newJString(Action))
  if Tags != nil:
    formData_606523.add "Tags", Tags
  add(query_606522, "Version", newJString(Version))
  result = call_606521.call(nil, query_606522, nil, formData_606523, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_606505(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_606506, base: "/",
    url: url_PostCreateDBSecurityGroup_606507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_606487 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSecurityGroup_606489(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_606488(path: JsonNode; query: JsonNode;
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
  var valid_606490 = query.getOrDefault("DBSecurityGroupName")
  valid_606490 = validateParameter(valid_606490, JString, required = true,
                                 default = nil)
  if valid_606490 != nil:
    section.add "DBSecurityGroupName", valid_606490
  var valid_606491 = query.getOrDefault("Tags")
  valid_606491 = validateParameter(valid_606491, JArray, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "Tags", valid_606491
  var valid_606492 = query.getOrDefault("DBSecurityGroupDescription")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = nil)
  if valid_606492 != nil:
    section.add "DBSecurityGroupDescription", valid_606492
  var valid_606493 = query.getOrDefault("Action")
  valid_606493 = validateParameter(valid_606493, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_606493 != nil:
    section.add "Action", valid_606493
  var valid_606494 = query.getOrDefault("Version")
  valid_606494 = validateParameter(valid_606494, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606494 != nil:
    section.add "Version", valid_606494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606495 = header.getOrDefault("X-Amz-Signature")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Signature", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Content-Sha256", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Date")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Date", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Credential")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Credential", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Security-Token")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Security-Token", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Algorithm")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Algorithm", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-SignedHeaders", valid_606501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606502: Call_GetCreateDBSecurityGroup_606487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606502.validator(path, query, header, formData, body)
  let scheme = call_606502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606502.url(scheme.get, call_606502.host, call_606502.base,
                         call_606502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606502, url, valid)

proc call*(call_606503: Call_GetCreateDBSecurityGroup_606487;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606504 = newJObject()
  add(query_606504, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_606504.add "Tags", Tags
  add(query_606504, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_606504, "Action", newJString(Action))
  add(query_606504, "Version", newJString(Version))
  result = call_606503.call(nil, query_606504, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_606487(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_606488, base: "/",
    url: url_GetCreateDBSecurityGroup_606489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_606542 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSnapshot_606544(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_606543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606545 = query.getOrDefault("Action")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606545 != nil:
    section.add "Action", valid_606545
  var valid_606546 = query.getOrDefault("Version")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606546 != nil:
    section.add "Version", valid_606546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Security-Token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Security-Token", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Algorithm")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Algorithm", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-SignedHeaders", valid_606553
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606554 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606554 = validateParameter(valid_606554, JString, required = true,
                                 default = nil)
  if valid_606554 != nil:
    section.add "DBInstanceIdentifier", valid_606554
  var valid_606555 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606555 = validateParameter(valid_606555, JString, required = true,
                                 default = nil)
  if valid_606555 != nil:
    section.add "DBSnapshotIdentifier", valid_606555
  var valid_606556 = formData.getOrDefault("Tags")
  valid_606556 = validateParameter(valid_606556, JArray, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "Tags", valid_606556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606557: Call_PostCreateDBSnapshot_606542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606557.validator(path, query, header, formData, body)
  let scheme = call_606557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606557.url(scheme.get, call_606557.host, call_606557.base,
                         call_606557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606557, url, valid)

proc call*(call_606558: Call_PostCreateDBSnapshot_606542;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_606559 = newJObject()
  var formData_606560 = newJObject()
  add(formData_606560, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_606560, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606559, "Action", newJString(Action))
  if Tags != nil:
    formData_606560.add "Tags", Tags
  add(query_606559, "Version", newJString(Version))
  result = call_606558.call(nil, query_606559, nil, formData_606560, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_606542(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_606543, base: "/",
    url: url_PostCreateDBSnapshot_606544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_606524 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSnapshot_606526(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_606525(path: JsonNode; query: JsonNode;
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
  var valid_606527 = query.getOrDefault("Tags")
  valid_606527 = validateParameter(valid_606527, JArray, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "Tags", valid_606527
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606528 = query.getOrDefault("DBInstanceIdentifier")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = nil)
  if valid_606528 != nil:
    section.add "DBInstanceIdentifier", valid_606528
  var valid_606529 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "DBSnapshotIdentifier", valid_606529
  var valid_606530 = query.getOrDefault("Action")
  valid_606530 = validateParameter(valid_606530, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_606530 != nil:
    section.add "Action", valid_606530
  var valid_606531 = query.getOrDefault("Version")
  valid_606531 = validateParameter(valid_606531, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606531 != nil:
    section.add "Version", valid_606531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606532 = header.getOrDefault("X-Amz-Signature")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Signature", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Content-Sha256", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Date")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Date", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Credential")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Credential", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Security-Token")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Security-Token", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Algorithm")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Algorithm", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-SignedHeaders", valid_606538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_GetCreateDBSnapshot_606524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_GetCreateDBSnapshot_606524;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606541 = newJObject()
  if Tags != nil:
    query_606541.add "Tags", Tags
  add(query_606541, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606541, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606541, "Action", newJString(Action))
  add(query_606541, "Version", newJString(Version))
  result = call_606540.call(nil, query_606541, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_606524(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_606525, base: "/",
    url: url_GetCreateDBSnapshot_606526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_606580 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSubnetGroup_606582(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_606581(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606583 = query.getOrDefault("Action")
  valid_606583 = validateParameter(valid_606583, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606583 != nil:
    section.add "Action", valid_606583
  var valid_606584 = query.getOrDefault("Version")
  valid_606584 = validateParameter(valid_606584, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606584 != nil:
    section.add "Version", valid_606584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606585 = header.getOrDefault("X-Amz-Signature")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Signature", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Content-Sha256", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Date")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Date", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Credential")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Credential", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Security-Token")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Security-Token", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Algorithm")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Algorithm", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-SignedHeaders", valid_606591
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_606592 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_606592 = validateParameter(valid_606592, JString, required = true,
                                 default = nil)
  if valid_606592 != nil:
    section.add "DBSubnetGroupDescription", valid_606592
  var valid_606593 = formData.getOrDefault("Tags")
  valid_606593 = validateParameter(valid_606593, JArray, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "Tags", valid_606593
  var valid_606594 = formData.getOrDefault("DBSubnetGroupName")
  valid_606594 = validateParameter(valid_606594, JString, required = true,
                                 default = nil)
  if valid_606594 != nil:
    section.add "DBSubnetGroupName", valid_606594
  var valid_606595 = formData.getOrDefault("SubnetIds")
  valid_606595 = validateParameter(valid_606595, JArray, required = true, default = nil)
  if valid_606595 != nil:
    section.add "SubnetIds", valid_606595
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606596: Call_PostCreateDBSubnetGroup_606580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606596.validator(path, query, header, formData, body)
  let scheme = call_606596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606596.url(scheme.get, call_606596.host, call_606596.base,
                         call_606596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606596, url, valid)

proc call*(call_606597: Call_PostCreateDBSubnetGroup_606580;
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
  var query_606598 = newJObject()
  var formData_606599 = newJObject()
  add(formData_606599, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606598, "Action", newJString(Action))
  if Tags != nil:
    formData_606599.add "Tags", Tags
  add(formData_606599, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606598, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_606599.add "SubnetIds", SubnetIds
  result = call_606597.call(nil, query_606598, nil, formData_606599, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_606580(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_606581, base: "/",
    url: url_PostCreateDBSubnetGroup_606582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_606561 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSubnetGroup_606563(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_606562(path: JsonNode; query: JsonNode;
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
  var valid_606564 = query.getOrDefault("Tags")
  valid_606564 = validateParameter(valid_606564, JArray, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "Tags", valid_606564
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_606565 = query.getOrDefault("SubnetIds")
  valid_606565 = validateParameter(valid_606565, JArray, required = true, default = nil)
  if valid_606565 != nil:
    section.add "SubnetIds", valid_606565
  var valid_606566 = query.getOrDefault("Action")
  valid_606566 = validateParameter(valid_606566, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606566 != nil:
    section.add "Action", valid_606566
  var valid_606567 = query.getOrDefault("DBSubnetGroupDescription")
  valid_606567 = validateParameter(valid_606567, JString, required = true,
                                 default = nil)
  if valid_606567 != nil:
    section.add "DBSubnetGroupDescription", valid_606567
  var valid_606568 = query.getOrDefault("DBSubnetGroupName")
  valid_606568 = validateParameter(valid_606568, JString, required = true,
                                 default = nil)
  if valid_606568 != nil:
    section.add "DBSubnetGroupName", valid_606568
  var valid_606569 = query.getOrDefault("Version")
  valid_606569 = validateParameter(valid_606569, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606569 != nil:
    section.add "Version", valid_606569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606570 = header.getOrDefault("X-Amz-Signature")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Signature", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Content-Sha256", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Date")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Date", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Credential")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Credential", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Security-Token")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Security-Token", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Algorithm")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Algorithm", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-SignedHeaders", valid_606576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606577: Call_GetCreateDBSubnetGroup_606561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606577.validator(path, query, header, formData, body)
  let scheme = call_606577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606577.url(scheme.get, call_606577.host, call_606577.base,
                         call_606577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606577, url, valid)

proc call*(call_606578: Call_GetCreateDBSubnetGroup_606561; SubnetIds: JsonNode;
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
  var query_606579 = newJObject()
  if Tags != nil:
    query_606579.add "Tags", Tags
  if SubnetIds != nil:
    query_606579.add "SubnetIds", SubnetIds
  add(query_606579, "Action", newJString(Action))
  add(query_606579, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606579, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606579, "Version", newJString(Version))
  result = call_606578.call(nil, query_606579, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_606561(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_606562, base: "/",
    url: url_GetCreateDBSubnetGroup_606563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_606622 = ref object of OpenApiRestCall_605573
proc url_PostCreateEventSubscription_606624(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_606623(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606625 = query.getOrDefault("Action")
  valid_606625 = validateParameter(valid_606625, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606625 != nil:
    section.add "Action", valid_606625
  var valid_606626 = query.getOrDefault("Version")
  valid_606626 = validateParameter(valid_606626, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606626 != nil:
    section.add "Version", valid_606626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
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
  var valid_606634 = formData.getOrDefault("SourceIds")
  valid_606634 = validateParameter(valid_606634, JArray, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "SourceIds", valid_606634
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_606635 = formData.getOrDefault("SnsTopicArn")
  valid_606635 = validateParameter(valid_606635, JString, required = true,
                                 default = nil)
  if valid_606635 != nil:
    section.add "SnsTopicArn", valid_606635
  var valid_606636 = formData.getOrDefault("Enabled")
  valid_606636 = validateParameter(valid_606636, JBool, required = false, default = nil)
  if valid_606636 != nil:
    section.add "Enabled", valid_606636
  var valid_606637 = formData.getOrDefault("SubscriptionName")
  valid_606637 = validateParameter(valid_606637, JString, required = true,
                                 default = nil)
  if valid_606637 != nil:
    section.add "SubscriptionName", valid_606637
  var valid_606638 = formData.getOrDefault("SourceType")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "SourceType", valid_606638
  var valid_606639 = formData.getOrDefault("EventCategories")
  valid_606639 = validateParameter(valid_606639, JArray, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "EventCategories", valid_606639
  var valid_606640 = formData.getOrDefault("Tags")
  valid_606640 = validateParameter(valid_606640, JArray, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "Tags", valid_606640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606641: Call_PostCreateEventSubscription_606622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606641.validator(path, query, header, formData, body)
  let scheme = call_606641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606641.url(scheme.get, call_606641.host, call_606641.base,
                         call_606641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606641, url, valid)

proc call*(call_606642: Call_PostCreateEventSubscription_606622;
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
  var query_606643 = newJObject()
  var formData_606644 = newJObject()
  if SourceIds != nil:
    formData_606644.add "SourceIds", SourceIds
  add(formData_606644, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_606644, "Enabled", newJBool(Enabled))
  add(formData_606644, "SubscriptionName", newJString(SubscriptionName))
  add(formData_606644, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_606644.add "EventCategories", EventCategories
  add(query_606643, "Action", newJString(Action))
  if Tags != nil:
    formData_606644.add "Tags", Tags
  add(query_606643, "Version", newJString(Version))
  result = call_606642.call(nil, query_606643, nil, formData_606644, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_606622(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_606623, base: "/",
    url: url_PostCreateEventSubscription_606624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_606600 = ref object of OpenApiRestCall_605573
proc url_GetCreateEventSubscription_606602(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_606601(path: JsonNode; query: JsonNode;
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
  var valid_606603 = query.getOrDefault("Tags")
  valid_606603 = validateParameter(valid_606603, JArray, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "Tags", valid_606603
  var valid_606604 = query.getOrDefault("SourceType")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "SourceType", valid_606604
  var valid_606605 = query.getOrDefault("Enabled")
  valid_606605 = validateParameter(valid_606605, JBool, required = false, default = nil)
  if valid_606605 != nil:
    section.add "Enabled", valid_606605
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_606606 = query.getOrDefault("SubscriptionName")
  valid_606606 = validateParameter(valid_606606, JString, required = true,
                                 default = nil)
  if valid_606606 != nil:
    section.add "SubscriptionName", valid_606606
  var valid_606607 = query.getOrDefault("EventCategories")
  valid_606607 = validateParameter(valid_606607, JArray, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "EventCategories", valid_606607
  var valid_606608 = query.getOrDefault("SourceIds")
  valid_606608 = validateParameter(valid_606608, JArray, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "SourceIds", valid_606608
  var valid_606609 = query.getOrDefault("Action")
  valid_606609 = validateParameter(valid_606609, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_606609 != nil:
    section.add "Action", valid_606609
  var valid_606610 = query.getOrDefault("SnsTopicArn")
  valid_606610 = validateParameter(valid_606610, JString, required = true,
                                 default = nil)
  if valid_606610 != nil:
    section.add "SnsTopicArn", valid_606610
  var valid_606611 = query.getOrDefault("Version")
  valid_606611 = validateParameter(valid_606611, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606611 != nil:
    section.add "Version", valid_606611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606612 = header.getOrDefault("X-Amz-Signature")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Signature", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Content-Sha256", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Date")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Date", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Credential")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Credential", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Security-Token")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Security-Token", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Algorithm")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Algorithm", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-SignedHeaders", valid_606618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606619: Call_GetCreateEventSubscription_606600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606619.validator(path, query, header, formData, body)
  let scheme = call_606619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606619.url(scheme.get, call_606619.host, call_606619.base,
                         call_606619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606619, url, valid)

proc call*(call_606620: Call_GetCreateEventSubscription_606600;
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
  var query_606621 = newJObject()
  if Tags != nil:
    query_606621.add "Tags", Tags
  add(query_606621, "SourceType", newJString(SourceType))
  add(query_606621, "Enabled", newJBool(Enabled))
  add(query_606621, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_606621.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_606621.add "SourceIds", SourceIds
  add(query_606621, "Action", newJString(Action))
  add(query_606621, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_606621, "Version", newJString(Version))
  result = call_606620.call(nil, query_606621, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_606600(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_606601, base: "/",
    url: url_GetCreateEventSubscription_606602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_606665 = ref object of OpenApiRestCall_605573
proc url_PostCreateOptionGroup_606667(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_606666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606668 = query.getOrDefault("Action")
  valid_606668 = validateParameter(valid_606668, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606668 != nil:
    section.add "Action", valid_606668
  var valid_606669 = query.getOrDefault("Version")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606669 != nil:
    section.add "Version", valid_606669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606670 = header.getOrDefault("X-Amz-Signature")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Signature", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Content-Sha256", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Date")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Date", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Credential")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Credential", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Security-Token")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Security-Token", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Algorithm")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Algorithm", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-SignedHeaders", valid_606676
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_606677 = formData.getOrDefault("OptionGroupDescription")
  valid_606677 = validateParameter(valid_606677, JString, required = true,
                                 default = nil)
  if valid_606677 != nil:
    section.add "OptionGroupDescription", valid_606677
  var valid_606678 = formData.getOrDefault("EngineName")
  valid_606678 = validateParameter(valid_606678, JString, required = true,
                                 default = nil)
  if valid_606678 != nil:
    section.add "EngineName", valid_606678
  var valid_606679 = formData.getOrDefault("MajorEngineVersion")
  valid_606679 = validateParameter(valid_606679, JString, required = true,
                                 default = nil)
  if valid_606679 != nil:
    section.add "MajorEngineVersion", valid_606679
  var valid_606680 = formData.getOrDefault("Tags")
  valid_606680 = validateParameter(valid_606680, JArray, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "Tags", valid_606680
  var valid_606681 = formData.getOrDefault("OptionGroupName")
  valid_606681 = validateParameter(valid_606681, JString, required = true,
                                 default = nil)
  if valid_606681 != nil:
    section.add "OptionGroupName", valid_606681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606682: Call_PostCreateOptionGroup_606665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606682.validator(path, query, header, formData, body)
  let scheme = call_606682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606682.url(scheme.get, call_606682.host, call_606682.base,
                         call_606682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606682, url, valid)

proc call*(call_606683: Call_PostCreateOptionGroup_606665;
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
  var query_606684 = newJObject()
  var formData_606685 = newJObject()
  add(formData_606685, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_606685, "EngineName", newJString(EngineName))
  add(formData_606685, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_606684, "Action", newJString(Action))
  if Tags != nil:
    formData_606685.add "Tags", Tags
  add(formData_606685, "OptionGroupName", newJString(OptionGroupName))
  add(query_606684, "Version", newJString(Version))
  result = call_606683.call(nil, query_606684, nil, formData_606685, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_606665(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_606666, base: "/",
    url: url_PostCreateOptionGroup_606667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_606645 = ref object of OpenApiRestCall_605573
proc url_GetCreateOptionGroup_606647(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_606646(path: JsonNode; query: JsonNode;
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
  var valid_606648 = query.getOrDefault("EngineName")
  valid_606648 = validateParameter(valid_606648, JString, required = true,
                                 default = nil)
  if valid_606648 != nil:
    section.add "EngineName", valid_606648
  var valid_606649 = query.getOrDefault("OptionGroupDescription")
  valid_606649 = validateParameter(valid_606649, JString, required = true,
                                 default = nil)
  if valid_606649 != nil:
    section.add "OptionGroupDescription", valid_606649
  var valid_606650 = query.getOrDefault("Tags")
  valid_606650 = validateParameter(valid_606650, JArray, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "Tags", valid_606650
  var valid_606651 = query.getOrDefault("Action")
  valid_606651 = validateParameter(valid_606651, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_606651 != nil:
    section.add "Action", valid_606651
  var valid_606652 = query.getOrDefault("OptionGroupName")
  valid_606652 = validateParameter(valid_606652, JString, required = true,
                                 default = nil)
  if valid_606652 != nil:
    section.add "OptionGroupName", valid_606652
  var valid_606653 = query.getOrDefault("Version")
  valid_606653 = validateParameter(valid_606653, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606653 != nil:
    section.add "Version", valid_606653
  var valid_606654 = query.getOrDefault("MajorEngineVersion")
  valid_606654 = validateParameter(valid_606654, JString, required = true,
                                 default = nil)
  if valid_606654 != nil:
    section.add "MajorEngineVersion", valid_606654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606655 = header.getOrDefault("X-Amz-Signature")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Signature", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Content-Sha256", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Date")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Date", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Credential")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Credential", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Security-Token")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Security-Token", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Algorithm")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Algorithm", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-SignedHeaders", valid_606661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606662: Call_GetCreateOptionGroup_606645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606662.validator(path, query, header, formData, body)
  let scheme = call_606662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606662.url(scheme.get, call_606662.host, call_606662.base,
                         call_606662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606662, url, valid)

proc call*(call_606663: Call_GetCreateOptionGroup_606645; EngineName: string;
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
  var query_606664 = newJObject()
  add(query_606664, "EngineName", newJString(EngineName))
  add(query_606664, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_606664.add "Tags", Tags
  add(query_606664, "Action", newJString(Action))
  add(query_606664, "OptionGroupName", newJString(OptionGroupName))
  add(query_606664, "Version", newJString(Version))
  add(query_606664, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_606663.call(nil, query_606664, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_606645(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_606646, base: "/",
    url: url_GetCreateOptionGroup_606647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_606704 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBInstance_606706(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_606705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606707 = query.getOrDefault("Action")
  valid_606707 = validateParameter(valid_606707, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606707 != nil:
    section.add "Action", valid_606707
  var valid_606708 = query.getOrDefault("Version")
  valid_606708 = validateParameter(valid_606708, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606708 != nil:
    section.add "Version", valid_606708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606709 = header.getOrDefault("X-Amz-Signature")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Signature", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Content-Sha256", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Date")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Date", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Credential")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Credential", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Security-Token")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Security-Token", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Algorithm")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Algorithm", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-SignedHeaders", valid_606715
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606716 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606716 = validateParameter(valid_606716, JString, required = true,
                                 default = nil)
  if valid_606716 != nil:
    section.add "DBInstanceIdentifier", valid_606716
  var valid_606717 = formData.getOrDefault("SkipFinalSnapshot")
  valid_606717 = validateParameter(valid_606717, JBool, required = false, default = nil)
  if valid_606717 != nil:
    section.add "SkipFinalSnapshot", valid_606717
  var valid_606718 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606719: Call_PostDeleteDBInstance_606704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606719.validator(path, query, header, formData, body)
  let scheme = call_606719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606719.url(scheme.get, call_606719.host, call_606719.base,
                         call_606719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606719, url, valid)

proc call*(call_606720: Call_PostDeleteDBInstance_606704;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_606721 = newJObject()
  var formData_606722 = newJObject()
  add(formData_606722, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606721, "Action", newJString(Action))
  add(formData_606722, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_606722, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_606721, "Version", newJString(Version))
  result = call_606720.call(nil, query_606721, nil, formData_606722, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_606704(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_606705, base: "/",
    url: url_PostDeleteDBInstance_606706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_606686 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBInstance_606688(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_606687(path: JsonNode; query: JsonNode;
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
  var valid_606689 = query.getOrDefault("DBInstanceIdentifier")
  valid_606689 = validateParameter(valid_606689, JString, required = true,
                                 default = nil)
  if valid_606689 != nil:
    section.add "DBInstanceIdentifier", valid_606689
  var valid_606690 = query.getOrDefault("SkipFinalSnapshot")
  valid_606690 = validateParameter(valid_606690, JBool, required = false, default = nil)
  if valid_606690 != nil:
    section.add "SkipFinalSnapshot", valid_606690
  var valid_606691 = query.getOrDefault("Action")
  valid_606691 = validateParameter(valid_606691, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606691 != nil:
    section.add "Action", valid_606691
  var valid_606692 = query.getOrDefault("Version")
  valid_606692 = validateParameter(valid_606692, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606692 != nil:
    section.add "Version", valid_606692
  var valid_606693 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606694 = header.getOrDefault("X-Amz-Signature")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Signature", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Content-Sha256", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Date")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Date", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Credential")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Credential", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Security-Token")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Security-Token", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Algorithm")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Algorithm", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-SignedHeaders", valid_606700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606701: Call_GetDeleteDBInstance_606686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606701.validator(path, query, header, formData, body)
  let scheme = call_606701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606701.url(scheme.get, call_606701.host, call_606701.base,
                         call_606701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606701, url, valid)

proc call*(call_606702: Call_GetDeleteDBInstance_606686;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_606703 = newJObject()
  add(query_606703, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606703, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_606703, "Action", newJString(Action))
  add(query_606703, "Version", newJString(Version))
  add(query_606703, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_606702.call(nil, query_606703, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_606686(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_606687, base: "/",
    url: url_GetDeleteDBInstance_606688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_606739 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBParameterGroup_606741(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_606740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606742 = query.getOrDefault("Action")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606742 != nil:
    section.add "Action", valid_606742
  var valid_606743 = query.getOrDefault("Version")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606743 != nil:
    section.add "Version", valid_606743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606744 = header.getOrDefault("X-Amz-Signature")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Signature", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Content-Sha256", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Date")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Date", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Credential")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Credential", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Security-Token")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Security-Token", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Algorithm")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Algorithm", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-SignedHeaders", valid_606750
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_606751 = formData.getOrDefault("DBParameterGroupName")
  valid_606751 = validateParameter(valid_606751, JString, required = true,
                                 default = nil)
  if valid_606751 != nil:
    section.add "DBParameterGroupName", valid_606751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606752: Call_PostDeleteDBParameterGroup_606739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606752.validator(path, query, header, formData, body)
  let scheme = call_606752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606752.url(scheme.get, call_606752.host, call_606752.base,
                         call_606752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606752, url, valid)

proc call*(call_606753: Call_PostDeleteDBParameterGroup_606739;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606754 = newJObject()
  var formData_606755 = newJObject()
  add(formData_606755, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606754, "Action", newJString(Action))
  add(query_606754, "Version", newJString(Version))
  result = call_606753.call(nil, query_606754, nil, formData_606755, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_606739(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_606740, base: "/",
    url: url_PostDeleteDBParameterGroup_606741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_606723 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBParameterGroup_606725(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_606724(path: JsonNode; query: JsonNode;
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
  var valid_606726 = query.getOrDefault("DBParameterGroupName")
  valid_606726 = validateParameter(valid_606726, JString, required = true,
                                 default = nil)
  if valid_606726 != nil:
    section.add "DBParameterGroupName", valid_606726
  var valid_606727 = query.getOrDefault("Action")
  valid_606727 = validateParameter(valid_606727, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_606727 != nil:
    section.add "Action", valid_606727
  var valid_606728 = query.getOrDefault("Version")
  valid_606728 = validateParameter(valid_606728, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606728 != nil:
    section.add "Version", valid_606728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606729 = header.getOrDefault("X-Amz-Signature")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Signature", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Content-Sha256", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Date")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Date", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Credential")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Credential", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Security-Token")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Security-Token", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Algorithm")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Algorithm", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-SignedHeaders", valid_606735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606736: Call_GetDeleteDBParameterGroup_606723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606736.validator(path, query, header, formData, body)
  let scheme = call_606736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606736.url(scheme.get, call_606736.host, call_606736.base,
                         call_606736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606736, url, valid)

proc call*(call_606737: Call_GetDeleteDBParameterGroup_606723;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606738 = newJObject()
  add(query_606738, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_606738, "Action", newJString(Action))
  add(query_606738, "Version", newJString(Version))
  result = call_606737.call(nil, query_606738, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_606723(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_606724, base: "/",
    url: url_GetDeleteDBParameterGroup_606725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_606772 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSecurityGroup_606774(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_606773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606775 = query.getOrDefault("Action")
  valid_606775 = validateParameter(valid_606775, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606775 != nil:
    section.add "Action", valid_606775
  var valid_606776 = query.getOrDefault("Version")
  valid_606776 = validateParameter(valid_606776, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606776 != nil:
    section.add "Version", valid_606776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606777 = header.getOrDefault("X-Amz-Signature")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Signature", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Content-Sha256", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Date")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Date", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Credential")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Credential", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Security-Token")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Security-Token", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Algorithm")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Algorithm", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-SignedHeaders", valid_606783
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_606784 = formData.getOrDefault("DBSecurityGroupName")
  valid_606784 = validateParameter(valid_606784, JString, required = true,
                                 default = nil)
  if valid_606784 != nil:
    section.add "DBSecurityGroupName", valid_606784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_PostDeleteDBSecurityGroup_606772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_PostDeleteDBSecurityGroup_606772;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606787 = newJObject()
  var formData_606788 = newJObject()
  add(formData_606788, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606787, "Action", newJString(Action))
  add(query_606787, "Version", newJString(Version))
  result = call_606786.call(nil, query_606787, nil, formData_606788, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_606772(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_606773, base: "/",
    url: url_PostDeleteDBSecurityGroup_606774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_606756 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSecurityGroup_606758(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_606757(path: JsonNode; query: JsonNode;
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
  var valid_606759 = query.getOrDefault("DBSecurityGroupName")
  valid_606759 = validateParameter(valid_606759, JString, required = true,
                                 default = nil)
  if valid_606759 != nil:
    section.add "DBSecurityGroupName", valid_606759
  var valid_606760 = query.getOrDefault("Action")
  valid_606760 = validateParameter(valid_606760, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_606760 != nil:
    section.add "Action", valid_606760
  var valid_606761 = query.getOrDefault("Version")
  valid_606761 = validateParameter(valid_606761, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606761 != nil:
    section.add "Version", valid_606761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606762 = header.getOrDefault("X-Amz-Signature")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Signature", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Content-Sha256", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Date")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Date", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Credential")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Credential", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Security-Token")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Security-Token", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Algorithm")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Algorithm", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-SignedHeaders", valid_606768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606769: Call_GetDeleteDBSecurityGroup_606756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606769.validator(path, query, header, formData, body)
  let scheme = call_606769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606769.url(scheme.get, call_606769.host, call_606769.base,
                         call_606769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606769, url, valid)

proc call*(call_606770: Call_GetDeleteDBSecurityGroup_606756;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606771 = newJObject()
  add(query_606771, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_606771, "Action", newJString(Action))
  add(query_606771, "Version", newJString(Version))
  result = call_606770.call(nil, query_606771, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_606756(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_606757, base: "/",
    url: url_GetDeleteDBSecurityGroup_606758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_606805 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSnapshot_606807(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_606806(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606808 = query.getOrDefault("Action")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606808 != nil:
    section.add "Action", valid_606808
  var valid_606809 = query.getOrDefault("Version")
  valid_606809 = validateParameter(valid_606809, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606809 != nil:
    section.add "Version", valid_606809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606810 = header.getOrDefault("X-Amz-Signature")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Signature", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Content-Sha256", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Date")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Date", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Credential")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Credential", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Security-Token")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Security-Token", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Algorithm")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Algorithm", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-SignedHeaders", valid_606816
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_606817 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_606817 = validateParameter(valid_606817, JString, required = true,
                                 default = nil)
  if valid_606817 != nil:
    section.add "DBSnapshotIdentifier", valid_606817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_PostDeleteDBSnapshot_606805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_PostDeleteDBSnapshot_606805;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606820 = newJObject()
  var formData_606821 = newJObject()
  add(formData_606821, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606820, "Action", newJString(Action))
  add(query_606820, "Version", newJString(Version))
  result = call_606819.call(nil, query_606820, nil, formData_606821, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_606805(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_606806, base: "/",
    url: url_PostDeleteDBSnapshot_606807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_606789 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSnapshot_606791(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_606790(path: JsonNode; query: JsonNode;
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
  var valid_606792 = query.getOrDefault("DBSnapshotIdentifier")
  valid_606792 = validateParameter(valid_606792, JString, required = true,
                                 default = nil)
  if valid_606792 != nil:
    section.add "DBSnapshotIdentifier", valid_606792
  var valid_606793 = query.getOrDefault("Action")
  valid_606793 = validateParameter(valid_606793, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_606793 != nil:
    section.add "Action", valid_606793
  var valid_606794 = query.getOrDefault("Version")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_GetDeleteDBSnapshot_606789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_GetDeleteDBSnapshot_606789;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606804 = newJObject()
  add(query_606804, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_606804, "Action", newJString(Action))
  add(query_606804, "Version", newJString(Version))
  result = call_606803.call(nil, query_606804, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_606789(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_606790, base: "/",
    url: url_GetDeleteDBSnapshot_606791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_606838 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSubnetGroup_606840(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_606839(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606841 = query.getOrDefault("Action")
  valid_606841 = validateParameter(valid_606841, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606841 != nil:
    section.add "Action", valid_606841
  var valid_606842 = query.getOrDefault("Version")
  valid_606842 = validateParameter(valid_606842, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606842 != nil:
    section.add "Version", valid_606842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606843 = header.getOrDefault("X-Amz-Signature")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Signature", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Content-Sha256", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Date")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Date", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Credential")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Credential", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Security-Token")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Security-Token", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Algorithm")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Algorithm", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-SignedHeaders", valid_606849
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_606850 = formData.getOrDefault("DBSubnetGroupName")
  valid_606850 = validateParameter(valid_606850, JString, required = true,
                                 default = nil)
  if valid_606850 != nil:
    section.add "DBSubnetGroupName", valid_606850
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606851: Call_PostDeleteDBSubnetGroup_606838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606851.validator(path, query, header, formData, body)
  let scheme = call_606851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606851.url(scheme.get, call_606851.host, call_606851.base,
                         call_606851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606851, url, valid)

proc call*(call_606852: Call_PostDeleteDBSubnetGroup_606838;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606853 = newJObject()
  var formData_606854 = newJObject()
  add(query_606853, "Action", newJString(Action))
  add(formData_606854, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606853, "Version", newJString(Version))
  result = call_606852.call(nil, query_606853, nil, formData_606854, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_606838(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_606839, base: "/",
    url: url_PostDeleteDBSubnetGroup_606840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_606822 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSubnetGroup_606824(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_606823(path: JsonNode; query: JsonNode;
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
  var valid_606825 = query.getOrDefault("Action")
  valid_606825 = validateParameter(valid_606825, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606825 != nil:
    section.add "Action", valid_606825
  var valid_606826 = query.getOrDefault("DBSubnetGroupName")
  valid_606826 = validateParameter(valid_606826, JString, required = true,
                                 default = nil)
  if valid_606826 != nil:
    section.add "DBSubnetGroupName", valid_606826
  var valid_606827 = query.getOrDefault("Version")
  valid_606827 = validateParameter(valid_606827, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606827 != nil:
    section.add "Version", valid_606827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606828 = header.getOrDefault("X-Amz-Signature")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Signature", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Content-Sha256", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Date")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Date", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Credential")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Credential", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Security-Token")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Security-Token", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Algorithm")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Algorithm", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-SignedHeaders", valid_606834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606835: Call_GetDeleteDBSubnetGroup_606822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606835.validator(path, query, header, formData, body)
  let scheme = call_606835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606835.url(scheme.get, call_606835.host, call_606835.base,
                         call_606835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606835, url, valid)

proc call*(call_606836: Call_GetDeleteDBSubnetGroup_606822;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_606837 = newJObject()
  add(query_606837, "Action", newJString(Action))
  add(query_606837, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606837, "Version", newJString(Version))
  result = call_606836.call(nil, query_606837, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_606822(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_606823, base: "/",
    url: url_GetDeleteDBSubnetGroup_606824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_606871 = ref object of OpenApiRestCall_605573
proc url_PostDeleteEventSubscription_606873(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_606872(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606874 = query.getOrDefault("Action")
  valid_606874 = validateParameter(valid_606874, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606874 != nil:
    section.add "Action", valid_606874
  var valid_606875 = query.getOrDefault("Version")
  valid_606875 = validateParameter(valid_606875, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606875 != nil:
    section.add "Version", valid_606875
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606876 = header.getOrDefault("X-Amz-Signature")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Signature", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Content-Sha256", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Date")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Date", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Credential")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Credential", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-Security-Token")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Security-Token", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-Algorithm")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Algorithm", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-SignedHeaders", valid_606882
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_606883 = formData.getOrDefault("SubscriptionName")
  valid_606883 = validateParameter(valid_606883, JString, required = true,
                                 default = nil)
  if valid_606883 != nil:
    section.add "SubscriptionName", valid_606883
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606884: Call_PostDeleteEventSubscription_606871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606884.validator(path, query, header, formData, body)
  let scheme = call_606884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606884.url(scheme.get, call_606884.host, call_606884.base,
                         call_606884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606884, url, valid)

proc call*(call_606885: Call_PostDeleteEventSubscription_606871;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606886 = newJObject()
  var formData_606887 = newJObject()
  add(formData_606887, "SubscriptionName", newJString(SubscriptionName))
  add(query_606886, "Action", newJString(Action))
  add(query_606886, "Version", newJString(Version))
  result = call_606885.call(nil, query_606886, nil, formData_606887, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_606871(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_606872, base: "/",
    url: url_PostDeleteEventSubscription_606873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_606855 = ref object of OpenApiRestCall_605573
proc url_GetDeleteEventSubscription_606857(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_606856(path: JsonNode; query: JsonNode;
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
  var valid_606858 = query.getOrDefault("SubscriptionName")
  valid_606858 = validateParameter(valid_606858, JString, required = true,
                                 default = nil)
  if valid_606858 != nil:
    section.add "SubscriptionName", valid_606858
  var valid_606859 = query.getOrDefault("Action")
  valid_606859 = validateParameter(valid_606859, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_606859 != nil:
    section.add "Action", valid_606859
  var valid_606860 = query.getOrDefault("Version")
  valid_606860 = validateParameter(valid_606860, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606860 != nil:
    section.add "Version", valid_606860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606861 = header.getOrDefault("X-Amz-Signature")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Signature", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Content-Sha256", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Date")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Date", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Credential")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Credential", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Security-Token")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Security-Token", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-Algorithm")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Algorithm", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-SignedHeaders", valid_606867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606868: Call_GetDeleteEventSubscription_606855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606868.validator(path, query, header, formData, body)
  let scheme = call_606868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606868.url(scheme.get, call_606868.host, call_606868.base,
                         call_606868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606868, url, valid)

proc call*(call_606869: Call_GetDeleteEventSubscription_606855;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606870 = newJObject()
  add(query_606870, "SubscriptionName", newJString(SubscriptionName))
  add(query_606870, "Action", newJString(Action))
  add(query_606870, "Version", newJString(Version))
  result = call_606869.call(nil, query_606870, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_606855(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_606856, base: "/",
    url: url_GetDeleteEventSubscription_606857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_606904 = ref object of OpenApiRestCall_605573
proc url_PostDeleteOptionGroup_606906(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_606905(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606907 = query.getOrDefault("Action")
  valid_606907 = validateParameter(valid_606907, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606907 != nil:
    section.add "Action", valid_606907
  var valid_606908 = query.getOrDefault("Version")
  valid_606908 = validateParameter(valid_606908, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606908 != nil:
    section.add "Version", valid_606908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606909 = header.getOrDefault("X-Amz-Signature")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Signature", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Content-Sha256", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Date")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Date", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Credential")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Credential", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Security-Token")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Security-Token", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Algorithm")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Algorithm", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-SignedHeaders", valid_606915
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_606916 = formData.getOrDefault("OptionGroupName")
  valid_606916 = validateParameter(valid_606916, JString, required = true,
                                 default = nil)
  if valid_606916 != nil:
    section.add "OptionGroupName", valid_606916
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606917: Call_PostDeleteOptionGroup_606904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606917.validator(path, query, header, formData, body)
  let scheme = call_606917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606917.url(scheme.get, call_606917.host, call_606917.base,
                         call_606917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606917, url, valid)

proc call*(call_606918: Call_PostDeleteOptionGroup_606904; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_606919 = newJObject()
  var formData_606920 = newJObject()
  add(query_606919, "Action", newJString(Action))
  add(formData_606920, "OptionGroupName", newJString(OptionGroupName))
  add(query_606919, "Version", newJString(Version))
  result = call_606918.call(nil, query_606919, nil, formData_606920, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_606904(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_606905, base: "/",
    url: url_PostDeleteOptionGroup_606906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_606888 = ref object of OpenApiRestCall_605573
proc url_GetDeleteOptionGroup_606890(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_606889(path: JsonNode; query: JsonNode;
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
  var valid_606891 = query.getOrDefault("Action")
  valid_606891 = validateParameter(valid_606891, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_606891 != nil:
    section.add "Action", valid_606891
  var valid_606892 = query.getOrDefault("OptionGroupName")
  valid_606892 = validateParameter(valid_606892, JString, required = true,
                                 default = nil)
  if valid_606892 != nil:
    section.add "OptionGroupName", valid_606892
  var valid_606893 = query.getOrDefault("Version")
  valid_606893 = validateParameter(valid_606893, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606893 != nil:
    section.add "Version", valid_606893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606894 = header.getOrDefault("X-Amz-Signature")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Signature", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Content-Sha256", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-Date")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Date", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Credential")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Credential", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Security-Token")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Security-Token", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Algorithm")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Algorithm", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-SignedHeaders", valid_606900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606901: Call_GetDeleteOptionGroup_606888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606901.validator(path, query, header, formData, body)
  let scheme = call_606901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606901.url(scheme.get, call_606901.host, call_606901.base,
                         call_606901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606901, url, valid)

proc call*(call_606902: Call_GetDeleteOptionGroup_606888; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_606903 = newJObject()
  add(query_606903, "Action", newJString(Action))
  add(query_606903, "OptionGroupName", newJString(OptionGroupName))
  add(query_606903, "Version", newJString(Version))
  result = call_606902.call(nil, query_606903, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_606888(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_606889, base: "/",
    url: url_GetDeleteOptionGroup_606890, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_606944 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBEngineVersions_606946(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_606945(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606947 = query.getOrDefault("Action")
  valid_606947 = validateParameter(valid_606947, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606947 != nil:
    section.add "Action", valid_606947
  var valid_606948 = query.getOrDefault("Version")
  valid_606948 = validateParameter(valid_606948, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606948 != nil:
    section.add "Version", valid_606948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606949 = header.getOrDefault("X-Amz-Signature")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Signature", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Content-Sha256", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Date")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Date", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Credential")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Credential", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Security-Token")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Security-Token", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Algorithm")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Algorithm", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-SignedHeaders", valid_606955
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
  var valid_606956 = formData.getOrDefault("DefaultOnly")
  valid_606956 = validateParameter(valid_606956, JBool, required = false, default = nil)
  if valid_606956 != nil:
    section.add "DefaultOnly", valid_606956
  var valid_606957 = formData.getOrDefault("MaxRecords")
  valid_606957 = validateParameter(valid_606957, JInt, required = false, default = nil)
  if valid_606957 != nil:
    section.add "MaxRecords", valid_606957
  var valid_606958 = formData.getOrDefault("EngineVersion")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "EngineVersion", valid_606958
  var valid_606959 = formData.getOrDefault("Marker")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "Marker", valid_606959
  var valid_606960 = formData.getOrDefault("Engine")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "Engine", valid_606960
  var valid_606961 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_606961 = validateParameter(valid_606961, JBool, required = false, default = nil)
  if valid_606961 != nil:
    section.add "ListSupportedCharacterSets", valid_606961
  var valid_606962 = formData.getOrDefault("Filters")
  valid_606962 = validateParameter(valid_606962, JArray, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "Filters", valid_606962
  var valid_606963 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "DBParameterGroupFamily", valid_606963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606964: Call_PostDescribeDBEngineVersions_606944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606964.validator(path, query, header, formData, body)
  let scheme = call_606964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606964.url(scheme.get, call_606964.host, call_606964.base,
                         call_606964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606964, url, valid)

proc call*(call_606965: Call_PostDescribeDBEngineVersions_606944;
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
  var query_606966 = newJObject()
  var formData_606967 = newJObject()
  add(formData_606967, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_606967, "MaxRecords", newJInt(MaxRecords))
  add(formData_606967, "EngineVersion", newJString(EngineVersion))
  add(formData_606967, "Marker", newJString(Marker))
  add(formData_606967, "Engine", newJString(Engine))
  add(formData_606967, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_606966, "Action", newJString(Action))
  if Filters != nil:
    formData_606967.add "Filters", Filters
  add(query_606966, "Version", newJString(Version))
  add(formData_606967, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606965.call(nil, query_606966, nil, formData_606967, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_606944(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_606945, base: "/",
    url: url_PostDescribeDBEngineVersions_606946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_606921 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBEngineVersions_606923(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_606922(path: JsonNode; query: JsonNode;
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
  var valid_606924 = query.getOrDefault("Marker")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "Marker", valid_606924
  var valid_606925 = query.getOrDefault("DBParameterGroupFamily")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "DBParameterGroupFamily", valid_606925
  var valid_606926 = query.getOrDefault("Engine")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "Engine", valid_606926
  var valid_606927 = query.getOrDefault("EngineVersion")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "EngineVersion", valid_606927
  var valid_606928 = query.getOrDefault("Action")
  valid_606928 = validateParameter(valid_606928, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606928 != nil:
    section.add "Action", valid_606928
  var valid_606929 = query.getOrDefault("ListSupportedCharacterSets")
  valid_606929 = validateParameter(valid_606929, JBool, required = false, default = nil)
  if valid_606929 != nil:
    section.add "ListSupportedCharacterSets", valid_606929
  var valid_606930 = query.getOrDefault("Version")
  valid_606930 = validateParameter(valid_606930, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606930 != nil:
    section.add "Version", valid_606930
  var valid_606931 = query.getOrDefault("Filters")
  valid_606931 = validateParameter(valid_606931, JArray, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "Filters", valid_606931
  var valid_606932 = query.getOrDefault("MaxRecords")
  valid_606932 = validateParameter(valid_606932, JInt, required = false, default = nil)
  if valid_606932 != nil:
    section.add "MaxRecords", valid_606932
  var valid_606933 = query.getOrDefault("DefaultOnly")
  valid_606933 = validateParameter(valid_606933, JBool, required = false, default = nil)
  if valid_606933 != nil:
    section.add "DefaultOnly", valid_606933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606934 = header.getOrDefault("X-Amz-Signature")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Signature", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Content-Sha256", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Date")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Date", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Credential")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Credential", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Security-Token")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Security-Token", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Algorithm")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Algorithm", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-SignedHeaders", valid_606940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606941: Call_GetDescribeDBEngineVersions_606921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606941.validator(path, query, header, formData, body)
  let scheme = call_606941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606941.url(scheme.get, call_606941.host, call_606941.base,
                         call_606941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606941, url, valid)

proc call*(call_606942: Call_GetDescribeDBEngineVersions_606921;
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
  var query_606943 = newJObject()
  add(query_606943, "Marker", newJString(Marker))
  add(query_606943, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606943, "Engine", newJString(Engine))
  add(query_606943, "EngineVersion", newJString(EngineVersion))
  add(query_606943, "Action", newJString(Action))
  add(query_606943, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_606943, "Version", newJString(Version))
  if Filters != nil:
    query_606943.add "Filters", Filters
  add(query_606943, "MaxRecords", newJInt(MaxRecords))
  add(query_606943, "DefaultOnly", newJBool(DefaultOnly))
  result = call_606942.call(nil, query_606943, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_606921(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_606922, base: "/",
    url: url_GetDescribeDBEngineVersions_606923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_606987 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBInstances_606989(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_606988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606990 = query.getOrDefault("Action")
  valid_606990 = validateParameter(valid_606990, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606990 != nil:
    section.add "Action", valid_606990
  var valid_606991 = query.getOrDefault("Version")
  valid_606991 = validateParameter(valid_606991, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606991 != nil:
    section.add "Version", valid_606991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606992 = header.getOrDefault("X-Amz-Signature")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Signature", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-Content-Sha256", valid_606993
  var valid_606994 = header.getOrDefault("X-Amz-Date")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Date", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Credential")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Credential", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Security-Token")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Security-Token", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Algorithm")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Algorithm", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-SignedHeaders", valid_606998
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_606999 = formData.getOrDefault("MaxRecords")
  valid_606999 = validateParameter(valid_606999, JInt, required = false, default = nil)
  if valid_606999 != nil:
    section.add "MaxRecords", valid_606999
  var valid_607000 = formData.getOrDefault("Marker")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "Marker", valid_607000
  var valid_607001 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "DBInstanceIdentifier", valid_607001
  var valid_607002 = formData.getOrDefault("Filters")
  valid_607002 = validateParameter(valid_607002, JArray, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "Filters", valid_607002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607003: Call_PostDescribeDBInstances_606987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607003.validator(path, query, header, formData, body)
  let scheme = call_607003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607003.url(scheme.get, call_607003.host, call_607003.base,
                         call_607003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607003, url, valid)

proc call*(call_607004: Call_PostDescribeDBInstances_606987; MaxRecords: int = 0;
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
  var query_607005 = newJObject()
  var formData_607006 = newJObject()
  add(formData_607006, "MaxRecords", newJInt(MaxRecords))
  add(formData_607006, "Marker", newJString(Marker))
  add(formData_607006, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607005, "Action", newJString(Action))
  if Filters != nil:
    formData_607006.add "Filters", Filters
  add(query_607005, "Version", newJString(Version))
  result = call_607004.call(nil, query_607005, nil, formData_607006, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_606987(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_606988, base: "/",
    url: url_PostDescribeDBInstances_606989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_606968 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBInstances_606970(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_606969(path: JsonNode; query: JsonNode;
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
  var valid_606971 = query.getOrDefault("Marker")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "Marker", valid_606971
  var valid_606972 = query.getOrDefault("DBInstanceIdentifier")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "DBInstanceIdentifier", valid_606972
  var valid_606973 = query.getOrDefault("Action")
  valid_606973 = validateParameter(valid_606973, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_606973 != nil:
    section.add "Action", valid_606973
  var valid_606974 = query.getOrDefault("Version")
  valid_606974 = validateParameter(valid_606974, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_606974 != nil:
    section.add "Version", valid_606974
  var valid_606975 = query.getOrDefault("Filters")
  valid_606975 = validateParameter(valid_606975, JArray, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "Filters", valid_606975
  var valid_606976 = query.getOrDefault("MaxRecords")
  valid_606976 = validateParameter(valid_606976, JInt, required = false, default = nil)
  if valid_606976 != nil:
    section.add "MaxRecords", valid_606976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606977 = header.getOrDefault("X-Amz-Signature")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Signature", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Content-Sha256", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-Date")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Date", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Credential")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Credential", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Security-Token")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Security-Token", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Algorithm")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Algorithm", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-SignedHeaders", valid_606983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606984: Call_GetDescribeDBInstances_606968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606984.validator(path, query, header, formData, body)
  let scheme = call_606984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606984.url(scheme.get, call_606984.host, call_606984.base,
                         call_606984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606984, url, valid)

proc call*(call_606985: Call_GetDescribeDBInstances_606968; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_606986 = newJObject()
  add(query_606986, "Marker", newJString(Marker))
  add(query_606986, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606986, "Action", newJString(Action))
  add(query_606986, "Version", newJString(Version))
  if Filters != nil:
    query_606986.add "Filters", Filters
  add(query_606986, "MaxRecords", newJInt(MaxRecords))
  result = call_606985.call(nil, query_606986, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_606968(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_606969, base: "/",
    url: url_GetDescribeDBInstances_606970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_607029 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBLogFiles_607031(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_607030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607032 = query.getOrDefault("Action")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_607032 != nil:
    section.add "Action", valid_607032
  var valid_607033 = query.getOrDefault("Version")
  valid_607033 = validateParameter(valid_607033, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607033 != nil:
    section.add "Version", valid_607033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607034 = header.getOrDefault("X-Amz-Signature")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Signature", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Content-Sha256", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Date")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Date", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Credential")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Credential", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Security-Token")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Security-Token", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Algorithm")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Algorithm", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-SignedHeaders", valid_607040
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
  var valid_607041 = formData.getOrDefault("FileSize")
  valid_607041 = validateParameter(valid_607041, JInt, required = false, default = nil)
  if valid_607041 != nil:
    section.add "FileSize", valid_607041
  var valid_607042 = formData.getOrDefault("MaxRecords")
  valid_607042 = validateParameter(valid_607042, JInt, required = false, default = nil)
  if valid_607042 != nil:
    section.add "MaxRecords", valid_607042
  var valid_607043 = formData.getOrDefault("Marker")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "Marker", valid_607043
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607044 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607044 = validateParameter(valid_607044, JString, required = true,
                                 default = nil)
  if valid_607044 != nil:
    section.add "DBInstanceIdentifier", valid_607044
  var valid_607045 = formData.getOrDefault("FilenameContains")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "FilenameContains", valid_607045
  var valid_607046 = formData.getOrDefault("Filters")
  valid_607046 = validateParameter(valid_607046, JArray, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "Filters", valid_607046
  var valid_607047 = formData.getOrDefault("FileLastWritten")
  valid_607047 = validateParameter(valid_607047, JInt, required = false, default = nil)
  if valid_607047 != nil:
    section.add "FileLastWritten", valid_607047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607048: Call_PostDescribeDBLogFiles_607029; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607048.validator(path, query, header, formData, body)
  let scheme = call_607048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607048.url(scheme.get, call_607048.host, call_607048.base,
                         call_607048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607048, url, valid)

proc call*(call_607049: Call_PostDescribeDBLogFiles_607029;
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
  var query_607050 = newJObject()
  var formData_607051 = newJObject()
  add(formData_607051, "FileSize", newJInt(FileSize))
  add(formData_607051, "MaxRecords", newJInt(MaxRecords))
  add(formData_607051, "Marker", newJString(Marker))
  add(formData_607051, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607051, "FilenameContains", newJString(FilenameContains))
  add(query_607050, "Action", newJString(Action))
  if Filters != nil:
    formData_607051.add "Filters", Filters
  add(query_607050, "Version", newJString(Version))
  add(formData_607051, "FileLastWritten", newJInt(FileLastWritten))
  result = call_607049.call(nil, query_607050, nil, formData_607051, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_607029(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_607030, base: "/",
    url: url_PostDescribeDBLogFiles_607031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_607007 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBLogFiles_607009(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_607008(path: JsonNode; query: JsonNode;
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
  var valid_607010 = query.getOrDefault("Marker")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "Marker", valid_607010
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607011 = query.getOrDefault("DBInstanceIdentifier")
  valid_607011 = validateParameter(valid_607011, JString, required = true,
                                 default = nil)
  if valid_607011 != nil:
    section.add "DBInstanceIdentifier", valid_607011
  var valid_607012 = query.getOrDefault("FileLastWritten")
  valid_607012 = validateParameter(valid_607012, JInt, required = false, default = nil)
  if valid_607012 != nil:
    section.add "FileLastWritten", valid_607012
  var valid_607013 = query.getOrDefault("Action")
  valid_607013 = validateParameter(valid_607013, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_607013 != nil:
    section.add "Action", valid_607013
  var valid_607014 = query.getOrDefault("FilenameContains")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "FilenameContains", valid_607014
  var valid_607015 = query.getOrDefault("Version")
  valid_607015 = validateParameter(valid_607015, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607015 != nil:
    section.add "Version", valid_607015
  var valid_607016 = query.getOrDefault("Filters")
  valid_607016 = validateParameter(valid_607016, JArray, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "Filters", valid_607016
  var valid_607017 = query.getOrDefault("MaxRecords")
  valid_607017 = validateParameter(valid_607017, JInt, required = false, default = nil)
  if valid_607017 != nil:
    section.add "MaxRecords", valid_607017
  var valid_607018 = query.getOrDefault("FileSize")
  valid_607018 = validateParameter(valid_607018, JInt, required = false, default = nil)
  if valid_607018 != nil:
    section.add "FileSize", valid_607018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607019 = header.getOrDefault("X-Amz-Signature")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Signature", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Content-Sha256", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Date")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Date", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Credential")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Credential", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Security-Token")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Security-Token", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Algorithm")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Algorithm", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-SignedHeaders", valid_607025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607026: Call_GetDescribeDBLogFiles_607007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607026.validator(path, query, header, formData, body)
  let scheme = call_607026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607026.url(scheme.get, call_607026.host, call_607026.base,
                         call_607026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607026, url, valid)

proc call*(call_607027: Call_GetDescribeDBLogFiles_607007;
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
  var query_607028 = newJObject()
  add(query_607028, "Marker", newJString(Marker))
  add(query_607028, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607028, "FileLastWritten", newJInt(FileLastWritten))
  add(query_607028, "Action", newJString(Action))
  add(query_607028, "FilenameContains", newJString(FilenameContains))
  add(query_607028, "Version", newJString(Version))
  if Filters != nil:
    query_607028.add "Filters", Filters
  add(query_607028, "MaxRecords", newJInt(MaxRecords))
  add(query_607028, "FileSize", newJInt(FileSize))
  result = call_607027.call(nil, query_607028, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_607007(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_607008, base: "/",
    url: url_GetDescribeDBLogFiles_607009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_607071 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameterGroups_607073(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_607072(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607074 = query.getOrDefault("Action")
  valid_607074 = validateParameter(valid_607074, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607074 != nil:
    section.add "Action", valid_607074
  var valid_607075 = query.getOrDefault("Version")
  valid_607075 = validateParameter(valid_607075, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607075 != nil:
    section.add "Version", valid_607075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607076 = header.getOrDefault("X-Amz-Signature")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Signature", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Content-Sha256", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-Date")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-Date", valid_607078
  var valid_607079 = header.getOrDefault("X-Amz-Credential")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "X-Amz-Credential", valid_607079
  var valid_607080 = header.getOrDefault("X-Amz-Security-Token")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Security-Token", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Algorithm")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Algorithm", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-SignedHeaders", valid_607082
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607083 = formData.getOrDefault("MaxRecords")
  valid_607083 = validateParameter(valid_607083, JInt, required = false, default = nil)
  if valid_607083 != nil:
    section.add "MaxRecords", valid_607083
  var valid_607084 = formData.getOrDefault("DBParameterGroupName")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "DBParameterGroupName", valid_607084
  var valid_607085 = formData.getOrDefault("Marker")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "Marker", valid_607085
  var valid_607086 = formData.getOrDefault("Filters")
  valid_607086 = validateParameter(valid_607086, JArray, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "Filters", valid_607086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607087: Call_PostDescribeDBParameterGroups_607071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607087.validator(path, query, header, formData, body)
  let scheme = call_607087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607087.url(scheme.get, call_607087.host, call_607087.base,
                         call_607087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607087, url, valid)

proc call*(call_607088: Call_PostDescribeDBParameterGroups_607071;
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
  var query_607089 = newJObject()
  var formData_607090 = newJObject()
  add(formData_607090, "MaxRecords", newJInt(MaxRecords))
  add(formData_607090, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607090, "Marker", newJString(Marker))
  add(query_607089, "Action", newJString(Action))
  if Filters != nil:
    formData_607090.add "Filters", Filters
  add(query_607089, "Version", newJString(Version))
  result = call_607088.call(nil, query_607089, nil, formData_607090, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_607071(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_607072, base: "/",
    url: url_PostDescribeDBParameterGroups_607073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_607052 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameterGroups_607054(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_607053(path: JsonNode; query: JsonNode;
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
  var valid_607055 = query.getOrDefault("Marker")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "Marker", valid_607055
  var valid_607056 = query.getOrDefault("DBParameterGroupName")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "DBParameterGroupName", valid_607056
  var valid_607057 = query.getOrDefault("Action")
  valid_607057 = validateParameter(valid_607057, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_607057 != nil:
    section.add "Action", valid_607057
  var valid_607058 = query.getOrDefault("Version")
  valid_607058 = validateParameter(valid_607058, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607058 != nil:
    section.add "Version", valid_607058
  var valid_607059 = query.getOrDefault("Filters")
  valid_607059 = validateParameter(valid_607059, JArray, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "Filters", valid_607059
  var valid_607060 = query.getOrDefault("MaxRecords")
  valid_607060 = validateParameter(valid_607060, JInt, required = false, default = nil)
  if valid_607060 != nil:
    section.add "MaxRecords", valid_607060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607061 = header.getOrDefault("X-Amz-Signature")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Signature", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Content-Sha256", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Date")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Date", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Credential")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Credential", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Security-Token")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Security-Token", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Algorithm")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Algorithm", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-SignedHeaders", valid_607067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607068: Call_GetDescribeDBParameterGroups_607052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607068.validator(path, query, header, formData, body)
  let scheme = call_607068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607068.url(scheme.get, call_607068.host, call_607068.base,
                         call_607068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607068, url, valid)

proc call*(call_607069: Call_GetDescribeDBParameterGroups_607052;
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
  var query_607070 = newJObject()
  add(query_607070, "Marker", newJString(Marker))
  add(query_607070, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607070, "Action", newJString(Action))
  add(query_607070, "Version", newJString(Version))
  if Filters != nil:
    query_607070.add "Filters", Filters
  add(query_607070, "MaxRecords", newJInt(MaxRecords))
  result = call_607069.call(nil, query_607070, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_607052(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_607053, base: "/",
    url: url_GetDescribeDBParameterGroups_607054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_607111 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBParameters_607113(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_607112(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607114 = query.getOrDefault("Action")
  valid_607114 = validateParameter(valid_607114, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607114 != nil:
    section.add "Action", valid_607114
  var valid_607115 = query.getOrDefault("Version")
  valid_607115 = validateParameter(valid_607115, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607115 != nil:
    section.add "Version", valid_607115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607116 = header.getOrDefault("X-Amz-Signature")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Signature", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Content-Sha256", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Date")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Date", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-Credential")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-Credential", valid_607119
  var valid_607120 = header.getOrDefault("X-Amz-Security-Token")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "X-Amz-Security-Token", valid_607120
  var valid_607121 = header.getOrDefault("X-Amz-Algorithm")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Algorithm", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-SignedHeaders", valid_607122
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607123 = formData.getOrDefault("Source")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "Source", valid_607123
  var valid_607124 = formData.getOrDefault("MaxRecords")
  valid_607124 = validateParameter(valid_607124, JInt, required = false, default = nil)
  if valid_607124 != nil:
    section.add "MaxRecords", valid_607124
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607125 = formData.getOrDefault("DBParameterGroupName")
  valid_607125 = validateParameter(valid_607125, JString, required = true,
                                 default = nil)
  if valid_607125 != nil:
    section.add "DBParameterGroupName", valid_607125
  var valid_607126 = formData.getOrDefault("Marker")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "Marker", valid_607126
  var valid_607127 = formData.getOrDefault("Filters")
  valid_607127 = validateParameter(valid_607127, JArray, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "Filters", valid_607127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607128: Call_PostDescribeDBParameters_607111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607128.validator(path, query, header, formData, body)
  let scheme = call_607128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607128.url(scheme.get, call_607128.host, call_607128.base,
                         call_607128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607128, url, valid)

proc call*(call_607129: Call_PostDescribeDBParameters_607111;
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
  var query_607130 = newJObject()
  var formData_607131 = newJObject()
  add(formData_607131, "Source", newJString(Source))
  add(formData_607131, "MaxRecords", newJInt(MaxRecords))
  add(formData_607131, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607131, "Marker", newJString(Marker))
  add(query_607130, "Action", newJString(Action))
  if Filters != nil:
    formData_607131.add "Filters", Filters
  add(query_607130, "Version", newJString(Version))
  result = call_607129.call(nil, query_607130, nil, formData_607131, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_607111(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_607112, base: "/",
    url: url_PostDescribeDBParameters_607113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_607091 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBParameters_607093(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_607092(path: JsonNode; query: JsonNode;
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
  var valid_607094 = query.getOrDefault("Marker")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "Marker", valid_607094
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_607095 = query.getOrDefault("DBParameterGroupName")
  valid_607095 = validateParameter(valid_607095, JString, required = true,
                                 default = nil)
  if valid_607095 != nil:
    section.add "DBParameterGroupName", valid_607095
  var valid_607096 = query.getOrDefault("Source")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "Source", valid_607096
  var valid_607097 = query.getOrDefault("Action")
  valid_607097 = validateParameter(valid_607097, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_607097 != nil:
    section.add "Action", valid_607097
  var valid_607098 = query.getOrDefault("Version")
  valid_607098 = validateParameter(valid_607098, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607098 != nil:
    section.add "Version", valid_607098
  var valid_607099 = query.getOrDefault("Filters")
  valid_607099 = validateParameter(valid_607099, JArray, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "Filters", valid_607099
  var valid_607100 = query.getOrDefault("MaxRecords")
  valid_607100 = validateParameter(valid_607100, JInt, required = false, default = nil)
  if valid_607100 != nil:
    section.add "MaxRecords", valid_607100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607101 = header.getOrDefault("X-Amz-Signature")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Signature", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Content-Sha256", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Date")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Date", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-Credential")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-Credential", valid_607104
  var valid_607105 = header.getOrDefault("X-Amz-Security-Token")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-Security-Token", valid_607105
  var valid_607106 = header.getOrDefault("X-Amz-Algorithm")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-Algorithm", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-SignedHeaders", valid_607107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607108: Call_GetDescribeDBParameters_607091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607108.validator(path, query, header, formData, body)
  let scheme = call_607108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607108.url(scheme.get, call_607108.host, call_607108.base,
                         call_607108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607108, url, valid)

proc call*(call_607109: Call_GetDescribeDBParameters_607091;
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
  var query_607110 = newJObject()
  add(query_607110, "Marker", newJString(Marker))
  add(query_607110, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607110, "Source", newJString(Source))
  add(query_607110, "Action", newJString(Action))
  add(query_607110, "Version", newJString(Version))
  if Filters != nil:
    query_607110.add "Filters", Filters
  add(query_607110, "MaxRecords", newJInt(MaxRecords))
  result = call_607109.call(nil, query_607110, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_607091(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_607092, base: "/",
    url: url_GetDescribeDBParameters_607093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_607151 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSecurityGroups_607153(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_607152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607154 = query.getOrDefault("Action")
  valid_607154 = validateParameter(valid_607154, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607154 != nil:
    section.add "Action", valid_607154
  var valid_607155 = query.getOrDefault("Version")
  valid_607155 = validateParameter(valid_607155, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607155 != nil:
    section.add "Version", valid_607155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607156 = header.getOrDefault("X-Amz-Signature")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-Signature", valid_607156
  var valid_607157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Content-Sha256", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Date")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Date", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Credential")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Credential", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Security-Token")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Security-Token", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Algorithm")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Algorithm", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-SignedHeaders", valid_607162
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607163 = formData.getOrDefault("DBSecurityGroupName")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "DBSecurityGroupName", valid_607163
  var valid_607164 = formData.getOrDefault("MaxRecords")
  valid_607164 = validateParameter(valid_607164, JInt, required = false, default = nil)
  if valid_607164 != nil:
    section.add "MaxRecords", valid_607164
  var valid_607165 = formData.getOrDefault("Marker")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "Marker", valid_607165
  var valid_607166 = formData.getOrDefault("Filters")
  valid_607166 = validateParameter(valid_607166, JArray, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "Filters", valid_607166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607167: Call_PostDescribeDBSecurityGroups_607151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607167.validator(path, query, header, formData, body)
  let scheme = call_607167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607167.url(scheme.get, call_607167.host, call_607167.base,
                         call_607167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607167, url, valid)

proc call*(call_607168: Call_PostDescribeDBSecurityGroups_607151;
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
  var query_607169 = newJObject()
  var formData_607170 = newJObject()
  add(formData_607170, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_607170, "MaxRecords", newJInt(MaxRecords))
  add(formData_607170, "Marker", newJString(Marker))
  add(query_607169, "Action", newJString(Action))
  if Filters != nil:
    formData_607170.add "Filters", Filters
  add(query_607169, "Version", newJString(Version))
  result = call_607168.call(nil, query_607169, nil, formData_607170, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_607151(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_607152, base: "/",
    url: url_PostDescribeDBSecurityGroups_607153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_607132 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSecurityGroups_607134(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_607133(path: JsonNode; query: JsonNode;
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
  var valid_607135 = query.getOrDefault("Marker")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "Marker", valid_607135
  var valid_607136 = query.getOrDefault("DBSecurityGroupName")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "DBSecurityGroupName", valid_607136
  var valid_607137 = query.getOrDefault("Action")
  valid_607137 = validateParameter(valid_607137, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_607137 != nil:
    section.add "Action", valid_607137
  var valid_607138 = query.getOrDefault("Version")
  valid_607138 = validateParameter(valid_607138, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607138 != nil:
    section.add "Version", valid_607138
  var valid_607139 = query.getOrDefault("Filters")
  valid_607139 = validateParameter(valid_607139, JArray, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "Filters", valid_607139
  var valid_607140 = query.getOrDefault("MaxRecords")
  valid_607140 = validateParameter(valid_607140, JInt, required = false, default = nil)
  if valid_607140 != nil:
    section.add "MaxRecords", valid_607140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607141 = header.getOrDefault("X-Amz-Signature")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Signature", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-Content-Sha256", valid_607142
  var valid_607143 = header.getOrDefault("X-Amz-Date")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Date", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Credential")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Credential", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Security-Token")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Security-Token", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Algorithm")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Algorithm", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-SignedHeaders", valid_607147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607148: Call_GetDescribeDBSecurityGroups_607132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607148.validator(path, query, header, formData, body)
  let scheme = call_607148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607148.url(scheme.get, call_607148.host, call_607148.base,
                         call_607148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607148, url, valid)

proc call*(call_607149: Call_GetDescribeDBSecurityGroups_607132;
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
  var query_607150 = newJObject()
  add(query_607150, "Marker", newJString(Marker))
  add(query_607150, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_607150, "Action", newJString(Action))
  add(query_607150, "Version", newJString(Version))
  if Filters != nil:
    query_607150.add "Filters", Filters
  add(query_607150, "MaxRecords", newJInt(MaxRecords))
  result = call_607149.call(nil, query_607150, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_607132(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_607133, base: "/",
    url: url_GetDescribeDBSecurityGroups_607134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_607192 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSnapshots_607194(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_607193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607195 = query.getOrDefault("Action")
  valid_607195 = validateParameter(valid_607195, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607195 != nil:
    section.add "Action", valid_607195
  var valid_607196 = query.getOrDefault("Version")
  valid_607196 = validateParameter(valid_607196, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607196 != nil:
    section.add "Version", valid_607196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607197 = header.getOrDefault("X-Amz-Signature")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Signature", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Content-Sha256", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Date")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Date", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Credential")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Credential", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Security-Token")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Security-Token", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Algorithm")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Algorithm", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-SignedHeaders", valid_607203
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607204 = formData.getOrDefault("SnapshotType")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "SnapshotType", valid_607204
  var valid_607205 = formData.getOrDefault("MaxRecords")
  valid_607205 = validateParameter(valid_607205, JInt, required = false, default = nil)
  if valid_607205 != nil:
    section.add "MaxRecords", valid_607205
  var valid_607206 = formData.getOrDefault("Marker")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "Marker", valid_607206
  var valid_607207 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "DBInstanceIdentifier", valid_607207
  var valid_607208 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "DBSnapshotIdentifier", valid_607208
  var valid_607209 = formData.getOrDefault("Filters")
  valid_607209 = validateParameter(valid_607209, JArray, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "Filters", valid_607209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607210: Call_PostDescribeDBSnapshots_607192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607210.validator(path, query, header, formData, body)
  let scheme = call_607210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607210.url(scheme.get, call_607210.host, call_607210.base,
                         call_607210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607210, url, valid)

proc call*(call_607211: Call_PostDescribeDBSnapshots_607192;
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
  var query_607212 = newJObject()
  var formData_607213 = newJObject()
  add(formData_607213, "SnapshotType", newJString(SnapshotType))
  add(formData_607213, "MaxRecords", newJInt(MaxRecords))
  add(formData_607213, "Marker", newJString(Marker))
  add(formData_607213, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607213, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607212, "Action", newJString(Action))
  if Filters != nil:
    formData_607213.add "Filters", Filters
  add(query_607212, "Version", newJString(Version))
  result = call_607211.call(nil, query_607212, nil, formData_607213, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_607192(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_607193, base: "/",
    url: url_PostDescribeDBSnapshots_607194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_607171 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSnapshots_607173(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_607172(path: JsonNode; query: JsonNode;
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
  var valid_607174 = query.getOrDefault("Marker")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "Marker", valid_607174
  var valid_607175 = query.getOrDefault("DBInstanceIdentifier")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "DBInstanceIdentifier", valid_607175
  var valid_607176 = query.getOrDefault("DBSnapshotIdentifier")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "DBSnapshotIdentifier", valid_607176
  var valid_607177 = query.getOrDefault("SnapshotType")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "SnapshotType", valid_607177
  var valid_607178 = query.getOrDefault("Action")
  valid_607178 = validateParameter(valid_607178, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_607178 != nil:
    section.add "Action", valid_607178
  var valid_607179 = query.getOrDefault("Version")
  valid_607179 = validateParameter(valid_607179, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607179 != nil:
    section.add "Version", valid_607179
  var valid_607180 = query.getOrDefault("Filters")
  valid_607180 = validateParameter(valid_607180, JArray, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "Filters", valid_607180
  var valid_607181 = query.getOrDefault("MaxRecords")
  valid_607181 = validateParameter(valid_607181, JInt, required = false, default = nil)
  if valid_607181 != nil:
    section.add "MaxRecords", valid_607181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607182 = header.getOrDefault("X-Amz-Signature")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Signature", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Content-Sha256", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Date")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Date", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Credential")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Credential", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Security-Token")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Security-Token", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Algorithm")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Algorithm", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-SignedHeaders", valid_607188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607189: Call_GetDescribeDBSnapshots_607171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607189.validator(path, query, header, formData, body)
  let scheme = call_607189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607189.url(scheme.get, call_607189.host, call_607189.base,
                         call_607189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607189, url, valid)

proc call*(call_607190: Call_GetDescribeDBSnapshots_607171; Marker: string = "";
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
  var query_607191 = newJObject()
  add(query_607191, "Marker", newJString(Marker))
  add(query_607191, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607191, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_607191, "SnapshotType", newJString(SnapshotType))
  add(query_607191, "Action", newJString(Action))
  add(query_607191, "Version", newJString(Version))
  if Filters != nil:
    query_607191.add "Filters", Filters
  add(query_607191, "MaxRecords", newJInt(MaxRecords))
  result = call_607190.call(nil, query_607191, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_607171(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_607172, base: "/",
    url: url_GetDescribeDBSnapshots_607173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_607233 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSubnetGroups_607235(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_607234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607236 = query.getOrDefault("Action")
  valid_607236 = validateParameter(valid_607236, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607236 != nil:
    section.add "Action", valid_607236
  var valid_607237 = query.getOrDefault("Version")
  valid_607237 = validateParameter(valid_607237, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607237 != nil:
    section.add "Version", valid_607237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607238 = header.getOrDefault("X-Amz-Signature")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-Signature", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Content-Sha256", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Date")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Date", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Credential")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Credential", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-Security-Token")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-Security-Token", valid_607242
  var valid_607243 = header.getOrDefault("X-Amz-Algorithm")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "X-Amz-Algorithm", valid_607243
  var valid_607244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607244 = validateParameter(valid_607244, JString, required = false,
                                 default = nil)
  if valid_607244 != nil:
    section.add "X-Amz-SignedHeaders", valid_607244
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607245 = formData.getOrDefault("MaxRecords")
  valid_607245 = validateParameter(valid_607245, JInt, required = false, default = nil)
  if valid_607245 != nil:
    section.add "MaxRecords", valid_607245
  var valid_607246 = formData.getOrDefault("Marker")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "Marker", valid_607246
  var valid_607247 = formData.getOrDefault("DBSubnetGroupName")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "DBSubnetGroupName", valid_607247
  var valid_607248 = formData.getOrDefault("Filters")
  valid_607248 = validateParameter(valid_607248, JArray, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "Filters", valid_607248
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607249: Call_PostDescribeDBSubnetGroups_607233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607249.validator(path, query, header, formData, body)
  let scheme = call_607249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607249.url(scheme.get, call_607249.host, call_607249.base,
                         call_607249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607249, url, valid)

proc call*(call_607250: Call_PostDescribeDBSubnetGroups_607233;
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
  var query_607251 = newJObject()
  var formData_607252 = newJObject()
  add(formData_607252, "MaxRecords", newJInt(MaxRecords))
  add(formData_607252, "Marker", newJString(Marker))
  add(query_607251, "Action", newJString(Action))
  add(formData_607252, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_607252.add "Filters", Filters
  add(query_607251, "Version", newJString(Version))
  result = call_607250.call(nil, query_607251, nil, formData_607252, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_607233(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_607234, base: "/",
    url: url_PostDescribeDBSubnetGroups_607235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_607214 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSubnetGroups_607216(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_607215(path: JsonNode; query: JsonNode;
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
  var valid_607217 = query.getOrDefault("Marker")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "Marker", valid_607217
  var valid_607218 = query.getOrDefault("Action")
  valid_607218 = validateParameter(valid_607218, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607218 != nil:
    section.add "Action", valid_607218
  var valid_607219 = query.getOrDefault("DBSubnetGroupName")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "DBSubnetGroupName", valid_607219
  var valid_607220 = query.getOrDefault("Version")
  valid_607220 = validateParameter(valid_607220, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607220 != nil:
    section.add "Version", valid_607220
  var valid_607221 = query.getOrDefault("Filters")
  valid_607221 = validateParameter(valid_607221, JArray, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "Filters", valid_607221
  var valid_607222 = query.getOrDefault("MaxRecords")
  valid_607222 = validateParameter(valid_607222, JInt, required = false, default = nil)
  if valid_607222 != nil:
    section.add "MaxRecords", valid_607222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607223 = header.getOrDefault("X-Amz-Signature")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Signature", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Content-Sha256", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Date")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Date", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Credential")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Credential", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-Security-Token")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-Security-Token", valid_607227
  var valid_607228 = header.getOrDefault("X-Amz-Algorithm")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "X-Amz-Algorithm", valid_607228
  var valid_607229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-SignedHeaders", valid_607229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607230: Call_GetDescribeDBSubnetGroups_607214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607230.validator(path, query, header, formData, body)
  let scheme = call_607230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607230.url(scheme.get, call_607230.host, call_607230.base,
                         call_607230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607230, url, valid)

proc call*(call_607231: Call_GetDescribeDBSubnetGroups_607214; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_607232 = newJObject()
  add(query_607232, "Marker", newJString(Marker))
  add(query_607232, "Action", newJString(Action))
  add(query_607232, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607232, "Version", newJString(Version))
  if Filters != nil:
    query_607232.add "Filters", Filters
  add(query_607232, "MaxRecords", newJInt(MaxRecords))
  result = call_607231.call(nil, query_607232, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_607214(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_607215, base: "/",
    url: url_GetDescribeDBSubnetGroups_607216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_607272 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEngineDefaultParameters_607274(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_607273(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607275 = query.getOrDefault("Action")
  valid_607275 = validateParameter(valid_607275, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607275 != nil:
    section.add "Action", valid_607275
  var valid_607276 = query.getOrDefault("Version")
  valid_607276 = validateParameter(valid_607276, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607276 != nil:
    section.add "Version", valid_607276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607277 = header.getOrDefault("X-Amz-Signature")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Signature", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Content-Sha256", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Date")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Date", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Credential")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Credential", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Security-Token")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Security-Token", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Algorithm")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Algorithm", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-SignedHeaders", valid_607283
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_607284 = formData.getOrDefault("MaxRecords")
  valid_607284 = validateParameter(valid_607284, JInt, required = false, default = nil)
  if valid_607284 != nil:
    section.add "MaxRecords", valid_607284
  var valid_607285 = formData.getOrDefault("Marker")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "Marker", valid_607285
  var valid_607286 = formData.getOrDefault("Filters")
  valid_607286 = validateParameter(valid_607286, JArray, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "Filters", valid_607286
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607287 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607287 = validateParameter(valid_607287, JString, required = true,
                                 default = nil)
  if valid_607287 != nil:
    section.add "DBParameterGroupFamily", valid_607287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607288: Call_PostDescribeEngineDefaultParameters_607272;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607288.validator(path, query, header, formData, body)
  let scheme = call_607288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607288.url(scheme.get, call_607288.host, call_607288.base,
                         call_607288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607288, url, valid)

proc call*(call_607289: Call_PostDescribeEngineDefaultParameters_607272;
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
  var query_607290 = newJObject()
  var formData_607291 = newJObject()
  add(formData_607291, "MaxRecords", newJInt(MaxRecords))
  add(formData_607291, "Marker", newJString(Marker))
  add(query_607290, "Action", newJString(Action))
  if Filters != nil:
    formData_607291.add "Filters", Filters
  add(query_607290, "Version", newJString(Version))
  add(formData_607291, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607289.call(nil, query_607290, nil, formData_607291, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_607272(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_607273, base: "/",
    url: url_PostDescribeEngineDefaultParameters_607274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_607253 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEngineDefaultParameters_607255(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_607254(path: JsonNode;
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
  var valid_607256 = query.getOrDefault("Marker")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "Marker", valid_607256
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607257 = query.getOrDefault("DBParameterGroupFamily")
  valid_607257 = validateParameter(valid_607257, JString, required = true,
                                 default = nil)
  if valid_607257 != nil:
    section.add "DBParameterGroupFamily", valid_607257
  var valid_607258 = query.getOrDefault("Action")
  valid_607258 = validateParameter(valid_607258, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_607258 != nil:
    section.add "Action", valid_607258
  var valid_607259 = query.getOrDefault("Version")
  valid_607259 = validateParameter(valid_607259, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607259 != nil:
    section.add "Version", valid_607259
  var valid_607260 = query.getOrDefault("Filters")
  valid_607260 = validateParameter(valid_607260, JArray, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "Filters", valid_607260
  var valid_607261 = query.getOrDefault("MaxRecords")
  valid_607261 = validateParameter(valid_607261, JInt, required = false, default = nil)
  if valid_607261 != nil:
    section.add "MaxRecords", valid_607261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607262 = header.getOrDefault("X-Amz-Signature")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Signature", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Content-Sha256", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Date")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Date", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Credential")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Credential", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Security-Token")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Security-Token", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Algorithm")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Algorithm", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-SignedHeaders", valid_607268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607269: Call_GetDescribeEngineDefaultParameters_607253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607269.validator(path, query, header, formData, body)
  let scheme = call_607269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607269.url(scheme.get, call_607269.host, call_607269.base,
                         call_607269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607269, url, valid)

proc call*(call_607270: Call_GetDescribeEngineDefaultParameters_607253;
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
  var query_607271 = newJObject()
  add(query_607271, "Marker", newJString(Marker))
  add(query_607271, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607271, "Action", newJString(Action))
  add(query_607271, "Version", newJString(Version))
  if Filters != nil:
    query_607271.add "Filters", Filters
  add(query_607271, "MaxRecords", newJInt(MaxRecords))
  result = call_607270.call(nil, query_607271, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_607253(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_607254, base: "/",
    url: url_GetDescribeEngineDefaultParameters_607255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_607309 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventCategories_607311(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_607310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607312 = query.getOrDefault("Action")
  valid_607312 = validateParameter(valid_607312, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607312 != nil:
    section.add "Action", valid_607312
  var valid_607313 = query.getOrDefault("Version")
  valid_607313 = validateParameter(valid_607313, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607313 != nil:
    section.add "Version", valid_607313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607314 = header.getOrDefault("X-Amz-Signature")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Signature", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-Content-Sha256", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-Date")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Date", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Credential")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Credential", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Security-Token")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Security-Token", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Algorithm")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Algorithm", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-SignedHeaders", valid_607320
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607321 = formData.getOrDefault("SourceType")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "SourceType", valid_607321
  var valid_607322 = formData.getOrDefault("Filters")
  valid_607322 = validateParameter(valid_607322, JArray, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "Filters", valid_607322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607323: Call_PostDescribeEventCategories_607309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607323.validator(path, query, header, formData, body)
  let scheme = call_607323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607323.url(scheme.get, call_607323.host, call_607323.base,
                         call_607323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607323, url, valid)

proc call*(call_607324: Call_PostDescribeEventCategories_607309;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_607325 = newJObject()
  var formData_607326 = newJObject()
  add(formData_607326, "SourceType", newJString(SourceType))
  add(query_607325, "Action", newJString(Action))
  if Filters != nil:
    formData_607326.add "Filters", Filters
  add(query_607325, "Version", newJString(Version))
  result = call_607324.call(nil, query_607325, nil, formData_607326, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_607309(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_607310, base: "/",
    url: url_PostDescribeEventCategories_607311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_607292 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventCategories_607294(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_607293(path: JsonNode; query: JsonNode;
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
  var valid_607295 = query.getOrDefault("SourceType")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "SourceType", valid_607295
  var valid_607296 = query.getOrDefault("Action")
  valid_607296 = validateParameter(valid_607296, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607296 != nil:
    section.add "Action", valid_607296
  var valid_607297 = query.getOrDefault("Version")
  valid_607297 = validateParameter(valid_607297, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607297 != nil:
    section.add "Version", valid_607297
  var valid_607298 = query.getOrDefault("Filters")
  valid_607298 = validateParameter(valid_607298, JArray, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "Filters", valid_607298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607299 = header.getOrDefault("X-Amz-Signature")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Signature", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Content-Sha256", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Date")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Date", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Credential")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Credential", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Security-Token")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Security-Token", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Algorithm")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Algorithm", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-SignedHeaders", valid_607305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607306: Call_GetDescribeEventCategories_607292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607306.validator(path, query, header, formData, body)
  let scheme = call_607306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607306.url(scheme.get, call_607306.host, call_607306.base,
                         call_607306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607306, url, valid)

proc call*(call_607307: Call_GetDescribeEventCategories_607292;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-09-09"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_607308 = newJObject()
  add(query_607308, "SourceType", newJString(SourceType))
  add(query_607308, "Action", newJString(Action))
  add(query_607308, "Version", newJString(Version))
  if Filters != nil:
    query_607308.add "Filters", Filters
  result = call_607307.call(nil, query_607308, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_607292(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_607293, base: "/",
    url: url_GetDescribeEventCategories_607294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_607346 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventSubscriptions_607348(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_607347(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607349 = query.getOrDefault("Action")
  valid_607349 = validateParameter(valid_607349, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607349 != nil:
    section.add "Action", valid_607349
  var valid_607350 = query.getOrDefault("Version")
  valid_607350 = validateParameter(valid_607350, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607350 != nil:
    section.add "Version", valid_607350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607351 = header.getOrDefault("X-Amz-Signature")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Signature", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Content-Sha256", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Date")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Date", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Credential")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Credential", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Security-Token")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Security-Token", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Algorithm")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Algorithm", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-SignedHeaders", valid_607357
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607358 = formData.getOrDefault("MaxRecords")
  valid_607358 = validateParameter(valid_607358, JInt, required = false, default = nil)
  if valid_607358 != nil:
    section.add "MaxRecords", valid_607358
  var valid_607359 = formData.getOrDefault("Marker")
  valid_607359 = validateParameter(valid_607359, JString, required = false,
                                 default = nil)
  if valid_607359 != nil:
    section.add "Marker", valid_607359
  var valid_607360 = formData.getOrDefault("SubscriptionName")
  valid_607360 = validateParameter(valid_607360, JString, required = false,
                                 default = nil)
  if valid_607360 != nil:
    section.add "SubscriptionName", valid_607360
  var valid_607361 = formData.getOrDefault("Filters")
  valid_607361 = validateParameter(valid_607361, JArray, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "Filters", valid_607361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607362: Call_PostDescribeEventSubscriptions_607346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607362.validator(path, query, header, formData, body)
  let scheme = call_607362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607362.url(scheme.get, call_607362.host, call_607362.base,
                         call_607362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607362, url, valid)

proc call*(call_607363: Call_PostDescribeEventSubscriptions_607346;
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
  var query_607364 = newJObject()
  var formData_607365 = newJObject()
  add(formData_607365, "MaxRecords", newJInt(MaxRecords))
  add(formData_607365, "Marker", newJString(Marker))
  add(formData_607365, "SubscriptionName", newJString(SubscriptionName))
  add(query_607364, "Action", newJString(Action))
  if Filters != nil:
    formData_607365.add "Filters", Filters
  add(query_607364, "Version", newJString(Version))
  result = call_607363.call(nil, query_607364, nil, formData_607365, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_607346(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_607347, base: "/",
    url: url_PostDescribeEventSubscriptions_607348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_607327 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventSubscriptions_607329(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_607328(path: JsonNode; query: JsonNode;
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
  var valid_607330 = query.getOrDefault("Marker")
  valid_607330 = validateParameter(valid_607330, JString, required = false,
                                 default = nil)
  if valid_607330 != nil:
    section.add "Marker", valid_607330
  var valid_607331 = query.getOrDefault("SubscriptionName")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "SubscriptionName", valid_607331
  var valid_607332 = query.getOrDefault("Action")
  valid_607332 = validateParameter(valid_607332, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_607332 != nil:
    section.add "Action", valid_607332
  var valid_607333 = query.getOrDefault("Version")
  valid_607333 = validateParameter(valid_607333, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607333 != nil:
    section.add "Version", valid_607333
  var valid_607334 = query.getOrDefault("Filters")
  valid_607334 = validateParameter(valid_607334, JArray, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "Filters", valid_607334
  var valid_607335 = query.getOrDefault("MaxRecords")
  valid_607335 = validateParameter(valid_607335, JInt, required = false, default = nil)
  if valid_607335 != nil:
    section.add "MaxRecords", valid_607335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607336 = header.getOrDefault("X-Amz-Signature")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Signature", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Content-Sha256", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Date")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Date", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Credential")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Credential", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Security-Token")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Security-Token", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-Algorithm")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-Algorithm", valid_607341
  var valid_607342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "X-Amz-SignedHeaders", valid_607342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607343: Call_GetDescribeEventSubscriptions_607327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_GetDescribeEventSubscriptions_607327;
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
  var query_607345 = newJObject()
  add(query_607345, "Marker", newJString(Marker))
  add(query_607345, "SubscriptionName", newJString(SubscriptionName))
  add(query_607345, "Action", newJString(Action))
  add(query_607345, "Version", newJString(Version))
  if Filters != nil:
    query_607345.add "Filters", Filters
  add(query_607345, "MaxRecords", newJInt(MaxRecords))
  result = call_607344.call(nil, query_607345, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_607327(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_607328, base: "/",
    url: url_GetDescribeEventSubscriptions_607329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607390 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEvents_607392(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_607391(path: JsonNode; query: JsonNode;
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
  var valid_607393 = query.getOrDefault("Action")
  valid_607393 = validateParameter(valid_607393, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607393 != nil:
    section.add "Action", valid_607393
  var valid_607394 = query.getOrDefault("Version")
  valid_607394 = validateParameter(valid_607394, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607394 != nil:
    section.add "Version", valid_607394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607395 = header.getOrDefault("X-Amz-Signature")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Signature", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Content-Sha256", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Date")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Date", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Credential")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Credential", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Security-Token")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Security-Token", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Algorithm")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Algorithm", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-SignedHeaders", valid_607401
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
  var valid_607402 = formData.getOrDefault("MaxRecords")
  valid_607402 = validateParameter(valid_607402, JInt, required = false, default = nil)
  if valid_607402 != nil:
    section.add "MaxRecords", valid_607402
  var valid_607403 = formData.getOrDefault("Marker")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "Marker", valid_607403
  var valid_607404 = formData.getOrDefault("SourceIdentifier")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "SourceIdentifier", valid_607404
  var valid_607405 = formData.getOrDefault("SourceType")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607405 != nil:
    section.add "SourceType", valid_607405
  var valid_607406 = formData.getOrDefault("Duration")
  valid_607406 = validateParameter(valid_607406, JInt, required = false, default = nil)
  if valid_607406 != nil:
    section.add "Duration", valid_607406
  var valid_607407 = formData.getOrDefault("EndTime")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "EndTime", valid_607407
  var valid_607408 = formData.getOrDefault("StartTime")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "StartTime", valid_607408
  var valid_607409 = formData.getOrDefault("EventCategories")
  valid_607409 = validateParameter(valid_607409, JArray, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "EventCategories", valid_607409
  var valid_607410 = formData.getOrDefault("Filters")
  valid_607410 = validateParameter(valid_607410, JArray, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "Filters", valid_607410
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607411: Call_PostDescribeEvents_607390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607411.validator(path, query, header, formData, body)
  let scheme = call_607411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607411.url(scheme.get, call_607411.host, call_607411.base,
                         call_607411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607411, url, valid)

proc call*(call_607412: Call_PostDescribeEvents_607390; MaxRecords: int = 0;
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
  var query_607413 = newJObject()
  var formData_607414 = newJObject()
  add(formData_607414, "MaxRecords", newJInt(MaxRecords))
  add(formData_607414, "Marker", newJString(Marker))
  add(formData_607414, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_607414, "SourceType", newJString(SourceType))
  add(formData_607414, "Duration", newJInt(Duration))
  add(formData_607414, "EndTime", newJString(EndTime))
  add(formData_607414, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_607414.add "EventCategories", EventCategories
  add(query_607413, "Action", newJString(Action))
  if Filters != nil:
    formData_607414.add "Filters", Filters
  add(query_607413, "Version", newJString(Version))
  result = call_607412.call(nil, query_607413, nil, formData_607414, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607390(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607391, base: "/",
    url: url_PostDescribeEvents_607392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607366 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEvents_607368(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_607367(path: JsonNode; query: JsonNode;
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
  var valid_607369 = query.getOrDefault("Marker")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "Marker", valid_607369
  var valid_607370 = query.getOrDefault("SourceType")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607370 != nil:
    section.add "SourceType", valid_607370
  var valid_607371 = query.getOrDefault("SourceIdentifier")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "SourceIdentifier", valid_607371
  var valid_607372 = query.getOrDefault("EventCategories")
  valid_607372 = validateParameter(valid_607372, JArray, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "EventCategories", valid_607372
  var valid_607373 = query.getOrDefault("Action")
  valid_607373 = validateParameter(valid_607373, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607373 != nil:
    section.add "Action", valid_607373
  var valid_607374 = query.getOrDefault("StartTime")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "StartTime", valid_607374
  var valid_607375 = query.getOrDefault("Duration")
  valid_607375 = validateParameter(valid_607375, JInt, required = false, default = nil)
  if valid_607375 != nil:
    section.add "Duration", valid_607375
  var valid_607376 = query.getOrDefault("EndTime")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "EndTime", valid_607376
  var valid_607377 = query.getOrDefault("Version")
  valid_607377 = validateParameter(valid_607377, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607377 != nil:
    section.add "Version", valid_607377
  var valid_607378 = query.getOrDefault("Filters")
  valid_607378 = validateParameter(valid_607378, JArray, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "Filters", valid_607378
  var valid_607379 = query.getOrDefault("MaxRecords")
  valid_607379 = validateParameter(valid_607379, JInt, required = false, default = nil)
  if valid_607379 != nil:
    section.add "MaxRecords", valid_607379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607387: Call_GetDescribeEvents_607366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607387.validator(path, query, header, formData, body)
  let scheme = call_607387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607387.url(scheme.get, call_607387.host, call_607387.base,
                         call_607387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607387, url, valid)

proc call*(call_607388: Call_GetDescribeEvents_607366; Marker: string = "";
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
  var query_607389 = newJObject()
  add(query_607389, "Marker", newJString(Marker))
  add(query_607389, "SourceType", newJString(SourceType))
  add(query_607389, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_607389.add "EventCategories", EventCategories
  add(query_607389, "Action", newJString(Action))
  add(query_607389, "StartTime", newJString(StartTime))
  add(query_607389, "Duration", newJInt(Duration))
  add(query_607389, "EndTime", newJString(EndTime))
  add(query_607389, "Version", newJString(Version))
  if Filters != nil:
    query_607389.add "Filters", Filters
  add(query_607389, "MaxRecords", newJInt(MaxRecords))
  result = call_607388.call(nil, query_607389, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607366(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607367,
    base: "/", url: url_GetDescribeEvents_607368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_607435 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroupOptions_607437(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_607436(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607438 = query.getOrDefault("Action")
  valid_607438 = validateParameter(valid_607438, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607438 != nil:
    section.add "Action", valid_607438
  var valid_607439 = query.getOrDefault("Version")
  valid_607439 = validateParameter(valid_607439, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607439 != nil:
    section.add "Version", valid_607439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607440 = header.getOrDefault("X-Amz-Signature")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Signature", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Content-Sha256", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Date")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Date", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Credential")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Credential", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Security-Token")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Security-Token", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-Algorithm")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Algorithm", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-SignedHeaders", valid_607446
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607447 = formData.getOrDefault("MaxRecords")
  valid_607447 = validateParameter(valid_607447, JInt, required = false, default = nil)
  if valid_607447 != nil:
    section.add "MaxRecords", valid_607447
  var valid_607448 = formData.getOrDefault("Marker")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "Marker", valid_607448
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_607449 = formData.getOrDefault("EngineName")
  valid_607449 = validateParameter(valid_607449, JString, required = true,
                                 default = nil)
  if valid_607449 != nil:
    section.add "EngineName", valid_607449
  var valid_607450 = formData.getOrDefault("MajorEngineVersion")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "MajorEngineVersion", valid_607450
  var valid_607451 = formData.getOrDefault("Filters")
  valid_607451 = validateParameter(valid_607451, JArray, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "Filters", valid_607451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607452: Call_PostDescribeOptionGroupOptions_607435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607452.validator(path, query, header, formData, body)
  let scheme = call_607452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607452.url(scheme.get, call_607452.host, call_607452.base,
                         call_607452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607452, url, valid)

proc call*(call_607453: Call_PostDescribeOptionGroupOptions_607435;
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
  var query_607454 = newJObject()
  var formData_607455 = newJObject()
  add(formData_607455, "MaxRecords", newJInt(MaxRecords))
  add(formData_607455, "Marker", newJString(Marker))
  add(formData_607455, "EngineName", newJString(EngineName))
  add(formData_607455, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607454, "Action", newJString(Action))
  if Filters != nil:
    formData_607455.add "Filters", Filters
  add(query_607454, "Version", newJString(Version))
  result = call_607453.call(nil, query_607454, nil, formData_607455, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_607435(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_607436, base: "/",
    url: url_PostDescribeOptionGroupOptions_607437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_607415 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroupOptions_607417(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_607416(path: JsonNode; query: JsonNode;
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
  var valid_607418 = query.getOrDefault("EngineName")
  valid_607418 = validateParameter(valid_607418, JString, required = true,
                                 default = nil)
  if valid_607418 != nil:
    section.add "EngineName", valid_607418
  var valid_607419 = query.getOrDefault("Marker")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "Marker", valid_607419
  var valid_607420 = query.getOrDefault("Action")
  valid_607420 = validateParameter(valid_607420, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_607420 != nil:
    section.add "Action", valid_607420
  var valid_607421 = query.getOrDefault("Version")
  valid_607421 = validateParameter(valid_607421, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607421 != nil:
    section.add "Version", valid_607421
  var valid_607422 = query.getOrDefault("Filters")
  valid_607422 = validateParameter(valid_607422, JArray, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "Filters", valid_607422
  var valid_607423 = query.getOrDefault("MaxRecords")
  valid_607423 = validateParameter(valid_607423, JInt, required = false, default = nil)
  if valid_607423 != nil:
    section.add "MaxRecords", valid_607423
  var valid_607424 = query.getOrDefault("MajorEngineVersion")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "MajorEngineVersion", valid_607424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607425 = header.getOrDefault("X-Amz-Signature")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Signature", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Content-Sha256", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Date")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Date", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-Credential")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-Credential", valid_607428
  var valid_607429 = header.getOrDefault("X-Amz-Security-Token")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Security-Token", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Algorithm")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Algorithm", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-SignedHeaders", valid_607431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607432: Call_GetDescribeOptionGroupOptions_607415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607432.validator(path, query, header, formData, body)
  let scheme = call_607432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607432.url(scheme.get, call_607432.host, call_607432.base,
                         call_607432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607432, url, valid)

proc call*(call_607433: Call_GetDescribeOptionGroupOptions_607415;
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
  var query_607434 = newJObject()
  add(query_607434, "EngineName", newJString(EngineName))
  add(query_607434, "Marker", newJString(Marker))
  add(query_607434, "Action", newJString(Action))
  add(query_607434, "Version", newJString(Version))
  if Filters != nil:
    query_607434.add "Filters", Filters
  add(query_607434, "MaxRecords", newJInt(MaxRecords))
  add(query_607434, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607433.call(nil, query_607434, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_607415(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_607416, base: "/",
    url: url_GetDescribeOptionGroupOptions_607417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_607477 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOptionGroups_607479(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_607478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607480 = query.getOrDefault("Action")
  valid_607480 = validateParameter(valid_607480, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607480 != nil:
    section.add "Action", valid_607480
  var valid_607481 = query.getOrDefault("Version")
  valid_607481 = validateParameter(valid_607481, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607481 != nil:
    section.add "Version", valid_607481
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607482 = header.getOrDefault("X-Amz-Signature")
  valid_607482 = validateParameter(valid_607482, JString, required = false,
                                 default = nil)
  if valid_607482 != nil:
    section.add "X-Amz-Signature", valid_607482
  var valid_607483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607483 = validateParameter(valid_607483, JString, required = false,
                                 default = nil)
  if valid_607483 != nil:
    section.add "X-Amz-Content-Sha256", valid_607483
  var valid_607484 = header.getOrDefault("X-Amz-Date")
  valid_607484 = validateParameter(valid_607484, JString, required = false,
                                 default = nil)
  if valid_607484 != nil:
    section.add "X-Amz-Date", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Credential")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Credential", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Security-Token")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Security-Token", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Algorithm")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Algorithm", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-SignedHeaders", valid_607488
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_607489 = formData.getOrDefault("MaxRecords")
  valid_607489 = validateParameter(valid_607489, JInt, required = false, default = nil)
  if valid_607489 != nil:
    section.add "MaxRecords", valid_607489
  var valid_607490 = formData.getOrDefault("Marker")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "Marker", valid_607490
  var valid_607491 = formData.getOrDefault("EngineName")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "EngineName", valid_607491
  var valid_607492 = formData.getOrDefault("MajorEngineVersion")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "MajorEngineVersion", valid_607492
  var valid_607493 = formData.getOrDefault("OptionGroupName")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "OptionGroupName", valid_607493
  var valid_607494 = formData.getOrDefault("Filters")
  valid_607494 = validateParameter(valid_607494, JArray, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "Filters", valid_607494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607495: Call_PostDescribeOptionGroups_607477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607495.validator(path, query, header, formData, body)
  let scheme = call_607495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607495.url(scheme.get, call_607495.host, call_607495.base,
                         call_607495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607495, url, valid)

proc call*(call_607496: Call_PostDescribeOptionGroups_607477; MaxRecords: int = 0;
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
  var query_607497 = newJObject()
  var formData_607498 = newJObject()
  add(formData_607498, "MaxRecords", newJInt(MaxRecords))
  add(formData_607498, "Marker", newJString(Marker))
  add(formData_607498, "EngineName", newJString(EngineName))
  add(formData_607498, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_607497, "Action", newJString(Action))
  add(formData_607498, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_607498.add "Filters", Filters
  add(query_607497, "Version", newJString(Version))
  result = call_607496.call(nil, query_607497, nil, formData_607498, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_607477(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_607478, base: "/",
    url: url_PostDescribeOptionGroups_607479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_607456 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOptionGroups_607458(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_607457(path: JsonNode; query: JsonNode;
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
  var valid_607459 = query.getOrDefault("EngineName")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "EngineName", valid_607459
  var valid_607460 = query.getOrDefault("Marker")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "Marker", valid_607460
  var valid_607461 = query.getOrDefault("Action")
  valid_607461 = validateParameter(valid_607461, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_607461 != nil:
    section.add "Action", valid_607461
  var valid_607462 = query.getOrDefault("OptionGroupName")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "OptionGroupName", valid_607462
  var valid_607463 = query.getOrDefault("Version")
  valid_607463 = validateParameter(valid_607463, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_607466 = query.getOrDefault("MajorEngineVersion")
  valid_607466 = validateParameter(valid_607466, JString, required = false,
                                 default = nil)
  if valid_607466 != nil:
    section.add "MajorEngineVersion", valid_607466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607467 = header.getOrDefault("X-Amz-Signature")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "X-Amz-Signature", valid_607467
  var valid_607468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "X-Amz-Content-Sha256", valid_607468
  var valid_607469 = header.getOrDefault("X-Amz-Date")
  valid_607469 = validateParameter(valid_607469, JString, required = false,
                                 default = nil)
  if valid_607469 != nil:
    section.add "X-Amz-Date", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Credential")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Credential", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Security-Token")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Security-Token", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Algorithm")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Algorithm", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-SignedHeaders", valid_607473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607474: Call_GetDescribeOptionGroups_607456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607474.validator(path, query, header, formData, body)
  let scheme = call_607474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607474.url(scheme.get, call_607474.host, call_607474.base,
                         call_607474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607474, url, valid)

proc call*(call_607475: Call_GetDescribeOptionGroups_607456;
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
  var query_607476 = newJObject()
  add(query_607476, "EngineName", newJString(EngineName))
  add(query_607476, "Marker", newJString(Marker))
  add(query_607476, "Action", newJString(Action))
  add(query_607476, "OptionGroupName", newJString(OptionGroupName))
  add(query_607476, "Version", newJString(Version))
  if Filters != nil:
    query_607476.add "Filters", Filters
  add(query_607476, "MaxRecords", newJInt(MaxRecords))
  add(query_607476, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_607475.call(nil, query_607476, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_607456(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_607457, base: "/",
    url: url_GetDescribeOptionGroups_607458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_607522 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOrderableDBInstanceOptions_607524(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_607523(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607525 = query.getOrDefault("Action")
  valid_607525 = validateParameter(valid_607525, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607525 != nil:
    section.add "Action", valid_607525
  var valid_607526 = query.getOrDefault("Version")
  valid_607526 = validateParameter(valid_607526, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607526 != nil:
    section.add "Version", valid_607526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607527 = header.getOrDefault("X-Amz-Signature")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Signature", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Content-Sha256", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Date")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Date", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Credential")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Credential", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Security-Token")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Security-Token", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Algorithm")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Algorithm", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-SignedHeaders", valid_607533
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
  var valid_607534 = formData.getOrDefault("DBInstanceClass")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "DBInstanceClass", valid_607534
  var valid_607535 = formData.getOrDefault("MaxRecords")
  valid_607535 = validateParameter(valid_607535, JInt, required = false, default = nil)
  if valid_607535 != nil:
    section.add "MaxRecords", valid_607535
  var valid_607536 = formData.getOrDefault("EngineVersion")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "EngineVersion", valid_607536
  var valid_607537 = formData.getOrDefault("Marker")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "Marker", valid_607537
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607538 = formData.getOrDefault("Engine")
  valid_607538 = validateParameter(valid_607538, JString, required = true,
                                 default = nil)
  if valid_607538 != nil:
    section.add "Engine", valid_607538
  var valid_607539 = formData.getOrDefault("Vpc")
  valid_607539 = validateParameter(valid_607539, JBool, required = false, default = nil)
  if valid_607539 != nil:
    section.add "Vpc", valid_607539
  var valid_607540 = formData.getOrDefault("LicenseModel")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "LicenseModel", valid_607540
  var valid_607541 = formData.getOrDefault("Filters")
  valid_607541 = validateParameter(valid_607541, JArray, required = false,
                                 default = nil)
  if valid_607541 != nil:
    section.add "Filters", valid_607541
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607542: Call_PostDescribeOrderableDBInstanceOptions_607522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607542.validator(path, query, header, formData, body)
  let scheme = call_607542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607542.url(scheme.get, call_607542.host, call_607542.base,
                         call_607542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607542, url, valid)

proc call*(call_607543: Call_PostDescribeOrderableDBInstanceOptions_607522;
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
  var query_607544 = newJObject()
  var formData_607545 = newJObject()
  add(formData_607545, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607545, "MaxRecords", newJInt(MaxRecords))
  add(formData_607545, "EngineVersion", newJString(EngineVersion))
  add(formData_607545, "Marker", newJString(Marker))
  add(formData_607545, "Engine", newJString(Engine))
  add(formData_607545, "Vpc", newJBool(Vpc))
  add(query_607544, "Action", newJString(Action))
  add(formData_607545, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_607545.add "Filters", Filters
  add(query_607544, "Version", newJString(Version))
  result = call_607543.call(nil, query_607544, nil, formData_607545, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_607522(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_607523, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_607524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_607499 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOrderableDBInstanceOptions_607501(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_607500(path: JsonNode;
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
  var valid_607502 = query.getOrDefault("Marker")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "Marker", valid_607502
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607503 = query.getOrDefault("Engine")
  valid_607503 = validateParameter(valid_607503, JString, required = true,
                                 default = nil)
  if valid_607503 != nil:
    section.add "Engine", valid_607503
  var valid_607504 = query.getOrDefault("LicenseModel")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "LicenseModel", valid_607504
  var valid_607505 = query.getOrDefault("Vpc")
  valid_607505 = validateParameter(valid_607505, JBool, required = false, default = nil)
  if valid_607505 != nil:
    section.add "Vpc", valid_607505
  var valid_607506 = query.getOrDefault("EngineVersion")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "EngineVersion", valid_607506
  var valid_607507 = query.getOrDefault("Action")
  valid_607507 = validateParameter(valid_607507, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607507 != nil:
    section.add "Action", valid_607507
  var valid_607508 = query.getOrDefault("Version")
  valid_607508 = validateParameter(valid_607508, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607508 != nil:
    section.add "Version", valid_607508
  var valid_607509 = query.getOrDefault("DBInstanceClass")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "DBInstanceClass", valid_607509
  var valid_607510 = query.getOrDefault("Filters")
  valid_607510 = validateParameter(valid_607510, JArray, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "Filters", valid_607510
  var valid_607511 = query.getOrDefault("MaxRecords")
  valid_607511 = validateParameter(valid_607511, JInt, required = false, default = nil)
  if valid_607511 != nil:
    section.add "MaxRecords", valid_607511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607512 = header.getOrDefault("X-Amz-Signature")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Signature", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Content-Sha256", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Date")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Date", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Credential")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Credential", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Security-Token")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Security-Token", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Algorithm")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Algorithm", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-SignedHeaders", valid_607518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607519: Call_GetDescribeOrderableDBInstanceOptions_607499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607519.validator(path, query, header, formData, body)
  let scheme = call_607519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607519.url(scheme.get, call_607519.host, call_607519.base,
                         call_607519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607519, url, valid)

proc call*(call_607520: Call_GetDescribeOrderableDBInstanceOptions_607499;
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
  var query_607521 = newJObject()
  add(query_607521, "Marker", newJString(Marker))
  add(query_607521, "Engine", newJString(Engine))
  add(query_607521, "LicenseModel", newJString(LicenseModel))
  add(query_607521, "Vpc", newJBool(Vpc))
  add(query_607521, "EngineVersion", newJString(EngineVersion))
  add(query_607521, "Action", newJString(Action))
  add(query_607521, "Version", newJString(Version))
  add(query_607521, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607521.add "Filters", Filters
  add(query_607521, "MaxRecords", newJInt(MaxRecords))
  result = call_607520.call(nil, query_607521, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_607499(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_607500, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_607501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_607571 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstances_607573(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_607572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607574 = query.getOrDefault("Action")
  valid_607574 = validateParameter(valid_607574, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607574 != nil:
    section.add "Action", valid_607574
  var valid_607575 = query.getOrDefault("Version")
  valid_607575 = validateParameter(valid_607575, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607575 != nil:
    section.add "Version", valid_607575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607576 = header.getOrDefault("X-Amz-Signature")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-Signature", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Content-Sha256", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Date")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Date", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Credential")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Credential", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Security-Token")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Security-Token", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-Algorithm")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Algorithm", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-SignedHeaders", valid_607582
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
  var valid_607583 = formData.getOrDefault("DBInstanceClass")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "DBInstanceClass", valid_607583
  var valid_607584 = formData.getOrDefault("MultiAZ")
  valid_607584 = validateParameter(valid_607584, JBool, required = false, default = nil)
  if valid_607584 != nil:
    section.add "MultiAZ", valid_607584
  var valid_607585 = formData.getOrDefault("MaxRecords")
  valid_607585 = validateParameter(valid_607585, JInt, required = false, default = nil)
  if valid_607585 != nil:
    section.add "MaxRecords", valid_607585
  var valid_607586 = formData.getOrDefault("ReservedDBInstanceId")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "ReservedDBInstanceId", valid_607586
  var valid_607587 = formData.getOrDefault("Marker")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "Marker", valid_607587
  var valid_607588 = formData.getOrDefault("Duration")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "Duration", valid_607588
  var valid_607589 = formData.getOrDefault("OfferingType")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "OfferingType", valid_607589
  var valid_607590 = formData.getOrDefault("ProductDescription")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "ProductDescription", valid_607590
  var valid_607591 = formData.getOrDefault("Filters")
  valid_607591 = validateParameter(valid_607591, JArray, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "Filters", valid_607591
  var valid_607592 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607592
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607593: Call_PostDescribeReservedDBInstances_607571;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607593.validator(path, query, header, formData, body)
  let scheme = call_607593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607593.url(scheme.get, call_607593.host, call_607593.base,
                         call_607593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607593, url, valid)

proc call*(call_607594: Call_PostDescribeReservedDBInstances_607571;
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
  var query_607595 = newJObject()
  var formData_607596 = newJObject()
  add(formData_607596, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607596, "MultiAZ", newJBool(MultiAZ))
  add(formData_607596, "MaxRecords", newJInt(MaxRecords))
  add(formData_607596, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_607596, "Marker", newJString(Marker))
  add(formData_607596, "Duration", newJString(Duration))
  add(formData_607596, "OfferingType", newJString(OfferingType))
  add(formData_607596, "ProductDescription", newJString(ProductDescription))
  add(query_607595, "Action", newJString(Action))
  if Filters != nil:
    formData_607596.add "Filters", Filters
  add(formData_607596, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607595, "Version", newJString(Version))
  result = call_607594.call(nil, query_607595, nil, formData_607596, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_607571(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_607572, base: "/",
    url: url_PostDescribeReservedDBInstances_607573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_607546 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstances_607548(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_607547(path: JsonNode;
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
  var valid_607549 = query.getOrDefault("Marker")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "Marker", valid_607549
  var valid_607550 = query.getOrDefault("ProductDescription")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "ProductDescription", valid_607550
  var valid_607551 = query.getOrDefault("OfferingType")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "OfferingType", valid_607551
  var valid_607552 = query.getOrDefault("ReservedDBInstanceId")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "ReservedDBInstanceId", valid_607552
  var valid_607553 = query.getOrDefault("Action")
  valid_607553 = validateParameter(valid_607553, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_607553 != nil:
    section.add "Action", valid_607553
  var valid_607554 = query.getOrDefault("MultiAZ")
  valid_607554 = validateParameter(valid_607554, JBool, required = false, default = nil)
  if valid_607554 != nil:
    section.add "MultiAZ", valid_607554
  var valid_607555 = query.getOrDefault("Duration")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "Duration", valid_607555
  var valid_607556 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607556
  var valid_607557 = query.getOrDefault("Version")
  valid_607557 = validateParameter(valid_607557, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607557 != nil:
    section.add "Version", valid_607557
  var valid_607558 = query.getOrDefault("DBInstanceClass")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "DBInstanceClass", valid_607558
  var valid_607559 = query.getOrDefault("Filters")
  valid_607559 = validateParameter(valid_607559, JArray, required = false,
                                 default = nil)
  if valid_607559 != nil:
    section.add "Filters", valid_607559
  var valid_607560 = query.getOrDefault("MaxRecords")
  valid_607560 = validateParameter(valid_607560, JInt, required = false, default = nil)
  if valid_607560 != nil:
    section.add "MaxRecords", valid_607560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607561 = header.getOrDefault("X-Amz-Signature")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-Signature", valid_607561
  var valid_607562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "X-Amz-Content-Sha256", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Date")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Date", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Credential")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Credential", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Security-Token")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Security-Token", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Algorithm")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Algorithm", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-SignedHeaders", valid_607567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607568: Call_GetDescribeReservedDBInstances_607546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607568.validator(path, query, header, formData, body)
  let scheme = call_607568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607568.url(scheme.get, call_607568.host, call_607568.base,
                         call_607568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607568, url, valid)

proc call*(call_607569: Call_GetDescribeReservedDBInstances_607546;
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
  var query_607570 = newJObject()
  add(query_607570, "Marker", newJString(Marker))
  add(query_607570, "ProductDescription", newJString(ProductDescription))
  add(query_607570, "OfferingType", newJString(OfferingType))
  add(query_607570, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607570, "Action", newJString(Action))
  add(query_607570, "MultiAZ", newJBool(MultiAZ))
  add(query_607570, "Duration", newJString(Duration))
  add(query_607570, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607570, "Version", newJString(Version))
  add(query_607570, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607570.add "Filters", Filters
  add(query_607570, "MaxRecords", newJInt(MaxRecords))
  result = call_607569.call(nil, query_607570, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_607546(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_607547, base: "/",
    url: url_GetDescribeReservedDBInstances_607548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_607621 = ref object of OpenApiRestCall_605573
proc url_PostDescribeReservedDBInstancesOfferings_607623(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_607622(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607624 = query.getOrDefault("Action")
  valid_607624 = validateParameter(valid_607624, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607624 != nil:
    section.add "Action", valid_607624
  var valid_607625 = query.getOrDefault("Version")
  valid_607625 = validateParameter(valid_607625, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607625 != nil:
    section.add "Version", valid_607625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607626 = header.getOrDefault("X-Amz-Signature")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Signature", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Content-Sha256", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Date")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Date", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-Credential")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-Credential", valid_607629
  var valid_607630 = header.getOrDefault("X-Amz-Security-Token")
  valid_607630 = validateParameter(valid_607630, JString, required = false,
                                 default = nil)
  if valid_607630 != nil:
    section.add "X-Amz-Security-Token", valid_607630
  var valid_607631 = header.getOrDefault("X-Amz-Algorithm")
  valid_607631 = validateParameter(valid_607631, JString, required = false,
                                 default = nil)
  if valid_607631 != nil:
    section.add "X-Amz-Algorithm", valid_607631
  var valid_607632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "X-Amz-SignedHeaders", valid_607632
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
  var valid_607633 = formData.getOrDefault("DBInstanceClass")
  valid_607633 = validateParameter(valid_607633, JString, required = false,
                                 default = nil)
  if valid_607633 != nil:
    section.add "DBInstanceClass", valid_607633
  var valid_607634 = formData.getOrDefault("MultiAZ")
  valid_607634 = validateParameter(valid_607634, JBool, required = false, default = nil)
  if valid_607634 != nil:
    section.add "MultiAZ", valid_607634
  var valid_607635 = formData.getOrDefault("MaxRecords")
  valid_607635 = validateParameter(valid_607635, JInt, required = false, default = nil)
  if valid_607635 != nil:
    section.add "MaxRecords", valid_607635
  var valid_607636 = formData.getOrDefault("Marker")
  valid_607636 = validateParameter(valid_607636, JString, required = false,
                                 default = nil)
  if valid_607636 != nil:
    section.add "Marker", valid_607636
  var valid_607637 = formData.getOrDefault("Duration")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "Duration", valid_607637
  var valid_607638 = formData.getOrDefault("OfferingType")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "OfferingType", valid_607638
  var valid_607639 = formData.getOrDefault("ProductDescription")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "ProductDescription", valid_607639
  var valid_607640 = formData.getOrDefault("Filters")
  valid_607640 = validateParameter(valid_607640, JArray, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "Filters", valid_607640
  var valid_607641 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607642: Call_PostDescribeReservedDBInstancesOfferings_607621;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607642.validator(path, query, header, formData, body)
  let scheme = call_607642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607642.url(scheme.get, call_607642.host, call_607642.base,
                         call_607642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607642, url, valid)

proc call*(call_607643: Call_PostDescribeReservedDBInstancesOfferings_607621;
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
  var query_607644 = newJObject()
  var formData_607645 = newJObject()
  add(formData_607645, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607645, "MultiAZ", newJBool(MultiAZ))
  add(formData_607645, "MaxRecords", newJInt(MaxRecords))
  add(formData_607645, "Marker", newJString(Marker))
  add(formData_607645, "Duration", newJString(Duration))
  add(formData_607645, "OfferingType", newJString(OfferingType))
  add(formData_607645, "ProductDescription", newJString(ProductDescription))
  add(query_607644, "Action", newJString(Action))
  if Filters != nil:
    formData_607645.add "Filters", Filters
  add(formData_607645, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607644, "Version", newJString(Version))
  result = call_607643.call(nil, query_607644, nil, formData_607645, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_607621(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_607622,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_607623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_607597 = ref object of OpenApiRestCall_605573
proc url_GetDescribeReservedDBInstancesOfferings_607599(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_607598(path: JsonNode;
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
  var valid_607600 = query.getOrDefault("Marker")
  valid_607600 = validateParameter(valid_607600, JString, required = false,
                                 default = nil)
  if valid_607600 != nil:
    section.add "Marker", valid_607600
  var valid_607601 = query.getOrDefault("ProductDescription")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "ProductDescription", valid_607601
  var valid_607602 = query.getOrDefault("OfferingType")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "OfferingType", valid_607602
  var valid_607603 = query.getOrDefault("Action")
  valid_607603 = validateParameter(valid_607603, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_607603 != nil:
    section.add "Action", valid_607603
  var valid_607604 = query.getOrDefault("MultiAZ")
  valid_607604 = validateParameter(valid_607604, JBool, required = false, default = nil)
  if valid_607604 != nil:
    section.add "MultiAZ", valid_607604
  var valid_607605 = query.getOrDefault("Duration")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "Duration", valid_607605
  var valid_607606 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607606
  var valid_607607 = query.getOrDefault("Version")
  valid_607607 = validateParameter(valid_607607, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607607 != nil:
    section.add "Version", valid_607607
  var valid_607608 = query.getOrDefault("DBInstanceClass")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "DBInstanceClass", valid_607608
  var valid_607609 = query.getOrDefault("Filters")
  valid_607609 = validateParameter(valid_607609, JArray, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "Filters", valid_607609
  var valid_607610 = query.getOrDefault("MaxRecords")
  valid_607610 = validateParameter(valid_607610, JInt, required = false, default = nil)
  if valid_607610 != nil:
    section.add "MaxRecords", valid_607610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607611 = header.getOrDefault("X-Amz-Signature")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Signature", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Content-Sha256", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-Date")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-Date", valid_607613
  var valid_607614 = header.getOrDefault("X-Amz-Credential")
  valid_607614 = validateParameter(valid_607614, JString, required = false,
                                 default = nil)
  if valid_607614 != nil:
    section.add "X-Amz-Credential", valid_607614
  var valid_607615 = header.getOrDefault("X-Amz-Security-Token")
  valid_607615 = validateParameter(valid_607615, JString, required = false,
                                 default = nil)
  if valid_607615 != nil:
    section.add "X-Amz-Security-Token", valid_607615
  var valid_607616 = header.getOrDefault("X-Amz-Algorithm")
  valid_607616 = validateParameter(valid_607616, JString, required = false,
                                 default = nil)
  if valid_607616 != nil:
    section.add "X-Amz-Algorithm", valid_607616
  var valid_607617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "X-Amz-SignedHeaders", valid_607617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607618: Call_GetDescribeReservedDBInstancesOfferings_607597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607618.validator(path, query, header, formData, body)
  let scheme = call_607618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607618.url(scheme.get, call_607618.host, call_607618.base,
                         call_607618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607618, url, valid)

proc call*(call_607619: Call_GetDescribeReservedDBInstancesOfferings_607597;
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
  var query_607620 = newJObject()
  add(query_607620, "Marker", newJString(Marker))
  add(query_607620, "ProductDescription", newJString(ProductDescription))
  add(query_607620, "OfferingType", newJString(OfferingType))
  add(query_607620, "Action", newJString(Action))
  add(query_607620, "MultiAZ", newJBool(MultiAZ))
  add(query_607620, "Duration", newJString(Duration))
  add(query_607620, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607620, "Version", newJString(Version))
  add(query_607620, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607620.add "Filters", Filters
  add(query_607620, "MaxRecords", newJInt(MaxRecords))
  result = call_607619.call(nil, query_607620, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_607597(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_607598, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_607599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_607665 = ref object of OpenApiRestCall_605573
proc url_PostDownloadDBLogFilePortion_607667(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_607666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607668 = query.getOrDefault("Action")
  valid_607668 = validateParameter(valid_607668, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607668 != nil:
    section.add "Action", valid_607668
  var valid_607669 = query.getOrDefault("Version")
  valid_607669 = validateParameter(valid_607669, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607669 != nil:
    section.add "Version", valid_607669
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607670 = header.getOrDefault("X-Amz-Signature")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "X-Amz-Signature", valid_607670
  var valid_607671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "X-Amz-Content-Sha256", valid_607671
  var valid_607672 = header.getOrDefault("X-Amz-Date")
  valid_607672 = validateParameter(valid_607672, JString, required = false,
                                 default = nil)
  if valid_607672 != nil:
    section.add "X-Amz-Date", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-Credential")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-Credential", valid_607673
  var valid_607674 = header.getOrDefault("X-Amz-Security-Token")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-Security-Token", valid_607674
  var valid_607675 = header.getOrDefault("X-Amz-Algorithm")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Algorithm", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-SignedHeaders", valid_607676
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607677 = formData.getOrDefault("NumberOfLines")
  valid_607677 = validateParameter(valid_607677, JInt, required = false, default = nil)
  if valid_607677 != nil:
    section.add "NumberOfLines", valid_607677
  var valid_607678 = formData.getOrDefault("Marker")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "Marker", valid_607678
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_607679 = formData.getOrDefault("LogFileName")
  valid_607679 = validateParameter(valid_607679, JString, required = true,
                                 default = nil)
  if valid_607679 != nil:
    section.add "LogFileName", valid_607679
  var valid_607680 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607680 = validateParameter(valid_607680, JString, required = true,
                                 default = nil)
  if valid_607680 != nil:
    section.add "DBInstanceIdentifier", valid_607680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607681: Call_PostDownloadDBLogFilePortion_607665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607681.validator(path, query, header, formData, body)
  let scheme = call_607681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607681.url(scheme.get, call_607681.host, call_607681.base,
                         call_607681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607681, url, valid)

proc call*(call_607682: Call_PostDownloadDBLogFilePortion_607665;
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
  var query_607683 = newJObject()
  var formData_607684 = newJObject()
  add(formData_607684, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_607684, "Marker", newJString(Marker))
  add(formData_607684, "LogFileName", newJString(LogFileName))
  add(formData_607684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607683, "Action", newJString(Action))
  add(query_607683, "Version", newJString(Version))
  result = call_607682.call(nil, query_607683, nil, formData_607684, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_607665(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_607666, base: "/",
    url: url_PostDownloadDBLogFilePortion_607667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_607646 = ref object of OpenApiRestCall_605573
proc url_GetDownloadDBLogFilePortion_607648(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_607647(path: JsonNode; query: JsonNode;
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
  var valid_607649 = query.getOrDefault("Marker")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "Marker", valid_607649
  var valid_607650 = query.getOrDefault("NumberOfLines")
  valid_607650 = validateParameter(valid_607650, JInt, required = false, default = nil)
  if valid_607650 != nil:
    section.add "NumberOfLines", valid_607650
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607651 = query.getOrDefault("DBInstanceIdentifier")
  valid_607651 = validateParameter(valid_607651, JString, required = true,
                                 default = nil)
  if valid_607651 != nil:
    section.add "DBInstanceIdentifier", valid_607651
  var valid_607652 = query.getOrDefault("Action")
  valid_607652 = validateParameter(valid_607652, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_607652 != nil:
    section.add "Action", valid_607652
  var valid_607653 = query.getOrDefault("LogFileName")
  valid_607653 = validateParameter(valid_607653, JString, required = true,
                                 default = nil)
  if valid_607653 != nil:
    section.add "LogFileName", valid_607653
  var valid_607654 = query.getOrDefault("Version")
  valid_607654 = validateParameter(valid_607654, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607654 != nil:
    section.add "Version", valid_607654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607655 = header.getOrDefault("X-Amz-Signature")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Signature", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Content-Sha256", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Date")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Date", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-Credential")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-Credential", valid_607658
  var valid_607659 = header.getOrDefault("X-Amz-Security-Token")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Security-Token", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Algorithm")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Algorithm", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-SignedHeaders", valid_607661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607662: Call_GetDownloadDBLogFilePortion_607646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607662.validator(path, query, header, formData, body)
  let scheme = call_607662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607662.url(scheme.get, call_607662.host, call_607662.base,
                         call_607662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607662, url, valid)

proc call*(call_607663: Call_GetDownloadDBLogFilePortion_607646;
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
  var query_607664 = newJObject()
  add(query_607664, "Marker", newJString(Marker))
  add(query_607664, "NumberOfLines", newJInt(NumberOfLines))
  add(query_607664, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607664, "Action", newJString(Action))
  add(query_607664, "LogFileName", newJString(LogFileName))
  add(query_607664, "Version", newJString(Version))
  result = call_607663.call(nil, query_607664, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_607646(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_607647, base: "/",
    url: url_GetDownloadDBLogFilePortion_607648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607702 = ref object of OpenApiRestCall_605573
proc url_PostListTagsForResource_607704(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607705 = query.getOrDefault("Action")
  valid_607705 = validateParameter(valid_607705, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607705 != nil:
    section.add "Action", valid_607705
  var valid_607706 = query.getOrDefault("Version")
  valid_607706 = validateParameter(valid_607706, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607706 != nil:
    section.add "Version", valid_607706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607707 = header.getOrDefault("X-Amz-Signature")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "X-Amz-Signature", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-Content-Sha256", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Date")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Date", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Credential")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Credential", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Security-Token")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Security-Token", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Algorithm")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Algorithm", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-SignedHeaders", valid_607713
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_607714 = formData.getOrDefault("Filters")
  valid_607714 = validateParameter(valid_607714, JArray, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "Filters", valid_607714
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_607715 = formData.getOrDefault("ResourceName")
  valid_607715 = validateParameter(valid_607715, JString, required = true,
                                 default = nil)
  if valid_607715 != nil:
    section.add "ResourceName", valid_607715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607716: Call_PostListTagsForResource_607702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607716.validator(path, query, header, formData, body)
  let scheme = call_607716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607716.url(scheme.get, call_607716.host, call_607716.base,
                         call_607716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607716, url, valid)

proc call*(call_607717: Call_PostListTagsForResource_607702; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_607718 = newJObject()
  var formData_607719 = newJObject()
  add(query_607718, "Action", newJString(Action))
  if Filters != nil:
    formData_607719.add "Filters", Filters
  add(query_607718, "Version", newJString(Version))
  add(formData_607719, "ResourceName", newJString(ResourceName))
  result = call_607717.call(nil, query_607718, nil, formData_607719, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607702(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607703, base: "/",
    url: url_PostListTagsForResource_607704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607685 = ref object of OpenApiRestCall_605573
proc url_GetListTagsForResource_607687(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607686(path: JsonNode; query: JsonNode;
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
  var valid_607688 = query.getOrDefault("ResourceName")
  valid_607688 = validateParameter(valid_607688, JString, required = true,
                                 default = nil)
  if valid_607688 != nil:
    section.add "ResourceName", valid_607688
  var valid_607689 = query.getOrDefault("Action")
  valid_607689 = validateParameter(valid_607689, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607689 != nil:
    section.add "Action", valid_607689
  var valid_607690 = query.getOrDefault("Version")
  valid_607690 = validateParameter(valid_607690, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607690 != nil:
    section.add "Version", valid_607690
  var valid_607691 = query.getOrDefault("Filters")
  valid_607691 = validateParameter(valid_607691, JArray, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "Filters", valid_607691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607692 = header.getOrDefault("X-Amz-Signature")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "X-Amz-Signature", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-Content-Sha256", valid_607693
  var valid_607694 = header.getOrDefault("X-Amz-Date")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "X-Amz-Date", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Credential")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Credential", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Security-Token")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Security-Token", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Algorithm")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Algorithm", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-SignedHeaders", valid_607698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607699: Call_GetListTagsForResource_607685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607699.validator(path, query, header, formData, body)
  let scheme = call_607699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607699.url(scheme.get, call_607699.host, call_607699.base,
                         call_607699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607699, url, valid)

proc call*(call_607700: Call_GetListTagsForResource_607685; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_607701 = newJObject()
  add(query_607701, "ResourceName", newJString(ResourceName))
  add(query_607701, "Action", newJString(Action))
  add(query_607701, "Version", newJString(Version))
  if Filters != nil:
    query_607701.add "Filters", Filters
  result = call_607700.call(nil, query_607701, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607685(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607686, base: "/",
    url: url_GetListTagsForResource_607687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_607753 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBInstance_607755(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_607754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607756 = query.getOrDefault("Action")
  valid_607756 = validateParameter(valid_607756, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607756 != nil:
    section.add "Action", valid_607756
  var valid_607757 = query.getOrDefault("Version")
  valid_607757 = validateParameter(valid_607757, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607757 != nil:
    section.add "Version", valid_607757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607758 = header.getOrDefault("X-Amz-Signature")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Signature", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Content-Sha256", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Date")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Date", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-Credential")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-Credential", valid_607761
  var valid_607762 = header.getOrDefault("X-Amz-Security-Token")
  valid_607762 = validateParameter(valid_607762, JString, required = false,
                                 default = nil)
  if valid_607762 != nil:
    section.add "X-Amz-Security-Token", valid_607762
  var valid_607763 = header.getOrDefault("X-Amz-Algorithm")
  valid_607763 = validateParameter(valid_607763, JString, required = false,
                                 default = nil)
  if valid_607763 != nil:
    section.add "X-Amz-Algorithm", valid_607763
  var valid_607764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607764 = validateParameter(valid_607764, JString, required = false,
                                 default = nil)
  if valid_607764 != nil:
    section.add "X-Amz-SignedHeaders", valid_607764
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
  var valid_607765 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607765 = validateParameter(valid_607765, JString, required = false,
                                 default = nil)
  if valid_607765 != nil:
    section.add "PreferredMaintenanceWindow", valid_607765
  var valid_607766 = formData.getOrDefault("DBInstanceClass")
  valid_607766 = validateParameter(valid_607766, JString, required = false,
                                 default = nil)
  if valid_607766 != nil:
    section.add "DBInstanceClass", valid_607766
  var valid_607767 = formData.getOrDefault("PreferredBackupWindow")
  valid_607767 = validateParameter(valid_607767, JString, required = false,
                                 default = nil)
  if valid_607767 != nil:
    section.add "PreferredBackupWindow", valid_607767
  var valid_607768 = formData.getOrDefault("MasterUserPassword")
  valid_607768 = validateParameter(valid_607768, JString, required = false,
                                 default = nil)
  if valid_607768 != nil:
    section.add "MasterUserPassword", valid_607768
  var valid_607769 = formData.getOrDefault("MultiAZ")
  valid_607769 = validateParameter(valid_607769, JBool, required = false, default = nil)
  if valid_607769 != nil:
    section.add "MultiAZ", valid_607769
  var valid_607770 = formData.getOrDefault("DBParameterGroupName")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "DBParameterGroupName", valid_607770
  var valid_607771 = formData.getOrDefault("EngineVersion")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "EngineVersion", valid_607771
  var valid_607772 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607772 = validateParameter(valid_607772, JArray, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "VpcSecurityGroupIds", valid_607772
  var valid_607773 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607773 = validateParameter(valid_607773, JInt, required = false, default = nil)
  if valid_607773 != nil:
    section.add "BackupRetentionPeriod", valid_607773
  var valid_607774 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_607774 = validateParameter(valid_607774, JBool, required = false, default = nil)
  if valid_607774 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607774
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607775 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607775 = validateParameter(valid_607775, JString, required = true,
                                 default = nil)
  if valid_607775 != nil:
    section.add "DBInstanceIdentifier", valid_607775
  var valid_607776 = formData.getOrDefault("ApplyImmediately")
  valid_607776 = validateParameter(valid_607776, JBool, required = false, default = nil)
  if valid_607776 != nil:
    section.add "ApplyImmediately", valid_607776
  var valid_607777 = formData.getOrDefault("Iops")
  valid_607777 = validateParameter(valid_607777, JInt, required = false, default = nil)
  if valid_607777 != nil:
    section.add "Iops", valid_607777
  var valid_607778 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_607778 = validateParameter(valid_607778, JBool, required = false, default = nil)
  if valid_607778 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607778
  var valid_607779 = formData.getOrDefault("OptionGroupName")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "OptionGroupName", valid_607779
  var valid_607780 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_607780 = validateParameter(valid_607780, JString, required = false,
                                 default = nil)
  if valid_607780 != nil:
    section.add "NewDBInstanceIdentifier", valid_607780
  var valid_607781 = formData.getOrDefault("DBSecurityGroups")
  valid_607781 = validateParameter(valid_607781, JArray, required = false,
                                 default = nil)
  if valid_607781 != nil:
    section.add "DBSecurityGroups", valid_607781
  var valid_607782 = formData.getOrDefault("AllocatedStorage")
  valid_607782 = validateParameter(valid_607782, JInt, required = false, default = nil)
  if valid_607782 != nil:
    section.add "AllocatedStorage", valid_607782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607783: Call_PostModifyDBInstance_607753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607783.validator(path, query, header, formData, body)
  let scheme = call_607783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607783.url(scheme.get, call_607783.host, call_607783.base,
                         call_607783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607783, url, valid)

proc call*(call_607784: Call_PostModifyDBInstance_607753;
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
  var query_607785 = newJObject()
  var formData_607786 = newJObject()
  add(formData_607786, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607786, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607786, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607786, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_607786, "MultiAZ", newJBool(MultiAZ))
  add(formData_607786, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_607786, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607786.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607786, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607786, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_607786, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607786, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_607786, "Iops", newJInt(Iops))
  add(query_607785, "Action", newJString(Action))
  add(formData_607786, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_607786, "OptionGroupName", newJString(OptionGroupName))
  add(formData_607786, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_607785, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_607786.add "DBSecurityGroups", DBSecurityGroups
  add(formData_607786, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_607784.call(nil, query_607785, nil, formData_607786, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_607753(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_607754, base: "/",
    url: url_PostModifyDBInstance_607755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_607720 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBInstance_607722(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_607721(path: JsonNode; query: JsonNode;
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
  var valid_607723 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "NewDBInstanceIdentifier", valid_607723
  var valid_607724 = query.getOrDefault("DBParameterGroupName")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "DBParameterGroupName", valid_607724
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607725 = query.getOrDefault("DBInstanceIdentifier")
  valid_607725 = validateParameter(valid_607725, JString, required = true,
                                 default = nil)
  if valid_607725 != nil:
    section.add "DBInstanceIdentifier", valid_607725
  var valid_607726 = query.getOrDefault("BackupRetentionPeriod")
  valid_607726 = validateParameter(valid_607726, JInt, required = false, default = nil)
  if valid_607726 != nil:
    section.add "BackupRetentionPeriod", valid_607726
  var valid_607727 = query.getOrDefault("EngineVersion")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "EngineVersion", valid_607727
  var valid_607728 = query.getOrDefault("Action")
  valid_607728 = validateParameter(valid_607728, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607728 != nil:
    section.add "Action", valid_607728
  var valid_607729 = query.getOrDefault("MultiAZ")
  valid_607729 = validateParameter(valid_607729, JBool, required = false, default = nil)
  if valid_607729 != nil:
    section.add "MultiAZ", valid_607729
  var valid_607730 = query.getOrDefault("DBSecurityGroups")
  valid_607730 = validateParameter(valid_607730, JArray, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "DBSecurityGroups", valid_607730
  var valid_607731 = query.getOrDefault("ApplyImmediately")
  valid_607731 = validateParameter(valid_607731, JBool, required = false, default = nil)
  if valid_607731 != nil:
    section.add "ApplyImmediately", valid_607731
  var valid_607732 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607732 = validateParameter(valid_607732, JArray, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "VpcSecurityGroupIds", valid_607732
  var valid_607733 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_607733 = validateParameter(valid_607733, JBool, required = false, default = nil)
  if valid_607733 != nil:
    section.add "AllowMajorVersionUpgrade", valid_607733
  var valid_607734 = query.getOrDefault("MasterUserPassword")
  valid_607734 = validateParameter(valid_607734, JString, required = false,
                                 default = nil)
  if valid_607734 != nil:
    section.add "MasterUserPassword", valid_607734
  var valid_607735 = query.getOrDefault("OptionGroupName")
  valid_607735 = validateParameter(valid_607735, JString, required = false,
                                 default = nil)
  if valid_607735 != nil:
    section.add "OptionGroupName", valid_607735
  var valid_607736 = query.getOrDefault("Version")
  valid_607736 = validateParameter(valid_607736, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607736 != nil:
    section.add "Version", valid_607736
  var valid_607737 = query.getOrDefault("AllocatedStorage")
  valid_607737 = validateParameter(valid_607737, JInt, required = false, default = nil)
  if valid_607737 != nil:
    section.add "AllocatedStorage", valid_607737
  var valid_607738 = query.getOrDefault("DBInstanceClass")
  valid_607738 = validateParameter(valid_607738, JString, required = false,
                                 default = nil)
  if valid_607738 != nil:
    section.add "DBInstanceClass", valid_607738
  var valid_607739 = query.getOrDefault("PreferredBackupWindow")
  valid_607739 = validateParameter(valid_607739, JString, required = false,
                                 default = nil)
  if valid_607739 != nil:
    section.add "PreferredBackupWindow", valid_607739
  var valid_607740 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "PreferredMaintenanceWindow", valid_607740
  var valid_607741 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_607741 = validateParameter(valid_607741, JBool, required = false, default = nil)
  if valid_607741 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607741
  var valid_607742 = query.getOrDefault("Iops")
  valid_607742 = validateParameter(valid_607742, JInt, required = false, default = nil)
  if valid_607742 != nil:
    section.add "Iops", valid_607742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607743 = header.getOrDefault("X-Amz-Signature")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Signature", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-Content-Sha256", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Date")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Date", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-Credential")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Credential", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-Security-Token")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-Security-Token", valid_607747
  var valid_607748 = header.getOrDefault("X-Amz-Algorithm")
  valid_607748 = validateParameter(valid_607748, JString, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "X-Amz-Algorithm", valid_607748
  var valid_607749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607749 = validateParameter(valid_607749, JString, required = false,
                                 default = nil)
  if valid_607749 != nil:
    section.add "X-Amz-SignedHeaders", valid_607749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607750: Call_GetModifyDBInstance_607720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607750.validator(path, query, header, formData, body)
  let scheme = call_607750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607750.url(scheme.get, call_607750.host, call_607750.base,
                         call_607750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607750, url, valid)

proc call*(call_607751: Call_GetModifyDBInstance_607720;
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
  var query_607752 = newJObject()
  add(query_607752, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_607752, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607752, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607752, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607752, "EngineVersion", newJString(EngineVersion))
  add(query_607752, "Action", newJString(Action))
  add(query_607752, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_607752.add "DBSecurityGroups", DBSecurityGroups
  add(query_607752, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_607752.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607752, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_607752, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_607752, "OptionGroupName", newJString(OptionGroupName))
  add(query_607752, "Version", newJString(Version))
  add(query_607752, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_607752, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607752, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_607752, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_607752, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_607752, "Iops", newJInt(Iops))
  result = call_607751.call(nil, query_607752, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_607720(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_607721, base: "/",
    url: url_GetModifyDBInstance_607722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_607804 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBParameterGroup_607806(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_607805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607807 = query.getOrDefault("Action")
  valid_607807 = validateParameter(valid_607807, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607807 != nil:
    section.add "Action", valid_607807
  var valid_607808 = query.getOrDefault("Version")
  valid_607808 = validateParameter(valid_607808, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607808 != nil:
    section.add "Version", valid_607808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607809 = header.getOrDefault("X-Amz-Signature")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "X-Amz-Signature", valid_607809
  var valid_607810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607810 = validateParameter(valid_607810, JString, required = false,
                                 default = nil)
  if valid_607810 != nil:
    section.add "X-Amz-Content-Sha256", valid_607810
  var valid_607811 = header.getOrDefault("X-Amz-Date")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "X-Amz-Date", valid_607811
  var valid_607812 = header.getOrDefault("X-Amz-Credential")
  valid_607812 = validateParameter(valid_607812, JString, required = false,
                                 default = nil)
  if valid_607812 != nil:
    section.add "X-Amz-Credential", valid_607812
  var valid_607813 = header.getOrDefault("X-Amz-Security-Token")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "X-Amz-Security-Token", valid_607813
  var valid_607814 = header.getOrDefault("X-Amz-Algorithm")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "X-Amz-Algorithm", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-SignedHeaders", valid_607815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_607816 = formData.getOrDefault("DBParameterGroupName")
  valid_607816 = validateParameter(valid_607816, JString, required = true,
                                 default = nil)
  if valid_607816 != nil:
    section.add "DBParameterGroupName", valid_607816
  var valid_607817 = formData.getOrDefault("Parameters")
  valid_607817 = validateParameter(valid_607817, JArray, required = true, default = nil)
  if valid_607817 != nil:
    section.add "Parameters", valid_607817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607818: Call_PostModifyDBParameterGroup_607804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607818.validator(path, query, header, formData, body)
  let scheme = call_607818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607818.url(scheme.get, call_607818.host, call_607818.base,
                         call_607818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607818, url, valid)

proc call*(call_607819: Call_PostModifyDBParameterGroup_607804;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_607820 = newJObject()
  var formData_607821 = newJObject()
  add(formData_607821, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_607820, "Action", newJString(Action))
  if Parameters != nil:
    formData_607821.add "Parameters", Parameters
  add(query_607820, "Version", newJString(Version))
  result = call_607819.call(nil, query_607820, nil, formData_607821, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_607804(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_607805, base: "/",
    url: url_PostModifyDBParameterGroup_607806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_607787 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBParameterGroup_607789(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_607788(path: JsonNode; query: JsonNode;
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
  var valid_607790 = query.getOrDefault("DBParameterGroupName")
  valid_607790 = validateParameter(valid_607790, JString, required = true,
                                 default = nil)
  if valid_607790 != nil:
    section.add "DBParameterGroupName", valid_607790
  var valid_607791 = query.getOrDefault("Parameters")
  valid_607791 = validateParameter(valid_607791, JArray, required = true, default = nil)
  if valid_607791 != nil:
    section.add "Parameters", valid_607791
  var valid_607792 = query.getOrDefault("Action")
  valid_607792 = validateParameter(valid_607792, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_607792 != nil:
    section.add "Action", valid_607792
  var valid_607793 = query.getOrDefault("Version")
  valid_607793 = validateParameter(valid_607793, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607793 != nil:
    section.add "Version", valid_607793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607794 = header.getOrDefault("X-Amz-Signature")
  valid_607794 = validateParameter(valid_607794, JString, required = false,
                                 default = nil)
  if valid_607794 != nil:
    section.add "X-Amz-Signature", valid_607794
  var valid_607795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607795 = validateParameter(valid_607795, JString, required = false,
                                 default = nil)
  if valid_607795 != nil:
    section.add "X-Amz-Content-Sha256", valid_607795
  var valid_607796 = header.getOrDefault("X-Amz-Date")
  valid_607796 = validateParameter(valid_607796, JString, required = false,
                                 default = nil)
  if valid_607796 != nil:
    section.add "X-Amz-Date", valid_607796
  var valid_607797 = header.getOrDefault("X-Amz-Credential")
  valid_607797 = validateParameter(valid_607797, JString, required = false,
                                 default = nil)
  if valid_607797 != nil:
    section.add "X-Amz-Credential", valid_607797
  var valid_607798 = header.getOrDefault("X-Amz-Security-Token")
  valid_607798 = validateParameter(valid_607798, JString, required = false,
                                 default = nil)
  if valid_607798 != nil:
    section.add "X-Amz-Security-Token", valid_607798
  var valid_607799 = header.getOrDefault("X-Amz-Algorithm")
  valid_607799 = validateParameter(valid_607799, JString, required = false,
                                 default = nil)
  if valid_607799 != nil:
    section.add "X-Amz-Algorithm", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-SignedHeaders", valid_607800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607801: Call_GetModifyDBParameterGroup_607787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607801.validator(path, query, header, formData, body)
  let scheme = call_607801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607801.url(scheme.get, call_607801.host, call_607801.base,
                         call_607801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607801, url, valid)

proc call*(call_607802: Call_GetModifyDBParameterGroup_607787;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607803 = newJObject()
  add(query_607803, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_607803.add "Parameters", Parameters
  add(query_607803, "Action", newJString(Action))
  add(query_607803, "Version", newJString(Version))
  result = call_607802.call(nil, query_607803, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_607787(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_607788, base: "/",
    url: url_GetModifyDBParameterGroup_607789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_607840 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBSubnetGroup_607842(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_607841(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607843 = query.getOrDefault("Action")
  valid_607843 = validateParameter(valid_607843, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607843 != nil:
    section.add "Action", valid_607843
  var valid_607844 = query.getOrDefault("Version")
  valid_607844 = validateParameter(valid_607844, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607844 != nil:
    section.add "Version", valid_607844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607845 = header.getOrDefault("X-Amz-Signature")
  valid_607845 = validateParameter(valid_607845, JString, required = false,
                                 default = nil)
  if valid_607845 != nil:
    section.add "X-Amz-Signature", valid_607845
  var valid_607846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Content-Sha256", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Date")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Date", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Credential")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Credential", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-Security-Token")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Security-Token", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Algorithm")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Algorithm", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-SignedHeaders", valid_607851
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_607852 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "DBSubnetGroupDescription", valid_607852
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_607853 = formData.getOrDefault("DBSubnetGroupName")
  valid_607853 = validateParameter(valid_607853, JString, required = true,
                                 default = nil)
  if valid_607853 != nil:
    section.add "DBSubnetGroupName", valid_607853
  var valid_607854 = formData.getOrDefault("SubnetIds")
  valid_607854 = validateParameter(valid_607854, JArray, required = true, default = nil)
  if valid_607854 != nil:
    section.add "SubnetIds", valid_607854
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607855: Call_PostModifyDBSubnetGroup_607840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607855.validator(path, query, header, formData, body)
  let scheme = call_607855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607855.url(scheme.get, call_607855.host, call_607855.base,
                         call_607855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607855, url, valid)

proc call*(call_607856: Call_PostModifyDBSubnetGroup_607840;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_607857 = newJObject()
  var formData_607858 = newJObject()
  add(formData_607858, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607857, "Action", newJString(Action))
  add(formData_607858, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607857, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_607858.add "SubnetIds", SubnetIds
  result = call_607856.call(nil, query_607857, nil, formData_607858, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_607840(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_607841, base: "/",
    url: url_PostModifyDBSubnetGroup_607842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_607822 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBSubnetGroup_607824(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_607823(path: JsonNode; query: JsonNode;
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
  var valid_607825 = query.getOrDefault("SubnetIds")
  valid_607825 = validateParameter(valid_607825, JArray, required = true, default = nil)
  if valid_607825 != nil:
    section.add "SubnetIds", valid_607825
  var valid_607826 = query.getOrDefault("Action")
  valid_607826 = validateParameter(valid_607826, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607826 != nil:
    section.add "Action", valid_607826
  var valid_607827 = query.getOrDefault("DBSubnetGroupDescription")
  valid_607827 = validateParameter(valid_607827, JString, required = false,
                                 default = nil)
  if valid_607827 != nil:
    section.add "DBSubnetGroupDescription", valid_607827
  var valid_607828 = query.getOrDefault("DBSubnetGroupName")
  valid_607828 = validateParameter(valid_607828, JString, required = true,
                                 default = nil)
  if valid_607828 != nil:
    section.add "DBSubnetGroupName", valid_607828
  var valid_607829 = query.getOrDefault("Version")
  valid_607829 = validateParameter(valid_607829, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607829 != nil:
    section.add "Version", valid_607829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607830 = header.getOrDefault("X-Amz-Signature")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Signature", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Content-Sha256", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Date")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Date", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Credential")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Credential", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-Security-Token")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Security-Token", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Algorithm")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Algorithm", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-SignedHeaders", valid_607836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607837: Call_GetModifyDBSubnetGroup_607822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607837.validator(path, query, header, formData, body)
  let scheme = call_607837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607837.url(scheme.get, call_607837.host, call_607837.base,
                         call_607837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607837, url, valid)

proc call*(call_607838: Call_GetModifyDBSubnetGroup_607822; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_607839 = newJObject()
  if SubnetIds != nil:
    query_607839.add "SubnetIds", SubnetIds
  add(query_607839, "Action", newJString(Action))
  add(query_607839, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607839, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607839, "Version", newJString(Version))
  result = call_607838.call(nil, query_607839, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_607822(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_607823, base: "/",
    url: url_GetModifyDBSubnetGroup_607824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_607879 = ref object of OpenApiRestCall_605573
proc url_PostModifyEventSubscription_607881(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_607880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607882 = query.getOrDefault("Action")
  valid_607882 = validateParameter(valid_607882, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607882 != nil:
    section.add "Action", valid_607882
  var valid_607883 = query.getOrDefault("Version")
  valid_607883 = validateParameter(valid_607883, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607883 != nil:
    section.add "Version", valid_607883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607884 = header.getOrDefault("X-Amz-Signature")
  valid_607884 = validateParameter(valid_607884, JString, required = false,
                                 default = nil)
  if valid_607884 != nil:
    section.add "X-Amz-Signature", valid_607884
  var valid_607885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607885 = validateParameter(valid_607885, JString, required = false,
                                 default = nil)
  if valid_607885 != nil:
    section.add "X-Amz-Content-Sha256", valid_607885
  var valid_607886 = header.getOrDefault("X-Amz-Date")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "X-Amz-Date", valid_607886
  var valid_607887 = header.getOrDefault("X-Amz-Credential")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Credential", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-Security-Token")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-Security-Token", valid_607888
  var valid_607889 = header.getOrDefault("X-Amz-Algorithm")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "X-Amz-Algorithm", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-SignedHeaders", valid_607890
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_607891 = formData.getOrDefault("SnsTopicArn")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "SnsTopicArn", valid_607891
  var valid_607892 = formData.getOrDefault("Enabled")
  valid_607892 = validateParameter(valid_607892, JBool, required = false, default = nil)
  if valid_607892 != nil:
    section.add "Enabled", valid_607892
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_607893 = formData.getOrDefault("SubscriptionName")
  valid_607893 = validateParameter(valid_607893, JString, required = true,
                                 default = nil)
  if valid_607893 != nil:
    section.add "SubscriptionName", valid_607893
  var valid_607894 = formData.getOrDefault("SourceType")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "SourceType", valid_607894
  var valid_607895 = formData.getOrDefault("EventCategories")
  valid_607895 = validateParameter(valid_607895, JArray, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "EventCategories", valid_607895
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607896: Call_PostModifyEventSubscription_607879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607896.validator(path, query, header, formData, body)
  let scheme = call_607896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607896.url(scheme.get, call_607896.host, call_607896.base,
                         call_607896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607896, url, valid)

proc call*(call_607897: Call_PostModifyEventSubscription_607879;
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
  var query_607898 = newJObject()
  var formData_607899 = newJObject()
  add(formData_607899, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_607899, "Enabled", newJBool(Enabled))
  add(formData_607899, "SubscriptionName", newJString(SubscriptionName))
  add(formData_607899, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_607899.add "EventCategories", EventCategories
  add(query_607898, "Action", newJString(Action))
  add(query_607898, "Version", newJString(Version))
  result = call_607897.call(nil, query_607898, nil, formData_607899, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_607879(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_607880, base: "/",
    url: url_PostModifyEventSubscription_607881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_607859 = ref object of OpenApiRestCall_605573
proc url_GetModifyEventSubscription_607861(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_607860(path: JsonNode; query: JsonNode;
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
  var valid_607862 = query.getOrDefault("SourceType")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "SourceType", valid_607862
  var valid_607863 = query.getOrDefault("Enabled")
  valid_607863 = validateParameter(valid_607863, JBool, required = false, default = nil)
  if valid_607863 != nil:
    section.add "Enabled", valid_607863
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_607864 = query.getOrDefault("SubscriptionName")
  valid_607864 = validateParameter(valid_607864, JString, required = true,
                                 default = nil)
  if valid_607864 != nil:
    section.add "SubscriptionName", valid_607864
  var valid_607865 = query.getOrDefault("EventCategories")
  valid_607865 = validateParameter(valid_607865, JArray, required = false,
                                 default = nil)
  if valid_607865 != nil:
    section.add "EventCategories", valid_607865
  var valid_607866 = query.getOrDefault("Action")
  valid_607866 = validateParameter(valid_607866, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_607866 != nil:
    section.add "Action", valid_607866
  var valid_607867 = query.getOrDefault("SnsTopicArn")
  valid_607867 = validateParameter(valid_607867, JString, required = false,
                                 default = nil)
  if valid_607867 != nil:
    section.add "SnsTopicArn", valid_607867
  var valid_607868 = query.getOrDefault("Version")
  valid_607868 = validateParameter(valid_607868, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607868 != nil:
    section.add "Version", valid_607868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607869 = header.getOrDefault("X-Amz-Signature")
  valid_607869 = validateParameter(valid_607869, JString, required = false,
                                 default = nil)
  if valid_607869 != nil:
    section.add "X-Amz-Signature", valid_607869
  var valid_607870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607870 = validateParameter(valid_607870, JString, required = false,
                                 default = nil)
  if valid_607870 != nil:
    section.add "X-Amz-Content-Sha256", valid_607870
  var valid_607871 = header.getOrDefault("X-Amz-Date")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "X-Amz-Date", valid_607871
  var valid_607872 = header.getOrDefault("X-Amz-Credential")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Credential", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Security-Token")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Security-Token", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Algorithm")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Algorithm", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-SignedHeaders", valid_607875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607876: Call_GetModifyEventSubscription_607859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607876.validator(path, query, header, formData, body)
  let scheme = call_607876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607876.url(scheme.get, call_607876.host, call_607876.base,
                         call_607876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607876, url, valid)

proc call*(call_607877: Call_GetModifyEventSubscription_607859;
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
  var query_607878 = newJObject()
  add(query_607878, "SourceType", newJString(SourceType))
  add(query_607878, "Enabled", newJBool(Enabled))
  add(query_607878, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_607878.add "EventCategories", EventCategories
  add(query_607878, "Action", newJString(Action))
  add(query_607878, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_607878, "Version", newJString(Version))
  result = call_607877.call(nil, query_607878, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_607859(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_607860, base: "/",
    url: url_GetModifyEventSubscription_607861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_607919 = ref object of OpenApiRestCall_605573
proc url_PostModifyOptionGroup_607921(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_607920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607922 = query.getOrDefault("Action")
  valid_607922 = validateParameter(valid_607922, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607922 != nil:
    section.add "Action", valid_607922
  var valid_607923 = query.getOrDefault("Version")
  valid_607923 = validateParameter(valid_607923, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607923 != nil:
    section.add "Version", valid_607923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607924 = header.getOrDefault("X-Amz-Signature")
  valid_607924 = validateParameter(valid_607924, JString, required = false,
                                 default = nil)
  if valid_607924 != nil:
    section.add "X-Amz-Signature", valid_607924
  var valid_607925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607925 = validateParameter(valid_607925, JString, required = false,
                                 default = nil)
  if valid_607925 != nil:
    section.add "X-Amz-Content-Sha256", valid_607925
  var valid_607926 = header.getOrDefault("X-Amz-Date")
  valid_607926 = validateParameter(valid_607926, JString, required = false,
                                 default = nil)
  if valid_607926 != nil:
    section.add "X-Amz-Date", valid_607926
  var valid_607927 = header.getOrDefault("X-Amz-Credential")
  valid_607927 = validateParameter(valid_607927, JString, required = false,
                                 default = nil)
  if valid_607927 != nil:
    section.add "X-Amz-Credential", valid_607927
  var valid_607928 = header.getOrDefault("X-Amz-Security-Token")
  valid_607928 = validateParameter(valid_607928, JString, required = false,
                                 default = nil)
  if valid_607928 != nil:
    section.add "X-Amz-Security-Token", valid_607928
  var valid_607929 = header.getOrDefault("X-Amz-Algorithm")
  valid_607929 = validateParameter(valid_607929, JString, required = false,
                                 default = nil)
  if valid_607929 != nil:
    section.add "X-Amz-Algorithm", valid_607929
  var valid_607930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607930 = validateParameter(valid_607930, JString, required = false,
                                 default = nil)
  if valid_607930 != nil:
    section.add "X-Amz-SignedHeaders", valid_607930
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_607931 = formData.getOrDefault("OptionsToRemove")
  valid_607931 = validateParameter(valid_607931, JArray, required = false,
                                 default = nil)
  if valid_607931 != nil:
    section.add "OptionsToRemove", valid_607931
  var valid_607932 = formData.getOrDefault("ApplyImmediately")
  valid_607932 = validateParameter(valid_607932, JBool, required = false, default = nil)
  if valid_607932 != nil:
    section.add "ApplyImmediately", valid_607932
  var valid_607933 = formData.getOrDefault("OptionsToInclude")
  valid_607933 = validateParameter(valid_607933, JArray, required = false,
                                 default = nil)
  if valid_607933 != nil:
    section.add "OptionsToInclude", valid_607933
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_607934 = formData.getOrDefault("OptionGroupName")
  valid_607934 = validateParameter(valid_607934, JString, required = true,
                                 default = nil)
  if valid_607934 != nil:
    section.add "OptionGroupName", valid_607934
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607935: Call_PostModifyOptionGroup_607919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607935.validator(path, query, header, formData, body)
  let scheme = call_607935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607935.url(scheme.get, call_607935.host, call_607935.base,
                         call_607935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607935, url, valid)

proc call*(call_607936: Call_PostModifyOptionGroup_607919; OptionGroupName: string;
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
  var query_607937 = newJObject()
  var formData_607938 = newJObject()
  if OptionsToRemove != nil:
    formData_607938.add "OptionsToRemove", OptionsToRemove
  add(formData_607938, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_607938.add "OptionsToInclude", OptionsToInclude
  add(query_607937, "Action", newJString(Action))
  add(formData_607938, "OptionGroupName", newJString(OptionGroupName))
  add(query_607937, "Version", newJString(Version))
  result = call_607936.call(nil, query_607937, nil, formData_607938, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_607919(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_607920, base: "/",
    url: url_PostModifyOptionGroup_607921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_607900 = ref object of OpenApiRestCall_605573
proc url_GetModifyOptionGroup_607902(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_607901(path: JsonNode; query: JsonNode;
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
  var valid_607903 = query.getOrDefault("Action")
  valid_607903 = validateParameter(valid_607903, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_607903 != nil:
    section.add "Action", valid_607903
  var valid_607904 = query.getOrDefault("ApplyImmediately")
  valid_607904 = validateParameter(valid_607904, JBool, required = false, default = nil)
  if valid_607904 != nil:
    section.add "ApplyImmediately", valid_607904
  var valid_607905 = query.getOrDefault("OptionsToRemove")
  valid_607905 = validateParameter(valid_607905, JArray, required = false,
                                 default = nil)
  if valid_607905 != nil:
    section.add "OptionsToRemove", valid_607905
  var valid_607906 = query.getOrDefault("OptionsToInclude")
  valid_607906 = validateParameter(valid_607906, JArray, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "OptionsToInclude", valid_607906
  var valid_607907 = query.getOrDefault("OptionGroupName")
  valid_607907 = validateParameter(valid_607907, JString, required = true,
                                 default = nil)
  if valid_607907 != nil:
    section.add "OptionGroupName", valid_607907
  var valid_607908 = query.getOrDefault("Version")
  valid_607908 = validateParameter(valid_607908, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607908 != nil:
    section.add "Version", valid_607908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607909 = header.getOrDefault("X-Amz-Signature")
  valid_607909 = validateParameter(valid_607909, JString, required = false,
                                 default = nil)
  if valid_607909 != nil:
    section.add "X-Amz-Signature", valid_607909
  var valid_607910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607910 = validateParameter(valid_607910, JString, required = false,
                                 default = nil)
  if valid_607910 != nil:
    section.add "X-Amz-Content-Sha256", valid_607910
  var valid_607911 = header.getOrDefault("X-Amz-Date")
  valid_607911 = validateParameter(valid_607911, JString, required = false,
                                 default = nil)
  if valid_607911 != nil:
    section.add "X-Amz-Date", valid_607911
  var valid_607912 = header.getOrDefault("X-Amz-Credential")
  valid_607912 = validateParameter(valid_607912, JString, required = false,
                                 default = nil)
  if valid_607912 != nil:
    section.add "X-Amz-Credential", valid_607912
  var valid_607913 = header.getOrDefault("X-Amz-Security-Token")
  valid_607913 = validateParameter(valid_607913, JString, required = false,
                                 default = nil)
  if valid_607913 != nil:
    section.add "X-Amz-Security-Token", valid_607913
  var valid_607914 = header.getOrDefault("X-Amz-Algorithm")
  valid_607914 = validateParameter(valid_607914, JString, required = false,
                                 default = nil)
  if valid_607914 != nil:
    section.add "X-Amz-Algorithm", valid_607914
  var valid_607915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607915 = validateParameter(valid_607915, JString, required = false,
                                 default = nil)
  if valid_607915 != nil:
    section.add "X-Amz-SignedHeaders", valid_607915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607916: Call_GetModifyOptionGroup_607900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607916.validator(path, query, header, formData, body)
  let scheme = call_607916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607916.url(scheme.get, call_607916.host, call_607916.base,
                         call_607916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607916, url, valid)

proc call*(call_607917: Call_GetModifyOptionGroup_607900; OptionGroupName: string;
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
  var query_607918 = newJObject()
  add(query_607918, "Action", newJString(Action))
  add(query_607918, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_607918.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_607918.add "OptionsToInclude", OptionsToInclude
  add(query_607918, "OptionGroupName", newJString(OptionGroupName))
  add(query_607918, "Version", newJString(Version))
  result = call_607917.call(nil, query_607918, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_607900(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_607901, base: "/",
    url: url_GetModifyOptionGroup_607902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_607957 = ref object of OpenApiRestCall_605573
proc url_PostPromoteReadReplica_607959(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_607958(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607960 = query.getOrDefault("Action")
  valid_607960 = validateParameter(valid_607960, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607960 != nil:
    section.add "Action", valid_607960
  var valid_607961 = query.getOrDefault("Version")
  valid_607961 = validateParameter(valid_607961, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607961 != nil:
    section.add "Version", valid_607961
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607962 = header.getOrDefault("X-Amz-Signature")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "X-Amz-Signature", valid_607962
  var valid_607963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607963 = validateParameter(valid_607963, JString, required = false,
                                 default = nil)
  if valid_607963 != nil:
    section.add "X-Amz-Content-Sha256", valid_607963
  var valid_607964 = header.getOrDefault("X-Amz-Date")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "X-Amz-Date", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-Credential")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-Credential", valid_607965
  var valid_607966 = header.getOrDefault("X-Amz-Security-Token")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Security-Token", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-Algorithm")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Algorithm", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-SignedHeaders", valid_607968
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_607969 = formData.getOrDefault("PreferredBackupWindow")
  valid_607969 = validateParameter(valid_607969, JString, required = false,
                                 default = nil)
  if valid_607969 != nil:
    section.add "PreferredBackupWindow", valid_607969
  var valid_607970 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607970 = validateParameter(valid_607970, JInt, required = false, default = nil)
  if valid_607970 != nil:
    section.add "BackupRetentionPeriod", valid_607970
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607971 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607971 = validateParameter(valid_607971, JString, required = true,
                                 default = nil)
  if valid_607971 != nil:
    section.add "DBInstanceIdentifier", valid_607971
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607972: Call_PostPromoteReadReplica_607957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607972.validator(path, query, header, formData, body)
  let scheme = call_607972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607972.url(scheme.get, call_607972.host, call_607972.base,
                         call_607972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607972, url, valid)

proc call*(call_607973: Call_PostPromoteReadReplica_607957;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607974 = newJObject()
  var formData_607975 = newJObject()
  add(formData_607975, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607975, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607975, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607974, "Action", newJString(Action))
  add(query_607974, "Version", newJString(Version))
  result = call_607973.call(nil, query_607974, nil, formData_607975, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_607957(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_607958, base: "/",
    url: url_PostPromoteReadReplica_607959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_607939 = ref object of OpenApiRestCall_605573
proc url_GetPromoteReadReplica_607941(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_607940(path: JsonNode; query: JsonNode;
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
  var valid_607942 = query.getOrDefault("DBInstanceIdentifier")
  valid_607942 = validateParameter(valid_607942, JString, required = true,
                                 default = nil)
  if valid_607942 != nil:
    section.add "DBInstanceIdentifier", valid_607942
  var valid_607943 = query.getOrDefault("BackupRetentionPeriod")
  valid_607943 = validateParameter(valid_607943, JInt, required = false, default = nil)
  if valid_607943 != nil:
    section.add "BackupRetentionPeriod", valid_607943
  var valid_607944 = query.getOrDefault("Action")
  valid_607944 = validateParameter(valid_607944, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_607944 != nil:
    section.add "Action", valid_607944
  var valid_607945 = query.getOrDefault("Version")
  valid_607945 = validateParameter(valid_607945, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607945 != nil:
    section.add "Version", valid_607945
  var valid_607946 = query.getOrDefault("PreferredBackupWindow")
  valid_607946 = validateParameter(valid_607946, JString, required = false,
                                 default = nil)
  if valid_607946 != nil:
    section.add "PreferredBackupWindow", valid_607946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607947 = header.getOrDefault("X-Amz-Signature")
  valid_607947 = validateParameter(valid_607947, JString, required = false,
                                 default = nil)
  if valid_607947 != nil:
    section.add "X-Amz-Signature", valid_607947
  var valid_607948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607948 = validateParameter(valid_607948, JString, required = false,
                                 default = nil)
  if valid_607948 != nil:
    section.add "X-Amz-Content-Sha256", valid_607948
  var valid_607949 = header.getOrDefault("X-Amz-Date")
  valid_607949 = validateParameter(valid_607949, JString, required = false,
                                 default = nil)
  if valid_607949 != nil:
    section.add "X-Amz-Date", valid_607949
  var valid_607950 = header.getOrDefault("X-Amz-Credential")
  valid_607950 = validateParameter(valid_607950, JString, required = false,
                                 default = nil)
  if valid_607950 != nil:
    section.add "X-Amz-Credential", valid_607950
  var valid_607951 = header.getOrDefault("X-Amz-Security-Token")
  valid_607951 = validateParameter(valid_607951, JString, required = false,
                                 default = nil)
  if valid_607951 != nil:
    section.add "X-Amz-Security-Token", valid_607951
  var valid_607952 = header.getOrDefault("X-Amz-Algorithm")
  valid_607952 = validateParameter(valid_607952, JString, required = false,
                                 default = nil)
  if valid_607952 != nil:
    section.add "X-Amz-Algorithm", valid_607952
  var valid_607953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607953 = validateParameter(valid_607953, JString, required = false,
                                 default = nil)
  if valid_607953 != nil:
    section.add "X-Amz-SignedHeaders", valid_607953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607954: Call_GetPromoteReadReplica_607939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_607954.validator(path, query, header, formData, body)
  let scheme = call_607954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607954.url(scheme.get, call_607954.host, call_607954.base,
                         call_607954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607954, url, valid)

proc call*(call_607955: Call_GetPromoteReadReplica_607939;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-09-09";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_607956 = newJObject()
  add(query_607956, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607956, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607956, "Action", newJString(Action))
  add(query_607956, "Version", newJString(Version))
  add(query_607956, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_607955.call(nil, query_607956, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_607939(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_607940, base: "/",
    url: url_GetPromoteReadReplica_607941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_607995 = ref object of OpenApiRestCall_605573
proc url_PostPurchaseReservedDBInstancesOffering_607997(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_607996(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607998 = query.getOrDefault("Action")
  valid_607998 = validateParameter(valid_607998, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607998 != nil:
    section.add "Action", valid_607998
  var valid_607999 = query.getOrDefault("Version")
  valid_607999 = validateParameter(valid_607999, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607999 != nil:
    section.add "Version", valid_607999
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608000 = header.getOrDefault("X-Amz-Signature")
  valid_608000 = validateParameter(valid_608000, JString, required = false,
                                 default = nil)
  if valid_608000 != nil:
    section.add "X-Amz-Signature", valid_608000
  var valid_608001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608001 = validateParameter(valid_608001, JString, required = false,
                                 default = nil)
  if valid_608001 != nil:
    section.add "X-Amz-Content-Sha256", valid_608001
  var valid_608002 = header.getOrDefault("X-Amz-Date")
  valid_608002 = validateParameter(valid_608002, JString, required = false,
                                 default = nil)
  if valid_608002 != nil:
    section.add "X-Amz-Date", valid_608002
  var valid_608003 = header.getOrDefault("X-Amz-Credential")
  valid_608003 = validateParameter(valid_608003, JString, required = false,
                                 default = nil)
  if valid_608003 != nil:
    section.add "X-Amz-Credential", valid_608003
  var valid_608004 = header.getOrDefault("X-Amz-Security-Token")
  valid_608004 = validateParameter(valid_608004, JString, required = false,
                                 default = nil)
  if valid_608004 != nil:
    section.add "X-Amz-Security-Token", valid_608004
  var valid_608005 = header.getOrDefault("X-Amz-Algorithm")
  valid_608005 = validateParameter(valid_608005, JString, required = false,
                                 default = nil)
  if valid_608005 != nil:
    section.add "X-Amz-Algorithm", valid_608005
  var valid_608006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608006 = validateParameter(valid_608006, JString, required = false,
                                 default = nil)
  if valid_608006 != nil:
    section.add "X-Amz-SignedHeaders", valid_608006
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_608007 = formData.getOrDefault("ReservedDBInstanceId")
  valid_608007 = validateParameter(valid_608007, JString, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "ReservedDBInstanceId", valid_608007
  var valid_608008 = formData.getOrDefault("Tags")
  valid_608008 = validateParameter(valid_608008, JArray, required = false,
                                 default = nil)
  if valid_608008 != nil:
    section.add "Tags", valid_608008
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_608009 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_608009 = validateParameter(valid_608009, JString, required = true,
                                 default = nil)
  if valid_608009 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_608009
  var valid_608010 = formData.getOrDefault("DBInstanceCount")
  valid_608010 = validateParameter(valid_608010, JInt, required = false, default = nil)
  if valid_608010 != nil:
    section.add "DBInstanceCount", valid_608010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608011: Call_PostPurchaseReservedDBInstancesOffering_607995;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608011.validator(path, query, header, formData, body)
  let scheme = call_608011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608011.url(scheme.get, call_608011.host, call_608011.base,
                         call_608011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608011, url, valid)

proc call*(call_608012: Call_PostPurchaseReservedDBInstancesOffering_607995;
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
  var query_608013 = newJObject()
  var formData_608014 = newJObject()
  add(formData_608014, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_608013, "Action", newJString(Action))
  if Tags != nil:
    formData_608014.add "Tags", Tags
  add(formData_608014, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_608013, "Version", newJString(Version))
  add(formData_608014, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_608012.call(nil, query_608013, nil, formData_608014, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_607995(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_607996, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_607997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_607976 = ref object of OpenApiRestCall_605573
proc url_GetPurchaseReservedDBInstancesOffering_607978(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_607977(path: JsonNode;
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
  var valid_607979 = query.getOrDefault("Tags")
  valid_607979 = validateParameter(valid_607979, JArray, required = false,
                                 default = nil)
  if valid_607979 != nil:
    section.add "Tags", valid_607979
  var valid_607980 = query.getOrDefault("DBInstanceCount")
  valid_607980 = validateParameter(valid_607980, JInt, required = false, default = nil)
  if valid_607980 != nil:
    section.add "DBInstanceCount", valid_607980
  var valid_607981 = query.getOrDefault("ReservedDBInstanceId")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "ReservedDBInstanceId", valid_607981
  var valid_607982 = query.getOrDefault("Action")
  valid_607982 = validateParameter(valid_607982, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_607982 != nil:
    section.add "Action", valid_607982
  var valid_607983 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_607983 = validateParameter(valid_607983, JString, required = true,
                                 default = nil)
  if valid_607983 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_607983
  var valid_607984 = query.getOrDefault("Version")
  valid_607984 = validateParameter(valid_607984, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_607984 != nil:
    section.add "Version", valid_607984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607985 = header.getOrDefault("X-Amz-Signature")
  valid_607985 = validateParameter(valid_607985, JString, required = false,
                                 default = nil)
  if valid_607985 != nil:
    section.add "X-Amz-Signature", valid_607985
  var valid_607986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607986 = validateParameter(valid_607986, JString, required = false,
                                 default = nil)
  if valid_607986 != nil:
    section.add "X-Amz-Content-Sha256", valid_607986
  var valid_607987 = header.getOrDefault("X-Amz-Date")
  valid_607987 = validateParameter(valid_607987, JString, required = false,
                                 default = nil)
  if valid_607987 != nil:
    section.add "X-Amz-Date", valid_607987
  var valid_607988 = header.getOrDefault("X-Amz-Credential")
  valid_607988 = validateParameter(valid_607988, JString, required = false,
                                 default = nil)
  if valid_607988 != nil:
    section.add "X-Amz-Credential", valid_607988
  var valid_607989 = header.getOrDefault("X-Amz-Security-Token")
  valid_607989 = validateParameter(valid_607989, JString, required = false,
                                 default = nil)
  if valid_607989 != nil:
    section.add "X-Amz-Security-Token", valid_607989
  var valid_607990 = header.getOrDefault("X-Amz-Algorithm")
  valid_607990 = validateParameter(valid_607990, JString, required = false,
                                 default = nil)
  if valid_607990 != nil:
    section.add "X-Amz-Algorithm", valid_607990
  var valid_607991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607991 = validateParameter(valid_607991, JString, required = false,
                                 default = nil)
  if valid_607991 != nil:
    section.add "X-Amz-SignedHeaders", valid_607991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607992: Call_GetPurchaseReservedDBInstancesOffering_607976;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_607992.validator(path, query, header, formData, body)
  let scheme = call_607992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607992.url(scheme.get, call_607992.host, call_607992.base,
                         call_607992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607992, url, valid)

proc call*(call_607993: Call_GetPurchaseReservedDBInstancesOffering_607976;
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
  var query_607994 = newJObject()
  if Tags != nil:
    query_607994.add "Tags", Tags
  add(query_607994, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_607994, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_607994, "Action", newJString(Action))
  add(query_607994, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_607994, "Version", newJString(Version))
  result = call_607993.call(nil, query_607994, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_607976(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_607977, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_607978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_608032 = ref object of OpenApiRestCall_605573
proc url_PostRebootDBInstance_608034(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_608033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608035 = query.getOrDefault("Action")
  valid_608035 = validateParameter(valid_608035, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_608035 != nil:
    section.add "Action", valid_608035
  var valid_608036 = query.getOrDefault("Version")
  valid_608036 = validateParameter(valid_608036, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608036 != nil:
    section.add "Version", valid_608036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608037 = header.getOrDefault("X-Amz-Signature")
  valid_608037 = validateParameter(valid_608037, JString, required = false,
                                 default = nil)
  if valid_608037 != nil:
    section.add "X-Amz-Signature", valid_608037
  var valid_608038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "X-Amz-Content-Sha256", valid_608038
  var valid_608039 = header.getOrDefault("X-Amz-Date")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Date", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Credential")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Credential", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Security-Token")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Security-Token", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-Algorithm")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-Algorithm", valid_608042
  var valid_608043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608043 = validateParameter(valid_608043, JString, required = false,
                                 default = nil)
  if valid_608043 != nil:
    section.add "X-Amz-SignedHeaders", valid_608043
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_608044 = formData.getOrDefault("ForceFailover")
  valid_608044 = validateParameter(valid_608044, JBool, required = false, default = nil)
  if valid_608044 != nil:
    section.add "ForceFailover", valid_608044
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608045 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608045 = validateParameter(valid_608045, JString, required = true,
                                 default = nil)
  if valid_608045 != nil:
    section.add "DBInstanceIdentifier", valid_608045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608046: Call_PostRebootDBInstance_608032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608046.validator(path, query, header, formData, body)
  let scheme = call_608046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608046.url(scheme.get, call_608046.host, call_608046.base,
                         call_608046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608046, url, valid)

proc call*(call_608047: Call_PostRebootDBInstance_608032;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608048 = newJObject()
  var formData_608049 = newJObject()
  add(formData_608049, "ForceFailover", newJBool(ForceFailover))
  add(formData_608049, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608048, "Action", newJString(Action))
  add(query_608048, "Version", newJString(Version))
  result = call_608047.call(nil, query_608048, nil, formData_608049, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_608032(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_608033, base: "/",
    url: url_PostRebootDBInstance_608034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_608015 = ref object of OpenApiRestCall_605573
proc url_GetRebootDBInstance_608017(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_608016(path: JsonNode; query: JsonNode;
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
  var valid_608018 = query.getOrDefault("ForceFailover")
  valid_608018 = validateParameter(valid_608018, JBool, required = false, default = nil)
  if valid_608018 != nil:
    section.add "ForceFailover", valid_608018
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608019 = query.getOrDefault("DBInstanceIdentifier")
  valid_608019 = validateParameter(valid_608019, JString, required = true,
                                 default = nil)
  if valid_608019 != nil:
    section.add "DBInstanceIdentifier", valid_608019
  var valid_608020 = query.getOrDefault("Action")
  valid_608020 = validateParameter(valid_608020, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_608020 != nil:
    section.add "Action", valid_608020
  var valid_608021 = query.getOrDefault("Version")
  valid_608021 = validateParameter(valid_608021, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608021 != nil:
    section.add "Version", valid_608021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608022 = header.getOrDefault("X-Amz-Signature")
  valid_608022 = validateParameter(valid_608022, JString, required = false,
                                 default = nil)
  if valid_608022 != nil:
    section.add "X-Amz-Signature", valid_608022
  var valid_608023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608023 = validateParameter(valid_608023, JString, required = false,
                                 default = nil)
  if valid_608023 != nil:
    section.add "X-Amz-Content-Sha256", valid_608023
  var valid_608024 = header.getOrDefault("X-Amz-Date")
  valid_608024 = validateParameter(valid_608024, JString, required = false,
                                 default = nil)
  if valid_608024 != nil:
    section.add "X-Amz-Date", valid_608024
  var valid_608025 = header.getOrDefault("X-Amz-Credential")
  valid_608025 = validateParameter(valid_608025, JString, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "X-Amz-Credential", valid_608025
  var valid_608026 = header.getOrDefault("X-Amz-Security-Token")
  valid_608026 = validateParameter(valid_608026, JString, required = false,
                                 default = nil)
  if valid_608026 != nil:
    section.add "X-Amz-Security-Token", valid_608026
  var valid_608027 = header.getOrDefault("X-Amz-Algorithm")
  valid_608027 = validateParameter(valid_608027, JString, required = false,
                                 default = nil)
  if valid_608027 != nil:
    section.add "X-Amz-Algorithm", valid_608027
  var valid_608028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "X-Amz-SignedHeaders", valid_608028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608029: Call_GetRebootDBInstance_608015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608029.validator(path, query, header, formData, body)
  let scheme = call_608029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608029.url(scheme.get, call_608029.host, call_608029.base,
                         call_608029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608029, url, valid)

proc call*(call_608030: Call_GetRebootDBInstance_608015;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608031 = newJObject()
  add(query_608031, "ForceFailover", newJBool(ForceFailover))
  add(query_608031, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608031, "Action", newJString(Action))
  add(query_608031, "Version", newJString(Version))
  result = call_608030.call(nil, query_608031, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_608015(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_608016, base: "/",
    url: url_GetRebootDBInstance_608017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_608067 = ref object of OpenApiRestCall_605573
proc url_PostRemoveSourceIdentifierFromSubscription_608069(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_608068(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608070 = query.getOrDefault("Action")
  valid_608070 = validateParameter(valid_608070, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_608070 != nil:
    section.add "Action", valid_608070
  var valid_608071 = query.getOrDefault("Version")
  valid_608071 = validateParameter(valid_608071, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608071 != nil:
    section.add "Version", valid_608071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608072 = header.getOrDefault("X-Amz-Signature")
  valid_608072 = validateParameter(valid_608072, JString, required = false,
                                 default = nil)
  if valid_608072 != nil:
    section.add "X-Amz-Signature", valid_608072
  var valid_608073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "X-Amz-Content-Sha256", valid_608073
  var valid_608074 = header.getOrDefault("X-Amz-Date")
  valid_608074 = validateParameter(valid_608074, JString, required = false,
                                 default = nil)
  if valid_608074 != nil:
    section.add "X-Amz-Date", valid_608074
  var valid_608075 = header.getOrDefault("X-Amz-Credential")
  valid_608075 = validateParameter(valid_608075, JString, required = false,
                                 default = nil)
  if valid_608075 != nil:
    section.add "X-Amz-Credential", valid_608075
  var valid_608076 = header.getOrDefault("X-Amz-Security-Token")
  valid_608076 = validateParameter(valid_608076, JString, required = false,
                                 default = nil)
  if valid_608076 != nil:
    section.add "X-Amz-Security-Token", valid_608076
  var valid_608077 = header.getOrDefault("X-Amz-Algorithm")
  valid_608077 = validateParameter(valid_608077, JString, required = false,
                                 default = nil)
  if valid_608077 != nil:
    section.add "X-Amz-Algorithm", valid_608077
  var valid_608078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608078 = validateParameter(valid_608078, JString, required = false,
                                 default = nil)
  if valid_608078 != nil:
    section.add "X-Amz-SignedHeaders", valid_608078
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_608079 = formData.getOrDefault("SubscriptionName")
  valid_608079 = validateParameter(valid_608079, JString, required = true,
                                 default = nil)
  if valid_608079 != nil:
    section.add "SubscriptionName", valid_608079
  var valid_608080 = formData.getOrDefault("SourceIdentifier")
  valid_608080 = validateParameter(valid_608080, JString, required = true,
                                 default = nil)
  if valid_608080 != nil:
    section.add "SourceIdentifier", valid_608080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608081: Call_PostRemoveSourceIdentifierFromSubscription_608067;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608081.validator(path, query, header, formData, body)
  let scheme = call_608081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608081.url(scheme.get, call_608081.host, call_608081.base,
                         call_608081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608081, url, valid)

proc call*(call_608082: Call_PostRemoveSourceIdentifierFromSubscription_608067;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608083 = newJObject()
  var formData_608084 = newJObject()
  add(formData_608084, "SubscriptionName", newJString(SubscriptionName))
  add(formData_608084, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608083, "Action", newJString(Action))
  add(query_608083, "Version", newJString(Version))
  result = call_608082.call(nil, query_608083, nil, formData_608084, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_608067(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_608068,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_608069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_608050 = ref object of OpenApiRestCall_605573
proc url_GetRemoveSourceIdentifierFromSubscription_608052(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_608051(path: JsonNode;
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
  var valid_608053 = query.getOrDefault("SourceIdentifier")
  valid_608053 = validateParameter(valid_608053, JString, required = true,
                                 default = nil)
  if valid_608053 != nil:
    section.add "SourceIdentifier", valid_608053
  var valid_608054 = query.getOrDefault("SubscriptionName")
  valid_608054 = validateParameter(valid_608054, JString, required = true,
                                 default = nil)
  if valid_608054 != nil:
    section.add "SubscriptionName", valid_608054
  var valid_608055 = query.getOrDefault("Action")
  valid_608055 = validateParameter(valid_608055, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_608055 != nil:
    section.add "Action", valid_608055
  var valid_608056 = query.getOrDefault("Version")
  valid_608056 = validateParameter(valid_608056, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608056 != nil:
    section.add "Version", valid_608056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608057 = header.getOrDefault("X-Amz-Signature")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-Signature", valid_608057
  var valid_608058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608058 = validateParameter(valid_608058, JString, required = false,
                                 default = nil)
  if valid_608058 != nil:
    section.add "X-Amz-Content-Sha256", valid_608058
  var valid_608059 = header.getOrDefault("X-Amz-Date")
  valid_608059 = validateParameter(valid_608059, JString, required = false,
                                 default = nil)
  if valid_608059 != nil:
    section.add "X-Amz-Date", valid_608059
  var valid_608060 = header.getOrDefault("X-Amz-Credential")
  valid_608060 = validateParameter(valid_608060, JString, required = false,
                                 default = nil)
  if valid_608060 != nil:
    section.add "X-Amz-Credential", valid_608060
  var valid_608061 = header.getOrDefault("X-Amz-Security-Token")
  valid_608061 = validateParameter(valid_608061, JString, required = false,
                                 default = nil)
  if valid_608061 != nil:
    section.add "X-Amz-Security-Token", valid_608061
  var valid_608062 = header.getOrDefault("X-Amz-Algorithm")
  valid_608062 = validateParameter(valid_608062, JString, required = false,
                                 default = nil)
  if valid_608062 != nil:
    section.add "X-Amz-Algorithm", valid_608062
  var valid_608063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608063 = validateParameter(valid_608063, JString, required = false,
                                 default = nil)
  if valid_608063 != nil:
    section.add "X-Amz-SignedHeaders", valid_608063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608064: Call_GetRemoveSourceIdentifierFromSubscription_608050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608064.validator(path, query, header, formData, body)
  let scheme = call_608064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608064.url(scheme.get, call_608064.host, call_608064.base,
                         call_608064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608064, url, valid)

proc call*(call_608065: Call_GetRemoveSourceIdentifierFromSubscription_608050;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608066 = newJObject()
  add(query_608066, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_608066, "SubscriptionName", newJString(SubscriptionName))
  add(query_608066, "Action", newJString(Action))
  add(query_608066, "Version", newJString(Version))
  result = call_608065.call(nil, query_608066, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_608050(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_608051,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_608052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_608102 = ref object of OpenApiRestCall_605573
proc url_PostRemoveTagsFromResource_608104(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_608103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608105 = query.getOrDefault("Action")
  valid_608105 = validateParameter(valid_608105, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608105 != nil:
    section.add "Action", valid_608105
  var valid_608106 = query.getOrDefault("Version")
  valid_608106 = validateParameter(valid_608106, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608106 != nil:
    section.add "Version", valid_608106
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608107 = header.getOrDefault("X-Amz-Signature")
  valid_608107 = validateParameter(valid_608107, JString, required = false,
                                 default = nil)
  if valid_608107 != nil:
    section.add "X-Amz-Signature", valid_608107
  var valid_608108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608108 = validateParameter(valid_608108, JString, required = false,
                                 default = nil)
  if valid_608108 != nil:
    section.add "X-Amz-Content-Sha256", valid_608108
  var valid_608109 = header.getOrDefault("X-Amz-Date")
  valid_608109 = validateParameter(valid_608109, JString, required = false,
                                 default = nil)
  if valid_608109 != nil:
    section.add "X-Amz-Date", valid_608109
  var valid_608110 = header.getOrDefault("X-Amz-Credential")
  valid_608110 = validateParameter(valid_608110, JString, required = false,
                                 default = nil)
  if valid_608110 != nil:
    section.add "X-Amz-Credential", valid_608110
  var valid_608111 = header.getOrDefault("X-Amz-Security-Token")
  valid_608111 = validateParameter(valid_608111, JString, required = false,
                                 default = nil)
  if valid_608111 != nil:
    section.add "X-Amz-Security-Token", valid_608111
  var valid_608112 = header.getOrDefault("X-Amz-Algorithm")
  valid_608112 = validateParameter(valid_608112, JString, required = false,
                                 default = nil)
  if valid_608112 != nil:
    section.add "X-Amz-Algorithm", valid_608112
  var valid_608113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608113 = validateParameter(valid_608113, JString, required = false,
                                 default = nil)
  if valid_608113 != nil:
    section.add "X-Amz-SignedHeaders", valid_608113
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_608114 = formData.getOrDefault("TagKeys")
  valid_608114 = validateParameter(valid_608114, JArray, required = true, default = nil)
  if valid_608114 != nil:
    section.add "TagKeys", valid_608114
  var valid_608115 = formData.getOrDefault("ResourceName")
  valid_608115 = validateParameter(valid_608115, JString, required = true,
                                 default = nil)
  if valid_608115 != nil:
    section.add "ResourceName", valid_608115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608116: Call_PostRemoveTagsFromResource_608102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608116.validator(path, query, header, formData, body)
  let scheme = call_608116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608116.url(scheme.get, call_608116.host, call_608116.base,
                         call_608116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608116, url, valid)

proc call*(call_608117: Call_PostRemoveTagsFromResource_608102; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_608118 = newJObject()
  var formData_608119 = newJObject()
  if TagKeys != nil:
    formData_608119.add "TagKeys", TagKeys
  add(query_608118, "Action", newJString(Action))
  add(query_608118, "Version", newJString(Version))
  add(formData_608119, "ResourceName", newJString(ResourceName))
  result = call_608117.call(nil, query_608118, nil, formData_608119, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_608102(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_608103, base: "/",
    url: url_PostRemoveTagsFromResource_608104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_608085 = ref object of OpenApiRestCall_605573
proc url_GetRemoveTagsFromResource_608087(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_608086(path: JsonNode; query: JsonNode;
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
  var valid_608088 = query.getOrDefault("ResourceName")
  valid_608088 = validateParameter(valid_608088, JString, required = true,
                                 default = nil)
  if valid_608088 != nil:
    section.add "ResourceName", valid_608088
  var valid_608089 = query.getOrDefault("TagKeys")
  valid_608089 = validateParameter(valid_608089, JArray, required = true, default = nil)
  if valid_608089 != nil:
    section.add "TagKeys", valid_608089
  var valid_608090 = query.getOrDefault("Action")
  valid_608090 = validateParameter(valid_608090, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_608090 != nil:
    section.add "Action", valid_608090
  var valid_608091 = query.getOrDefault("Version")
  valid_608091 = validateParameter(valid_608091, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608099: Call_GetRemoveTagsFromResource_608085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608099.validator(path, query, header, formData, body)
  let scheme = call_608099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608099.url(scheme.get, call_608099.host, call_608099.base,
                         call_608099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608099, url, valid)

proc call*(call_608100: Call_GetRemoveTagsFromResource_608085;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608101 = newJObject()
  add(query_608101, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_608101.add "TagKeys", TagKeys
  add(query_608101, "Action", newJString(Action))
  add(query_608101, "Version", newJString(Version))
  result = call_608100.call(nil, query_608101, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_608085(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_608086, base: "/",
    url: url_GetRemoveTagsFromResource_608087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_608138 = ref object of OpenApiRestCall_605573
proc url_PostResetDBParameterGroup_608140(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_608139(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608141 = query.getOrDefault("Action")
  valid_608141 = validateParameter(valid_608141, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608141 != nil:
    section.add "Action", valid_608141
  var valid_608142 = query.getOrDefault("Version")
  valid_608142 = validateParameter(valid_608142, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608142 != nil:
    section.add "Version", valid_608142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608143 = header.getOrDefault("X-Amz-Signature")
  valid_608143 = validateParameter(valid_608143, JString, required = false,
                                 default = nil)
  if valid_608143 != nil:
    section.add "X-Amz-Signature", valid_608143
  var valid_608144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608144 = validateParameter(valid_608144, JString, required = false,
                                 default = nil)
  if valid_608144 != nil:
    section.add "X-Amz-Content-Sha256", valid_608144
  var valid_608145 = header.getOrDefault("X-Amz-Date")
  valid_608145 = validateParameter(valid_608145, JString, required = false,
                                 default = nil)
  if valid_608145 != nil:
    section.add "X-Amz-Date", valid_608145
  var valid_608146 = header.getOrDefault("X-Amz-Credential")
  valid_608146 = validateParameter(valid_608146, JString, required = false,
                                 default = nil)
  if valid_608146 != nil:
    section.add "X-Amz-Credential", valid_608146
  var valid_608147 = header.getOrDefault("X-Amz-Security-Token")
  valid_608147 = validateParameter(valid_608147, JString, required = false,
                                 default = nil)
  if valid_608147 != nil:
    section.add "X-Amz-Security-Token", valid_608147
  var valid_608148 = header.getOrDefault("X-Amz-Algorithm")
  valid_608148 = validateParameter(valid_608148, JString, required = false,
                                 default = nil)
  if valid_608148 != nil:
    section.add "X-Amz-Algorithm", valid_608148
  var valid_608149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608149 = validateParameter(valid_608149, JString, required = false,
                                 default = nil)
  if valid_608149 != nil:
    section.add "X-Amz-SignedHeaders", valid_608149
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_608150 = formData.getOrDefault("ResetAllParameters")
  valid_608150 = validateParameter(valid_608150, JBool, required = false, default = nil)
  if valid_608150 != nil:
    section.add "ResetAllParameters", valid_608150
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_608151 = formData.getOrDefault("DBParameterGroupName")
  valid_608151 = validateParameter(valid_608151, JString, required = true,
                                 default = nil)
  if valid_608151 != nil:
    section.add "DBParameterGroupName", valid_608151
  var valid_608152 = formData.getOrDefault("Parameters")
  valid_608152 = validateParameter(valid_608152, JArray, required = false,
                                 default = nil)
  if valid_608152 != nil:
    section.add "Parameters", valid_608152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608153: Call_PostResetDBParameterGroup_608138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608153.validator(path, query, header, formData, body)
  let scheme = call_608153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608153.url(scheme.get, call_608153.host, call_608153.base,
                         call_608153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608153, url, valid)

proc call*(call_608154: Call_PostResetDBParameterGroup_608138;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_608155 = newJObject()
  var formData_608156 = newJObject()
  add(formData_608156, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_608156, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_608155, "Action", newJString(Action))
  if Parameters != nil:
    formData_608156.add "Parameters", Parameters
  add(query_608155, "Version", newJString(Version))
  result = call_608154.call(nil, query_608155, nil, formData_608156, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_608138(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_608139, base: "/",
    url: url_PostResetDBParameterGroup_608140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_608120 = ref object of OpenApiRestCall_605573
proc url_GetResetDBParameterGroup_608122(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_608121(path: JsonNode; query: JsonNode;
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
  var valid_608123 = query.getOrDefault("DBParameterGroupName")
  valid_608123 = validateParameter(valid_608123, JString, required = true,
                                 default = nil)
  if valid_608123 != nil:
    section.add "DBParameterGroupName", valid_608123
  var valid_608124 = query.getOrDefault("Parameters")
  valid_608124 = validateParameter(valid_608124, JArray, required = false,
                                 default = nil)
  if valid_608124 != nil:
    section.add "Parameters", valid_608124
  var valid_608125 = query.getOrDefault("ResetAllParameters")
  valid_608125 = validateParameter(valid_608125, JBool, required = false, default = nil)
  if valid_608125 != nil:
    section.add "ResetAllParameters", valid_608125
  var valid_608126 = query.getOrDefault("Action")
  valid_608126 = validateParameter(valid_608126, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_608126 != nil:
    section.add "Action", valid_608126
  var valid_608127 = query.getOrDefault("Version")
  valid_608127 = validateParameter(valid_608127, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608127 != nil:
    section.add "Version", valid_608127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608128 = header.getOrDefault("X-Amz-Signature")
  valid_608128 = validateParameter(valid_608128, JString, required = false,
                                 default = nil)
  if valid_608128 != nil:
    section.add "X-Amz-Signature", valid_608128
  var valid_608129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608129 = validateParameter(valid_608129, JString, required = false,
                                 default = nil)
  if valid_608129 != nil:
    section.add "X-Amz-Content-Sha256", valid_608129
  var valid_608130 = header.getOrDefault("X-Amz-Date")
  valid_608130 = validateParameter(valid_608130, JString, required = false,
                                 default = nil)
  if valid_608130 != nil:
    section.add "X-Amz-Date", valid_608130
  var valid_608131 = header.getOrDefault("X-Amz-Credential")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "X-Amz-Credential", valid_608131
  var valid_608132 = header.getOrDefault("X-Amz-Security-Token")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "X-Amz-Security-Token", valid_608132
  var valid_608133 = header.getOrDefault("X-Amz-Algorithm")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-Algorithm", valid_608133
  var valid_608134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608134 = validateParameter(valid_608134, JString, required = false,
                                 default = nil)
  if valid_608134 != nil:
    section.add "X-Amz-SignedHeaders", valid_608134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608135: Call_GetResetDBParameterGroup_608120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_608135.validator(path, query, header, formData, body)
  let scheme = call_608135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608135.url(scheme.get, call_608135.host, call_608135.base,
                         call_608135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608135, url, valid)

proc call*(call_608136: Call_GetResetDBParameterGroup_608120;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_608137 = newJObject()
  add(query_608137, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_608137.add "Parameters", Parameters
  add(query_608137, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_608137, "Action", newJString(Action))
  add(query_608137, "Version", newJString(Version))
  result = call_608136.call(nil, query_608137, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_608120(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_608121, base: "/",
    url: url_GetResetDBParameterGroup_608122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_608187 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceFromDBSnapshot_608189(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_608188(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608190 = query.getOrDefault("Action")
  valid_608190 = validateParameter(valid_608190, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608190 != nil:
    section.add "Action", valid_608190
  var valid_608191 = query.getOrDefault("Version")
  valid_608191 = validateParameter(valid_608191, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608191 != nil:
    section.add "Version", valid_608191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608192 = header.getOrDefault("X-Amz-Signature")
  valid_608192 = validateParameter(valid_608192, JString, required = false,
                                 default = nil)
  if valid_608192 != nil:
    section.add "X-Amz-Signature", valid_608192
  var valid_608193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608193 = validateParameter(valid_608193, JString, required = false,
                                 default = nil)
  if valid_608193 != nil:
    section.add "X-Amz-Content-Sha256", valid_608193
  var valid_608194 = header.getOrDefault("X-Amz-Date")
  valid_608194 = validateParameter(valid_608194, JString, required = false,
                                 default = nil)
  if valid_608194 != nil:
    section.add "X-Amz-Date", valid_608194
  var valid_608195 = header.getOrDefault("X-Amz-Credential")
  valid_608195 = validateParameter(valid_608195, JString, required = false,
                                 default = nil)
  if valid_608195 != nil:
    section.add "X-Amz-Credential", valid_608195
  var valid_608196 = header.getOrDefault("X-Amz-Security-Token")
  valid_608196 = validateParameter(valid_608196, JString, required = false,
                                 default = nil)
  if valid_608196 != nil:
    section.add "X-Amz-Security-Token", valid_608196
  var valid_608197 = header.getOrDefault("X-Amz-Algorithm")
  valid_608197 = validateParameter(valid_608197, JString, required = false,
                                 default = nil)
  if valid_608197 != nil:
    section.add "X-Amz-Algorithm", valid_608197
  var valid_608198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608198 = validateParameter(valid_608198, JString, required = false,
                                 default = nil)
  if valid_608198 != nil:
    section.add "X-Amz-SignedHeaders", valid_608198
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
  var valid_608199 = formData.getOrDefault("Port")
  valid_608199 = validateParameter(valid_608199, JInt, required = false, default = nil)
  if valid_608199 != nil:
    section.add "Port", valid_608199
  var valid_608200 = formData.getOrDefault("DBInstanceClass")
  valid_608200 = validateParameter(valid_608200, JString, required = false,
                                 default = nil)
  if valid_608200 != nil:
    section.add "DBInstanceClass", valid_608200
  var valid_608201 = formData.getOrDefault("MultiAZ")
  valid_608201 = validateParameter(valid_608201, JBool, required = false, default = nil)
  if valid_608201 != nil:
    section.add "MultiAZ", valid_608201
  var valid_608202 = formData.getOrDefault("AvailabilityZone")
  valid_608202 = validateParameter(valid_608202, JString, required = false,
                                 default = nil)
  if valid_608202 != nil:
    section.add "AvailabilityZone", valid_608202
  var valid_608203 = formData.getOrDefault("Engine")
  valid_608203 = validateParameter(valid_608203, JString, required = false,
                                 default = nil)
  if valid_608203 != nil:
    section.add "Engine", valid_608203
  var valid_608204 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608204 = validateParameter(valid_608204, JBool, required = false, default = nil)
  if valid_608204 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608204
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608205 = formData.getOrDefault("DBInstanceIdentifier")
  valid_608205 = validateParameter(valid_608205, JString, required = true,
                                 default = nil)
  if valid_608205 != nil:
    section.add "DBInstanceIdentifier", valid_608205
  var valid_608206 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_608206 = validateParameter(valid_608206, JString, required = true,
                                 default = nil)
  if valid_608206 != nil:
    section.add "DBSnapshotIdentifier", valid_608206
  var valid_608207 = formData.getOrDefault("DBName")
  valid_608207 = validateParameter(valid_608207, JString, required = false,
                                 default = nil)
  if valid_608207 != nil:
    section.add "DBName", valid_608207
  var valid_608208 = formData.getOrDefault("Iops")
  valid_608208 = validateParameter(valid_608208, JInt, required = false, default = nil)
  if valid_608208 != nil:
    section.add "Iops", valid_608208
  var valid_608209 = formData.getOrDefault("PubliclyAccessible")
  valid_608209 = validateParameter(valid_608209, JBool, required = false, default = nil)
  if valid_608209 != nil:
    section.add "PubliclyAccessible", valid_608209
  var valid_608210 = formData.getOrDefault("LicenseModel")
  valid_608210 = validateParameter(valid_608210, JString, required = false,
                                 default = nil)
  if valid_608210 != nil:
    section.add "LicenseModel", valid_608210
  var valid_608211 = formData.getOrDefault("Tags")
  valid_608211 = validateParameter(valid_608211, JArray, required = false,
                                 default = nil)
  if valid_608211 != nil:
    section.add "Tags", valid_608211
  var valid_608212 = formData.getOrDefault("DBSubnetGroupName")
  valid_608212 = validateParameter(valid_608212, JString, required = false,
                                 default = nil)
  if valid_608212 != nil:
    section.add "DBSubnetGroupName", valid_608212
  var valid_608213 = formData.getOrDefault("OptionGroupName")
  valid_608213 = validateParameter(valid_608213, JString, required = false,
                                 default = nil)
  if valid_608213 != nil:
    section.add "OptionGroupName", valid_608213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608214: Call_PostRestoreDBInstanceFromDBSnapshot_608187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608214.validator(path, query, header, formData, body)
  let scheme = call_608214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608214.url(scheme.get, call_608214.host, call_608214.base,
                         call_608214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608214, url, valid)

proc call*(call_608215: Call_PostRestoreDBInstanceFromDBSnapshot_608187;
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
  var query_608216 = newJObject()
  var formData_608217 = newJObject()
  add(formData_608217, "Port", newJInt(Port))
  add(formData_608217, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608217, "MultiAZ", newJBool(MultiAZ))
  add(formData_608217, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608217, "Engine", newJString(Engine))
  add(formData_608217, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608217, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_608217, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_608217, "DBName", newJString(DBName))
  add(formData_608217, "Iops", newJInt(Iops))
  add(formData_608217, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608216, "Action", newJString(Action))
  add(formData_608217, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_608217.add "Tags", Tags
  add(formData_608217, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608217, "OptionGroupName", newJString(OptionGroupName))
  add(query_608216, "Version", newJString(Version))
  result = call_608215.call(nil, query_608216, nil, formData_608217, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_608187(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_608188, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_608189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_608157 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceFromDBSnapshot_608159(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_608158(path: JsonNode;
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
  var valid_608160 = query.getOrDefault("DBName")
  valid_608160 = validateParameter(valid_608160, JString, required = false,
                                 default = nil)
  if valid_608160 != nil:
    section.add "DBName", valid_608160
  var valid_608161 = query.getOrDefault("Engine")
  valid_608161 = validateParameter(valid_608161, JString, required = false,
                                 default = nil)
  if valid_608161 != nil:
    section.add "Engine", valid_608161
  var valid_608162 = query.getOrDefault("Tags")
  valid_608162 = validateParameter(valid_608162, JArray, required = false,
                                 default = nil)
  if valid_608162 != nil:
    section.add "Tags", valid_608162
  var valid_608163 = query.getOrDefault("LicenseModel")
  valid_608163 = validateParameter(valid_608163, JString, required = false,
                                 default = nil)
  if valid_608163 != nil:
    section.add "LicenseModel", valid_608163
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_608164 = query.getOrDefault("DBInstanceIdentifier")
  valid_608164 = validateParameter(valid_608164, JString, required = true,
                                 default = nil)
  if valid_608164 != nil:
    section.add "DBInstanceIdentifier", valid_608164
  var valid_608165 = query.getOrDefault("DBSnapshotIdentifier")
  valid_608165 = validateParameter(valid_608165, JString, required = true,
                                 default = nil)
  if valid_608165 != nil:
    section.add "DBSnapshotIdentifier", valid_608165
  var valid_608166 = query.getOrDefault("Action")
  valid_608166 = validateParameter(valid_608166, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_608166 != nil:
    section.add "Action", valid_608166
  var valid_608167 = query.getOrDefault("MultiAZ")
  valid_608167 = validateParameter(valid_608167, JBool, required = false, default = nil)
  if valid_608167 != nil:
    section.add "MultiAZ", valid_608167
  var valid_608168 = query.getOrDefault("Port")
  valid_608168 = validateParameter(valid_608168, JInt, required = false, default = nil)
  if valid_608168 != nil:
    section.add "Port", valid_608168
  var valid_608169 = query.getOrDefault("AvailabilityZone")
  valid_608169 = validateParameter(valid_608169, JString, required = false,
                                 default = nil)
  if valid_608169 != nil:
    section.add "AvailabilityZone", valid_608169
  var valid_608170 = query.getOrDefault("OptionGroupName")
  valid_608170 = validateParameter(valid_608170, JString, required = false,
                                 default = nil)
  if valid_608170 != nil:
    section.add "OptionGroupName", valid_608170
  var valid_608171 = query.getOrDefault("DBSubnetGroupName")
  valid_608171 = validateParameter(valid_608171, JString, required = false,
                                 default = nil)
  if valid_608171 != nil:
    section.add "DBSubnetGroupName", valid_608171
  var valid_608172 = query.getOrDefault("Version")
  valid_608172 = validateParameter(valid_608172, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608172 != nil:
    section.add "Version", valid_608172
  var valid_608173 = query.getOrDefault("DBInstanceClass")
  valid_608173 = validateParameter(valid_608173, JString, required = false,
                                 default = nil)
  if valid_608173 != nil:
    section.add "DBInstanceClass", valid_608173
  var valid_608174 = query.getOrDefault("PubliclyAccessible")
  valid_608174 = validateParameter(valid_608174, JBool, required = false, default = nil)
  if valid_608174 != nil:
    section.add "PubliclyAccessible", valid_608174
  var valid_608175 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608175 = validateParameter(valid_608175, JBool, required = false, default = nil)
  if valid_608175 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608175
  var valid_608176 = query.getOrDefault("Iops")
  valid_608176 = validateParameter(valid_608176, JInt, required = false, default = nil)
  if valid_608176 != nil:
    section.add "Iops", valid_608176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608177 = header.getOrDefault("X-Amz-Signature")
  valid_608177 = validateParameter(valid_608177, JString, required = false,
                                 default = nil)
  if valid_608177 != nil:
    section.add "X-Amz-Signature", valid_608177
  var valid_608178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608178 = validateParameter(valid_608178, JString, required = false,
                                 default = nil)
  if valid_608178 != nil:
    section.add "X-Amz-Content-Sha256", valid_608178
  var valid_608179 = header.getOrDefault("X-Amz-Date")
  valid_608179 = validateParameter(valid_608179, JString, required = false,
                                 default = nil)
  if valid_608179 != nil:
    section.add "X-Amz-Date", valid_608179
  var valid_608180 = header.getOrDefault("X-Amz-Credential")
  valid_608180 = validateParameter(valid_608180, JString, required = false,
                                 default = nil)
  if valid_608180 != nil:
    section.add "X-Amz-Credential", valid_608180
  var valid_608181 = header.getOrDefault("X-Amz-Security-Token")
  valid_608181 = validateParameter(valid_608181, JString, required = false,
                                 default = nil)
  if valid_608181 != nil:
    section.add "X-Amz-Security-Token", valid_608181
  var valid_608182 = header.getOrDefault("X-Amz-Algorithm")
  valid_608182 = validateParameter(valid_608182, JString, required = false,
                                 default = nil)
  if valid_608182 != nil:
    section.add "X-Amz-Algorithm", valid_608182
  var valid_608183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608183 = validateParameter(valid_608183, JString, required = false,
                                 default = nil)
  if valid_608183 != nil:
    section.add "X-Amz-SignedHeaders", valid_608183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608184: Call_GetRestoreDBInstanceFromDBSnapshot_608157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608184.validator(path, query, header, formData, body)
  let scheme = call_608184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608184.url(scheme.get, call_608184.host, call_608184.base,
                         call_608184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608184, url, valid)

proc call*(call_608185: Call_GetRestoreDBInstanceFromDBSnapshot_608157;
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
  var query_608186 = newJObject()
  add(query_608186, "DBName", newJString(DBName))
  add(query_608186, "Engine", newJString(Engine))
  if Tags != nil:
    query_608186.add "Tags", Tags
  add(query_608186, "LicenseModel", newJString(LicenseModel))
  add(query_608186, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_608186, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_608186, "Action", newJString(Action))
  add(query_608186, "MultiAZ", newJBool(MultiAZ))
  add(query_608186, "Port", newJInt(Port))
  add(query_608186, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608186, "OptionGroupName", newJString(OptionGroupName))
  add(query_608186, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608186, "Version", newJString(Version))
  add(query_608186, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608186, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608186, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608186, "Iops", newJInt(Iops))
  result = call_608185.call(nil, query_608186, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_608157(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_608158, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_608159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_608250 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBInstanceToPointInTime_608252(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_608251(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608253 = query.getOrDefault("Action")
  valid_608253 = validateParameter(valid_608253, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608253 != nil:
    section.add "Action", valid_608253
  var valid_608254 = query.getOrDefault("Version")
  valid_608254 = validateParameter(valid_608254, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608254 != nil:
    section.add "Version", valid_608254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608255 = header.getOrDefault("X-Amz-Signature")
  valid_608255 = validateParameter(valid_608255, JString, required = false,
                                 default = nil)
  if valid_608255 != nil:
    section.add "X-Amz-Signature", valid_608255
  var valid_608256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608256 = validateParameter(valid_608256, JString, required = false,
                                 default = nil)
  if valid_608256 != nil:
    section.add "X-Amz-Content-Sha256", valid_608256
  var valid_608257 = header.getOrDefault("X-Amz-Date")
  valid_608257 = validateParameter(valid_608257, JString, required = false,
                                 default = nil)
  if valid_608257 != nil:
    section.add "X-Amz-Date", valid_608257
  var valid_608258 = header.getOrDefault("X-Amz-Credential")
  valid_608258 = validateParameter(valid_608258, JString, required = false,
                                 default = nil)
  if valid_608258 != nil:
    section.add "X-Amz-Credential", valid_608258
  var valid_608259 = header.getOrDefault("X-Amz-Security-Token")
  valid_608259 = validateParameter(valid_608259, JString, required = false,
                                 default = nil)
  if valid_608259 != nil:
    section.add "X-Amz-Security-Token", valid_608259
  var valid_608260 = header.getOrDefault("X-Amz-Algorithm")
  valid_608260 = validateParameter(valid_608260, JString, required = false,
                                 default = nil)
  if valid_608260 != nil:
    section.add "X-Amz-Algorithm", valid_608260
  var valid_608261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608261 = validateParameter(valid_608261, JString, required = false,
                                 default = nil)
  if valid_608261 != nil:
    section.add "X-Amz-SignedHeaders", valid_608261
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
  var valid_608262 = formData.getOrDefault("Port")
  valid_608262 = validateParameter(valid_608262, JInt, required = false, default = nil)
  if valid_608262 != nil:
    section.add "Port", valid_608262
  var valid_608263 = formData.getOrDefault("DBInstanceClass")
  valid_608263 = validateParameter(valid_608263, JString, required = false,
                                 default = nil)
  if valid_608263 != nil:
    section.add "DBInstanceClass", valid_608263
  var valid_608264 = formData.getOrDefault("MultiAZ")
  valid_608264 = validateParameter(valid_608264, JBool, required = false, default = nil)
  if valid_608264 != nil:
    section.add "MultiAZ", valid_608264
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_608265 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_608265 = validateParameter(valid_608265, JString, required = true,
                                 default = nil)
  if valid_608265 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608265
  var valid_608266 = formData.getOrDefault("AvailabilityZone")
  valid_608266 = validateParameter(valid_608266, JString, required = false,
                                 default = nil)
  if valid_608266 != nil:
    section.add "AvailabilityZone", valid_608266
  var valid_608267 = formData.getOrDefault("Engine")
  valid_608267 = validateParameter(valid_608267, JString, required = false,
                                 default = nil)
  if valid_608267 != nil:
    section.add "Engine", valid_608267
  var valid_608268 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_608268 = validateParameter(valid_608268, JBool, required = false, default = nil)
  if valid_608268 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608268
  var valid_608269 = formData.getOrDefault("UseLatestRestorableTime")
  valid_608269 = validateParameter(valid_608269, JBool, required = false, default = nil)
  if valid_608269 != nil:
    section.add "UseLatestRestorableTime", valid_608269
  var valid_608270 = formData.getOrDefault("DBName")
  valid_608270 = validateParameter(valid_608270, JString, required = false,
                                 default = nil)
  if valid_608270 != nil:
    section.add "DBName", valid_608270
  var valid_608271 = formData.getOrDefault("Iops")
  valid_608271 = validateParameter(valid_608271, JInt, required = false, default = nil)
  if valid_608271 != nil:
    section.add "Iops", valid_608271
  var valid_608272 = formData.getOrDefault("PubliclyAccessible")
  valid_608272 = validateParameter(valid_608272, JBool, required = false, default = nil)
  if valid_608272 != nil:
    section.add "PubliclyAccessible", valid_608272
  var valid_608273 = formData.getOrDefault("LicenseModel")
  valid_608273 = validateParameter(valid_608273, JString, required = false,
                                 default = nil)
  if valid_608273 != nil:
    section.add "LicenseModel", valid_608273
  var valid_608274 = formData.getOrDefault("Tags")
  valid_608274 = validateParameter(valid_608274, JArray, required = false,
                                 default = nil)
  if valid_608274 != nil:
    section.add "Tags", valid_608274
  var valid_608275 = formData.getOrDefault("DBSubnetGroupName")
  valid_608275 = validateParameter(valid_608275, JString, required = false,
                                 default = nil)
  if valid_608275 != nil:
    section.add "DBSubnetGroupName", valid_608275
  var valid_608276 = formData.getOrDefault("OptionGroupName")
  valid_608276 = validateParameter(valid_608276, JString, required = false,
                                 default = nil)
  if valid_608276 != nil:
    section.add "OptionGroupName", valid_608276
  var valid_608277 = formData.getOrDefault("RestoreTime")
  valid_608277 = validateParameter(valid_608277, JString, required = false,
                                 default = nil)
  if valid_608277 != nil:
    section.add "RestoreTime", valid_608277
  var valid_608278 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_608278 = validateParameter(valid_608278, JString, required = true,
                                 default = nil)
  if valid_608278 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608279: Call_PostRestoreDBInstanceToPointInTime_608250;
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

proc call*(call_608280: Call_PostRestoreDBInstanceToPointInTime_608250;
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
  var query_608281 = newJObject()
  var formData_608282 = newJObject()
  add(formData_608282, "Port", newJInt(Port))
  add(formData_608282, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_608282, "MultiAZ", newJBool(MultiAZ))
  add(formData_608282, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_608282, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_608282, "Engine", newJString(Engine))
  add(formData_608282, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_608282, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_608282, "DBName", newJString(DBName))
  add(formData_608282, "Iops", newJInt(Iops))
  add(formData_608282, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608281, "Action", newJString(Action))
  add(formData_608282, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_608282.add "Tags", Tags
  add(formData_608282, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_608282, "OptionGroupName", newJString(OptionGroupName))
  add(formData_608282, "RestoreTime", newJString(RestoreTime))
  add(formData_608282, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608281, "Version", newJString(Version))
  result = call_608280.call(nil, query_608281, nil, formData_608282, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_608250(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_608251, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_608252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_608218 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBInstanceToPointInTime_608220(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_608219(path: JsonNode;
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
  var valid_608221 = query.getOrDefault("DBName")
  valid_608221 = validateParameter(valid_608221, JString, required = false,
                                 default = nil)
  if valid_608221 != nil:
    section.add "DBName", valid_608221
  var valid_608222 = query.getOrDefault("Engine")
  valid_608222 = validateParameter(valid_608222, JString, required = false,
                                 default = nil)
  if valid_608222 != nil:
    section.add "Engine", valid_608222
  var valid_608223 = query.getOrDefault("UseLatestRestorableTime")
  valid_608223 = validateParameter(valid_608223, JBool, required = false, default = nil)
  if valid_608223 != nil:
    section.add "UseLatestRestorableTime", valid_608223
  var valid_608224 = query.getOrDefault("Tags")
  valid_608224 = validateParameter(valid_608224, JArray, required = false,
                                 default = nil)
  if valid_608224 != nil:
    section.add "Tags", valid_608224
  var valid_608225 = query.getOrDefault("LicenseModel")
  valid_608225 = validateParameter(valid_608225, JString, required = false,
                                 default = nil)
  if valid_608225 != nil:
    section.add "LicenseModel", valid_608225
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_608226 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_608226 = validateParameter(valid_608226, JString, required = true,
                                 default = nil)
  if valid_608226 != nil:
    section.add "TargetDBInstanceIdentifier", valid_608226
  var valid_608227 = query.getOrDefault("Action")
  valid_608227 = validateParameter(valid_608227, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_608227 != nil:
    section.add "Action", valid_608227
  var valid_608228 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_608228 = validateParameter(valid_608228, JString, required = true,
                                 default = nil)
  if valid_608228 != nil:
    section.add "SourceDBInstanceIdentifier", valid_608228
  var valid_608229 = query.getOrDefault("MultiAZ")
  valid_608229 = validateParameter(valid_608229, JBool, required = false, default = nil)
  if valid_608229 != nil:
    section.add "MultiAZ", valid_608229
  var valid_608230 = query.getOrDefault("Port")
  valid_608230 = validateParameter(valid_608230, JInt, required = false, default = nil)
  if valid_608230 != nil:
    section.add "Port", valid_608230
  var valid_608231 = query.getOrDefault("AvailabilityZone")
  valid_608231 = validateParameter(valid_608231, JString, required = false,
                                 default = nil)
  if valid_608231 != nil:
    section.add "AvailabilityZone", valid_608231
  var valid_608232 = query.getOrDefault("OptionGroupName")
  valid_608232 = validateParameter(valid_608232, JString, required = false,
                                 default = nil)
  if valid_608232 != nil:
    section.add "OptionGroupName", valid_608232
  var valid_608233 = query.getOrDefault("DBSubnetGroupName")
  valid_608233 = validateParameter(valid_608233, JString, required = false,
                                 default = nil)
  if valid_608233 != nil:
    section.add "DBSubnetGroupName", valid_608233
  var valid_608234 = query.getOrDefault("RestoreTime")
  valid_608234 = validateParameter(valid_608234, JString, required = false,
                                 default = nil)
  if valid_608234 != nil:
    section.add "RestoreTime", valid_608234
  var valid_608235 = query.getOrDefault("DBInstanceClass")
  valid_608235 = validateParameter(valid_608235, JString, required = false,
                                 default = nil)
  if valid_608235 != nil:
    section.add "DBInstanceClass", valid_608235
  var valid_608236 = query.getOrDefault("PubliclyAccessible")
  valid_608236 = validateParameter(valid_608236, JBool, required = false, default = nil)
  if valid_608236 != nil:
    section.add "PubliclyAccessible", valid_608236
  var valid_608237 = query.getOrDefault("Version")
  valid_608237 = validateParameter(valid_608237, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608237 != nil:
    section.add "Version", valid_608237
  var valid_608238 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_608238 = validateParameter(valid_608238, JBool, required = false, default = nil)
  if valid_608238 != nil:
    section.add "AutoMinorVersionUpgrade", valid_608238
  var valid_608239 = query.getOrDefault("Iops")
  valid_608239 = validateParameter(valid_608239, JInt, required = false, default = nil)
  if valid_608239 != nil:
    section.add "Iops", valid_608239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608240 = header.getOrDefault("X-Amz-Signature")
  valid_608240 = validateParameter(valid_608240, JString, required = false,
                                 default = nil)
  if valid_608240 != nil:
    section.add "X-Amz-Signature", valid_608240
  var valid_608241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608241 = validateParameter(valid_608241, JString, required = false,
                                 default = nil)
  if valid_608241 != nil:
    section.add "X-Amz-Content-Sha256", valid_608241
  var valid_608242 = header.getOrDefault("X-Amz-Date")
  valid_608242 = validateParameter(valid_608242, JString, required = false,
                                 default = nil)
  if valid_608242 != nil:
    section.add "X-Amz-Date", valid_608242
  var valid_608243 = header.getOrDefault("X-Amz-Credential")
  valid_608243 = validateParameter(valid_608243, JString, required = false,
                                 default = nil)
  if valid_608243 != nil:
    section.add "X-Amz-Credential", valid_608243
  var valid_608244 = header.getOrDefault("X-Amz-Security-Token")
  valid_608244 = validateParameter(valid_608244, JString, required = false,
                                 default = nil)
  if valid_608244 != nil:
    section.add "X-Amz-Security-Token", valid_608244
  var valid_608245 = header.getOrDefault("X-Amz-Algorithm")
  valid_608245 = validateParameter(valid_608245, JString, required = false,
                                 default = nil)
  if valid_608245 != nil:
    section.add "X-Amz-Algorithm", valid_608245
  var valid_608246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608246 = validateParameter(valid_608246, JString, required = false,
                                 default = nil)
  if valid_608246 != nil:
    section.add "X-Amz-SignedHeaders", valid_608246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608247: Call_GetRestoreDBInstanceToPointInTime_608218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608247.validator(path, query, header, formData, body)
  let scheme = call_608247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608247.url(scheme.get, call_608247.host, call_608247.base,
                         call_608247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608247, url, valid)

proc call*(call_608248: Call_GetRestoreDBInstanceToPointInTime_608218;
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
  var query_608249 = newJObject()
  add(query_608249, "DBName", newJString(DBName))
  add(query_608249, "Engine", newJString(Engine))
  add(query_608249, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_608249.add "Tags", Tags
  add(query_608249, "LicenseModel", newJString(LicenseModel))
  add(query_608249, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_608249, "Action", newJString(Action))
  add(query_608249, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_608249, "MultiAZ", newJBool(MultiAZ))
  add(query_608249, "Port", newJInt(Port))
  add(query_608249, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_608249, "OptionGroupName", newJString(OptionGroupName))
  add(query_608249, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_608249, "RestoreTime", newJString(RestoreTime))
  add(query_608249, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_608249, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_608249, "Version", newJString(Version))
  add(query_608249, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_608249, "Iops", newJInt(Iops))
  result = call_608248.call(nil, query_608249, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_608218(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_608219, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_608220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_608303 = ref object of OpenApiRestCall_605573
proc url_PostRevokeDBSecurityGroupIngress_608305(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_608304(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_608306 = query.getOrDefault("Action")
  valid_608306 = validateParameter(valid_608306, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608306 != nil:
    section.add "Action", valid_608306
  var valid_608307 = query.getOrDefault("Version")
  valid_608307 = validateParameter(valid_608307, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608307 != nil:
    section.add "Version", valid_608307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608308 = header.getOrDefault("X-Amz-Signature")
  valid_608308 = validateParameter(valid_608308, JString, required = false,
                                 default = nil)
  if valid_608308 != nil:
    section.add "X-Amz-Signature", valid_608308
  var valid_608309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608309 = validateParameter(valid_608309, JString, required = false,
                                 default = nil)
  if valid_608309 != nil:
    section.add "X-Amz-Content-Sha256", valid_608309
  var valid_608310 = header.getOrDefault("X-Amz-Date")
  valid_608310 = validateParameter(valid_608310, JString, required = false,
                                 default = nil)
  if valid_608310 != nil:
    section.add "X-Amz-Date", valid_608310
  var valid_608311 = header.getOrDefault("X-Amz-Credential")
  valid_608311 = validateParameter(valid_608311, JString, required = false,
                                 default = nil)
  if valid_608311 != nil:
    section.add "X-Amz-Credential", valid_608311
  var valid_608312 = header.getOrDefault("X-Amz-Security-Token")
  valid_608312 = validateParameter(valid_608312, JString, required = false,
                                 default = nil)
  if valid_608312 != nil:
    section.add "X-Amz-Security-Token", valid_608312
  var valid_608313 = header.getOrDefault("X-Amz-Algorithm")
  valid_608313 = validateParameter(valid_608313, JString, required = false,
                                 default = nil)
  if valid_608313 != nil:
    section.add "X-Amz-Algorithm", valid_608313
  var valid_608314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608314 = validateParameter(valid_608314, JString, required = false,
                                 default = nil)
  if valid_608314 != nil:
    section.add "X-Amz-SignedHeaders", valid_608314
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608315 = formData.getOrDefault("DBSecurityGroupName")
  valid_608315 = validateParameter(valid_608315, JString, required = true,
                                 default = nil)
  if valid_608315 != nil:
    section.add "DBSecurityGroupName", valid_608315
  var valid_608316 = formData.getOrDefault("EC2SecurityGroupName")
  valid_608316 = validateParameter(valid_608316, JString, required = false,
                                 default = nil)
  if valid_608316 != nil:
    section.add "EC2SecurityGroupName", valid_608316
  var valid_608317 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608317 = validateParameter(valid_608317, JString, required = false,
                                 default = nil)
  if valid_608317 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608317
  var valid_608318 = formData.getOrDefault("EC2SecurityGroupId")
  valid_608318 = validateParameter(valid_608318, JString, required = false,
                                 default = nil)
  if valid_608318 != nil:
    section.add "EC2SecurityGroupId", valid_608318
  var valid_608319 = formData.getOrDefault("CIDRIP")
  valid_608319 = validateParameter(valid_608319, JString, required = false,
                                 default = nil)
  if valid_608319 != nil:
    section.add "CIDRIP", valid_608319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608320: Call_PostRevokeDBSecurityGroupIngress_608303;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608320.validator(path, query, header, formData, body)
  let scheme = call_608320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608320.url(scheme.get, call_608320.host, call_608320.base,
                         call_608320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608320, url, valid)

proc call*(call_608321: Call_PostRevokeDBSecurityGroupIngress_608303;
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
  var query_608322 = newJObject()
  var formData_608323 = newJObject()
  add(formData_608323, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_608323, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_608323, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_608323, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_608323, "CIDRIP", newJString(CIDRIP))
  add(query_608322, "Action", newJString(Action))
  add(query_608322, "Version", newJString(Version))
  result = call_608321.call(nil, query_608322, nil, formData_608323, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_608303(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_608304, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_608305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_608283 = ref object of OpenApiRestCall_605573
proc url_GetRevokeDBSecurityGroupIngress_608285(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_608284(path: JsonNode;
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
  var valid_608286 = query.getOrDefault("EC2SecurityGroupName")
  valid_608286 = validateParameter(valid_608286, JString, required = false,
                                 default = nil)
  if valid_608286 != nil:
    section.add "EC2SecurityGroupName", valid_608286
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_608287 = query.getOrDefault("DBSecurityGroupName")
  valid_608287 = validateParameter(valid_608287, JString, required = true,
                                 default = nil)
  if valid_608287 != nil:
    section.add "DBSecurityGroupName", valid_608287
  var valid_608288 = query.getOrDefault("EC2SecurityGroupId")
  valid_608288 = validateParameter(valid_608288, JString, required = false,
                                 default = nil)
  if valid_608288 != nil:
    section.add "EC2SecurityGroupId", valid_608288
  var valid_608289 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_608289 = validateParameter(valid_608289, JString, required = false,
                                 default = nil)
  if valid_608289 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_608289
  var valid_608290 = query.getOrDefault("Action")
  valid_608290 = validateParameter(valid_608290, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_608290 != nil:
    section.add "Action", valid_608290
  var valid_608291 = query.getOrDefault("Version")
  valid_608291 = validateParameter(valid_608291, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_608291 != nil:
    section.add "Version", valid_608291
  var valid_608292 = query.getOrDefault("CIDRIP")
  valid_608292 = validateParameter(valid_608292, JString, required = false,
                                 default = nil)
  if valid_608292 != nil:
    section.add "CIDRIP", valid_608292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_608293 = header.getOrDefault("X-Amz-Signature")
  valid_608293 = validateParameter(valid_608293, JString, required = false,
                                 default = nil)
  if valid_608293 != nil:
    section.add "X-Amz-Signature", valid_608293
  var valid_608294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608294 = validateParameter(valid_608294, JString, required = false,
                                 default = nil)
  if valid_608294 != nil:
    section.add "X-Amz-Content-Sha256", valid_608294
  var valid_608295 = header.getOrDefault("X-Amz-Date")
  valid_608295 = validateParameter(valid_608295, JString, required = false,
                                 default = nil)
  if valid_608295 != nil:
    section.add "X-Amz-Date", valid_608295
  var valid_608296 = header.getOrDefault("X-Amz-Credential")
  valid_608296 = validateParameter(valid_608296, JString, required = false,
                                 default = nil)
  if valid_608296 != nil:
    section.add "X-Amz-Credential", valid_608296
  var valid_608297 = header.getOrDefault("X-Amz-Security-Token")
  valid_608297 = validateParameter(valid_608297, JString, required = false,
                                 default = nil)
  if valid_608297 != nil:
    section.add "X-Amz-Security-Token", valid_608297
  var valid_608298 = header.getOrDefault("X-Amz-Algorithm")
  valid_608298 = validateParameter(valid_608298, JString, required = false,
                                 default = nil)
  if valid_608298 != nil:
    section.add "X-Amz-Algorithm", valid_608298
  var valid_608299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608299 = validateParameter(valid_608299, JString, required = false,
                                 default = nil)
  if valid_608299 != nil:
    section.add "X-Amz-SignedHeaders", valid_608299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_608300: Call_GetRevokeDBSecurityGroupIngress_608283;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_608300.validator(path, query, header, formData, body)
  let scheme = call_608300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608300.url(scheme.get, call_608300.host, call_608300.base,
                         call_608300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608300, url, valid)

proc call*(call_608301: Call_GetRevokeDBSecurityGroupIngress_608283;
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
  var query_608302 = newJObject()
  add(query_608302, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_608302, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_608302, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_608302, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_608302, "Action", newJString(Action))
  add(query_608302, "Version", newJString(Version))
  add(query_608302, "CIDRIP", newJString(CIDRIP))
  result = call_608301.call(nil, query_608302, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_608283(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_608284, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_608285,
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
